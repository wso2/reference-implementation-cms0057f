// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).

// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/log;
import ballerina/time;
import ballerina/uuid;
import ballerinax/health.clients.fhir as fhirClient;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincipdex220;
import ballerinax/health.fhir.r4.international401;

// ============================================================================
// Async Job Store
// ============================================================================

isolated map<DaVinciExportJob> davinciExportJobStore = {};

// ============================================================================
// DefaultDaVinciDataExporter — implements davincipdex220:DaVinciDataExporter
// ============================================================================

# Default implementation of the PDex DaVinciDataExporter interface.
# Creates an async job that fans out patient-level bulk exports for every
# member of the requested Group, then returns a Content-Location polling URL.
public isolated class DefaultDaVinciDataExporter {
    *davincipdex220:DaVinciDataExporter;

    public isolated function initiateExport(string groupId, davincipdex220:DataExportParameters params)
            returns davincipdex220:DataExportJob|r4:FHIRError {

        string jobId = uuid:createType1AsString();
        lock {
            davinciExportJobStore[jobId] = {
                jobId: jobId,
                status: DAVINCI_EXPORT_PENDING,
                createdAt: time:utcNow(),
                completedAt: (),
                result: (),
                errorMessage: ()
            };
        }
        _ = start processAndStoreDaVinciExport(jobId, groupId, params.cloneReadOnly());
        return {
            contentLocation: "/fhir/r4/_export/davinci-export-status/" + jobId,
            statusCode: 202
        };
    }
}

// ============================================================================
// Background Processor
// ============================================================================

# Fans out patient-level bulk exports for each member of the Group and
# stores the collected polling URLs in davinciExportJobStore.
#
# + jobId - The ID of the pre-created DaVinciExportJob
# + groupId - Logical ID of the Group resource to export
# + params - Export parameters (patient filter, date range, resource types, etc.)
isolated function processAndStoreDaVinciExport(
        string jobId, string groupId, davincipdex220:DataExportParameters & readonly params) {

    // Mark as processing
    lock {
        if davinciExportJobStore.hasKey(jobId) {
            DaVinciExportJob current = davinciExportJobStore.get(jobId);
            davinciExportJobStore[jobId] = {
                jobId: current.jobId,
                status: DAVINCI_EXPORT_PROCESSING,
                createdAt: current.createdAt,
                completedAt: (),
                result: (),
                errorMessage: ()
            };
        }
    }

    r4:DomainResource|r4:FHIRError groupResource = getById(fhirConnector, GROUP, groupId);
    if groupResource is r4:FHIRError {
        lock {
            if davinciExportJobStore.hasKey(jobId) {
                DaVinciExportJob current = davinciExportJobStore.get(jobId);
                davinciExportJobStore[jobId] = {
                    jobId: current.jobId,
                    status: DAVINCI_EXPORT_FAILED,
                    createdAt: current.createdAt,
                    completedAt: time:utcNow(),
                    result: (),
                    errorMessage: groupResource.message()
                };
            }
        }
        return;
    }

    Group|error currentGroup = groupResource.cloneWithType(Group);
    if currentGroup is error {
        lock {
            if davinciExportJobStore.hasKey(jobId) {
                DaVinciExportJob current = davinciExportJobStore.get(jobId);
                davinciExportJobStore[jobId] = {
                    jobId: current.jobId,
                    status: DAVINCI_EXPORT_FAILED,
                    createdAt: current.createdAt,
                    completedAt: time:utcNow(),
                    result: (),
                    errorMessage: "Failed to parse Group resource: " + currentGroup.message()
                };
            }
        }
        return;
    }

    international401:GroupMember[]? members = currentGroup.member;
    map<string> exportUrls = {};

    if members !is () {
        // Build patient filter set for O(1) lookup
        map<boolean> patientFilterSet = {};
        r4:Reference[]? patientFilter = params.patient;
        if patientFilter !is () {
            foreach r4:Reference pf in patientFilter {
                string? ref = pf.reference;
                if ref is string {
                    string pid = ref.startsWith("Patient/") ? ref.substring(8) : ref;
                    patientFilterSet[pid] = true;
                }
            }
        }
        boolean hasPatientFilter = patientFilterSet.length() > 0;

        foreach international401:GroupMember member in members {
            r4:Reference entity = member.entity;
            string? reference = entity.reference;
            if reference is string && reference.startsWith("Patient/") {
                string patientId = reference.substring(8);

                // Apply optional patient filter
                if hasPatientFilter && !patientFilterSet.hasKey(patientId) {
                    log:printDebug("Skipping patient " + patientId + ": not in patient filter");
                    continue;
                }

                // Build per-patient query parameters from DataExportParameters
                map<string[]> patientQueryParams = {};
                string? sinceVal = params._since;
                if sinceVal is string {
                    patientQueryParams["_since"] = [sinceVal];
                }
                string? untilVal = params._until;
                if untilVal is string {
                    patientQueryParams["_until"] = [untilVal];
                }
                string? typeVal = params._type;
                if typeVal is string {
                    patientQueryParams["_type"] = [typeVal];
                }
                string? typeFilterVal = params._typeFilter;
                if typeFilterVal is string {
                    patientQueryParams["_typeFilter"] = [typeFilterVal];
                }

                r4:FHIRError|http:Response|error exportRes =
                        invokePatientExport(patientId, patientQueryParams, fhirClient:GET);
                if exportRes is http:Response {
                    string|error pollingUrl = exportRes.getHeader("content-location");
                    if pollingUrl is string {
                        exportUrls[patientId] = pollingUrl.startsWith("/") ? serverBaseUrl + pollingUrl : pollingUrl;
                    } else {
                        exportUrls[patientId] = "Failed to get Content-Location: "
                                + exportRes.statusCode.toString();
                    }
                } else if exportRes is error {
                    exportUrls[patientId] = "Error: " + exportRes.message();
                }
            }
        }
    }

    DaVinciExportResult result = {
        transactionTime: time:utcToString(time:utcNow()),
        exportType: params.exportType ?: PDEX_EXPORT_TYPE_P2P,
        exportUrls: exportUrls
    };

    lock {
        if davinciExportJobStore.hasKey(jobId) {
            DaVinciExportJob current = davinciExportJobStore.get(jobId);
            davinciExportJobStore[jobId] = {
                jobId: current.jobId,
                status: DAVINCI_EXPORT_COMPLETED,
                createdAt: current.createdAt,
                completedAt: time:utcNow(),
                result: result.cloneReadOnly(),
                errorMessage: ()
            };
        }
    }
}

// ============================================================================
// Job Status Helper
// ============================================================================

# Returns a copy of the stored DaVinciExportJob for the given job ID, or () if not found.
#
# + jobId - The async job ID
# + return - A copy of the job record, or () if no such job exists
isolated function getDaVinciExportJob(string jobId) returns DaVinciExportJob? {
    lock {
        if davinciExportJobStore.hasKey(jobId) {
            return davinciExportJobStore.get(jobId).clone();
        }
    }
    return ();
}

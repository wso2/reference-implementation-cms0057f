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
import ballerina/lang.runtime;
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

const int MAX_POLL_ATTEMPTS = 60;
const decimal POLL_INTERVAL_SECONDS = 5.0d;

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
    // Phase A: kick off per-patient exports and collect polling URLs
    map<string> patientPollingUrls = {};

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
                        patientPollingUrls[patientId] =
                                pollingUrl.startsWith("/") ? serverBaseUrl + pollingUrl : pollingUrl;
                    } else {
                        log:printError("Patient " + patientId + ": missing Content-Location, status "
                                + exportRes.statusCode.toString());
                    }
                } else if exportRes is error {
                    log:printError("Patient " + patientId + ": export kick-off failed: " + exportRes.message());
                }
            }
        }
    }

    // Phase B: poll each per-patient export until it completes and collect output file URLs
    BulkDataOutputFile[] combinedOutput = [];
    BulkDataOutputFile[] combinedErrors = [];

    foreach string patientId in patientPollingUrls.keys() {
        string pollingUrl = patientPollingUrls.get(patientId);

        // Split the absolute polling URL into base (scheme+host+port) and path so that
        // the http:Client base never bleeds into the path, regardless of upstream port.
        int schemeEnd = pollingUrl.indexOf("://") ?: 0;
        int pathStartIdx = pollingUrl.indexOf("/", schemeEnd + 3) ?: pollingUrl.length();
        string clientBase = pollingUrl.substring(0, pathStartIdx);
        string pollPath = pathStartIdx < pollingUrl.length() ? pollingUrl.substring(pathStartIdx) : "/";

        http:Client|error statusClient = new http:Client(clientBase);
        if statusClient is error {
            log:printError("Patient " + patientId + ": failed to create HTTP client for "
                    + clientBase + ": " + statusClient.message());
            continue;
        }

        boolean patientDone = false;
        int attempt = 0;
        while !patientDone && attempt < MAX_POLL_ATTEMPTS {
            attempt += 1;
            http:Response|error pollRes = statusClient->get(pollPath);
            if pollRes is error {
                log:printError("Patient " + patientId + ": poll error on attempt " + attempt.toString()
                        + ": " + pollRes.message());
                runtime:sleep(POLL_INTERVAL_SECONDS);
                continue;
            }

            if pollRes.statusCode == http:STATUS_OK {
                json|error body = pollRes.getJsonPayload();
                if body is json {
                    json[] outputArr = [];
                    json|error outputField = body.output;
                    if outputField is json[] {
                        outputArr = outputField;
                    }
                    foreach json fileEntry in outputArr {
                        json|error fileType = fileEntry.'type;
                        json|error fileUrl = fileEntry.url;
                        if fileType is string && fileUrl is string {
                            string absUrl = fileUrl.startsWith("/") ? serverBaseUrl + fileUrl : fileUrl;
                            combinedOutput.push({'type: fileType, url: absUrl});
                        }
                    }
                    json[] errorArr = [];
                    json|error errorField = body.'error;
                    if errorField is json[] {
                        errorArr = errorField;
                    }
                    foreach json fileEntry in errorArr {
                        json|error fileType = fileEntry.'type;
                        json|error fileUrl = fileEntry.url;
                        if fileType is string && fileUrl is string {
                            string absUrl = fileUrl.startsWith("/") ? serverBaseUrl + fileUrl : fileUrl;
                            combinedErrors.push({'type: fileType, url: absUrl});
                        }
                    }
                }
                patientDone = true;
                log:printDebug("Patient " + patientId + ": export complete");
            } else if pollRes.statusCode == http:STATUS_ACCEPTED {
                decimal retryAfter = POLL_INTERVAL_SECONDS;
                string|error retryHeader = pollRes.getHeader("retry-after");
                if retryHeader is string {
                    int|error parsed = int:fromString(retryHeader);
                    if parsed is int {
                        retryAfter = <decimal>parsed;
                    }
                }
                log:printDebug("Patient " + patientId + ": still processing, retrying in "
                        + retryAfter.toString() + "s (attempt " + attempt.toString() + ")");
                runtime:sleep(retryAfter);
            } else {
                log:printError("Patient " + patientId + ": unexpected status " + pollRes.statusCode.toString());
                patientDone = true;
            }
        }
        if !patientDone {
            log:printError("Patient " + patientId + ": timed out after " + MAX_POLL_ATTEMPTS.toString() + " attempts");
        }
    }

    // Phase C: build the Bulk Data manifest and mark the group job complete
    DaVinciExportResult result = {
        transactionTime: time:utcToString(time:utcNow()),
        request: serverBaseUrl + "/fhir/r4/Group/" + groupId + "/$davinci-data-export",
        requiresAccessToken: false,
        output: combinedOutput,
        'error: combinedErrors.length() > 0 ? combinedErrors : ()
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

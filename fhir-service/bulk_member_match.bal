// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).

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
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincihrex100 as hrex100;
import ballerinax/health.fhir.r4.davincipdex220;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.uscore501;

// ============================================================================
// Async Job Store
// ============================================================================

isolated map<BulkMemberMatchJob> bulkMatchJobStore = {};

const decimal BULK_MATCH_JOB_TTL_SECONDS = 3600.0d;

isolated function evictExpiredBulkMatchJobs() {
    time:Utc now = time:utcNow();
    lock {
        string[] toRemove = [];
        foreach string key in bulkMatchJobStore.keys() {
            BulkMemberMatchJob job = bulkMatchJobStore.get(key);
            if time:utcDiffSeconds(now, job.createdAt) > BULK_MATCH_JOB_TTL_SECONDS {
                toRemove.push(key);
            }
        }
        foreach string key in toRemove {
            _ = bulkMatchJobStore.remove(key);
        }
    }
}

// ============================================================================
// Core Processing
// ============================================================================

# Processes a $bulk-member-match request, iterating over each MemberBundle entry in the
# input Parameters and categorising each member into one of:
#   - MatchedMembers        (match found, consent valid)
#   - NonMatchedMembers     (no match found in the system)
#   - ConsentConstrainedMembers (match found but consent evaluation failed)
#
# The MatchedMembers Group is persisted to the FHIR store so it can be used
# as the target of a subsequent $davinci-data-export call.
#
# + parameters - PDex Multi-Member Match Request Parameters resource
# + return - PDex typed response Parameters with three Group resources, or FHIRError
isolated function processBulkMemberMatch(davincipdex220:PDexMultiMemberMatchRequestParameters parameters)
        returns davincipdex220:PDexMultiMemberMatchResponseParameters|r4:FHIRError {

    davincipdex220:PDexMultiMemberMatchRequestParametersParameter[] paramEntries = parameters.'parameter;
    if paramEntries.length() == 0 {
        return r4:createFHIRError(BULK_MATCH_NO_MEMBER_BUNDLES, r4:ERROR, r4:INVALID,
                httpStatusCode = 400);
    }

    MemberOutcomeEntry[] matchedEntries = [];
    MemberOutcomeEntry[] nonMatchedEntries = [];
    MemberOutcomeEntry[] consentConstrainedEntries = [];

    foreach davincipdex220:PDexMultiMemberMatchRequestParametersParameter entry in paramEntries {
        if entry.name != "MemberBundle" {
            continue;
        }

        // Each MemberBundle has nested parts
        international401:ParametersParameter[]? parts = entry.part;
        if parts is () || parts.length() == 0 {
            log:printWarn("MemberBundle entry has no parts — skipping");
            nonMatchedEntries.push({originalPatient: (), memberRef: (), displayOnly: "MemberBundle with no parts"});
            continue;
        }

        // Extract the four resources from the MemberBundle parts
        uscore501:USCorePatientProfile? memberPatient = ();
        hrex100:HRexCoverage? coverageToMatch = ();
        hrex100:HRexCoverage? coverageToLink = ();
        hrex100:HRexConsent? consent = ();

        foreach international401:ParametersParameter part in parts {
            anydata partResource = part?.'resource;
            if partResource is () {
                continue;
            }
            match part.name {
                "MemberPatient" => {
                    uscore501:USCorePatientProfile|error pt =
                            partResource.cloneWithType(uscore501:USCorePatientProfile);
                    if pt is uscore501:USCorePatientProfile {
                        memberPatient = pt;
                    } else {
                        // Fallback: coerce a basic FHIR Patient by injecting required USCore
                        // fields (e.g. an empty identifier array) so cloneWithType succeeds.
                        log:printWarn("Strict USCore parse failed (" + pt.message()
                                + "); attempting lenient fallback for MemberPatient");
                        json|error ptJson = partResource.cloneWithType(json);
                        if ptJson is map<json> {
                            if !ptJson.hasKey("identifier") {
                                ptJson["identifier"] = [];
                            }
                            uscore501:USCorePatientProfile|error coerced =
                                    ptJson.cloneWithType(uscore501:USCorePatientProfile);
                            if coerced is uscore501:USCorePatientProfile {
                                memberPatient = coerced;
                            } else {
                                log:printWarn("Patient USCore parse also failed: " + coerced.message());
                            }
                        } else {
                            log:printWarn("Failed to convert MemberPatient to JSON: "
                                    + (ptJson is error ? ptJson.message() : "unexpected type"));
                        }
                    }
                }
                "CoverageToMatch" => {
                    hrex100:HRexCoverage|error cov =
                            partResource.cloneWithType(hrex100:HRexCoverage);
                    if cov is hrex100:HRexCoverage {
                        coverageToMatch = cov;
                    } else {
                        log:printWarn("Failed to parse CoverageToMatch: " + cov.message());
                    }
                }
                "CoverageToLink" => {
                    hrex100:HRexCoverage|error cov =
                            partResource.cloneWithType(hrex100:HRexCoverage);
                    if cov is hrex100:HRexCoverage {
                        coverageToLink = cov;
                    }
                }
                "Consent" => {
                    hrex100:HRexConsent|error c =
                            partResource.cloneWithType(hrex100:HRexConsent);
                    if c is hrex100:HRexConsent {
                        consent = c;
                    } else {
                        log:printWarn("Failed to parse Consent: " + c.message());
                    }
                }
            }
        }

        // Validate required parts
        if memberPatient is () {
            log:printWarn(BULK_MATCH_MISSING_PATIENT + " — marking as non-matched");
            nonMatchedEntries.push({originalPatient: (), memberRef: (), displayOnly: BULK_MATCH_MISSING_PATIENT});
            continue;
        }
        if coverageToMatch is () {
            log:printWarn(BULK_MATCH_MISSING_COVERAGE + " — marking as non-matched");
            nonMatchedEntries.push({originalPatient: memberPatient, memberRef: (), displayOnly: BULK_MATCH_MISSING_COVERAGE});
            continue;
        }
        if consent is () {
            log:printWarn(BULK_MATCH_MISSING_CONSENT + " — marking as non-matched");
            nonMatchedEntries.push({originalPatient: memberPatient, memberRef: (), displayOnly: BULK_MATCH_MISSING_CONSENT});
            continue;
        }

        hrex100:MemberMatchResources memberMatchResources = {
            memberPatient: memberPatient,
            coverageToMatch: coverageToMatch,
            coverageToLink: coverageToLink,
            consent: consent
        };

        // Run per-member match using the existing DemoFHIRMemberMatcher
        hrex100:MemberIdentifier|r4:FHIRError matchResult =
                fhirMemberMatcher.matchMember(memberMatchResources);

        if matchResult is r4:FHIRError {
            string covId = coverageToMatch.id ?: "unknown";
            int statusCode = matchResult.detail().httpStatusCode;
            if statusCode == http:STATUS_UNPROCESSABLE_ENTITY || statusCode == http:STATUS_NOT_FOUND {
                // Expected no-match outcome — member is not in this payer's system
                log:printDebug("No match for member (coverage " + covId + "): " + matchResult.message());
                nonMatchedEntries.push({originalPatient: memberPatient, memberRef: ()});
            } else {
                // Unexpected processing error — log at error level and surface the reason
                log:printError("Member match processing error for coverage " + covId
                        + ": " + matchResult.message());
                nonMatchedEntries.push({originalPatient: memberPatient, memberRef: (),
                        displayOnly: "Match error: " + matchResult.message()});
            }
            continue;
        }

        string patientId = matchResult;
        r4:Reference patientRef = {reference: "Patient/" + patientId};
        log:printDebug("Matched patient: " + patientId);

        // Convert HRexConsent to international401:Consent for the evaluateConsent() helper
        // (consent non-nil is guaranteed by the earlier nil check above)
        international401:Consent|error i4Consent =
                consent.cloneWithType(international401:Consent);
        if i4Consent is error {
            log:printWarn("Failed to convert HRexConsent for patient " + patientId
                    + ": " + i4Consent.message() + " — treating as consent constrained");
            consentConstrainedEntries.push({originalPatient: memberPatient, memberRef: patientRef});
            continue;
        }

        // Per HRex spec, Consent.patient SHALL be a local reference to the input MemberPatient
        // , not the matched patient ID. Validate against the input patient's
        // local id so cross-system IDs are never compared.
        // Ref: https://hl7.org/fhir/us/davinci-hrex/STU1/OperationDefinition-member-match.html
        //      "Resolving parameter references" — Consent.patient SHALL resolve to MemberPatient.
        string inputPatientId = memberPatient.id ?: "";
        ConsentEvaluationResult consentResult = evaluateConsent(i4Consent, inputPatientId);
        if consentResult.isValid {
            log:printDebug("Consent valid for patient " + patientId);
            matchedEntries.push({originalPatient: memberPatient, memberRef: patientRef});
        } else {
            log:printDebug("Consent constrained for patient " + patientId
                    + ": " + (consentResult.reason ?: "unknown reason"));
            consentConstrainedEntries.push({originalPatient: memberPatient, memberRef: patientRef});
        }
    }

    // Build the three result Group resources
    international401:Group matchedGroup =
            buildBulkMatchGroupResource(PDEX_MEMBER_MATCH_GROUP_PROFILE, PDEX_MATCH_CODE, matchedEntries);
    matchedGroup.id = uuid:createType4AsString();
    international401:Group nonMatchedGroup =
            buildBulkMatchGroupResource(PDEX_NO_MATCH_GROUP_PROFILE, PDEX_NO_MATCH_CODE, nonMatchedEntries);
    international401:Group consentConstrainedGroup =
            buildBulkMatchGroupResource(PDEX_NO_MATCH_GROUP_PROFILE, PDEX_CONSENT_CONSTRAINT_CODE, consentConstrainedEntries);

    // Persist the MatchedMembers Group so it can be targeted by $davinci-data-export.
    // Both failure paths propagate as FHIRError: a Group without an id would make any
    // subsequent $davinci-data-export call target a non-existent resource.
    if matchedEntries.length() > 0 {
        r4:DomainResource|r4:FHIRError persistResult =
                create(fhirConnector, GROUP, matchedGroup.toJson());
        if persistResult is r4:FHIRError {
            log:printError("Failed to persist MatchedMembers Group: " + persistResult.message());
            return persistResult;
        }
        international401:Group|error persistedGroup =
                persistResult.cloneWithType(international401:Group);
        if persistedGroup is error {
            log:printError("Persisted Group response could not be parsed: " + persistedGroup.message());
            return r4:createFHIRError(
                    "Failed to read persisted MatchedMembers Group: " + persistedGroup.message(),
                    r4:ERROR, r4:PROCESSING, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
        matchedGroup = persistedGroup;
        log:printDebug("MatchedMembers Group persisted with id: " + (persistedGroup.id ?: "unknown"));
    }

    // Build typed response Parameters with the three named Groups
    davincipdex220:PDexMultiMemberMatchResponseParameters response = {
        'parameter: [
            {name: "MatchedMembers", 'resource: matchedGroup},
            {name: "NonMatchedMembers", 'resource: nonMatchedGroup},
            {name: "ConsentConstrainedMembers", 'resource: consentConstrainedGroup}
        ]
    };
    return response;
}

// ============================================================================
// DefaultBulkMemberMatcher — implements davincipdex220:BulkMemberMatcher
// ============================================================================

# Default implementation of the PDex BulkMemberMatcher interface.
# Delegates to processBulkMemberMatch() for the actual matching logic.
public isolated class DefaultBulkMemberMatcher {
    *davincipdex220:BulkMemberMatcher;

    public isolated function matchMembers(davincipdex220:BulkMemberMatchResources resources)
            returns davincipdex220:BulkMemberMatchResult|r4:FHIRError {
        davincipdex220:PDexMultiMemberMatchResponseParameters|r4:FHIRError result =
                processBulkMemberMatch(resources.requestParameters);
        if result is r4:FHIRError {
            return result;
        }
        return {responseParameters: result};
    }
}

// ============================================================================
// Group Builder
// ============================================================================

# Builds a PDex-profiled Group resource per the multi-member-match spec.
#
# Each entry with an originalPatient is embedded as a contained resource (id = "1", "2", ...).
# The member.entity carries:
#   - MatchedMembers:  entity.reference = receiving-payer Patient ref; extension → contained #N
#   - Non/Constrained: entity.reference = contained #N (no matched patient exists)
# Ref: https://hl7.org/fhir/us/davinci-pdex/STU2/OperationDefinition-bulk-member-match.html
#
# + profileUrl  - Canonical profile URL for the Group
# + matchCode   - PdexMultiMemberMatchResultCS code (match / nomatch / consentconstraint)
# + entries     - MemberOutcomeEntry list with original patients and outcome references
# + return      - A populated international401:Group resource
isolated function buildBulkMatchGroupResource(string profileUrl, string matchCode,
        MemberOutcomeEntry[] entries) returns international401:Group {

    r4:Resource[] contained = [];
    international401:GroupMember[] members = [];
    int containedIndex = 1;

    foreach MemberOutcomeEntry entry in entries {
        international401:Patient? originalPatient = entry.originalPatient;

        if originalPatient is international401:Patient {
            // Assign a stable local contained-resource id for this entry
            string containedId = containedIndex.toString();
            containedIndex += 1;

            // Strip any incoming id and assign the local contained id
            international401:Patient containedPatient = originalPatient.clone();
            containedPatient.id = containedId;
            contained.push(containedPatient);

            // Extension linking entity back to the contained input patient
            r4:ReferenceExtension matchParamsExt = {
                url: BASE_EXT_MATCH_PARAMETERS_URL,
                valueReference: {reference: "#" + containedId}
            };

            // For matched members the entity points to the receiving-payer patient;
            // for non-matched / consent-constrained it points to the contained patient itself.
            r4:Reference? matchedRef = entry.memberRef;
            r4:Reference entityRef = matchedRef is r4:Reference
                    ? {reference: matchedRef.reference, extension: [matchParamsExt]}
                    : {reference: "#" + containedId, extension: [matchParamsExt]};

            members.push({entity: entityRef});
        } else {
            // Parsing failed before we had a patient — use a display-only reference
            members.push({entity: {display: entry.displayOnly ?: "unknown"}});
        }
    }

    international401:Group grp = {
        'type: "person",
        actual: true,
        meta: {profile: [profileUrl]},
        code: {
            coding: [{
                system: PDEX_MULTI_MEMBER_MATCH_RESULT_CS,
                code: matchCode
            }]
        },
        member: members
    };
    if contained.length() > 0 {
        grp.contained = contained;
    }
    return grp;
}

// ============================================================================
// Async Job Helpers
// ============================================================================

# Processes bulk member match in the background and stores the result in
# bulkMatchJobStore. Called via `start` for async execution.
#
# + jobId - The ID previously stored in bulkMatchJobStore
# + parameters - The PDex Multi-Member Match Request Parameters
isolated function processAndStoreBulkMemberMatch(
        string jobId,
        davincipdex220:PDexMultiMemberMatchRequestParameters & readonly parameters) {

    // Mark job as processing
    lock {
        if bulkMatchJobStore.hasKey(jobId) {
            BulkMemberMatchJob current = bulkMatchJobStore.get(jobId);
            bulkMatchJobStore[jobId] = {
                jobId: current.jobId,
                status: BULK_MATCH_PROCESSING,
                createdAt: current.createdAt,
                completedAt: (),
                result: (),
                errorMessage: ()
            };
        }
    }

    davincipdex220:BulkMemberMatchResult|r4:FHIRError|error matchResult =
            trap bulkMemberMatcher.matchMembers({requestParameters: parameters});

    lock {
        if bulkMatchJobStore.hasKey(jobId) {
            BulkMemberMatchJob current = bulkMatchJobStore.get(jobId);
            if matchResult is davincipdex220:BulkMemberMatchResult {
                bulkMatchJobStore[jobId] = {
                    jobId: current.jobId,
                    status: BULK_MATCH_COMPLETED,
                    createdAt: current.createdAt,
                    completedAt: time:utcNow(),
                    result: matchResult.responseParameters.cloneReadOnly(),
                    errorMessage: ()
                };
            } else {
                string errMsg = matchResult is r4:FHIRError
                        ? matchResult.message()
                        : "Unexpected error: " + matchResult.message();
                log:printError("Bulk member match job " + jobId + " failed: " + errMsg);
                bulkMatchJobStore[jobId] = {
                    jobId: current.jobId,
                    status: BULK_MATCH_FAILED,
                    createdAt: current.createdAt,
                    completedAt: time:utcNow(),
                    result: (),
                    errorMessage: errMsg
                };
            }
        }
    }
}

# Returns a copy of the stored BulkMemberMatchJob for the given job ID, or () if not found.
#
# + jobId - The async job ID
# + return - A copy of the job record, or () if no such job exists
isolated function getBulkMemberMatchJob(string jobId) returns BulkMemberMatchJob? {
    lock {
        if bulkMatchJobStore.hasKey(jobId) {
            return bulkMatchJobStore.get(jobId).clone();
        }
    }
    return ();
}

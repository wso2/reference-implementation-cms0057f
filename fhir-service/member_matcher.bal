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
import ballerinax/health.clients.fhir as fhirClient;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincihrex100 as hrex100;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.uscore501;

// Error indicating an internal server error occurred during the member matching process
final r4:FHIRError & readonly INTERNAL_ERROR = r4:createFHIRError("Internal server error", r4:ERROR,
        r4:PROCESSING, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);

configurable string CONSENT_SERVICE_BASE_URL = "http://localhost:9090";

# # This class implements the reference member matcher for the Da Vinci HRex Member Matcher.
# # The matcher is used to match a member's coverage with the existing patient records in the FHIR repository.
# # It uses the patient's name and coverage details to find a match in the existing patient records.
# # If a match is found, it returns the member identifier (patient ID). If no match is found, it returns an error indicating that no match was found.
public isolated class DemoFHIRMemberMatcher {
    *hrex100:MemberMatcher;
    private final fhirClient:FHIRConnector fhirConnector;

    public isolated function init(fhirClient:FHIRConnector fhirConnector) {
        self.fhirConnector = fhirConnector;
    }

    public isolated function matchMember(anydata memberMatchResources) returns hrex100:MemberIdentifier|r4:FHIRError {

        if memberMatchResources !is hrex100:MemberMatchResources {
            log:printError("Invalid type for \"memberMatchResources\". Expected type: MemberMatchResources.");
            return r4:createFHIRError("Internal server error", r4:ERROR, r4:PROCESSING, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
        log:printDebug("Custom matcher engaged");

        // Member match resources
        uscore501:USCorePatientProfile memberPatient = memberMatchResources.memberPatient;
        hrex100:HRexCoverage coverageToMatch = memberMatchResources.coverageToMatch;
        hrex100:HRexCoverage? _ = memberMatchResources.coverageToLink;

        // Search candidates by given name (blocking step)
        uscore501:USCorePatientProfileName[] name = memberPatient.name;
        string[] given = name[0].given ?: [];
        if given.length() == 0 {
            log:printInfo("[member-match] Input patient has no given name — returning no match");
            return r4:createFHIRError("No match found", r4:ERROR, r4:PROCESSING_NOT_FOUND,
                    httpStatusCode = http:STATUS_UNPROCESSABLE_ENTITY);
        }
        string givenName = given[0];
        log:printInfo(string `[member-match] FHIR search request: GET Patient?given=${givenName}`);
        r4:Bundle|r4:FHIRError candidateBundleResult = search(self.fhirConnector, PATIENT, {"given": [givenName]});
        if candidateBundleResult is r4:FHIRError {
            log:printError(string `[member-match] FHIR search error: Patient?given=${givenName}`, candidateBundleResult);
            return candidateBundleResult;
        }
        r4:Bundle candidateBundle = candidateBundleResult;
        int totalCandidates = candidateBundle.total ?: 0;
        log:printInfo(string `[member-match] FHIR search response: total=${totalCandidates}`);

        r4:BundleEntry[]? entry = candidateBundle.entry;
        if entry is () || entry.length() == 0 {
            log:printInfo("[member-match] No candidates found in search response — returning no match");
            return r4:createFHIRError("No match found", r4:ERROR, r4:PROCESSING_NOT_FOUND, httpStatusCode = http:STATUS_UNPROCESSABLE_ENTITY);
        }

        // Score each candidate and collect all that share the best score
        decimal bestScore = 0.0d;
        string[] topCandidateIds = [];

        foreach r4:BundleEntry bundleEntry in entry {
            anydata 'resource = bundleEntry?.'resource;
            uscore501:USCorePatientProfile|error candidate = 'resource.cloneWithType(uscore501:USCorePatientProfile);
            if candidate is error {
                log:printDebug("[member-match] Could not coerce candidate to USCorePatientProfile, skipping");
                continue;
            }
            string candidateId = candidate.id ?: "unknown";
            string candidateFamily = candidate.name.length() > 0 ? (candidate.name[0].family ?: "") : "";
            string[] candidateGivenArr = candidate.name.length() > 0 ? (candidate.name[0].given ?: []) : [];
            string candidateGiven = candidateGivenArr.length() > 0 ? candidateGivenArr[0] : "";
            string candidateDob = candidate.birthDate ?: "";
            string candidateGender = candidate.gender.toString();
            decimal score = calculateScore(memberPatient, candidate);
            log:printInfo(string `[member-match] Candidate: id=${candidateId} name="${candidateGiven} ${candidateFamily}" dob=${candidateDob} gender=${candidateGender} score=${score}`);
            if score > bestScore {
                bestScore = score;
                topCandidateIds = [candidateId];
            } else if score == bestScore && score > 0.0d {
                topCandidateIds.push(candidateId);
            }
        }

        string matchGrade = getMatchGrade(bestScore);
        log:printInfo(string `[member-match] Best score: ${bestScore}, grade=${matchGrade}, top-candidates=${topCandidateIds.toString()}`);

        if topCandidateIds.length() == 0 || matchGrade == "certainly-not" {
            log:printInfo(string `[member-match] Score too low (${bestScore}) — returning no match`);
            return r4:createFHIRError("No match found", r4:ERROR, r4:PROCESSING_NOT_FOUND, httpStatusCode = http:STATUS_UNPROCESSABLE_ENTITY);
        }

        // Verify coverage beneficiary — also serves as tie-breaker when multiple candidates share the best score
        string? coverageIdOpt = coverageToMatch.id;
        if coverageIdOpt is () {
            log:printError("[member-match] coverageToMatch has no id — cannot look up coverage");
            return INTERNAL_ERROR;
        }
        string coverageId = coverageIdOpt;
        log:printInfo(string `[member-match] FHIR read request: GET Coverage/${coverageId}`);
        r4:DomainResource|r4:FHIRError oldCoverage = getById(self.fhirConnector, COVERAGE, coverageId);
        if oldCoverage is r4:FHIRError {
            log:printError(string `[member-match] FHIR read error: Coverage/${coverageId}`, oldCoverage);
            return INTERNAL_ERROR;
        }
        international401:Coverage|error i4OldCoverage = oldCoverage.cloneWithType();
        if i4OldCoverage is error {
            log:printError("[member-match] Failed to clone Coverage resource", i4OldCoverage);
            return INTERNAL_ERROR;
        }
        string oldBeneficiaryRef = <string>i4OldCoverage.beneficiary.reference;
        string[] refParts = re `/`.split(oldBeneficiaryRef);
        string extractedBeneficiaryId = refParts[refParts.length() - 1];
        log:printInfo(string `[member-match] Coverage beneficiary.reference="${oldBeneficiaryRef}" extracted-id="${extractedBeneficiaryId}" top-candidates=${topCandidateIds.toString()}`);

        foreach string candidateId in topCandidateIds {
            if extractedBeneficiaryId == candidateId {
                log:printInfo(string `[member-match] Match successful: patient=${candidateId}`);
                return <hrex100:MemberIdentifier>candidateId;
            }
        }

        log:printInfo(string `[member-match] No coverage beneficiary match among top candidates — returning no match`);
        return r4:createFHIRError("No match found", r4:ERROR, r4:PROCESSING_NOT_FOUND, httpStatusCode = http:STATUS_UNPROCESSABLE_ENTITY);
    }

    isolated function queryConsentEvaluate(international401:Parameters parameters) returns ConsentEvaluationResponse|r4:FHIRError {
        http:Client|error consentClient = new (CONSENT_SERVICE_BASE_URL);

        if consentClient is error {
            log:printError("Failed to create consent client", consentClient);
            return r4:createFHIRError("Internal server error - failed to create client",
                    r4:ERROR, r4:PROCESSING,
                    httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }

        http:Response|error response = consentClient->post("/fhir/r4/Consent/$evaluate", parameters.toJson(), {
            "Content-Type": "application/fhir+json",
            "Accept": "application/fhir+json"
        });

        if response is error {
            log:printError("Failed to query consent evaluate endpoint", response);
            return r4:createFHIRError("Internal server error - failed to query consent endpoint",
                    r4:ERROR, r4:PROCESSING,
                    httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }

        int statusCode = response.statusCode;
        log:printDebug(string `Consent evaluate response status: ${statusCode}`);

        if statusCode == http:STATUS_OK {
            // Success case - return the parameters response
            json|error responsePayload = response.getJsonPayload();
            if responsePayload is error {
                log:printError("Failed to parse success response payload", responsePayload);
                return r4:createFHIRError("Invalid response format",
                        r4:ERROR, r4:PROCESSING,
                        httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
            }

            international401:Parameters|error parametersResponse = responsePayload.cloneWithType();
            if parametersResponse is error {
                log:printError("Failed to convert response to Parameters", parametersResponse);
                return r4:createFHIRError("Invalid Parameters response",
                        r4:ERROR, r4:PROCESSING,
                        httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
            }

            return {
                statusCode: statusCode,
                success: true,
                parameters: parametersResponse
            };

        } else if statusCode == http:STATUS_UNPROCESSABLE_ENTITY {
            // Validation failure case - return the operation outcome
            json|error responsePayload = response.getJsonPayload();
            if responsePayload is error {
                log:printError("Failed to parse error response payload", responsePayload);
                return r4:createFHIRError("Invalid error response format",
                        r4:ERROR, r4:PROCESSING,
                        httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
            }

            r4:OperationOutcome|international401:Parameters|error operationOutcome = responsePayload.cloneWithType();
            if operationOutcome is error {
                log:printError("Failed to convert response to OperationOutcome", operationOutcome);
                return r4:createFHIRError("Invalid OperationOutcome response",
                        r4:ERROR, r4:PROCESSING,
                        httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
            }
            if operationOutcome is international401:Parameters {
                log:printDebug(operationOutcome.toString());
                return r4:createFHIRError("Member identity does not match",
                        r4:ERROR, r4:PROCESSING,
                        httpStatusCode = http:STATUS_UNPROCESSABLE_ENTITY);
            }

            return {
                statusCode: statusCode,
                success: false,
                operationOutcome: <r4:OperationOutcome>operationOutcome
            };

        } else {
            // Unexpected status code
            log:printError(string `Unexpected status code from consent evaluate: ${statusCode}`);
            return r4:createFHIRError(string `Unexpected response status: ${statusCode}`,
                    r4:ERROR, r4:PROCESSING,
                    httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
    }

    isolated function createConsentParamsPayload(hrex100:HRexConsent? consentResource, string memberIdentifier) returns international401:Parameters {
        // Mocking a Parameters resource for consent evaluation

        international401:Parameters parameters = {
            id: "member-match-in",
            'parameter: [
                {
                    name: "Consent",
                    'resource: consentResource
                },
                {
                    name: "memberIdentifier",
                    valueString: memberIdentifier
                }
            ]
        };
        return parameters;

    }
}

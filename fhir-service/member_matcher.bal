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
            log:printError("[member-match] Invalid memberMatchResources type");
            return r4:createFHIRError("Internal server error", r4:ERROR, r4:PROCESSING, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }

        // Member match resources
        uscore501:USCorePatientProfile memberPatient = memberMatchResources.memberPatient;
        hrex100:HRexCoverage coverageToMatch = memberMatchResources.coverageToMatch;
        hrex100:HRexCoverage? _ = memberMatchResources.coverageToLink;

        // Search candidates by given name (blocking step)
        uscore501:USCorePatientProfileName[] name = memberPatient.name;
        if name.length() == 0 {
            return r4:createFHIRError("No match found", r4:ERROR, r4:PROCESSING_NOT_FOUND,
                    httpStatusCode = http:STATUS_UNPROCESSABLE_ENTITY);
        }
        string[] given = name[0].given ?: [];
        string givenName = "";
        foreach string g in given {
            string trimmed = g.trim();
            if trimmed.length() > 0 {
                givenName = trimmed;
                break;
            }
        }
        if givenName.length() == 0 {
            return r4:createFHIRError("No match found", r4:ERROR, r4:PROCESSING_NOT_FOUND,
                    httpStatusCode = http:STATUS_UNPROCESSABLE_ENTITY);
        }
        r4:Bundle|r4:FHIRError candidateBundleResult = search(self.fhirConnector, PATIENT, {"given": [givenName]});
        if candidateBundleResult is r4:FHIRError {
            log:printError("[member-match] Patient search failed", candidateBundleResult);
            return candidateBundleResult;
        }
        r4:Bundle candidateBundle = candidateBundleResult;

        r4:BundleEntry[]? entry = candidateBundle.entry;
        if entry is () || entry.length() == 0 {
            return r4:createFHIRError("No match found", r4:ERROR, r4:PROCESSING_NOT_FOUND, httpStatusCode = http:STATUS_UNPROCESSABLE_ENTITY);
        }

        // Score each candidate and collect all that share the best score
        decimal bestScore = 0.0d;
        string[] topCandidateIds = [];

        foreach r4:BundleEntry bundleEntry in entry {
            anydata 'resource = bundleEntry?.'resource;
            uscore501:USCorePatientProfile|error candidate = 'resource.cloneWithType(uscore501:USCorePatientProfile);
            if candidate is error {
                continue;
            }
            string candidateId = candidate.id ?: "unknown";
            decimal score = calculateScore(memberPatient, candidate);
            if score > bestScore {
                bestScore = score;
                topCandidateIds = [candidateId];
            } else if score == bestScore && score > 0.0d {
                topCandidateIds.push(candidateId);
            }
        }

        string matchGrade = getMatchGrade(bestScore);
        if topCandidateIds.length() == 0 || matchGrade == "certainly-not" {
            return r4:createFHIRError("No match found", r4:ERROR, r4:PROCESSING_NOT_FOUND, httpStatusCode = http:STATUS_UNPROCESSABLE_ENTITY);
        }

        // Verify coverage beneficiary using the input coverageToMatch directly —
        // cross-check only against the coverage submitted in the request, not a server-side lookup.
        string? beneficiaryRef = coverageToMatch.beneficiary.reference;
        if beneficiaryRef is () {
            log:printWarn("[member-match] coverageToMatch missing beneficiary.reference");
            return r4:createFHIRError("coverageToMatch.beneficiary.reference is required", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
        }
        string[] refParts = re `/`.split(beneficiaryRef);
        string extractedBeneficiaryId = refParts[refParts.length() - 1];

        foreach string candidateId in topCandidateIds {
            if extractedBeneficiaryId == candidateId {
                log:printInfo(string `[member-match] Match successful: patientId=${candidateId} score=${bestScore} grade=${matchGrade}`);
                return <hrex100:MemberIdentifier>candidateId;
            }
        }

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

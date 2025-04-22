import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincipas;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.parser;

configurable string claimRepositoryServiceUrl = ?;

isolated http:Client claimRepositoryServiceClient = check new (claimRepositoryServiceUrl);

public isolated function submit(international401:Parameters payload) returns r4:FHIRError|international401:Parameters|error {
    international401:Parameters|error 'parameters = parser:parseWithValidation(payload.toJson(), international401:Parameters).ensureType();

    if parameters is error {
        return r4:createFHIRError(parameters.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        international401:ParametersParameter[]? 'parameter = parameters.'parameter;
        if 'parameter is international401:ParametersParameter[] {
            foreach var item in 'parameter {
                if item.name == "resource" {
                    r4:Resource? resourceResult = item.'resource;
                    if resourceResult is r4:Resource {
                        // r4:Bundle bundle = check parser:parse(resourceResult.toJson(), r4:Bundle).ensureType();
                        r4:Bundle cloneWithType = check resourceResult.cloneWithType(r4:Bundle);
                        r4:BundleEntry[]? entry = cloneWithType.entry;
                        if entry is r4:BundleEntry[] {
                            r4:BundleEntry bundleEntry = entry[0];
                            anydata 'resource = bundleEntry?.'resource;
                            davincipas:PASClaim claim = check parser:parse('resource.toJson(), davincipas:PASClaim).ensureType();

                            davincipas:PASClaim newClaimClone;

                            lock {
                                http:Response|error response = claimRepositoryServiceClient->/Claim.post(claim.clone());

                                if response is http:Response {
                                    if response.statusCode == http:STATUS_CREATED {
                                        json|http:Error claimResponseJson = response.getJsonPayload();
                                        if claimResponseJson is http:Error {
                                            return r4:createFHIRError("Error: " + claimResponseJson.message(), r4:ERROR, r4:INVALID, httpStatusCode = response.statusCode);
                                        }

                                        davincipas:PASClaim|error newClaim = parser:parse(claimResponseJson, davincipas:PASClaim).ensureType();
                                        if newClaim is error {
                                            return r4:createFHIRError("Error: " + newClaim.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
                                        }

                                        newClaimClone = newClaim.clone();
                                    } else {
                                        return r4:createFHIRError("Error occurred while creating the claim", r4:ERROR, r4:INVALID, httpStatusCode = response.statusCode);
                                    }
                                } else {
                                    return r4:createFHIRError("Error: " + response.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
                                }
                            }

                            davincipas:PASClaimResponse claimResponse;
                            lock {
                                claimResponse = check parser:parse(claimResponseJson.clone(), davincipas:PASClaimResponse).ensureType();
                            }
                            claimResponse.patient = newClaimClone.patient;
                            claimResponse.insurer = newClaimClone.insurer;
                            claimResponse.created = newClaimClone.created;
                            claimResponse.request = {reference: "Claim/" + <string>newClaimClone.id};

                            lock {
                                http:Response|error response = claimRepositoryServiceClient->/ClaimResponse.post(claimResponse.clone());

                                if response is http:Response {
                                    if (response.statusCode == http:STATUS_CREATED) {
                                        json|http:Error claimResponseJson = response.getJsonPayload();
                                        if claimResponseJson is http:Error {
                                            return r4:createFHIRError("Error: " + claimResponseJson.message(), r4:ERROR, r4:INVALID, httpStatusCode = response.statusCode);
                                        }

                                        davincipas:PASClaimResponse|error newClaimResponse = parser:parse(claimResponseJson, davincipas:PASClaimResponse).ensureType();
                                        if newClaimResponse is error {
                                            return r4:createFHIRError("Error: " + newClaimResponse.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
                                        }

                                        international401:ParametersParameter p = {
                                            name: "return",
                                            'resource: newClaimResponse.clone()
                                        };

                                        international401:Parameters parameterResponse = {
                                            'parameter: [p]
                                        };
                                        return parameterResponse.clone();
                                    }
                                    return r4:createFHIRError("Error: Invalid request or server error.", r4:ERROR, r4:INVALID, httpStatusCode = response.statusCode);
                                } else {
                                    return r4:createFHIRError("Error: " + response.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return r4:createFHIRError("Something went wrong", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
}

isolated json claimResponseJson = {
    "resourceType": "ClaimResponse",
    "id": "12344",
    "status": "active",
    "type": {
        "coding": [
            {
                "system": "http://terminology.hl7.org/CodeSystem/claim-type",
                "code": "professional",
                "display": "Professional"
            }
        ]
    },
    "use": "preauthorization",
    "patient": {
        "reference": "Patient/101"
    },
    "created": "2025-03-02",
    "insurer": {
        "reference": "Organization/insurance-org"
    },
    "request": {
        "reference": "Claim/12344"
    },
    "outcome": "complete",
    "disposition": "Prior authorization approved for Aimovig 70 mg Injection.",
    "preAuthRef": "PA-20250302-001",
    "preAuthPeriod": {
        "start": "2025-03-02",
        "end": "2025-06-02"
    },
    "payment": {
        "type": {
            "coding": [
                {
                    "system": "http://terminology.hl7.org/CodeSystem/payment-type",
                    "code": "complete",
                    "display": "Payment complete"
                }
            ]
        },
        "adjustmentReason": {
            "coding": [
                {
                    "system": "http://terminology.hl7.org/CodeSystem/claim-adjustment-reason",
                    "code": "45",
                    "display": "Charge exceeds fee schedule/maximum allowable or contracted/legislated fee arrangement"
                }
            ]
        },
        "amount": {
            "value": 600.00,
            "currency": "USD"
        },
        "date": "2025-03-03"
    }
};

import ballerina/http;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincipas;
import ballerinax/health.fhir.r4.parser;

// http client for claim repository service
isolated http:Client claimRepositoryServiceClient = check new (claimRepositoryServiceUrl);

public isolated function create(davincipas:PASClaim payload) returns r4:FHIRError|http:Error|davincipas:PASClaimResponse|error {
    davincipas:PASClaim claim = check parser:parse(payload.toJson(), davincipas:PASClaim).ensureType();

    lock {
        http:Response|error response = claimRepositoryServiceClient->/Claim.post(claim.clone());

        if response is http:Response {
            if response.statusCode == http:STATUS_CREATED {
                davincipas:PASClaimResponse claimResponse = check parser:parse(check response.getJsonPayload(), davincipas:PASClaimResponse).ensureType();
                return claimResponse.clone();
            } 
            
            return r4:createFHIRError("Error occurred while creating the claim", r4:ERROR, r4:INVALID, httpStatusCode = response.statusCode);
        } else {
            return r4:createFHIRError("Error: " + response.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
    }
}

public isolated function getById(string id) returns r4:FHIRError|http:Error|davincipas:PASClaim|error {
    lock {
        http:Response|error response = claimRepositoryServiceClient->/Claim/[id];

        if response is http:Response {
            if response.statusCode == http:STATUS_OK {
                davincipas:PASClaim claim = check parser:parse(check response.getJsonPayload(), davincipas:PASClaim).ensureType();
                return claim.clone();
            } 
            
            return r4:createFHIRError(string `Not found resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = response.statusCode);
        } else {
            return r4:createFHIRError("Error: " + response.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
    }
}

public isolated function update(json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function patchResource(string 'resource, string id, json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
}

public isolated function delete(string 'resource, string id) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:Bundle|r4:FHIRError|http:Error|error {
    r4:Bundle bundle = {
        'type: "collection",
        entry: []
    };
    
    if searchParameters is map<string[]> {
        lock {
            http:Response|error response = claimRepositoryServiceClient->/Claim/Search.post(searchParameters.clone());

            if response is http:Response {
                if response.statusCode == http:STATUS_OK || response.statusCode == http:STATUS_CREATED {
                    r4:Bundle bundleResponse = check parser:parse(check response.getJsonPayload()).ensureType();
                    bundle = bundleResponse.clone();
                } else {
                    return r4:createFHIRError("Error occurred while retrieving the claims", r4:ERROR, r4:INVALID, httpStatusCode = response.statusCode);
                }
            } else {
                return r4:createFHIRError("Error: " + response.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
            }
        }
    }

    return bundle;
}

function init() returns error? {
    lock {
        json claimJson = {
            "resourceType": "Claim",
            "identifier": [
                {
                    "system": "http://hospital.org/claims",
                    "value": "PA-20250302-001"
                }
            ],
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
            "priority": {
                "coding": [
                    {
                        "system": "http://terminology.hl7.org/CodeSystem/processpriority",
                        "code": "stat",
                        "display": "Immediate"
                    }
                ]
            },
            "patient": {
                "reference": "Patient/102"
            },
            "created": "2025-03-02",
            "insurer": {
                "reference": "Organization/insurance-org"
            },
            "provider": {
                "reference": "PractitionerRole/456"
            },
            "insurance": [
                {
                    "sequence": 1,
                    "focal": true,
                    "coverage": {
                        "reference": "Coverage/insurance-coverage"
                    }
                }
            ],
            "supportingInfo": [
                {
                    "sequence": 1,
                    "category": {
                        "coding": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/claiminformationcategory",
                                "code": "info",
                                "display": "Supporting Information"
                            }
                        ]
                    },
                    "valueReference": {
                        "reference": "QuestionnaireResponse/1121"
                    }
                }
            ],
            "item": [
                {
                    "sequence": 1,
                    "category": {
                        "coding": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/ex-benefitcategory",
                                "code": "pharmacy",
                                "display": "Pharmacy"
                            }
                        ]
                    },
                    "productOrService": {
                        "coding": [
                            {
                                "system": "http://www.nlm.nih.gov/research/umls/rxnorm",
                                "code": "1746007",
                                "display": "Aimovig 70 mg Injection"
                            }
                        ]
                    },
                    "servicedDate": "2025-03-02",
                    "unitPrice": {
                        "value": 600.00,
                        "currency": "USD"
                    },
                    "quantity": {
                        "value": 1
                    }
                }
            ]
        };
        davincipas:PASClaim claim = check parser:parse(claimJson, davincipas:PASClaim).ensureType();

        _ = check create(claim);
    }
}

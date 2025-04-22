import ballerina/http;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincipas;
import ballerinax/health.fhir.r4.parser;

// http client for claim repository service
isolated http:Client claimRepositoryServiceClient = check new (claimRepositoryServiceUrl);

public isolated function create(davincipas:PASClaimResponse payload) returns r4:FHIRError|davincipas:PASClaimResponse {
    davincipas:PASClaimResponse|error claimResponse = parser:parse(payload.toJson(), davincipas:PASClaimResponse).ensureType();

    if claimResponse is error {
        return r4:createFHIRError(claimResponse.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

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

                return newClaimResponse.clone();
            }
            return r4:createFHIRError("Error: Invalid request or server error.", r4:ERROR, r4:INVALID, httpStatusCode = response.statusCode);
        } else {
            return r4:createFHIRError("Error: " + response.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
    }
}

public isolated function getById(string id) returns r4:FHIRError|davincipas:PASClaimResponse {
    lock {
        http:Response|error response = claimRepositoryServiceClient->/ClaimResponse/[id];

        if response is http:Response {
            if response.statusCode == http:STATUS_OK {
                json|http:Error claimResponseJson = response.getJsonPayload();
                if claimResponseJson is http:Error {
                    return r4:createFHIRError("Error: " + claimResponseJson.message(), r4:ERROR, r4:INVALID, httpStatusCode = response.statusCode);
                }

                davincipas:PASClaimResponse|error claimResponse = parser:parse(claimResponseJson, davincipas:PASClaimResponse).ensureType();
                if claimResponse is error {
                    return r4:createFHIRError("Error: " + claimResponse.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
                }

                return claimResponse.clone();
            } 
            
            return r4:createFHIRError(string `Cannot find a ClaimResponse resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
        } else {
            return r4:createFHIRError("Error: " + response.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
    }
}

public isolated function getAll() returns r4:FHIRError|davincipas:PASClaimResponse[] {
    lock {
        http:Response|error response = claimRepositoryServiceClient->/ClaimResponse;

        if response is http:Response {
            if response.statusCode == http:STATUS_OK {
                json|http:Error claimsJson = response.getJsonPayload();
                if claimsJson is http:Error {
                    return r4:createFHIRError("Error: " + claimsJson.message(), r4:ERROR, r4:INVALID, httpStatusCode = response.statusCode);
                }

                if claimsJson is json[] {
                    davincipas:PASClaimResponse[] claims = [];
                    foreach json claimJsonObj in claimsJson {
                        davincipas:PASClaimResponse|error claim = parser:parse(claimJsonObj, davincipas:PASClaimResponse).ensureType();

                        if claim is error {
                            return r4:createFHIRError("Error: " + claim.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
                        }

                        claims.push(claim);
                    }
                    
                    return claims.clone();
                } 
            }
        } 
    }

    return r4:createFHIRError("Error: Possible reason: Malformed response from server.", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
}

public isolated function update(json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented. This functionality is not yet supported.", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
}

public isolated function patchResource(string 'resource, string id, json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented. This functionality is not yet supported.", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
}

public isolated function delete(string 'resource, string id) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented. This functionality is not yet supported.", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    davincipas:PASClaimResponse byId = check getById(searchParameters.get('key)[0]);
                    bundle.entry = [
                        {
                            'resource: byId
                        }
                    ];
                    return bundle;
                }
                "_count" => {
                    davincipas:PASClaimResponse[] allClaims = check getAll();
                    r4:BundleEntry[] entries = [];

                    foreach davincipas:PASClaimResponse item in allClaims {
                        entries.push({
                            'resource: item
                        });
                    }

                    bundle.total = entries.length();
                    bundle.entry = entries;
                    return bundle;
                }
                _ => {
                    return r4:createFHIRError(string `Not supported search parameter: ${'key}. Possible reason: Unsupported query parameter.`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
                }
            }
        }
    }

    return bundle;
}

function init() returns error? {
    lock {
        json claimResponseJson = {
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

        davincipas:PASClaimResponse claimResponse = check parser:parse(claimResponseJson, davincipas:PASClaimResponse).ensureType();
        
        _ = check create(claimResponse);
    }

}

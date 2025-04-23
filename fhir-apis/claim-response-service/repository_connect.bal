import ballerina/http;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincipas;
import ballerinax/health.fhir.r4.parser;

// http client for claim repository service
isolated http:Client claimRepositoryServiceClient = check new (claimRepositoryServiceUrl);

public isolated function create(davincipas:PASClaimResponse payload) returns r4:FHIRError|davincipas:PASClaimResponse|error {
    davincipas:PASClaimResponse claimResponse = check parser:parse(payload.toJson(), davincipas:PASClaimResponse).ensureType();

    lock {
        http:Response|error response = claimRepositoryServiceClient->/ClaimResponse.post(claimResponse.clone());

        if response is http:Response {
            if (response.statusCode == http:STATUS_CREATED) {
                davincipas:PASClaimResponse newClaimResponse = check parser:parse(check response.getJsonPayload(), davincipas:PASClaimResponse).ensureType();
                return newClaimResponse.clone();
            }

            return r4:createFHIRError("Error: Invalid request or server error.", r4:ERROR, r4:INVALID, httpStatusCode = response.statusCode);
        } else {
            return r4:createFHIRError("Error: " + response.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
    }
}

public isolated function getById(string id) returns r4:FHIRError|davincipas:PASClaimResponse|error {
    lock {
        http:Response|error response = claimRepositoryServiceClient->/ClaimResponse/[id];

        if response is http:Response {
            if response.statusCode == http:STATUS_OK {
                davincipas:PASClaimResponse claimResponse = check parser:parse(check response.getJsonPayload(), davincipas:PASClaimResponse).ensureType();
                return claimResponse.clone();
            } 
            
            return r4:createFHIRError(string `Cannot find a ClaimResponse resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
        } else {
            return r4:createFHIRError("Error: " + response.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
    }
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

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle|error {
    r4:Bundle bundle = {
        'type: "collection",
        entry: []
    };
    
    if searchParameters is map<string[]> {
        lock {
            http:Response|error response = claimRepositoryServiceClient->/ClaimResponse/Search.post(searchParameters.clone());

            if response is http:Response {
                if response.statusCode == http:STATUS_OK || response.statusCode == http:STATUS_CREATED {
                    r4:Bundle bundleResponse = check parser:parse(check response.getJsonPayload()).ensureType();
                    bundle = bundleResponse.clone();
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

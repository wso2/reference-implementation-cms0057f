import ballerina/http;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincipas;
import ballerinax/health.fhir.r4.parser;

isolated davincipas:PASClaimResponse[] claimResponses = [];
isolated int createOperationNextId = 12343;

public isolated function create(davincipas:PASClaimResponse payload) returns r4:FHIRError|davincipas:PASClaimResponse {
    davincipas:PASClaimResponse|error claimResponse = parser:parseWithValidation(payload.toJson(), davincipas:PASClaimResponse).ensureType();

    if claimResponse is error {
        return r4:createFHIRError(claimResponse.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            claimResponse.id = (++createOperationNextId).toBalString();
        }

        lock {
            claimResponses.push(claimResponse.clone());
        }

        return claimResponse;
    }
}

public isolated function getById(string id) returns r4:FHIRError|davincipas:PASClaimResponse {
    lock {
        foreach var item in claimResponses {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a ClaimResponse resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
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

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        if searchParameters.keys().count() == 1 {
            lock {
                r4:BundleEntry[] bundleEntries = [];
                foreach var item in claimResponses {
                    r4:BundleEntry bundleEntry = {
                        'resource: item
                    };
                    bundleEntries.push(bundleEntry);
                }
                r4:Bundle BundleClone = bundle.clone();
                BundleClone.entry = bundleEntries;
                return BundleClone.clone();
            }
        }

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
                _ => {
                    return r4:createFHIRError(string `Not supported search parameter: ${'key}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
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
        claimResponses.push(claimResponse);
    }

}

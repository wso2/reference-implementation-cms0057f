import ballerina/http;
import ballerina/time;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincipas;
import ballerinax/health.fhir.r4.parser;

// http client for claim repository service
isolated http:Client claimRepositoryServiceClient = check new (claimRepositoryServiceUrl);

public isolated function create(davincipas:PASClaim payload) returns r4:FHIRError|davincipas:PASClaimResponse|error {
    davincipas:PASClaim|error claim = parser:parse(payload.toJson(), davincipas:PASClaim).ensureType();
    if claim is error {
        return r4:createFHIRError(claim.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

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
    return claimResponse.clone();
}

public isolated function getById(string id) returns r4:FHIRError|davincipas:PASClaim {
    lock {
        http:Response|error response = claimRepositoryServiceClient->/Claim/[id];

        if response is http:Response {
            if response.statusCode == http:STATUS_OK {
                json|http:Error claimJson = response.getJsonPayload();
                if claimJson is http:Error {
                    return r4:createFHIRError("Error occurred while retrieving the claim", r4:ERROR, r4:INVALID, httpStatusCode = response.statusCode);
                }

                davincipas:PASClaim|error claim = parser:parse(claimJson, davincipas:PASClaim).ensureType();
                if claim is error {
                    return r4:createFHIRError(claim.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
                }

                return claim.clone();
            } 
            
            return r4:createFHIRError(string `Cannot find a Patient resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
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

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        string? id = ();
        string? patient = ();
        string? use = ();
        string? created = ();

        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    id = searchParameters.get('key)[0];
                }
                "patient" => {
                    patient = searchParameters.get('key)[0];
                }
                "use" => {
                    use = searchParameters.get('key)[0];
                }
                "created" => {
                    created = searchParameters.get('key)[0];
                }
                "_count" => {
                    // pagination is not used in this service
                    continue;
                }
                _ => {
                    return r4:createFHIRError(string `Not supported search parameter: ${'key}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
                }
            }
        }

        if id is string {
            davincipas:PASClaim byId = check getById(id);

            bundle.entry = [
                {
                    'resource: byId
                }
            ];

            bundle.total = 1;
            return bundle;
        }

        davincipas:PASClaim[] results = [];
        lock {
            http:Response|error response = claimRepositoryServiceClient->/Claim;
            if response is http:Response {
                if response.statusCode == http:STATUS_OK {
                    // convert response to json array and convert to PASClaim array
                    json|http:Error claimsJson = response.getJsonPayload();
                    if claimsJson is http:Error {
                        return r4:createFHIRError("Error occurred while retrieving the claims", r4:ERROR, r4:INVALID, httpStatusCode = response.statusCode);
                    }

                    if claimsJson is json[] {
                        davincipas:PASClaim[] claims = [];
                        foreach json claimJson in claimsJson {
                            davincipas:PASClaim|error claim = parser:parse(claimJson, davincipas:PASClaim).ensureType();
                            if claim is error {
                                return r4:createFHIRError(claim.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
                            }

                            claims.push(claim);
                        }

                        results = claims.clone();
                    } else {
                        return r4:createFHIRError("Error: invalid response", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
                    }
                } else {
                    return r4:createFHIRError(string `Error, StatusCode: ${response.statusCode}.`, r4:ERROR, r4:INVALID, httpStatusCode = response.statusCode);
                }
            } else {
                return r4:createFHIRError("Error: " + response.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
            }
        }

        if patient is string {
            results = getByPatient(patient, results);
        }

        if use is string {
            results = getByUse(use, results);
        }

        if created is string {
            results = check getByCreatedDate(created, results);
        }

        // reorder the results as decending order by Created date
        results = orderByCreatedDate(results);

        r4:BundleEntry[] bundleEntries = [];

        foreach davincipas:PASClaim item in results {
            r4:BundleEntry bundleEntry = {
                'resource: item
            };
            bundleEntries.push(bundleEntry);
        }
        bundle.entry = bundleEntries;
        bundle.total = results.length();
    }

    return bundle;
}

isolated function getByUse(string use, davincipas:PASClaim[] targetArr) returns davincipas:PASClaim[] {
    davincipas:PASClaim[] filteredClaims = [];
    foreach davincipas:PASClaim claim in targetArr {
        if claim.use == use {
            filteredClaims.push(claim.clone());
        }
    }
    return filteredClaims;
}

isolated function getByPatient(string patient, davincipas:PASClaim[] targetArr) returns davincipas:PASClaim[] {
    davincipas:PASClaim[] filteredClaims = [];
    foreach davincipas:PASClaim claim in targetArr {
        if claim.patient.reference == patient {
            filteredClaims.push(claim.clone());
        }
    }
    return filteredClaims;
}

isolated function orderByCreatedDate(davincipas:PASClaim[] targetArr) returns davincipas:PASClaim[] {
    return from davincipas:PASClaim item in targetArr
        order by item.created descending
        select item;
}

isolated function getByCreatedDate(string created, davincipas:PASClaim[] targetArr) returns davincipas:PASClaim[]|r4:FHIRError {
    string operator = created.substring(0, 2);
    r4:dateTime datetimeR4 = created.substring(2);

    // convert r4:dateTime to time:Utc
    time:Utc|time:Error dateTimeUtc = time:utcFromString(datetimeR4.includes("T") ? datetimeR4 : datetimeR4 + "T00:00:00.000Z");
    if dateTimeUtc is time:Error {
        return r4:createFHIRError(string `Invalid date format: ${created}, ${dateTimeUtc.message()}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    time:Utc lowerBound = time:utcAddSeconds(dateTimeUtc, 86400);
    time:Utc upperBound = time:utcAddSeconds(dateTimeUtc, -86400);

    davincipas:PASClaim[] filteredClaims = [];
    foreach davincipas:PASClaim claim in targetArr {
        r4:dateTime claimDateTimeR4 = claim.created;
        time:Utc|time:Error claimDateTimeUtc = time:utcFromString(claimDateTimeR4.includes("T") ? claimDateTimeR4 : claimDateTimeR4 + "T00:00:00.000Z");
        if claimDateTimeUtc is time:Error {
            continue; // Skip invalid date formats
        }
        match operator {
            "eq" => {
                if claimDateTimeUtc == dateTimeUtc {
                    filteredClaims.push(claim.clone());
                }
            }
            "ne" => {
                if claimDateTimeUtc != dateTimeUtc {
                    filteredClaims.push(claim.clone());
                }
            }
            "lt" => {
                if claimDateTimeUtc < dateTimeUtc {
                    filteredClaims.push(claim.clone());
                }
            }
            "gt" => {
                if claimDateTimeUtc > dateTimeUtc {
                    filteredClaims.push(claim.clone());
                }
            }
            "ge" => {
                if claimDateTimeUtc >= dateTimeUtc {
                    filteredClaims.push(claim.clone());
                }
            }
            "le" => {
                if claimDateTimeUtc <= dateTimeUtc {
                    filteredClaims.push(claim.clone());
                }
            }
            "sa" => {
                if claimDateTimeUtc > dateTimeUtc {
                    filteredClaims.push(claim.clone());
                }
            }
            "eb" => {
                if claimDateTimeUtc < dateTimeUtc {
                    filteredClaims.push(claim.clone());
                }
            }
            "ap" => {
                // Approximation: Check if the claim date is within 1 day of the given date
                if claimDateTimeUtc >= lowerBound && claimDateTimeUtc <= upperBound {
                    filteredClaims.push(claim.clone());
                }
            }
            _ => {
                return r4:createFHIRError(string `Invalid operator: ${operator}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
            }
        }
    }
    return filteredClaims;
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

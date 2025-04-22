import ballerina/http;
import ballerina/time;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincipas;
import ballerinax/health.fhir.r4.parser;

isolated davincipas:PASClaim[] claims = [];
isolated int createOperationNextId = 12344;

public isolated function create(davincipas:PASClaim payload) returns r4:FHIRError|davincipas:PASClaimResponse|r4:FHIRParseError|error {
    davincipas:PASClaim|error claim = parser:parseWithValidation(payload.toJson(), davincipas:PASClaim).ensureType();

    if claim is error {
        return r4:createFHIRError(claim.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            claim.id = (++createOperationNextId).toBalString();
        }

        lock {
            claims.push(claim.clone());
        }

        lock {
            davincipas:PASClaimResponse claimResponse = check parser:parse(claimResponseJson, davincipas:PASClaimResponse).ensureType();
            claimResponse.patient = claim.clone().patient;
            claimResponse.insurer = claim.clone().insurer;
            claimResponse.created = claim.clone().created;
            return claimResponse.clone();
        }
    }
}

public isolated function getById(string id) returns r4:FHIRError|davincipas:PASClaim {
    lock {
        foreach var item in claims {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a Patient resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
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
            results = claims.clone();
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
        json patientJson = {
            "resourceType": "Claim",
            "id": "12344",
            "identifier":
                [
                {
                    "system": "http://hospital.org/claims",
                    "value": "PA-20250302-001"
                }
            ]
            ,
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
        davincipas:PASClaim patient = check parser:parse(patientJson, davincipas:PASClaim).ensureType();
        claims.push(patient);
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

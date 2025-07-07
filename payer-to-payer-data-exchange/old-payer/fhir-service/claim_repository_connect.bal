import ballerina/http;
import ballerina/log;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincipas;
import ballerinax/health.fhir.r4.parser;

isolated davincipas:PASClaim[] claims = [];
isolated int createOperationNextIdClaim = 12344;

public isolated function createClaim(davincipas:PASClaim payload) returns r4:FHIRError|davincipas:PASClaimResponse|r4:FHIRParseError|error {
    davincipas:PASClaim|error claim = parser:parseWithValidation(payload.toJson(), davincipas:PASClaim).ensureType();

    if claim is error {
        return r4:createFHIRError(claim.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextIdClaim = createOperationNextIdClaim + 1;
            claim.id = createOperationNextIdClaim.toBalString();
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

public isolated function getByIdClaim(string id) returns r4:FHIRError|davincipas:PASClaim {
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

public isolated function updateClaim(json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function patchResourceClaim(string 'resource, string id, json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
}

public isolated function deleteClaim(string 'resource, string id) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function searchClaim(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        if searchParameters.keys().count() == 0 {
            lock {
                r4:BundleEntry[] bundleEntries = [];
                foreach var item in claims {
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
                    davincipas:PASClaim byId = check getByIdClaim(searchParameters.get('key)[0]);
                    bundle.entry = [
                        {
                            'resource: byId
                        }
                    ];
                    return bundle;
                }
                "patient" => {

                    lock {
                        r4:BundleEntry[] bundleEntries = [];
                        foreach davincipas:PASClaim item in claims {
                            string patientSearchParam = searchParameters.get('key)[0];
                            string patientReference = (<string>item.patient.reference);

                            log:printDebug(string `References are: ${patientSearchParam} and ${patientReference}`);

                            if patientSearchParam != patientReference {
                                continue;
                            }

                            r4:BundleEntry bundleEntry = {
                                'resource: item
                            };
                            bundleEntries.push(bundleEntry);

                        }
                        r4:Bundle bundleClone = bundle.clone();
                        bundleClone.entry = bundleEntries;
                        return bundleClone.clone();
                    }

                }
                _ => {
                    return r4:createFHIRError(string `Not supported search parameter: ${'key}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
                }
            }
        }
    }

    return bundle;
}

function loadClaimData() returns error? {
    lock {
        json patientJson1 = {
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

        json patientJson2 = {
            "resourceType": "Claim",
            "id": "12345",
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
        json patientJson3 = {
            "resourceType": "Claim",
            "id": "12346",
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
                "reference": "Patient/105"
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
        davincipas:PASClaim patient = check parser:parse(patientJson1, davincipas:PASClaim).ensureType();
        davincipas:PASClaim patient2 = check parser:parse(patientJson2, davincipas:PASClaim).ensureType();
        davincipas:PASClaim patient3 = check parser:parse(patientJson3, davincipas:PASClaim).ensureType();

        claims.push(patient);
        claims.push(patient2);
        claims.push(patient3);
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

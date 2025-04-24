import ballerinax/health.fhir.r4.davincipas;
import ballerinax/health.fhir.r4.parser;

function init() returns error? {
    string claimId = "";
    lock {
        claimId = claimCreateOperationNextId.toBalString();
    }
    lock {
        json claimJson = {
            "resourceType": "Claim",
            "id": claimId,
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
        claims.push(claim.clone()); 
    }

    string claimResponseId = "";
    lock {
        claimResponseId = claimResponseCreateOperationNextId.toBalString();
    }
    lock {
        json claimResponseJson = {
            "resourceType": "ClaimResponse",
            "id": claimResponseId,
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
                "reference": "Claim/" + claimId
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
        claimResponses.push(claimResponse.clone());
    }
}

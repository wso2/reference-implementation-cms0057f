import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincipas;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.parser;

isolated davincipas:PASClaim[] claims = [];
isolated davincipas:PASClaimResponse[] claimResponses = [];
isolated int createOperationNextId = 12344;

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

                            lock {
                                claim.id = (++createOperationNextId).toBalString();
                            }

                            lock {
                                claims.push(claim.clone());
                            }

                            davincipas:PASClaimResponse claimResponse = {use: "claim", insurer: {}, patient: {}, created: "", 'type: {}, outcome: "partial", status: "entered-in-error"};
                            lock {
                                claimResponse = check parser:parse(claimResponseJson.clone(), davincipas:PASClaimResponse).ensureType();
                            }

                            lock {
                                davincipas:PASClaimResponse claimResponseClone = claimResponse.clone();
                                claimResponseClone.id = claim.id;
                                claimResponseClone.patient = claim.clone().patient;
                                claimResponseClone.insurer = claim.clone().insurer;
                                claimResponseClone.created = claim.clone().created;
                                claimResponses.push(claimResponseClone);

                                international401:ParametersParameter p = {
                                    name: "return",
                                    'resource: claimResponseClone.clone()
                                };

                                international401:Parameters response = {
                                    'parameter: [p]
                                };
                                return response.clone();
                            }

                        }
                    }

                }
            }
        }

    }
    return r4:createFHIRError("Something went wrong", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
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

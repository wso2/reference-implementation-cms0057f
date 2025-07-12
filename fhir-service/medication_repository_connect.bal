// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).

// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore501;

isolated uscore501:USCoreMedicationRequestProfile[] medicationRequests = [];
isolated int createOperationNextIdMedicationRequest = 111113;

public isolated function createMedicationRequest(uscore501:USCoreMedicationRequestProfile payload) returns r4:FHIRError|uscore501:USCoreMedicationRequestProfile {
    uscore501:USCoreMedicationRequestProfile|error medicationRequest = parser:parseWithValidation(payload.toJson(), uscore501:USCoreMedicationRequestProfile).ensureType();

    if medicationRequest is error {
        return r4:createFHIRError(medicationRequest.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            medicationRequest.id = (++createOperationNextIdMedicationRequest).toBalString();
        }

        lock {
            medicationRequests.push(medicationRequest.clone());
        }

        return medicationRequest;
    }
}

public isolated function getByIdMedicationRequest(string id) returns r4:FHIRError|uscore501:USCoreMedicationRequestProfile {
    lock {
        foreach var item in medicationRequests {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a Patient resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function updateMedicationRequest(json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function patchResourceMedicationRequest(string 'resource, string id, json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
}

public isolated function deleteMedicationRequest(string 'resource, string id) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function searchMedicationRequest(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        if searchParameters.keys().length() == 1 {
            lock {
                r4:BundleEntry[] bundleEntries = [];
                foreach var item in medicationRequests {
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
                    uscore501:USCoreMedicationRequestProfile byId = check getByIdMedicationRequest(searchParameters.get('key)[0]);
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

function loadMedicationRequestData() returns error? {
    lock {
        json medicationRequestJson1 = {
            "resourceType": "MedicationRequest",
            "id": "111112",
            "meta": {
                "profile": [
                    "http://hl7.org/fhir/StructureDefinition/MedicationRequest"
                ]
            },
            "status": "active",
            "intent": "order",
            "medicationReference": {
                "reference": "Medication/aimovig-70mg"
            },
            "medicationCodeableConcept": {
                "coding": [
                    {
                        "system": "http://www.nlm.nih.gov/research/umls/rxnorm",
                        "code": "1746007",
                        "display": "Aimovig 70 mg Injection"
                    }
                ],
                "text": "Aimovig 70 mg Injection"
            },
            "subject": {
                "reference": "Patient/101"
            },
            "requester": {
                "reference": "Practitioner/practitioner-456"
            },
            "authoredOn": "2025-03-02",
            "dosageInstruction": [
                {
                    "text": "Inject 70 mg subcutaneously once a month",
                    "timing": {
                        "repeat": {
                            "boundsPeriod": {
                                "start": "2025-03-02"
                            },
                            "frequency": 1,
                            "period": 1.0,
                            "periodUnit": "mo"
                        }
                    },
                    "doseAndRate": [
                        {
                            "doseQuantity": {
                                "value": 70.0,
                                "unit": "mg",
                                "system": "http://unitsofmeasure.org",
                                "code": "mg"
                            }
                        }
                    ]
                }
            ],
            "dispenseRequest": {
                "quantity": {
                    "value": 1.0,
                    "unit": "injection",
                    "system": "http://unitsofmeasure.org",
                    "code": "injection"
                },
                "expectedSupplyDuration": {
                    "value": 30,
                    "unit": "days",
                    "system": "http://unitsofmeasure.org",
                    "code": "d"
                }
            }
        };

        json medicationRequestJson2 = {
            "resourceType": "MedicationRequest",
            "id": "111114",
            "meta": {
                "profile": ["http://hl7.org/fhir/StructureDefinition/MedicationRequest"]
            },
            "status": "active",
            "intent": "order",
            "medicationReference": {
                "reference": "Medication/lisinopril-10mg"
            },
            "medicationCodeableConcept": {
                "coding": [
                    {
                        "system": "http://www.nlm.nih.gov/research/umls/rxnorm",
                        "code": "197361",
                        "display": "Lisinopril 10 mg oral tablet"
                    }
                ],
                "text": "Lisinopril 10 mg Tablet"
            },
            "subject": {
                "reference": "Patient/101"
            },
            "requester": {
                "reference": "Practitioner/practitioner-456"
            },
            "authoredOn": "2025-04-01",
            "dosageInstruction": [
                {
                    "text": "Take 1 tablet by mouth once daily",
                    "timing": {
                        "repeat": {
                            "frequency": 1,
                            "period": 1,
                            "periodUnit": "d"
                        }
                    },
                    "doseAndRate": [
                        {
                            "doseQuantity": {
                                "value": 10,
                                "unit": "mg",
                                "system": "http://unitsofmeasure.org",
                                "code": "mg"
                            }
                        }
                    ]
                }
            ],
            "dispenseRequest": {
                "quantity": {
                    "value": 30,
                    "unit": "tablets",
                    "system": "http://unitsofmeasure.org",
                    "code": "tablet"
                },
                "expectedSupplyDuration": {
                    "value": 30,
                    "unit": "days",
                    "system": "http://unitsofmeasure.org",
                    "code": "d"
                }
            }
        };

        json medicationRequestJson3 = {
            "resourceType": "MedicationRequest",
            "id": "111113",
            "meta": {
                "profile": ["http://hl7.org/fhir/StructureDefinition/MedicationRequest"]
            },
            "status": "active",
            "intent": "order",
            "medicationReference": {
                "reference": "Medication/metformin-500mg"
            },
            "medicationCodeableConcept": {
                "coding": [
                    {
                        "system": "http://www.nlm.nih.gov/research/umls/rxnorm",
                        "code": "860975",
                        "display": "Metformin 500 mg oral tablet"
                    }
                ],
                "text": "Metformin 500 mg Tablet"
            },
            "subject": {
                "reference": "Patient/101"
            },
            "requester": {
                "reference": "Practitioner/practitioner-456"
            },
            "authoredOn": "2025-03-10",
            "dosageInstruction": [
                {
                    "text": "Take 1 tablet by mouth twice daily with meals",
                    "timing": {
                        "repeat": {
                            "frequency": 2,
                            "period": 1,
                            "periodUnit": "d"
                        }
                    },
                    "doseAndRate": [
                        {
                            "doseQuantity": {
                                "value": 500,
                                "unit": "mg",
                                "system": "http://unitsofmeasure.org",
                                "code": "mg"
                            }
                        }
                    ]
                }
            ],
            "dispenseRequest": {
                "quantity": {
                    "value": 60,
                    "unit": "tablets",
                    "system": "http://unitsofmeasure.org",
                    "code": "tablet"
                },
                "expectedSupplyDuration": {
                    "value": 30,
                    "unit": "days",
                    "system": "http://unitsofmeasure.org",
                    "code": "d"
                }
            }
        };

        json medicationRequestJson4 = {
            "resourceType": "MedicationRequest",
            "id": "111115",
            "meta": {
                "profile": ["http://hl7.org/fhir/StructureDefinition/MedicationRequest"]
            },
            "status": "active",
            "intent": "order",
            "medicationReference": {
                "reference": "Medication/lantus-100units"
            },
            "medicationCodeableConcept": {
                "coding": [
                    {
                        "system": "http://www.nlm.nih.gov/research/umls/rxnorm",
                        "code": "310798",
                        "display": "Insulin glargine 100 unit/mL injectable solution"
                    }
                ],
                "text": "Lantus (Insulin Glargine) 100 units/mL"
            },
            "subject": {
                "reference": "Patient/101"
            },
            "requester": {
                "reference": "Practitioner/practitioner-456"
            },
            "authoredOn": "2025-05-01",
            "dosageInstruction": [
                {
                    "text": "Inject 10 units subcutaneously at bedtime",
                    "timing": {
                        "repeat": {
                            "frequency": 1,
                            "period": 1,
                            "periodUnit": "d"
                        }
                    },
                    "doseAndRate": [
                        {
                            "doseQuantity": {
                                "value": 10,
                                "unit": "units",
                                "system": "http://unitsofmeasure.org",
                                "code": "U"
                            }
                        }
                    ]
                }
            ],
            "dispenseRequest": {
                "quantity": {
                    "value": 1,
                    "unit": "vial",
                    "system": "http://unitsofmeasure.org",
                    "code": "vial"
                },
                "expectedSupplyDuration": {
                    "value": 30,
                    "unit": "days",
                    "system": "http://unitsofmeasure.org",
                    "code": "d"
                }
            }
        };

        uscore501:USCoreMedicationRequestProfile medicationRequest1 = check parser:parse(medicationRequestJson1, uscore501:USCoreMedicationRequestProfile).ensureType();
        uscore501:USCoreMedicationRequestProfile medicationRequest2 = check parser:parse(medicationRequestJson2, uscore501:USCoreMedicationRequestProfile).ensureType();
        uscore501:USCoreMedicationRequestProfile medicationRequest3 = check parser:parse(medicationRequestJson3, uscore501:USCoreMedicationRequestProfile).ensureType();
        uscore501:USCoreMedicationRequestProfile medicationRequest4 = check parser:parse(medicationRequestJson4, uscore501:USCoreMedicationRequestProfile).ensureType();

        medicationRequests.push(medicationRequest1, medicationRequest2, medicationRequest3, medicationRequest4);

    }

}

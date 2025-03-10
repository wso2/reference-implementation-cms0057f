import ballerina/http;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore501;

isolated uscore501:USCoreMedicationRequestProfile[] medicationRequests = [];
isolated int createOperationNextId = 111113;

public isolated function create(uscore501:USCoreMedicationRequestProfile payload) returns r4:FHIRError|uscore501:USCoreMedicationRequestProfile {
    uscore501:USCoreMedicationRequestProfile|error medicationRequest = parser:parseWithValidation(payload.toJson(), uscore501:USCoreMedicationRequestProfile).ensureType();

    if medicationRequest is error {
        return r4:createFHIRError(medicationRequest.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            medicationRequest.id = (++createOperationNextId).toBalString();
        }

        lock {
            medicationRequests.push(medicationRequest.clone());
        }

        return medicationRequest;
    }
}

public isolated function getById(string id) returns r4:FHIRError|uscore501:USCoreMedicationRequestProfile {
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
                    uscore501:USCoreMedicationRequestProfile byId = check getById(searchParameters.get('key)[0]);
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
        json organizationJson = {
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
                "reference": "Patient/john-smith"
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

        uscore501:USCoreMedicationRequestProfile medicationRequest = check parser:parse(organizationJson, uscore501:USCoreMedicationRequestProfile).ensureType();
        medicationRequests.push(medicationRequest);
    }

}

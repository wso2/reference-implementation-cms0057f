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
import ballerinax/health.fhir.r4 as r4;
import ballerinax/health.fhir.r4.parser;

isolated Observation[] observations = [];
isolated int createObservationNextId = 63230;

public isolated function createObservation(Observation observation) returns r4:FHIRError|Observation {
    lock {
        createObservationNextId = createObservationNextId + 1;
        observation.id = createObservationNextId.toBalString();
    }

    lock {
        Observation|error parsed = parser:parse(observation.clone().toJson()).ensureType();
        if parsed is Observation {
            observations.push(parsed);
        }

    }
    return observation;

}

public isolated function getByIdObservation(string id) returns r4:FHIRError|Observation {
    lock {
        foreach var item in observations {
            if item.id == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find an Observation resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function searchObservation(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        string? id = ();
        string? patient = ();

        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    id = searchParameters.get('key)[0];
                }
                "patient" => {
                    patient = searchParameters.get('key)[0];
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
        Observation[] results;
        lock {
            results = observations.clone();
        }

        if id is string {
            Observation byId = check getByIdObservation(id);
            results.push(byId);
        }

        if patient is string {
            results = getByPatientObservation(patient, results);
        }

        r4:BundleEntry[] bundleEntries = [];
        foreach Observation item in results {
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

isolated function getByPatientObservation(string patient, Observation[] observations) returns Observation[] {
    Observation[] filteredObservation = [];
    foreach Observation observation in observations {
        if observation.subject.reference == patient {
            filteredObservation.push(observation);
        }
    }
    return filteredObservation;
}

function loadObservationData() returns error? {
    lock {
        json observationJson1 = {
            "resourceType": "Observation",
            "id": "63230",
            "meta": {
                "profile": [
                    "http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-clinical-test"
                ]
            },
            "status": "final",
            "category": [
                {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                            "code": "vital-signs",
                            "display": "Vital Signs"
                        }
                    ]
                }
            ],
            "code": {
                "coding": [
                    {
                        "system": "http://loinc.org",
                        "code": "8310-5",
                        "display": "Body temperature"
                    }
                ],
                "text": "Body temperature"
            },
            "subject": {
                "reference": "Patient/101"
            },
            "effectivePeriod": {
                "start": "2025-06-10T08:30:00-05:00",
                "end": "2025-06-10T08:35:00-05:00"
            },
            "valueQuantity": {
                "value": 98.6,
                "unit": "°F",
                "system": "http://unitsofmeasure.org",
                "code": "°F"
            }
        };

        json observationJson2 = {
            "resourceType": "Observation",
            "id": "63229",
            "meta": {
                "profile": [
                    "http://hl7.org/fhir/us/core/StructureDefinition/us-core-blood-pressure"
                ]
            },
            "status": "final",
            "category": [
                {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                            "code": "vital-signs",
                            "display": "Vital Signs"
                        }
                    ]
                }
            ],
            "code": {
                "coding": [
                    {
                        "system": "http://loinc.org",
                        "code": "85354-9",
                        "display": "Blood pressure panel with all children optional"
                    }
                ],
                "text": "Blood Pressure"
            },
            "subject": {
                "reference": "Patient/101"
            },
            "effectivePeriod": {
                "start": "2025-06-10T08:35:00-05:00",
                "end": "2025-06-10T08:40:00-05:00"
            },
            "effectiveDateTime": "2025-06-10T08:35:00-05:00",
            "component": [
                {
                    "code": {
                        "coding": [
                            {
                                "system": "http://loinc.org",
                                "code": "8480-6",
                                "display": "Systolic blood pressure"
                            }
                        ]
                    },
                    "valueQuantity": {
                        "value": 120,
                        "unit": "mmHg",
                        "system": "http://unitsofmeasure.org",
                        "code": "mm[Hg]"
                    }
                },
                {
                    "code": {
                        "coding": [
                            {
                                "system": "http://loinc.org",
                                "code": "8462-4",
                                "display": "Diastolic blood pressure"
                            }
                        ]
                    },
                    "valueQuantity": {
                        "value": 80,
                        "unit": "mmHg",
                        "system": "http://unitsofmeasure.org",
                        "code": "mm[Hg]"
                    }
                }
            ]
        };

        json observationJson3 = {
            "resourceType": "Observation",
            "id": "63228",
            "meta": {
                "profile": [
                    "http://hl7.org/fhir/us/core/StructureDefinition/us-core-pulse-oximetry"
                ]
            },
            "status": "final",
            "category": [
                {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/observation-category",
                            "code": "vital-signs",
                            "display": "Vital Signs"
                        }
                    ]
                }
            ],
            "code": {
                "coding": [
                    {
                        "system": "http://loinc.org",
                        "code": "59408-5",
                        "display": "Oxygen saturation in Arterial blood by Pulse oximetry"
                    }
                ],
                "text": "Oxygen Saturation"
            },
            "subject": {
                "reference": "Patient/102"
            },
            "effectivePeriod": {
                "start": "2025-06-10T08:40:00-05:00",
                "end": "2025-06-10T08:45:00-05:00"
            },
            "effectiveDateTime": "2025-06-10T08:30:00-05:00",
            "valueQuantity": {
                "value": 97,
                "unit": "%",
                "system": "http://unitsofmeasure.org",
                "code": "%"
            }
        };

        Observation observation1 = check parser:parse(observationJson1).ensureType();
        Observation observation2 = check parser:parse(observationJson2).ensureType();
        Observation observation3 = check parser:parse(observationJson3).ensureType();
        observations.push(observation1, observation2, observation3);
    }
}

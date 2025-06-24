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

isolated AllergyIntolerance[] allergyIntolerances = [];
isolated int createAllergyIntoleranceNextId = 20300;

public isolated function createAllergyIntolerance(AllergyIntolerance allergyIntolerance) returns r4:FHIRError|AllergyIntolerance {
    lock {
        createAllergyIntoleranceNextId += 1;
        allergyIntolerance.id = (createAllergyIntoleranceNextId).toBalString();
    }
    lock {
        allergyIntolerances.push(allergyIntolerance.clone());
    }
    return allergyIntolerance;

}

public isolated function getByIdAllergyIntolerance(string id) returns r4:FHIRError|AllergyIntolerance {
    lock {
        foreach var item in allergyIntolerances {
            if item.id == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find an AllergyIntolerance resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function searchAllergyIntolerance(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
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
        AllergyIntolerance[] results;
        lock {
            results = allergyIntolerances.clone();
        }

        if id is string {
            AllergyIntolerance byId = check getByIdAllergyIntolerance(id);
            results.push(byId);
        }

        if patient is string {
            results = getByPatientAllergyIntolerance(patient, results);
        }

        r4:BundleEntry[] bundleEntries = [];
        foreach AllergyIntolerance item in results {
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

isolated function getByPatientAllergyIntolerance(string patient, AllergyIntolerance[] allergyIntolerances) returns AllergyIntolerance[] {
    AllergyIntolerance[] filteredAllergyIntolerance = [];
    foreach AllergyIntolerance allergyIntolerance in allergyIntolerances {
        if allergyIntolerance.patient.reference == patient {
            filteredAllergyIntolerance.push(allergyIntolerance);
        }
    }
    return filteredAllergyIntolerance;
}

function loadAllergyIntoleranceData() returns error? {
    lock {
        json allergyIntoleranceJson1 = {
            "resourceType": "AllergyIntolerance",
            "id": "20300",
            "meta": {
                "profile": [
                    "http://hl7.org/fhir/us/core/StructureDefinition/us-core-allergyintolerance"
                ]
            },
            "clinicalStatus": {
                "coding": [
                    {
                        "system": "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical",
                        "code": "active",
                        "display": "Active"
                    }
                ]
            },
            "verificationStatus": {
                "coding": [
                    {
                        "system": "http://terminology.hl7.org/CodeSystem/allergyintolerance-verification",
                        "code": "confirmed",
                        "display": "Confirmed"
                    }
                ]
            },
            "type": "allergy",
            "category": ["medication"],
            "criticality": "high",
            "code": {
                "coding": [
                    {
                        "system": "http://www.nlm.nih.gov/research/umls/rxnorm",
                        "code": "7980",
                        "display": "Penicillin"
                    }
                ],
                "text": "Penicillin"
            },
            "patient": {
                "reference": "Patient/101"
            },
            "onsetDateTime": "2012-06-10",
            "recordedDate": "2012-06-15",
            "recorder": {
                "reference": "Practitioner/practitioner-456"
            },
            "reaction": [
                {
                    "manifestation": [
                        {
                            "coding": [
                                {
                                    "system": "http://snomed.info/sct",
                                    "code": "271807003",
                                    "display": "Rash"
                                }
                            ],
                            "text": "Skin rash"
                        }
                    ],
                    "severity": "moderate",
                    "description": "Developed itchy rash after taking penicillin"
                }
            ]
        };

        json allergyIntoleranceJson2 = {
            "resourceType": "AllergyIntolerance",
            "id": "allergy-peanut",
            "meta": {
                "profile": [
                    "http://hl7.org/fhir/us/core/StructureDefinition/us-core-allergyintolerance"
                ]
            },
            "clinicalStatus": {
                "coding": [
                    {
                        "system": "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical",
                        "code": "active",
                        "display": "Active"
                    }
                ]
            },
            "verificationStatus": {
                "coding": [
                    {
                        "system": "http://terminology.hl7.org/CodeSystem/allergyintolerance-verification",
                        "code": "confirmed",
                        "display": "Confirmed"
                    }
                ]
            },
            "type": "allergy",
            "category": ["food"],
            "criticality": "high",
            "code": {
                "coding": [
                    {
                        "system": "http://snomed.info/sct",
                        "code": "91935009",
                        "display": "Allergy to peanuts"
                    }
                ],
                "text": "Peanut Allergy"
            },
            "patient": {
                "reference": "Patient/101"
            },
            "onsetDateTime": "2008-09-20",
            "recordedDate": "2008-09-25",
            "recorder": {
                "reference": "Practitioner/practitioner-456"
            },
            "reaction": [
                {
                    "manifestation": [
                        {
                            "coding": [
                                {
                                    "system": "http://snomed.info/sct",
                                    "code": "39579001",
                                    "display": "Anaphylaxis"
                                }
                            ],
                            "text": "Severe allergic reaction (anaphylaxis)"
                        }
                    ],
                    "severity": "severe",
                    "description": "Swelling and difficulty breathing after eating peanut-containing food"
                }
            ]
        };

        json allergyIntoleranceJson3 = {
            "resourceType": "AllergyIntolerance",
            "id": "allergy-pollen",
            "meta": {
                "profile": [
                    "http://hl7.org/fhir/us/core/StructureDefinition/us-core-allergyintolerance"
                ]
            },
            "clinicalStatus": {
                "coding": [
                    {
                        "system": "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical",
                        "code": "active",
                        "display": "Active"
                    }
                ]
            },
            "verificationStatus": {
                "coding": [
                    {
                        "system": "http://terminology.hl7.org/CodeSystem/allergyintolerance-verification",
                        "code": "confirmed",
                        "display": "Confirmed"
                    }
                ]
            },
            "type": "allergy",
            "category": ["environment"],
            "criticality": "low",
            "code": {
                "coding": [
                    {
                        "system": "http://snomed.info/sct",
                        "code": "418689008",
                        "display": "Allergy to pollen"
                    }
                ],
                "text": "Pollen Allergy"
            },
            "patient": {
                "reference": "Patient/102"
            },
            "onsetDateTime": "2015-04-01",
            "recordedDate": "2015-04-05",
            "recorder": {
                "reference": "Practitioner/practitioner-456"
            },
            "reaction": [
                {
                    "manifestation": [
                        {
                            "coding": [
                                {
                                    "system": "http://snomed.info/sct",
                                    "code": "78352004",
                                    "display": "Sneezing"
                                }
                            ],
                            "text": "Sneezing and runny nose"
                        }
                    ],
                    "severity": "mild",
                    "description": "Seasonal sneezing and nasal congestion"
                }
            ]
        };

        AllergyIntolerance allergyIntolerance1 = check parser:parse(allergyIntoleranceJson1).ensureType();
        AllergyIntolerance allergyIntolerance2 = check parser:parse(allergyIntoleranceJson2).ensureType();
        AllergyIntolerance allergyIntolerance3 = check parser:parse(allergyIntoleranceJson3).ensureType();
        allergyIntolerances.push(allergyIntolerance1, allergyIntolerance2, allergyIntolerance3);
    }
}

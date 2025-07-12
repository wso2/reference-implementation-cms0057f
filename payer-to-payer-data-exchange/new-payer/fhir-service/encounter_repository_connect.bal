import ballerina/http;
import ballerina/log;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.parser;

isolated international401:Encounter[] encounters = [];
isolated int createOperationNextIdEncounter = 12344;

public isolated function createEncounter(international401:Encounter payload) returns r4:FHIRError|r4:FHIRParseError? {
    international401:Encounter|error encounter = parser:parseWithValidation(payload.toJson(), international401:Encounter).ensureType();

    if encounter is error {
        return r4:createFHIRError(encounter.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextIdEncounter = createOperationNextIdEncounter + 1;
            encounter.id = createOperationNextIdEncounter.toBalString();
        }

        lock {
            encounters.push(encounter.clone());
        }
    }
    return;
}

public isolated function getByIdEncounter(string id) returns r4:FHIRError|international401:Encounter {
    lock {
        foreach var item in encounters {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a Patient resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function updateEncounter(json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function patchResourceEncounter(string 'resource, string id, json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
}

public isolated function deleteEncounter(string 'resource, string id) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function searchEncounter(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        if searchParameters.keys().count() == 0 {
            lock {
                r4:BundleEntry[] bundleEntries = [];
                foreach var item in encounters {
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
                    international401:Encounter byId = check getByIdEncounter(searchParameters.get('key)[0]);
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
                        foreach international401:Encounter item in encounters {
                            string patientSearchParam = searchParameters.get('key)[0];
                            string patientReference = "";
                            if item.subject is r4:Reference {
                                patientReference = <string>(<r4:Reference>item.subject).reference;
                            }

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

function loadEncounterData() returns error? {
    lock {
        json patientJson1 = {
            "resourceType": "Encounter",
            "id": "f201",
            "identifier": [
                {
                    "use": "temp",
                    "value": "Encounter_Roel_20130404"
                }
            ],
            "status": "finished",
            "class": {
                "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                "code": "AMB",
                "display": "ambulatory"
            },
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://snomed.info/sct",
                            "code": "11429006",
                            "display": "Consultation"
                        }
                    ]
                }
            ],
            "priority": {
                "coding": [
                    {
                        "system": "http://snomed.info/sct",
                        "code": "17621005",
                        "display": "Normal"
                    }
                ]
            },
            "subject": {
                "reference": "Patient/101",
                "display": "Roel"
            },
            "participant": [
                {
                    "individual": {
                        "reference": "Practitioner/f201"
                    }
                }
            ],
            "reasonCode": [
                {
                    "text": "The patient had fever peaks over the last couple of days. He is worried about these peaks."
                }
            ],
            "serviceProvider": {
                "reference": "Organization/f201"
            }
        };

        json patientJson2 = {
            "resourceType": "Encounter",
            "id": "f002",
            "identifier": [
                {
                    "use": "official",
                    "system": "http://www.bmc.nl/zorgportal/identifiers/encounters",
                    "value": "v3251"
                }
            ],
            "status": "finished",
            "class": {
                "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                "code": "AMB",
                "display": "ambulatory"
            },
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://snomed.info/sct",
                            "code": "270427003",
                            "display": "Patient-initiated encounter"
                        }
                    ]
                }
            ],
            "priority": {
                "coding": [
                    {
                        "system": "http://snomed.info/sct",
                        "code": "103391001",
                        "display": "Urgent"
                    }
                ]
            },
            "subject": {
                "reference": "Patient/102",
                "display": "P. van de Heuvel"
            },
            "participant": [
                {
                    "individual": {
                        "reference": "Practitioner/f003",
                        "display": "M.I.M Versteegh"
                    }
                }
            ],
            "length": {
                "value": 140,
                "unit": "min",
                "system": "http://unitsofmeasure.org",
                "code": "min"
            },
            "reasonCode": [
                {
                    "coding": [
                        {
                            "system": "http://snomed.info/sct",
                            "code": "34068001",
                            "display": "Partial lobectomy of lung"
                        }
                    ]
                }
            ],
            "hospitalization": {
                "preAdmissionIdentifier": {
                    "use": "official",
                    "system": "http://www.bmc.nl/zorgportal/identifiers/pre-admissions",
                    "value": "98682"
                },
                "admitSource": {
                    "coding": [
                        {
                            "system": "http://snomed.info/sct",
                            "code": "305997006",
                            "display": "Referral by radiologist"
                        }
                    ]
                },
                "dischargeDisposition": {
                    "coding": [
                        {
                            "system": "http://snomed.info/sct",
                            "code": "306689006",
                            "display": "Discharge to home"
                        }
                    ]
                }
            },
            "serviceProvider": {
                "reference": "Organization/f001",
                "display": "BMC"
            }
        };
        json patientJson3 = {
            "resourceType": "Encounter",
            "id": "f203",
            "identifier": [
                {
                    "use": "temp",
                    "value": "Encounter_Roel_20130311"
                }
            ],
            "status": "finished",
            "statusHistory": [
                {
                    "status": "arrived",
                    "period": {
                        "start": "2013-03-08"
                    }
                }
            ],
            "class": {
                "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                "code": "IMP",
                "display": "inpatient encounter"
            },
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://snomed.info/sct",
                            "code": "183807002",
                            "display": "Inpatient stay for nine days"
                        }
                    ]
                }
            ],
            "priority": {
                "coding": [
                    {
                        "system": "http://snomed.info/sct",
                        "code": "394849002",
                        "display": "High priority"
                    }
                ]
            },
            "subject": {
                "reference": "Patient/102",
                "display": "Roel"
            },
            "episodeOfCare": [
                {
                    "reference": "EpisodeOfCare/example"
                }
            ],
            "basedOn": [
                {
                    "reference": "ServiceRequest/myringotomy"
                }
            ],
            "participant": [
                {
                    "type": [
                        {
                            "coding": [
                                {
                                    "system": "http://terminology.hl7.org/CodeSystem/v3-ParticipationType",
                                    "code": "PART"
                                }
                            ]
                        }
                    ],
                    "individual": {
                        "reference": "Practitioner/f201"
                    }
                }
            ],
            "appointment": [
                {
                    "reference": "Appointment/example"
                }
            ],
            "period": {
                "start": "2013-03-11",
                "end": "2013-03-20"
            },
            "reasonCode": [
                {
                    "text": "The patient seems to suffer from bilateral pneumonia and renal insufficiency, most likely due to chemotherapy."
                }
            ],
            "diagnosis": [
                {
                    "condition": {
                        "reference": "Condition/stroke"
                    },
                    "use": {
                        "coding": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/diagnosis-role",
                                "code": "AD",
                                "display": "Admission diagnosis"
                            }
                        ]
                    },
                    "rank": 1
                },
                {
                    "condition": {
                        "reference": "Condition/f201"
                    },
                    "use": {
                        "coding": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/diagnosis-role",
                                "code": "DD",
                                "display": "Discharge diagnosis"
                            }
                        ]
                    }
                }
            ],
            "account": [
                {
                    "reference": "Account/example"
                }
            ],
            "hospitalization": {
                "origin": {
                    "reference": "Location/2"
                },
                "admitSource": {
                    "coding": [
                        {
                            "system": "http://snomed.info/sct",
                            "code": "309902002",
                            "display": "Clinical Oncology Department"
                        }
                    ]
                },
                "reAdmission": {
                    "coding": [
                        {
                            "display": "readmitted"
                        }
                    ]
                },
                "dietPreference": [
                    {
                        "coding": [
                            {
                                "system": "http://snomed.info/sct",
                                "code": "276026009",
                                "display": "Fluid balance regulation"
                            }
                        ]
                    }
                ],
                "specialCourtesy": [
                    {
                        "coding": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/v3-EncounterSpecialCourtesy",
                                "code": "NRM",
                                "display": "normal courtesy"
                            }
                        ]
                    }
                ],
                "specialArrangement": [
                    {
                        "coding": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/encounter-special-arrangements",
                                "code": "wheel",
                                "display": "Wheelchair"
                            }
                        ]
                    }
                ],
                "destination": {
                    "reference": "Location/2"
                }
            },
            "serviceProvider": {
                "reference": "Organization/2"
            },
            "partOf": {
                "reference": "Encounter/f203"
            }
        };
        international401:Encounter patient = check parser:parse(patientJson1, international401:Encounter).ensureType();
        international401:Encounter patient2 = check parser:parse(patientJson2, international401:Encounter).ensureType();
        international401:Encounter patient3 = check parser:parse(patientJson3, international401:Encounter).ensureType();

        encounters.push(patient);
        encounters.push(patient2);
        encounters.push(patient3);
    }

}

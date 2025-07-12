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
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore501;

isolated uscore501:USCoreEncounterProfile[] encounters = [];
isolated int createOperationNextIdEncounter = 12344;

public isolated function createEncounter(json payload) returns r4:FHIRError|uscore501:USCoreEncounterProfile {
    uscore501:USCoreEncounterProfile|error encounter = parser:parse(payload, uscore501:USCoreEncounterProfile).ensureType();

    if encounter is error {
        return r4:createFHIRError(encounter.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextIdEncounter += 1;
            encounter.id = (createOperationNextIdEncounter).toBalString();
        }

        lock {
            encounters.push(encounter.clone());
        }

        return encounter;
    }
}

public isolated function getByIdEncounter(string id) returns r4:FHIRError|uscore501:USCoreEncounterProfile {
    lock {
        foreach var item in encounters {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a encounter resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function searchEncounter(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    uscore501:USCoreEncounterProfile byId = check getByIdEncounter(searchParameters.get('key)[0]);
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
                        foreach uscore501:USCoreEncounterProfile item in encounters {
                            string patientSearchParam = searchParameters.get('key)[0];
                            string patientReference = <string>(item.subject).reference;

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

    lock {
        r4:BundleEntry[] bundleEntries = [];
        foreach var item in encounters {
            r4:BundleEntry bundleEntry = {
                'resource: item
            };
            bundleEntries.push(bundleEntry);
        }
        r4:Bundle cloneBundle = bundle.clone();
        cloneBundle.entry = bundleEntries;
        return cloneBundle.clone();
    }
}

function loadEncounterData() returns error? {
    lock {
        json encounterJson = {
            "resourceType": "Encounter",
            "id": "12344",
            "meta": {
                "lastUpdated": "2024-01-28T16:06:21-08:00",
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-encounter|7.0.0"]
            },
            "text": {
                "status": "generated",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p><b>Generated Narrative: Encounter</b><a name=\"1036\"> </a><a name=\"hc1036\"> </a></p><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Resource Encounter &quot;1036&quot; Updated &quot;2024-01-28 16:06:21-0800&quot; </p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-us-core-encounter.html\">US Core Encounter Profile (version 7.0.0)</a></p></div><p><b>status</b>: in-progress</p><p><b>class</b>: inpatient encounter (Details: http://terminology.hl7.org/CodeSystem/v3-ActCode code IMP = 'inpatient encounter', stated as 'inpatient encounter')</p><p><b>type</b>: Unknown (qualifier value) <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"https://browser.ihtsdotools.org/\">SNOMED CT[US]</a>#261665006)</span></p><p><b>subject</b>: <a href=\"Patient-example.html\">Patient/example</a> &quot; SHAW&quot;</p><h3>Hospitalizations</h3><table class=\"grid\"><tr><td style=\"display: none\">-</td><td><b>DischargeDisposition</b></td></tr><tr><td style=\"display: none\">*</td><td>Discharged to Home <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"http://terminology.hl7.org/5.3.0/CodeSystem-AHANUBCPatientDischargeStatus.html\">AHA NUBC Patient Discharge Status Codes</a>#01)</span></td></tr></table><h3>Locations</h3><table class=\"grid\"><tr><td style=\"display: none\">-</td><td><b>Location</b></td></tr><tr><td style=\"display: none\">*</td><td><a href=\"Location-hospital.html\">Location/hospital: Holy Family Hospital</a> &quot;Holy Family Hospital&quot;</td></tr></table></div>"
            },
            "status": "in-progress",
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
                            "version": "http://snomed.info/sct/731000124108",
                            "code": "261665006",
                            "display": "Unknown (qualifier value)"
                        }
                    ],
                    "text": "Unknown (qualifier value)"
                }
            ],
            "subject": {
                "reference": "Patient/example"
            },
            "hospitalization": {
                "dischargeDisposition": {
                    "coding": [
                        {
                            "system": "https://www.nubc.org/CodeSystem/PatDischargeStatus",
                            "code": "01",
                            "display": "Discharged to Home"
                        }
                    ]
                }
            },
            "location": [
                {
                    "location": {
                        "reference": "Location/hospital",
                        "display": "Holy Family Hospital"
                    }
                }
            ]
        };
        uscore501:USCoreEncounterProfile encounter = check parser:parse(encounterJson, uscore501:USCoreEncounterProfile).ensureType();
        encounters.push(encounter.clone());
    }
}

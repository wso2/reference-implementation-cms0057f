import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated uscore700:USCoreMedicationRequestProfile[] medicationRequests = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|uscore700:USCoreMedicationRequestProfile {
    uscore700:USCoreMedicationRequestProfile|error medicationRequest = parser:parse(payload, uscore700:USCoreMedicationRequestProfile).ensureType();

    if medicationRequest is error {
        return r4:createFHIRError(medicationRequest.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            medicationRequest.id = (createOperationNextId).toBalString();
        }

        lock {
            medicationRequests.push(medicationRequest.clone());
        }

        return medicationRequest;
    }
}

public isolated function getById(string id) returns r4:FHIRError|uscore700:USCoreMedicationRequestProfile {
    lock {
        foreach var item in medicationRequests {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a medicationRequest resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    uscore700:USCoreMedicationRequestProfile byId = check getById(searchParameters.get('key)[0]);
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

    lock {
        r4:BundleEntry[] bundleEntries = [];
        foreach var item in medicationRequests {
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

function init() returns error? {
    lock {
        json medicationRequestJson = {
            "resourceType": "MedicationRequest",
            "id": "12344",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-medicationrequest|7.0.0"]
            },
            "text": {
                "status": "extensions",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p><b>Generated Narrative: MedicationRequest</b><a name=\"medicationrequest-coded-oral-axid\"> </a><a name=\"hcmedicationrequest-coded-oral-axid\"> </a></p><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Resource MedicationRequest &quot;medicationrequest-coded-oral-axid&quot; </p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-us-core-medicationrequest.html\">US Core MedicationRequest Profile (version 7.0.0)</a></p></div><blockquote><p><b>US Core Medication Adherence Extension</b></p><blockquote><p><b>url</b></p><code>medicationAdherence</code></blockquote><p><b>value</b>: Drugs - partial non-compliance (finding) <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"https://browser.ihtsdotools.org/\">SNOMED CT</a>#275928001)</span></p><blockquote><p><b>url</b></p><code>dateAsserted</code></blockquote><p><b>value</b>: 2023-08-11 08:15:49+0000</p><blockquote><p><b>url</b></p><code>informationSource</code></blockquote><p><b>value</b>: Patient (person) <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"https://browser.ihtsdotools.org/\">SNOMED CT</a>#116154003)</span></p><blockquote><p><b>url</b></p><code>informationSource</code></blockquote><p><b>value</b>: Pharmacy <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"https://www.cdc.gov/nhsn/cdaportal/terminology/codesystem/hsloc.html\">Healthcare Service Location</a>#1179-1)</span></p></blockquote><p><b>status</b>: active</p><p><b>intent</b>: order</p><p><b>medication</b>: Nizatidine 15 MG/ML Oral Solution <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"http://terminology.hl7.org/5.3.0/CodeSystem-v3-rxNorm.html\">RxNorm</a>#476872)</span></p><p><b>subject</b>: <a href=\"Patient-example.html\">Patient/example: Amy Shaw</a> &quot; SHAW&quot;</p><p><b>authoredOn</b>: 2008-04-05</p><p><b>requester</b>: <a href=\"Practitioner-practitioner-1.html\">Practitioner/practitioner-1: Ronald Bone, MD</a> &quot; BONE&quot;</p><p><b>reasonCode</b>: Active Duodenal Ulcer <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"https://browser.ihtsdotools.org/\">SNOMED CT[US]</a>#51868009 &quot;Ulcer of duodenum (disorder)&quot;)</span></p><blockquote><p><b>dosageInstruction</b></p><p><b>text</b>: 10 mL bid</p><p><b>timing</b>: Starting 2008-04-05, 2 per 1 days</p><blockquote><p><b>doseAndRate</b></p></blockquote></blockquote><blockquote><p><b>dispenseRequest</b></p><p><b>numberOfRepeatsAllowed</b>: 1</p><p><b>quantity</b>: 480 mL<span style=\"background: LightGoldenRodYellow\"> (Details: UCUM code mL = 'mL')</span></p><h3>ExpectedSupplyDurations</h3><table class=\"grid\"><tr><td style=\"display: none\">-</td><td><b>Value</b></td><td><b>Unit</b></td><td><b>System</b></td><td><b>Code</b></td></tr><tr><td style=\"display: none\">*</td><td>30</td><td>days</td><td><a href=\"http://terminology.hl7.org/5.3.0/CodeSystem-v3-ucum.html\">Unified Code for Units of Measure (UCUM)</a></td><td>d</td></tr></table></blockquote></div>"
            },
            "extension": [
                {
                    "extension": [
                        {
                            "url": "medicationAdherence",
                            "valueCodeableConcept": {
                                "coding": [
                                    {
                                        "system": "http://snomed.info/sct",
                                        "code": "275928001",
                                        "display": "Drugs - partial non-compliance (finding)"
                                    }
                                ]
                            }
                        },
                        {
                            "url": "dateAsserted",
                            "valueDateTime": "2023-08-11T08:15:49.449Z"
                        },
                        {
                            "url": "informationSource",
                            "valueCodeableConcept": {
                                "coding": [
                                    {
                                        "system": "http://snomed.info/sct",
                                        "code": "116154003",
                                        "display": "Patient (person)"
                                    }
                                ]
                            }
                        },
                        {
                            "url": "informationSource",
                            "valueCodeableConcept": {
                                "coding": [
                                    {
                                        "system": "https://www.cdc.gov/nhsn/cdaportal/terminology/codesystem/hsloc.html",
                                        "code": "1179-1",
                                        "display": "Pharmacy"
                                    }
                                ]
                            }
                        }
                    ],
                    "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication-adherence"
                }
            ],
            "status": "active",
            "intent": "order",
            "medicationCodeableConcept": {
                "coding": [
                    {
                        "system": "http://www.nlm.nih.gov/research/umls/rxnorm",
                        "code": "476872",
                        "display": "Nizatidine 15 MG/ML Oral Solution"
                    }
                ],
                "text": "Nizatidine 15 MG/ML Oral Solution"
            },
            "subject": {
                "reference": "Patient/example",
                "display": "Amy Shaw"
            },
            "authoredOn": "2008-04-05",
            "requester": {
                "reference": "Practitioner/practitioner-1",
                "display": "Ronald Bone, MD"
            },
            "reasonCode": [
                {
                    "coding": [
                        {
                            "system": "http://snomed.info/sct",
                            "version": "http://snomed.info/sct/731000124108",
                            "code": "51868009",
                            "display": "Ulcer of duodenum (disorder)"
                        }
                    ],
                    "text": "Active Duodenal Ulcer"
                }
            ],
            "dosageInstruction": [
                {
                    "text": "10 mL bid",
                    "timing": {
                        "repeat": {
                            "boundsPeriod": {
                                "start": "2008-04-05"
                            },
                            "frequency": 2,
                            "period": 1,
                            "periodUnit": "d"
                        }
                    },
                    "doseAndRate": [
                        {
                            "doseQuantity": {
                                "value": 10,
                                "unit": "ml",
                                "system": "http://unitsofmeasure.org",
                                "code": "mL"
                            }
                        }
                    ]
                }
            ],
            "dispenseRequest": {
                "numberOfRepeatsAllowed": 1,
                "quantity": {
                    "value": 480,
                    "unit": "mL",
                    "system": "http://unitsofmeasure.org",
                    "code": "mL"
                },
                "expectedSupplyDuration": {
                    "value": 30,
                    "unit": "days",
                    "system": "http://unitsofmeasure.org",
                    "code": "d"
                }
            },
            "medicationReference": {
                "reference": "Medication/example",
                "display": "Nizatidine 15 MG/ML Oral Solution"
            }
        };
        uscore700:USCoreMedicationRequestProfile medicationRequest = check parser:parse(medicationRequestJson, uscore700:USCoreMedicationRequestProfile).ensureType();
        medicationRequests.push(medicationRequest.clone());
    }
}

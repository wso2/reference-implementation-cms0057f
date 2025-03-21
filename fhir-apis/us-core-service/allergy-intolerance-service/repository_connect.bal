import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated uscore700:USCoreAllergyIntolerance[] allergyIntolerances = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|uscore700:USCoreAllergyIntolerance {
    uscore700:USCoreAllergyIntolerance|error allergyIntolerance = parser:parseWithValidation(payload, uscore700:USCoreAllergyIntolerance).ensureType();

    if allergyIntolerance is error {
        return r4:createFHIRError(allergyIntolerance.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            allergyIntolerance.id = (createOperationNextId).toBalString();
        }

        lock {
            allergyIntolerances.push(allergyIntolerance.clone());
        }

        return allergyIntolerance;
    }
}

public isolated function getById(string id) returns r4:FHIRError|uscore700:USCoreAllergyIntolerance {
    lock {
        foreach var item in allergyIntolerances {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find an AllergyIntolerance resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    uscore700:USCoreAllergyIntolerance byId = check getById(searchParameters.get('key)[0]);
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
        foreach var item in allergyIntolerances {
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
        json allergyIntoleranceJson = {
            "resourceType": "AllergyIntolerance",
            "id": "12344",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-allergyintolerance|7.0.0"]
            },
            "text": {
                "status": "generated",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p><b>Generated Narrative: AllergyIntolerance</b><a name=\"example\"> </a><a name=\"hcexample\"> </a></p><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Resource AllergyIntolerance &quot;example&quot; </p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-us-core-allergyintolerance.html\">US Core AllergyIntolerance Profile (version 7.0.0)</a></p></div><p><b>clinicalStatus</b>: Active <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"http://terminology.hl7.org/5.5.0/CodeSystem-allergyintolerance-clinical.html\">AllergyIntolerance Clinical Status Codes</a>#active)</span></p><p><b>verificationStatus</b>: Confirmed <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"http://terminology.hl7.org/5.5.0/CodeSystem-allergyintolerance-verification.html\">AllergyIntolerance Verification Status</a>#confirmed)</span></p><p><b>category</b>: medication</p><p><b>criticality</b>: high</p><p><b>code</b>: sulfonamide antibacterial <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"https://browser.ihtsdotools.org/\">SNOMED CT[US]</a>#763875007 &quot;Product containing sulfonamide (product)&quot;)</span></p><p><b>patient</b>: <a href=\"Patient-example.html\">Patient/example: Amy V. Shaw</a> &quot; SHAW&quot;</p><h3>Reactions</h3><table class=\"grid\"><tr><td style=\"display: none\">-</td><td><b>Manifestation</b></td><td><b>Severity</b></td></tr><tr><td style=\"display: none\">*</td><td>skin rash <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"https://browser.ihtsdotools.org/\">SNOMED CT[US]</a>#271807003)</span></td><td>mild</td></tr></table></div>"
            },
            "clinicalStatus": {
                "coding": [
                    {
                        "system": "http://terminology.hl7.org/CodeSystem/allergyintolerance-clinical",
                        "code": "active"
                    }
                ]
            },
            "verificationStatus": {
                "coding": [
                    {
                        "system": "http://terminology.hl7.org/CodeSystem/allergyintolerance-verification",
                        "code": "confirmed"
                    }
                ]
            },
            "category": ["medication"],
            "criticality": "high",
            "code": {
                "coding": [
                    {
                        "system": "http://snomed.info/sct",
                        "version": "http://snomed.info/sct/731000124108",
                        "code": "763875007",
                        "display": "Product containing sulfonamide (product)"
                    }
                ],
                "text": "sulfonamide antibacterial"
            },
            "patient": {
                "reference": "Patient/example",
                "display": "Amy V. Shaw"
            },
            "reaction": [
                {
                    "manifestation": [
                        {
                            "coding": [
                                {
                                    "system": "http://snomed.info/sct",
                                    "version": "http://snomed.info/sct/731000124108",
                                    "code": "271807003",
                                    "display": "skin rash"
                                }
                            ],
                            "text": "skin rash"
                        }
                    ],
                    "severity": "mild"
                }
            ]
        };
        uscore700:USCoreAllergyIntolerance allergyIntolerance = check parser:parse(allergyIntoleranceJson, uscore700:USCoreAllergyIntolerance).ensureType();
        allergyIntolerances.push(allergyIntolerance.clone());
    }
}

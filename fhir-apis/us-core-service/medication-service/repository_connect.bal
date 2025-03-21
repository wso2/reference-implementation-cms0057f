import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated uscore700:USCoreMedicationProfile[] medications = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|uscore700:USCoreMedicationProfile {
    uscore700:USCoreMedicationProfile|error medication = parser:parse(payload, uscore700:USCoreMedicationProfile).ensureType();

    if medication is error {
        return r4:createFHIRError(medication.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            medication.id = (createOperationNextId).toBalString();
        }

        lock {
            medications.push(medication.clone());
        }

        return medication;
    }
}

public isolated function getById(string id) returns r4:FHIRError|uscore700:USCoreMedicationProfile {
    lock {
        foreach var item in medications {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a medication resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    uscore700:USCoreMedicationProfile byId = check getById(searchParameters.get('key)[0]);
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
        foreach var item in medications {
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
        json medicationJson = {
            "resourceType": "Medication",
            "id": "12344",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication|7.0.0"]
            },
            "text": {
                "status": "generated",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p><b>Generated Narrative: Medication</b><a name=\"uscore-med1\"> </a><a name=\"hcuscore-med1\"> </a></p><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Resource Medication &quot;uscore-med1&quot; </p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-us-core-medication.html\">US Core Medication Profile (version 7.0.0)</a></p></div><p><b>code</b>: lisinopril oral 10 mg <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"http://terminology.hl7.org/5.3.0/CodeSystem-v3-rxNorm.html\">RxNorm</a>#206765 &quot;Prinivil 10 MG Oral Tablet&quot;)</span></p></div>"
            },
            "code": {
                "coding": [
                    {
                        "system": "http://www.nlm.nih.gov/research/umls/rxnorm",
                        "code": "206765",
                        "display": "Prinivil 10 MG Oral Tablet"
                    }
                ],
                "text": "lisinopril oral 10 mg"
            }
        };
        uscore700:USCoreMedicationProfile medication = check parser:parse(medicationJson, uscore700:USCoreMedicationProfile).ensureType();
        medications.push(medication.clone());
    }
}

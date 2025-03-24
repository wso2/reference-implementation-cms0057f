import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.carinbb200;
import ballerinax/health.fhir.r4.parser;

isolated carinbb200:C4BBRelatedPerson[] relatedPersons = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|carinbb200:C4BBRelatedPerson {
    carinbb200:C4BBRelatedPerson|error relatedPerson = parser:parseWithValidation(payload, carinbb200:C4BBRelatedPerson).ensureType();

    if relatedPerson is error {
        return r4:createFHIRError(relatedPerson.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            relatedPerson.id = (createOperationNextId).toBalString();
        }

        lock {
            relatedPersons.push(relatedPerson.clone());
        }

        return relatedPerson;
    }
}

public isolated function getById(string id) returns r4:FHIRError|carinbb200:C4BBRelatedPerson {
    lock {
        foreach var item in relatedPersons {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a Patient resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    carinbb200:C4BBRelatedPerson byId = check getById(searchParameters.get('key)[0]);
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
        foreach var item in relatedPersons {
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
        json relatedPersonJson = {
            "resourceType": "RelatedPerson",
            "id": "12344",
            "meta": {
                "lastUpdated": "2020-05-04T03:02:01-04:00",
                "profile": ["http://hl7.org/fhir/us/carin-bb/StructureDefinition/C4BB-RelatedPerson"]
            },
            "text": {
                "status": "generated",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p class=\"res-header-id\"><b>Generated Narrative: RelatedPerson RelatedPerson1</b></p><a name=\"RelatedPerson1\"> </a><a name=\"hcRelatedPerson1\"> </a><a name=\"RelatedPerson1-en-US\"> </a><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Last updated: 2020-05-04 03:02:01-0400</p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-C4BB-RelatedPerson.html\">C4BB RelatedPersonversion: null2.1.0)</a></p></div><p><b>active</b>: true</p><p><b>patient</b>: <a href=\"Patient-Patient1.html\">Johnny Example1  Male, DoB: 1986-01-01 ( Member Number)</a></p><p><b>relationship</b>: <span title=\"Codes:{http://terminology.hl7.org/CodeSystem/v3-RoleCode MTH}\">mother</span></p><p><b>name</b>: Mary Example1 </p><p><b>telecom</b>: ph: (301)666-1212</p><p><b>address</b>: 123 Main Street Pittsburgh PA 12519 </p></div>"
            },
            "active": true,
            "patient": {
                "reference": "Patient/Patient1"
            },
            "relationship": [
                {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/v3-RoleCode",
                            "code": "MTH"
                        }
                    ]
                }
            ],
            "name": [
                {
                    "family": "Example1",
                    "given": ["Mary"]
                }
            ],
            "telecom": [
                {
                    "system": "phone",
                    "value": "(301)666-1212",
                    "rank": 2
                }
            ],
            "address": [
                {
                    "type": "physical",
                    "line": ["123 Main Street"],
                    "city": "Pittsburgh",
                    "state": "PA",
                    "postalCode": "12519"
                }
            ]
        };
        carinbb200:C4BBRelatedPerson relatedPerson = check parser:parse(relatedPersonJson, carinbb200:C4BBRelatedPerson).ensureType();
        relatedPersons.push(relatedPerson.clone());
    }
}

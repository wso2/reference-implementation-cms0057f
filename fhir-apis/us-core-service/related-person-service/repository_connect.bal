import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated uscore700:USCoreRelatedPersonProfile[] relatedPersons = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|uscore700:USCoreRelatedPersonProfile {
    uscore700:USCoreRelatedPersonProfile|error relatedPerson = parser:parse(payload, uscore700:USCoreRelatedPersonProfile).ensureType();

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

public isolated function getById(string id) returns r4:FHIRError|uscore700:USCoreRelatedPersonProfile {
    lock {
        foreach var item in relatedPersons {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a relatedPerson resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    uscore700:USCoreRelatedPersonProfile byId = check getById(searchParameters.get('key)[0]);
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
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-relatedperson|7.0.0"]
            },
            "text": {
                "status": "generated",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p><b>Generated Narrative: RelatedPerson</b><a name=\"shaw-niece\"> </a><a name=\"hcshaw-niece\"> </a></p><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Resource RelatedPerson &quot;shaw-niece&quot; </p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-us-core-relatedperson.html\">US Core RelatedPerson Profile (version 7.0.0)</a></p></div><p><b>active</b>: true</p><p><b>patient</b>: <a href=\"Patient-example.html\">Patient/example: Amy V. Shaw</a> &quot; SHAW&quot;</p><p><b>relationship</b>: niece <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"http://terminology.hl7.org/5.5.0/CodeSystem-v3-RoleCode.html\">RoleCode</a>#NIECE)</span></p><p><b>name</b>: Sarah van Putten (Official)</p><p><b>telecom</b>: ph: 555-555-5555(HOME), <a href=\"mailto:sarah.vanputten@example.com\">sarah.vanputten@example.com</a></p><p><b>birthDate</b>: 1996-01-28</p><p><b>address</b>: 80A VILLAGE ST NEW HOLLAND PA 17557 (home)</p></div>"
            },
            "active": true,
            "patient": {
                "reference": "Patient/example",
                "display": "Amy V. Shaw"
            },
            "relationship": [
                {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/v3-RoleCode",
                            "code": "NIECE",
                            "display": "niece"
                        }
                    ]
                }
            ],
            "name": [
                {
                    "use": "official",
                    "family": "van Putten",
                    "given": ["Sarah"]
                }
            ],
            "telecom": [
                {
                    "system": "phone",
                    "value": "555-555-5555",
                    "use": "home"
                },
                {
                    "system": "email",
                    "value": "sarah.vanputten@example.com",
                    "use": "home"
                }
            ],
            "birthDate": "1996-01-28",
            "address": [
                {
                    "use": "home",
                    "line": ["80A VILLAGE ST"],
                    "city": "NEW HOLLAND",
                    "state": "PA",
                    "postalCode": "17557"
                }
            ]
        };
        uscore700:USCoreRelatedPersonProfile relatedPerson = check parser:parse(relatedPersonJson, uscore700:USCoreRelatedPersonProfile).ensureType();
        relatedPersons.push(relatedPerson.clone());
    }
}

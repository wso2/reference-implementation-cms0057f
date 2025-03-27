import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.carinbb200;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated RelatedPerson[] relatedPersons = [];
isolated int createOperationNextId = 12345;

// Use US Core RelatedPerson profile is the default profile
final string DEFAULT_PROFILE = "http://hl7.org/fhir/us/core/StructureDefinition/us-core-relatedperson";

public isolated function create(json payload) returns r4:FHIRError|RelatedPerson {
    RelatedPerson|error relatedPerson = parser:parse(payload, carinbb200:C4BBRelatedPerson).ensureType();

    if relatedPerson is error {
        relatedPerson = parser:parse(payload, uscore700:USCoreRelatedPersonProfile).ensureType();
    }

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

public isolated function getById(string id, RelatedPerson[]? targetRelatedPersonArr = ()) returns r4:FHIRError|RelatedPerson {
    RelatedPerson[] relatedPersonArr;
    if targetRelatedPersonArr is RelatedPerson[] {
        relatedPersonArr = targetRelatedPersonArr;
    } else {
        lock {
            relatedPersonArr = relatedPersons.clone();
        }
    }

    lock {
        foreach var item in relatedPersonArr {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a relatedPerson resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

isolated function getByProfile(string profile) returns r4:FHIRError|RelatedPerson[] {
    lock {
        RelatedPerson[] items = [];
        
        foreach var item in relatedPersons {
            r4:Meta? itemMeta = item.meta;

            if itemMeta is r4:Meta {
                r4:canonical[]? profileArray = itemMeta.profile;

                if profileArray is r4:canonical[] {
                    string profileValue = profileArray[0].toString();

                    if profileValue == profile {
                        items.push(item.clone());
                    }
                }
            }
        }

        return items.length() > 0 ? items.clone() : r4:createFHIRError(string `Cannot find a relatedPerson resource with profile: ${profile}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
    }
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:Bundle|error {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        string? id = ();
        string? profile = ();

        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    id = searchParameters.get('key)[0];
                }
                "_profile" => {
                    profile = searchParameters.get('key)[0];
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

        RelatedPerson[] byProfile = check getByProfile(profile is string ? profile : DEFAULT_PROFILE);

        if id is string {
            RelatedPerson byId = check getById(id, byProfile);

            bundle.entry = [
                {
                    'resource: byId
                }
            ];
        } else {
            // default to search by profile
            r4:BundleEntry[] bundleEntries = [];
            foreach var item in byProfile {
                bundleEntries.push({
                    'resource: item
                });
            }
            bundle.entry = bundleEntries;
            bundle.total = byProfile.length();
        }

        return bundle;
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
        json uSCoreRelatedPersonProfileJson = {
            "resourceType": "RelatedPerson",
            "id": "12344",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-relatedperson"]
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

        json c4BBRelatedPersonjSON = {
            "resourceType": "RelatedPerson",
            "id": "12345",
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

        relatedPersons.push(<RelatedPerson>check parser:parse(uSCoreRelatedPersonProfileJson, uscore700:USCoreRelatedPersonProfile).ensureType());
        relatedPersons.push(<RelatedPerson>check parser:parse(c4BBRelatedPersonjSON, carinbb200:C4BBRelatedPerson).ensureType());
    }
}

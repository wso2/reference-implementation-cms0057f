import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated uscore700:USCorePractitionerProfile[] practitioners = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|uscore700:USCorePractitionerProfile {
    uscore700:USCorePractitionerProfile|error practitioner = parser:parse(payload, uscore700:USCorePractitionerProfile).ensureType();

    if practitioner is error {
        return r4:createFHIRError(practitioner.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            practitioner.id = (createOperationNextId).toBalString();
        }

        lock {
            practitioners.push(practitioner.clone());
        }

        return practitioner;
    }
}

public isolated function getById(string id) returns r4:FHIRError|uscore700:USCorePractitionerProfile {
    lock {
        foreach var item in practitioners {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a practitioner resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    uscore700:USCorePractitionerProfile byId = check getById(searchParameters.get('key)[0]);
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
        foreach var item in practitioners {
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
        json practitionerJson = {
            "resourceType": "Practitioner",
            "id": "12344",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner|7.0.0"]
            },
            "text": {
                "status": "generated",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p><b>Generated Narrative: Practitioner</b><a name=\"practitioner-1\"> </a><a name=\"hcpractitioner-1\"> </a></p><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Resource Practitioner &quot;practitioner-1&quot; </p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-us-core-practitioner.html\">US Core Practitioner Profile (version 7.0.0)</a></p></div><p><b>identifier</b>: <a href=\"http://terminology.hl7.org/5.3.0/NamingSystem-npi.html\" title=\"National Provider Identifier\">United States National Provider Identifier</a>/9941339100, <code>http://www.acme.org/practitioners</code>/25456</p><p><b>name</b>: Ronald Bone </p><p><b>address</b>: 1003 HEALTHCARE DR AMHERST MA 01002 (work)</p></div>"
            },
            "identifier": [
                {
                    "system": "http://hl7.org/fhir/sid/us-npi",
                    "value": "9941339100"
                },
                {
                    "extension": [
                        {
                            "url": "http://hl7.org/fhir/us/core/StructureDefinition/us-core-jurisdiction",
                            "valueCodeableConcept": {
                                "coding": [
                                    {
                                        "system": "https://www.usps.com/",
                                        "code": "MA"
                                    }
                                ],
                                "text": "Massachusetts"
                            }
                        }
                    ],
                    "system": "http://www.acme.org/practitioners",
                    "value": "25456"
                }
            ],
            "name": [
                {
                    "family": "Bone",
                    "given": ["Ronald"],
                    "prefix": ["Dr"]
                }
            ],
            "address": [
                {
                    "use": "work",
                    "line": ["1003 HEALTHCARE DR"],
                    "city": "AMHERST",
                    "state": "MA",
                    "postalCode": "01002"
                }
            ]
        };
        uscore700:USCorePractitionerProfile practitioner = check parser:parse(practitionerJson, uscore700:USCorePractitionerProfile).ensureType();
        practitioners.push(practitioner.clone());
    }
}

import ballerina/http;
import ballerinax/health.fhir.r4 as r4;
import ballerinax/health.fhir.r4.davinciplannet120;
import ballerinax/health.fhir.r4.parser;

isolated davinciplannet120:PlannetNetwork[] organization = [];
isolated int createendpointNextId = 9000;

public isolated function create(json payload) returns r4:FHIRError|davinciplannet120:PlannetNetwork {
    davinciplannet120:PlannetNetwork|error endpoint = parser:parse(payload).ensureType();
    if endpoint is error {
        return r4:createFHIRError(endpoint.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createendpointNextId += 1;
            endpoint.id = (createendpointNextId).toBalString();
        }
        lock {
            organization.push(endpoint.clone());
        }
        return endpoint;
    }
}

public isolated function getById(string id) returns r4:FHIRError|davinciplannet120:PlannetNetwork {
    lock {
        foreach var item in organization {
            if item.id == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find an endpoint resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };
    if (searchParameters is map<string[]>) {
        foreach var key in searchParameters.keys() {
            match key {
                "_id" => {
                    davinciplannet120:PlannetNetwork byId = check getById(searchParameters.get(key)[0]);
                    bundle.entry = [
                        {
                            'resource: byId
                        }
                    ];
                    return bundle;
                }
                _ => {
                    return r4:createFHIRError(string `Not supported search parameter: ${key}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
                }
            }
        }
    }
    lock {
        r4:BundleEntry[] bundleEntries = [];
        foreach var item in organization {
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
        json eocJson = {
            "resourceType": "Organization",
            "id": "9000",
            "meta": {
                "lastUpdated": "2020-07-07T13:26:22.0314215+00:00",
                "profile": ["http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Network"]
            },
            "language": "en-US",
            "text": {
                "status": "extensions",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en-US\" lang=\"en-US\"><p class=\"res-header-id\"><b>Generated Narrative: Organization AcmeofCTPremNet</b></p><a name=\"AcmeofCTPremNet\"> </a><a name=\"hcAcmeofCTPremNet\"> </a><a name=\"AcmeofCTPremNet-en-US\"> </a><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Last updated: 2020-07-07 13:26:22+0000; Language: en-US</p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-plannet-Network.html\">Plan-Net Network</a></p></div><p><b>Location Reference</b>: <a href=\"Location-StateOfCTLocation.html\">Location State of CT Area</a></p><p><b>active</b>: true</p><p><b>type</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/OrgTypeCS ntwk}\">Network</span></p><p><b>name</b>: ACME CT Premium Preferred Provider Network</p><p><b>partOf</b>: <a href=\"Organization-Acme.html\">Organization Acme of CT</a></p><h3>Contacts</h3><table class=\"grid\"><tr><td style=\"display: none\">-</td><td><b>Name</b></td><td><b>Telecom</b></td></tr><tr><td style=\"display: none\">*</td><td>Jane Kawasaki </td><td>-unknown-</td></tr></table></div>"
            },
            "extension": [
                {
                    "url": "http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/location-reference",
                    "valueReference": {
                        "reference": "Location/StateOfCTLocation"
                    }
                }
            ],
            "active": true,
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/OrgTypeCS",
                            "code": "ntwk",
                            "display": "Network"
                        }
                    ]
                }
            ],
            "name": "ACME CT Premium Preferred Provider Network",
            "partOf": {
                "reference": "Organization/Acme"
            },
            "contact": [
                {
                    "name": {
                        "family": "Kawasaki",
                        "given": ["Jane"]
                    },
                    "telecom": [
                        {
                            "extension": [
                                {
                                    "url": "http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/via-intermediary",
                                    "valueReference": {
                                        "reference": "Organization/Acme"
                                    }
                                }
                            ]
                        }
                    ]
                }
            ]
        };

        davinciplannet120:PlannetNetwork endpoint = check parser:parse(eocJson).ensureType();
        organization.push(endpoint.clone());
    }
}

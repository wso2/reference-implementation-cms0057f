import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated uscore700:USCoreLocationProfile[] locations = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|uscore700:USCoreLocationProfile {
    uscore700:USCoreLocationProfile|error location = parser:parse(payload, uscore700:USCoreLocationProfile).ensureType();

    if location is error {
        return r4:createFHIRError(location.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            location.id = (createOperationNextId).toBalString();
        }

        lock {
            locations.push(location.clone());
        }

        return location;
    }
}

public isolated function getById(string id) returns r4:FHIRError|uscore700:USCoreLocationProfile {
    lock {
        foreach var item in locations {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a location resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    uscore700:USCoreLocationProfile byId = check getById(searchParameters.get('key)[0]);
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
        foreach var item in locations {
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
        json locationJson = {
            "resourceType": "Location",
            "id": "12344",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-location|7.0.0"]
            },
            "text": {
                "status": "generated",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p><b>Generated Narrative: Location</b><a name=\"hl7east\"> </a><a name=\"hchl7east\"> </a></p><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Resource Location &quot;hl7east&quot; </p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-us-core-location.html\">US Core Location Profile (version 7.0.0)</a></p></div><p><b>identifier</b>: <code>http://www.acme.org/location</code>/29</p><p><b>status</b>: active</p><p><b>name</b>: Health Level Seven International - Amherst</p><p><b>description</b>: HL7 Headquarters - East</p><p><b>type</b>: Administrative Office <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"http://terminology.hl7.org/5.5.0/CodeSystem-v3-RoleCode.html\">RoleCode</a>#_DedicatedNonClinicalLocationRoleType &quot;DedicatedNonClinicalLocationRoleType&quot;)</span></p><p><b>telecom</b>: ph: (+1) 734-677-7777</p><p><b>address</b>: 3300 WASHTENAW AVE STE 227 AMHERST MA 01002 USA </p><h3>Positions</h3><table class=\"grid\"><tr><td style=\"display: none\">-</td><td><b>Longitude</b></td><td><b>Latitude</b></td></tr><tr><td style=\"display: none\">*</td><td>-72.519854</td><td>42.373222</td></tr></table><p><b>managingOrganization</b>: <span>: Health Level Seven International</span></p></div>"
            },
            "identifier": [
                {
                    "system": "http://www.acme.org/location",
                    "value": "29"
                }
            ],
            "status": "active",
            "name": "Health Level Seven International - Amherst",
            "description": "HL7 Headquarters - East",
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/v3-RoleCode",
                            "code": "_DedicatedNonClinicalLocationRoleType",
                            "display": "DedicatedNonClinicalLocationRoleType"
                        }
                    ],
                    "text": "Administrative Office"
                }
            ],
            "telecom": [
                {
                    "system": "phone",
                    "value": "(+1) 734-677-7777"
                }
            ],
            "address": {
                "line": ["3300 WASHTENAW AVE STE 227"],
                "city": "AMHERST",
                "state": "MA",
                "postalCode": "01002",
                "country": "USA"
            },
            "position": {
                "longitude": -72.519854,
                "latitude": 42.373222
            },
            "managingOrganization": {
                "display": "Health Level Seven International"
            }
        };
        uscore700:USCoreLocationProfile location = check parser:parse(locationJson, uscore700:USCoreLocationProfile).ensureType();
        locations.push(location.clone());
    }
}

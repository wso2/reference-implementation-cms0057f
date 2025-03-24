import ballerina/http;
import ballerinax/health.fhir.r4 as r4;
import ballerinax/health.fhir.r4.davinciplannet120;
import ballerinax/health.fhir.r4.parser;

isolated davinciplannet120:PlannetLocation[] locations = [];
isolated int createlocationNextId = 9000;

public isolated function create(json payload) returns r4:FHIRError|davinciplannet120:PlannetLocation {
    davinciplannet120:PlannetLocation|error location = parser:parse(payload).ensureType();
    if location is error {
        return r4:createFHIRError(location.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createlocationNextId += 1;
            location.id = (createlocationNextId).toBalString();
        }
        lock {
            locations.push(location.clone());
        }
        return location;
    }
}

public isolated function getById(string id) returns r4:FHIRError|davinciplannet120:PlannetLocation {
    lock {
        foreach var item in locations {
            if item.id == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find an location resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };
    if (searchParameters is map<string[]>) {
        foreach var key in searchParameters.keys() {
            match key {
                "_id" => {
                    davinciplannet120:PlannetLocation byId = check getById(searchParameters.get(key)[0]);
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
        json eocJson = {
            "resourceType": "Location",
            "id": "9000",
            "meta": {
                "lastUpdated": "2020-07-07T13:26:22.0314215+00:00",
                "profile": ["http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Location"]
            },
            "language": "en-US",
            "text": {
                "status": "extensions",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en-US\" lang=\"en-US\"><p class=\"res-header-id\"><b>Generated Narrative: Location CancerClinicLoc</b></p><a name=\"CancerClinicLoc\"> </a><a name=\"hcCancerClinicLoc\"> </a><a name=\"CancerClinicLoc-en-US\"> </a><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Last updated: 2020-07-07 13:26:22+0000; Language: en-US</p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-plannet-Location.html\">Plan-Net Location</a></p></div><p><b>Accessibility</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/AccessibilityCS adacomp}\">ADA compliant</span></p><p><b>Accessibility</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/AccessibilityCS pubtrans}\">public transit options</span></p><p><b>status</b>: Active</p><p><b>name</b>: Cancer Clinic</p><p><b>type</b>: <span title=\"Codes:{http://terminology.hl7.org/CodeSystem/v3-RoleCode HOSP}\">Hospital</span></p><p><b>telecom</b>: ph: (111)-222-3333, <a href=\"https://www.hgh.com\">https://www.hgh.com</a></p><p><b>address</b>: 456 Main Street Anytown CT 00014-1234 </p><h3>Positions</h3><table class=\"grid\"><tr><td style=\"display: none\">-</td><td><b>Longitude</b></td><td><b>Latitude</b></td></tr><tr><td style=\"display: none\">*</td><td>3</td><td>15</td></tr></table><p><b>managingOrganization</b>: <a href=\"Organization-CancerClinic.html\">Organization Hamilton Clinic</a></p><blockquote><p><b>hoursOfOperation</b></p><p><b>daysOfWeek</b>: Monday, Tuesday, Wednesday, Thursday, Friday</p></blockquote></div>"
            },
            "extension": [
                {
                    "url": "http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/accessibility",
                    "valueCodeableConcept": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/AccessibilityCS",
                                "code": "adacomp"
                            }
                        ]
                    }
                },
                {
                    "url": "http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/accessibility",
                    "valueCodeableConcept": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/AccessibilityCS",
                                "code": "pubtrans"
                            }
                        ]
                    }
                }
            ],
            "status": "active",
            "name": "Cancer Clinic",
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/v3-RoleCode",
                            "code": "HOSP"
                        }
                    ]
                }
            ],
            "telecom": [
                {
                    "extension": [
                        {
                            "extension": [
                                {
                                    "url": "daysOfWeek",
                                    "valueCode": "mon"
                                },
                                {
                                    "url": "daysOfWeek",
                                    "valueCode": "tue"
                                },
                                {
                                    "url": "daysOfWeek",
                                    "valueCode": "wed"
                                },
                                {
                                    "url": "daysOfWeek",
                                    "valueCode": "thu"
                                },
                                {
                                    "url": "daysOfWeek",
                                    "valueCode": "fri"
                                },
                                {
                                    "url": "allDay",
                                    "valueBoolean": true
                                }
                            ],
                            "url": "http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/contactpoint-availabletime"
                        }
                    ],
                    "system": "phone",
                    "value": "(111)-222-3333",
                    "rank": 2
                },
                {
                    "system": "url",
                    "value": "https://www.hgh.com",
                    "rank": 1
                }
            ],
            "address": {
                "line": ["456 Main Street"],
                "city": "Anytown",
                "state": "CT",
                "postalCode": "00014-1234"
            },
            "position": {
                "longitude": 3,
                "latitude": 15
            },
            "managingOrganization": {
                "reference": "Organization/CancerClinic"
            },
            "hoursOfOperation": [
                {
                    "daysOfWeek": [
                        "mon",
                        "tue",
                        "wed",
                        "thu",
                        "fri"
                    ]
                }
            ]
        };

        davinciplannet120:PlannetLocation location = check parser:parse(eocJson).ensureType();
        locations.push(location.clone());
    }
}

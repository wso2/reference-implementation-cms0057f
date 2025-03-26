import ballerina/http;
import ballerinax/health.fhir.r4 as r4;
import ballerinax/health.fhir.r4.davinciplannet120;
import ballerinax/health.fhir.r4.parser;

isolated davinciplannet120:PlannetInsurancePlan[] insurancePlans = [];
isolated int createinsurancePlanNextId = 9000;

public isolated function create(json payload) returns r4:FHIRError|davinciplannet120:PlannetInsurancePlan {
    davinciplannet120:PlannetInsurancePlan|error insurancePlan = parser:parse(payload).ensureType();
    if insurancePlan is error {
        return r4:createFHIRError(insurancePlan.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createinsurancePlanNextId += 1;
            insurancePlan.id = (createinsurancePlanNextId).toBalString();
        }
        lock {
            insurancePlans.push(insurancePlan.clone());
        }
        return insurancePlan;
    }
}

public isolated function getById(string id) returns r4:FHIRError|davinciplannet120:PlannetInsurancePlan {
    lock {
        foreach var item in insurancePlans {
            if item.id == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find an insurancePlan resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };
    if (searchParameters is map<string[]>) {
        foreach var key in searchParameters.keys() {
            match key {
                "_id" => {
                    davinciplannet120:PlannetInsurancePlan byId = check getById(searchParameters.get(key)[0]);
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
        foreach var item in insurancePlans {
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
            "resourceType": "InsurancePlan",
            "id": "9000",
            "meta": {
                "lastUpdated": "2020-07-07T13:26:22.0314215+00:00",
                "profile": ["http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-InsurancePlan"]
            },
            "language": "en-US",
            "text": {
                "status": "generated",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en-US\" lang=\"en-US\"><p class=\"res-header-id\"><b>Generated Narrative: InsurancePlan AcmeQHPBronze</b></p><a name=\"AcmeQHPBronze\"> </a><a name=\"hcAcmeQHPBronze\"> </a><a name=\"AcmeQHPBronze-en-US\"> </a><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Last updated: 2020-07-07 13:26:22+0000; Language: en-US</p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-plannet-InsurancePlan.html\">Plan-Net InsurancePlan</a></p></div><p><b>status</b>: Active</p><p><b>type</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/InsuranceProductTypeCS qhp}\">Qualified Health Plan</span></p><p><b>name</b>: Acme of CT QHP Bronze</p><p><b>ownedBy</b>: <a href=\"Organization-Acme.html\">Organization Acme of CT</a></p><p><b>administeredBy</b>: <a href=\"Organization-Acme.html\">Organization Acme of CT</a></p><p><b>coverageArea</b>: <a href=\"Location-StateOfCTLocation.html\">Location State of CT Area</a></p><p><b>endpoint</b>: <a href=\"Endpoint-AcmeOfCTPortalEndpoint.html\">Endpoint Endpoint for Acme of CT Portal</a></p><p><b>network</b>: <a href=\"Organization-AcmeofCTStdNet.html\">Organization ACME CT Preferred Provider Network</a></p><h3>Plans</h3><table class=\"grid\"><tr><td style=\"display: none\">-</td><td><b>Type</b></td></tr><tr><td style=\"display: none\">*</td><td><span title=\"Codes:{http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/InsurancePlanTypeCS bronze}\">Bronze-QHP</span></td></tr></table></div>"
            },
            "status": "active",
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/InsuranceProductTypeCS",
                            "code": "qhp",
                            "display": "Qualified Health Plan"
                        }
                    ]
                }
            ],
            "name": "Acme of CT QHP Bronze",
            "ownedBy": {
                "reference": "Organization/Acme"
            },
            "administeredBy": {
                "reference": "Organization/Acme"
            },
            "coverageArea": [
                {
                    "reference": "Location/StateOfCTLocation"
                }
            ],
            "endpoint": [
                {
                    "reference": "Endpoint/AcmeOfCTPortalEndpoint"
                }
            ],
            "network": [
                {
                    "reference": "Organization/AcmeofCTStdNet"
                }
            ],
            "plan": [
                {
                    "type": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/InsurancePlanTypeCS",
                                "code": "bronze",
                                "display": "Bronze-QHP"
                            }
                        ]
                    }
                }
            ]
        };

        davinciplannet120:PlannetInsurancePlan insurancePlan = check parser:parse(eocJson).ensureType();
        insurancePlans.push(insurancePlan.clone());
    }
}

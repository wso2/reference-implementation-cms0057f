import ballerina/http;
import ballerinax/health.fhir.r4 as r4;
import ballerinax/health.fhir.r4.davinciplannet120;
import ballerinax/health.fhir.r4.parser;

isolated davinciplannet120:PlannetOrganizationAffiliation[] organizationAffiliation = [];
isolated int createendpointNextId = 9000;

public isolated function create(json payload) returns r4:FHIRError|davinciplannet120:PlannetOrganizationAffiliation {
    davinciplannet120:PlannetOrganizationAffiliation|error endpoint = parser:parse(payload).ensureType();
    if endpoint is error {
        return r4:createFHIRError(endpoint.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createendpointNextId += 1;
            endpoint.id = (createendpointNextId).toBalString();
        }
        lock {
            organizationAffiliation.push(endpoint.clone());
        }
        return endpoint;
    }
}

public isolated function getById(string id) returns r4:FHIRError|davinciplannet120:PlannetOrganizationAffiliation {
    lock {
        foreach var item in organizationAffiliation {
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
                    davinciplannet120:PlannetOrganizationAffiliation byId = check getById(searchParameters.get(key)[0]);
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
        foreach var item in organizationAffiliation {
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
            "resourceType": "OrganizationAffiliation",
            "id": "9000",
            "meta": {
                "lastUpdated": "2020-07-07T13:26:22.0314215+00:00",
                "profile": ["http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-OrganizationAffiliation"]
            },
            "language": "en-US",
            "text": {
                "status": "generated",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en-US\" lang=\"en-US\"><p class=\"res-header-id\"><b>Generated Narrative: OrganizationAffiliation BurrClinicAffil</b></p><a name=\"BurrClinicAffil\"> </a><a name=\"hcBurrClinicAffil\"> </a><a name=\"BurrClinicAffil-en-US\"> </a><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Last updated: 2020-07-07 13:26:22+0000; Language: en-US</p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-plannet-OrganizationAffiliation.html\">Plan-Net OrganizationAffiliation</a></p></div><p><b>active</b>: true</p><p><b>organization</b>: <a href=\"Organization-Hospital.html\">Organization Hartford General Hospital</a></p><p><b>participatingOrganization</b>: <a href=\"Organization-BurrClinic.html\">Organization Burr Clinic</a></p><p><b>network</b>: <a href=\"Organization-AcmeofCTStdNet.html\">Organization ACME CT Preferred Provider Network</a></p><p><b>code</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/OrganizationAffiliationRoleCS outpatient}\">Clinic or Outpatient Facility</span></p><p><b>location</b>: <a href=\"Location-HospLoc2.html\">Location Hartford Hospital Location 2</a></p><p><b>healthcareService</b>: <a href=\"HealthcareService-BurrClinicServices.html\">HealthcareService: extension = ; category = Clinic or Outpatient Facility; specialty = Family Medicine Physician</a></p></div>"
            },
            "active": true,
            "organization": {
                "reference": "Organization/Hospital"
            },
            "participatingOrganization": {
                "reference": "Organization/BurrClinic"
            },
            "network": [
                {
                    "reference": "Organization/AcmeofCTStdNet"
                }
            ],
            "code": [
                {
                    "coding": [
                        {
                            "system": "http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/OrganizationAffiliationRoleCS",
                            "code": "outpatient"
                        }
                    ]
                }
            ],
            "location": [
                {
                    "reference": "Location/HospLoc2"
                }
            ],
            "healthcareService": [
                {
                    "reference": "HealthcareService/BurrClinicServices"
                }
            ]
        };

        davinciplannet120:PlannetOrganizationAffiliation endpoint = check parser:parse(eocJson).ensureType();
        organizationAffiliation.push(endpoint.clone());
    }
}

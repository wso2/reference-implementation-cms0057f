import ballerina/http;
import ballerinax/health.fhir.r4 as r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.davinciplannet120;

isolated davinciplannet120:PlannetHealthcareService[] endpoints = [];
isolated int createendpointNextId = 9000;

public isolated function create(json payload) returns r4:FHIRError|davinciplannet120:PlannetHealthcareService {
    davinciplannet120:PlannetHealthcareService|error endpoint = parser:parse(payload).ensureType();
    if endpoint is error {
        return r4:createFHIRError(endpoint.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createendpointNextId += 1;
            endpoint.id = (createendpointNextId).toBalString();
        }
        lock {
            endpoints.push(endpoint.clone());
        }
        return endpoint;
    }
}

public isolated function getById(string id) returns r4:FHIRError|davinciplannet120:PlannetHealthcareService {
    lock {
        foreach var item in endpoints {
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
                    davinciplannet120:PlannetHealthcareService byId = check getById(searchParameters.get(key)[0]);
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
        foreach var item in endpoints {
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
            "resourceType" : "HealthcareService",
            "id" : "9000",
            "meta" : {
                "lastUpdated" : "2020-07-07T13:26:22.0314215+00:00",
                "profile" : ["http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-HealthcareService"]
            },
            "language" : "en-US",
            "text" : {
                "status" : "extensions",
                "div" : "<div xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en-US\" lang=\"en-US\"><p class=\"res-header-id\"><b>Generated Narrative: HealthcareService BurrClinicServices</b></p><a name=\"BurrClinicServices\"> </a><a name=\"hcBurrClinicServices\"> </a><a name=\"BurrClinicServices-en-US\"> </a><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Last updated: 2020-07-07 13:26:22+0000; Language: en-US</p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-plannet-HealthcareService.html\">Plan-Net HealthcareService</a></p></div><blockquote><p><b>Delivery Method</b></p><ul><li>type: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/DeliveryMethodCS physical}\">Physical</span></li></ul></blockquote><p><b>active</b>: true</p><p><b>providedBy</b>: <a href=\"Organization-BurrClinic.html\">Organization Burr Clinic</a></p><p><b>category</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/HealthcareServiceCategoryCS outpat}\">Clinic or Outpatient Facility</span></p><p><b>specialty</b>: <span title=\"Codes:{http://nucc.org/provider-taxonomy 207Q00000X}\">Family Medicine Physician</span></p><p><b>location</b>: <a href=\"Location-HospLoc1.html\">Location Hartford Hospital Location 1</a></p></div>"
            },
            "extension" : [{
                "extension" : [{
                "url" : "type",
                "valueCodeableConcept" : {
                    "coding" : [{
                    "system" : "http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/DeliveryMethodCS",
                    "code" : "physical"
                    }]
                }
                }],
                "url" : "http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/delivery-method"
            }],
            "active" : true,
            "providedBy" : {
                "reference" : "Organization/BurrClinic"
            },
            "category" : [{
                "coding" : [{
                "system" : "http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/HealthcareServiceCategoryCS",
                "code" : "outpat"
                }]
            }],
            "specialty" : [{
                "coding" : [{
                "system" : "http://nucc.org/provider-taxonomy",
                "code" : "207Q00000X",
                "display" : "Family Medicine Physician"
                }]
            }],
            "location" : [{
                "reference" : "Location/HospLoc1"
            }]
        };

        davinciplannet120:PlannetHealthcareService endpoint = check parser:parse(eocJson).ensureType();
        endpoints.push(endpoint.clone());
    }
}

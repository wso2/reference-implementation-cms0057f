import ballerina/http;
import ballerinax/health.fhir.r4 as r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.davinciplannet120;

isolated davinciplannet120:PlannetEndpoint[] endpoints = [];
isolated int createendpointNextId = 9000;

public isolated function create(json payload) returns r4:FHIRError|davinciplannet120:PlannetEndpoint {
    davinciplannet120:PlannetEndpoint|error endpoint = parser:parse(payload).ensureType();
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

public isolated function getById(string id) returns r4:FHIRError|davinciplannet120:PlannetEndpoint {
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
                    davinciplannet120:PlannetEndpoint byId = check getById(searchParameters.get(key)[0]);
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
            "resourceType" : "Endpoint",
            "id" : "12344",
            "meta" : {
                "lastUpdated" : "2020-07-07T13:26:22.0314215+00:00",
                "profile" : ["http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Endpoint"]
            },
            "language" : "en-US",
            "text" : {
                "status" : "extensions",
                "div" : "<div xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en-US\" lang=\"en-US\"><p class=\"res-header-id\"><b>Generated Narrative: Endpoint AcmeOfCTPortalEndpoint</b></p><a name=\"AcmeOfCTPortalEndpoint\"> </a><a name=\"hcAcmeOfCTPortalEndpoint\"> </a><a name=\"AcmeOfCTPortalEndpoint-en-US\"> </a><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Last updated: 2020-07-07 13:26:22+0000; Language: en-US</p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-plannet-Endpoint.html\">Plan-Net Endpoint</a></p></div><blockquote><p><b>Endpoint Usecase</b></p><ul><li>type: <span title=\"Codes:{http://terminology.hl7.org/CodeSystem/v3-ActReason HOPERAT}\">healthcare operations</span></li></ul></blockquote><p><b>status</b>: Active</p><p><b>connectionType</b>: <a href=\"CodeSystem-EndpointConnectionTypeCS.html#EndpointConnectionTypeCS-rest-non-fhir\">Endpoint Connection Types (additional) rest-non-fhir</a>: REST (not FHIR)</p><p><b>name</b>: Endpoint for Acme of CT Portal</p><p><b>payloadType</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/EndpointPayloadTypeCS NA}\">Not Applicable</span></p><p><b>address</b>: <a href=\"https://urlofportal.acmect.com\">https://urlofportal.acmect.com</a></p></div>"
            },
            "extension" : [{
                "extension" : [{
                "url" : "type",
                "valueCodeableConcept" : {
                    "coding" : [{
                    "system" : "http://terminology.hl7.org/CodeSystem/v3-ActReason",
                    "code" : "HOPERAT"
                    }]
                }
                }],
                "url" : "http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/endpoint-usecase"
            }],
            "status" : "active",
            "connectionType" : {
                "system" : "http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/EndpointConnectionTypeCS",
                "code" : "rest-non-fhir"
            },
            "name" : "Endpoint for Acme of CT Portal",
            "payloadType" : [{
                "coding" : [{
                "system" : "http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/EndpointPayloadTypeCS",
                "code" : "NA"
                }]
            }],
            "address" : "https://urlofportal.acmect.com"
        };

        davinciplannet120:PlannetEndpoint endpoint = check parser:parse(eocJson).ensureType();
        endpoints.push(endpoint.clone());
    }
}

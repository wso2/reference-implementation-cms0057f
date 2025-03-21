import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated uscore700:USCoreServiceRequestProfile[] serviceRequests = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|uscore700:USCoreServiceRequestProfile {
    uscore700:USCoreServiceRequestProfile|error serviceRequest = parser:parse(payload, uscore700:USCoreServiceRequestProfile).ensureType();

    if serviceRequest is error {
        return r4:createFHIRError(serviceRequest.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            serviceRequest.id = (createOperationNextId).toBalString();
        }

        lock {
            serviceRequests.push(serviceRequest.clone());
        }

        return serviceRequest;
    }
}

public isolated function getById(string id) returns r4:FHIRError|uscore700:USCoreServiceRequestProfile {
    lock {
        foreach var item in serviceRequests {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a serviceRequest resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    uscore700:USCoreServiceRequestProfile byId = check getById(searchParameters.get('key)[0]);
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
        foreach var item in serviceRequests {
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
        json serviceRequestJson = {
            "resourceType": "ServiceRequest",
            "id": "12344",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-servicerequest|7.0.0"]
            },
            "text": {
                "status": "generated",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p><b>Generated Narrative: ServiceRequest</b><a name=\"foodpantry-referral\"> </a><a name=\"hcfoodpantry-referral\"> </a></p><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Resource ServiceRequest &quot;foodpantry-referral&quot; </p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-us-core-servicerequest.html\">US Core ServiceRequest Profile (version 7.0.0)</a></p></div><p><b>status</b>: active</p><p><b>intent</b>: order</p><p><b>category</b>: Social Determinants Of Health <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"CodeSystem-us-core-category.html\">US Core Category</a>#sdoh &quot;SDOH&quot;)</span></p><p><b>code</b>: Assistance with application for food pantry program <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"https://browser.ihtsdotools.org/\">SNOMED CT[US]</a>#467771000124109)</span></p><p><b>subject</b>: <a href=\"Patient-example.html\">Patient/example</a> &quot; SHAW&quot;</p><p><b>occurrence</b>: 2021-11-20</p><p><b>authoredOn</b>: 2021-11-12 10:59:38-0800</p><p><b>requester</b>: <a href=\"Practitioner-practitioner-1.html\">Practitioner/practitioner-1</a> &quot; BONE&quot;</p></div>"
            },
            "status": "active",
            "intent": "order",
            "category": [
                {
                    "coding": [
                        {
                            "system": "http://hl7.org/fhir/us/core/CodeSystem/us-core-category",
                            "code": "sdoh",
                            "display": "SDOH"
                        }
                    ],
                    "text": "Social Determinants Of Health"
                }
            ],
            "code": {
                "coding": [
                    {
                        "system": "http://snomed.info/sct",
                        "version": "http://snomed.info/sct/731000124108",
                        "code": "467771000124109",
                        "display": "Assistance with application for food pantry program"
                    }
                ]
            },
            "subject": {
                "reference": "Patient/example"
            },
            "occurrenceDateTime": "2021-11-20",
            "authoredOn": "2021-11-12T10:59:38-08:00",
            "requester": {
                "reference": "Practitioner/practitioner-1"
            }
        };
        uscore700:USCoreServiceRequestProfile serviceRequest = check parser:parse(serviceRequestJson, uscore700:USCoreServiceRequestProfile).ensureType();
        serviceRequests.push(serviceRequest.clone());
    }
}

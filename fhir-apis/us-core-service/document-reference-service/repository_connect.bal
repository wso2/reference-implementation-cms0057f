import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated uscore700:USCoreDocumentReferenceProfile[] documentReferences = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|uscore700:USCoreDocumentReferenceProfile {
    uscore700:USCoreDocumentReferenceProfile|error documentReference = parser:parse(payload, uscore700:USCoreDocumentReferenceProfile).ensureType();

    if documentReference is error {
        return r4:createFHIRError(documentReference.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            documentReference.id = (createOperationNextId).toBalString();
        }

        lock {
            documentReferences.push(documentReference.clone());
        }

        return documentReference;
    }
}

public isolated function getById(string id) returns r4:FHIRError|uscore700:USCoreDocumentReferenceProfile {
    lock {
        foreach var item in documentReferences {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a documentReference resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    uscore700:USCoreDocumentReferenceProfile byId = check getById(searchParameters.get('key)[0]);
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
        foreach var item in documentReferences {
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
        json documentReferenceJson = {
            "resourceType": "DocumentReference",
            "id": "12344",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-documentreference|7.0.0"]
            },
            "status": "current",
            "type": {
                "coding": [
                    {
                        "system": "http://loinc.org",
                        "code": "18842-5",
                        "display": "Discharge Summary"
                    }
                ],
                "text": "Discharge Summary"
            },
            "category": [
                {
                    "coding": [
                        {
                            "system": "http://hl7.org/fhir/us/core/CodeSystem/us-core-documentreference-category",
                            "code": "clinical-note",
                            "display": "Clinical Note"
                        }
                    ],
                    "text": "Clinical No"
                }
            ],
            "subject": {
                "reference": "Patient/example"
            },
            "content": [
                {
                    "attachment": {
                        "contentType": "text/plain",
                        "data": "Tm8gYWN0aXZpdHkgcmVzdHJpY3Rpb24sIHJlZ3VsYXIgZGlldCwgZm9sbG93IHVwIGluIHR3byB0byB0aHJlZSB3ZWVrcyB3aXRoIHByaW1hcnkgY2FyZSBwcm92aWRlci4="
                    }
                }
            ],
            "context": {
                "encounter": [
                    {
                        "reference": "Encounter/example-1"
                    }
                ]
            }
        };
        uscore700:USCoreDocumentReferenceProfile documentReference = check parser:parse(documentReferenceJson, uscore700:USCoreDocumentReferenceProfile).ensureType();
        documentReferences.push(documentReference.clone());
    }
}

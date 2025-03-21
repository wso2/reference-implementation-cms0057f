import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated uscore700:USCoreProvenance[] provenances = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|uscore700:USCoreProvenance {
    uscore700:USCoreProvenance|error provenance = parser:parse(payload, uscore700:USCoreProvenance).ensureType();

    if provenance is error {
        return r4:createFHIRError(provenance.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            provenance.id = (createOperationNextId).toBalString();
        }

        lock {
            provenances.push(provenance.clone());
        }

        return provenance;
    }
}

public isolated function getById(string id) returns r4:FHIRError|uscore700:USCoreProvenance {
    lock {
        foreach var item in provenances {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a provenance resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    uscore700:USCoreProvenance byId = check getById(searchParameters.get('key)[0]);
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
        foreach var item in provenances {
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
        json provenanceJson = {
            "resourceType": "Provenance",
            "id": "12344",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-provenance|7.0.0"]
            },
            "target": [
                {
                    "extension": [
                        {
                            "url": "http://hl7.org/fhir/StructureDefinition/targetElement",
                            "valueUri": "race"
                        }
                    ],
                    "reference": "Patient/example-targeted-provenance"
                }
            ],
            "recorded": "2023-02-28T15:26:23.217+00:00",
            "agent": [
                {
                    "type": {
                        "coding": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/provenance-participant-type",
                                "code": "informant",
                                "display": "Informant"
                            }
                        ]
                    },
                    "who": {
                        "reference": "Patient/example-targeted-provenance"
                    }
                }
            ],
            "entity": [
                {
                    "role": "source",
                    "what": {
                        "display": "admission form"
                    }
                }
            ]
        };
        uscore700:USCoreProvenance provenance = check parser:parse(provenanceJson, uscore700:USCoreProvenance).ensureType();
        provenances.push(provenance.clone());
    }
}

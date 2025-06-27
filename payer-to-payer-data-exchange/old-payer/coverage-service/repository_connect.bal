import ballerina/http;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.parser;

// http:OAuth2ClientCredentialsGrantConfig ehrSystemAuthConfig = {
//     tokenUrl: "https://login.microsoftonline.com/da76d684-740f-4d94-8717-9d5fb21dd1f9/oauth2/token",
//     clientId: "",
//     clientSecret: "",
//     scopes: ["system/Patient.read, system/Patient.write"],
//     optionalParams: {
//         "resource": "https://ohfhirrepositorypoc-ohfhirrepositorypoc.fhir.azurehealthcareapis.com"
//     }
// };

// fhir:FHIRConnectorConfig ehrSystemConfig = {
//     baseURL: "https://ohfhirrepositorypoc-ohfhirrepositorypoc.fhir.azurehealthcareapis.com/",
//     mimeType: fhir:FHIR_JSON,
//     authConfig: ehrSystemAuthConfig
// };

// isolated fhir:FHIRConnector fhirConnectorObj = check new (ehrSystemConfig);

isolated international401:Coverage[] coverages = [];
isolated int createOperationNextId = 368;

public isolated function create(international401:Coverage payload) returns r4:FHIRError|international401:Coverage {
    international401:Coverage|error coverage = parser:parseWithValidation(payload.toJson(), international401:Coverage).ensureType();

    if coverage is error {
        return r4:createFHIRError(coverage.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            coverage.id = (++createOperationNextId).toBalString();
        }

        lock {
            coverages.push(coverage.clone());
        }

        return coverage;
    }
}

public isolated function getById(string id) returns r4:FHIRError|international401:Coverage {
    lock {
        foreach var item in coverages {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a Coverage resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function update(json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function patchResource(string 'resource, string id, json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
}

public isolated function delete(string 'resource, string id) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        if searchParameters.keys().count() == 1 {
            lock {
                r4:BundleEntry[] bundleEntries = [];
                foreach var item in coverages {
                    r4:BundleEntry bundleEntry = {
                        'resource: item
                    };
                    bundleEntries.push(bundleEntry);
                }
                r4:Bundle BundleClone = bundle.clone();
                BundleClone.entry = bundleEntries;
                return BundleClone.clone();
            }
        }

        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    international401:Coverage byId = check getById(searchParameters.get('key)[0]);
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

    return bundle;
}

function init() returns error? {
    lock {
        json coverageJson = {
            "resourceType": "Coverage",
            "id": "367",
            "meta": {
                "profile": [
                    "http://hl7.org/fhir/StructureDefinition/Coverage"
                ]
            },
            "status": "active",
            "subscriber": {
                "reference": "Patient/588675dc-e80e-4528-a78f-af10f9755f23"
            },
            "subscriberId": "UC-123456789",
            "beneficiary": {
                "reference": "Patient/588675dc-e80e-4528-a78f-af10f9755f23"
            },
            "payor": [
                {
                    "reference": "Organization/50"
                }
            ],
            "class": [
                {
                    "type": {
                        "coding": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/coverage-class",
                                "code": "group",
                                "display": "Group"
                            }
                        ]
                    },
                    "value": "UC-Group-001",
                    "name": "UnitedCare Standard Plan"
                }
            ],
            "period": {
                "start": "2025-01-01",
                "end": "2025-12-31"
            },
            "network": "UC-Preferred-Network",
            "costToBeneficiary": [
                {
                    "type": {
                        "coding": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/coverage-copay-type",
                                "code": "copay",
                                "display": "CoPay"
                            }
                        ]
                    },
                    "valueMoney": {
                        "value": 50.00,
                        "currency": "USD"
                    },
                    "valueQuantity": {
                        "value": 1,
                        "unit": "visit",
                        "system": "http://unitsofmeasure.org",
                        "code": "visit"
                    }
                }
            ]
        };
        international401:Coverage coverage = check parser:parseWithValidation(coverageJson, international401:Coverage).ensureType();
        coverages.push(coverage);
    
    }
}

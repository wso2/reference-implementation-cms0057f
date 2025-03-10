import ballerina/http;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore501;

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

isolated uscore501:USCoreOrganizationProfile[] organizations = [];
isolated int createOperationNextId = 50;

public isolated function create(uscore501:USCoreOrganizationProfile organization) returns r4:FHIRError|uscore501:USCoreOrganizationProfile {
    uscore501:USCoreOrganizationProfile|error claim = parser:parseWithValidation(organization.toJson(), uscore501:USCoreOrganizationProfile).ensureType();

    if claim is error {
        return r4:createFHIRError(claim.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            claim.id = (++createOperationNextId).toBalString();
        }

        lock {
            organizations.push(claim.clone());
        }

        return claim;
    }
}

public isolated function getById(string id) returns r4:FHIRError|uscore501:USCoreOrganizationProfile {
    lock {
        foreach var item in organizations {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a Patient resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
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
                foreach var item in organizations {
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
                    uscore501:USCoreOrganizationProfile byId = check getById(searchParameters.get('key)[0]);
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
        json organizationJson = {
            "resourceType": "Organization",
            "id": "50",
            "meta": {
                "profile": [
                    "http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization"
                ]
            },
            "identifier": [
                {
                    "system": "http://hl7.org/fhir/sid/us-npi",
                    "value": "1234567890"
                }
            ],
            "active": true,
            "name": "UnitedCare Health Insurance",
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/organization-type",
                            "code": "pay",
                            "display": "Payer"
                        }
                    ]
                }
            ],
            "telecom": [
                {
                    "system": "phone",
                    "value": "+1 800-555-1234",
                    "use": "work"
                },
                {
                    "system": "email",
                    "value": "support@unitedcare.com",
                    "use": "work"
                }
            ],
            "address": [
                {
                    "line": ["456 Insurance Ave"],
                    "city": "Insuretown",
                    "state": "CA",
                    "postalCode": "90310",
                    "country": "US"
                }
            ],
            "contact": [
                {
                    "name": {
                        "family": "Doe",
                        "given": ["John"]
                    },
                    "telecom": [
                        {
                            "system": "phone",
                            "value": "+1 800-555-5678",
                            "use": "work"
                        },
                        {
                            "system": "email",
                            "value": "johndoe@unitedcare.com",
                            "use": "work"
                        }
                    ],
                    "purpose": {
                        "coding": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/contactentity-type",
                                "code": "ADMIN",
                                "display": "Administrative"
                            }
                        ]
                    }
                }
            ]
        };

        uscore501:USCoreOrganizationProfile organization = check parser:parse(organizationJson, uscore501:USCoreOrganizationProfile).ensureType();
        organizations.push(organization);
    }

}

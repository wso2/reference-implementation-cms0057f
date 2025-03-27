import ballerina/http;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davinciplannet120;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

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

isolated Organization[] organizations = [];
isolated int createOperationNextId = 59;

// Use US Core Organization profile is the default profile
final string DEFAULT_PROFILE = "http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization";

public isolated function create(json payload) returns r4:FHIRError|Organization {
    Organization|error organization = parser:parseWithValidation(payload, uscore700:USCoreOrganizationProfile).ensureType();

    if organization is error {
        organization = parser:parseWithValidation(payload, davinciplannet120:PlannetNetwork).ensureType();
    }

    if organization is error {
        return r4:createFHIRError(organization.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            organization.id = createOperationNextId.toBalString();
        }

        lock {
            organizations.push(organization.clone());
        }

        return organization;
    }
}

public isolated function getById(string id, Organization[]? targetOrganizationArr = ()) returns r4:FHIRError|Organization {
    Organization[] organizationArr;
    if targetOrganizationArr is Organization[] {
        organizationArr = targetOrganizationArr;
    } else {
        lock {
            organizationArr = organizations.clone();
        }
    }

    foreach var item in organizationArr {
        string result = item.id ?: "";

        if result == id {
            return item.clone();
        }
    }
    return r4:createFHIRError(string `Cannot find a Patient resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

isolated function getByType(string 'type, Organization[]? targetOrganizationArr = ()) returns r4:FHIRError|Organization[] {
    Organization[] organizationArr;
    if targetOrganizationArr is Organization[] {
        organizationArr = targetOrganizationArr;
    } else {
        lock {
            organizationArr = organizations.clone();
        }
    }

    Organization[] searchedOrganizations = [];
    foreach var item in organizationArr {
        r4:CodeableConcept[]? typeResult = item.'type;
        if typeResult is r4:CodeableConcept[] {
            r4:CodeableConcept typeRecord = typeResult[0];
            r4:Coding[]? codings = typeRecord.coding;
            if codings is r4:Coding[] {
                r4:Coding coding = codings[0];
                if coding.code == 'type {
                    searchedOrganizations.push(item.clone());
                }
            }
        }
    }

    return searchedOrganizations;
}

isolated function getByProfile(string profile) returns r4:FHIRError|Organization[] {
    lock {
        Organization[] items = [];

        foreach var item in organizations {
            r4:Meta? itemMeta = item.meta;

            if itemMeta is r4:Meta {
                r4:canonical[]? profileArray = itemMeta.profile;

                if profileArray is r4:canonical[] {
                    string profileValue = profileArray[0].toString();

                    if profileValue == profile {
                        items.push(item.clone());
                    }
                }
            }
        }

        return items.length() > 0 ? items.clone() : r4:createFHIRError(string `Cannot find a organization resource with profile: ${profile}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
    }
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
        string? id = ();
        string? profile = ();
        string? 'type = ();

        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    id = searchParameters.get('key)[0];
                }
                "type" => {
                    'type = searchParameters.get('key)[0];
                }
                "_profile" => {
                    profile = searchParameters.get('key)[0];
                }
                "_count" => {
                    // pagination is not used in this service
                    continue;
                }
                _ => {
                    return r4:createFHIRError(string `Not supported search parameter: ${'key}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
                }
            }
        }

        Organization[] byProfile = check getByProfile(profile is string ? profile : DEFAULT_PROFILE);

        if id is string {
            Organization byId = check getById(id, byProfile);
            bundle.entry = [
                {
                    'resource: byId
                }
            ];
            return bundle;
        }

        Organization[] results = [];

        if 'type is string {
            results = check getByType('type, byProfile);
        } else {
            // default to byProfile
            results = byProfile;
        }

        r4:BundleEntry[] bundleEntries = [];
        foreach var item in results {
            bundleEntries.push({
                'resource: item
            });
        }
        bundle.entry = bundleEntries;
        bundle.total = results.length();
    }

    return bundle;
}

function init() returns error? {
    lock {
        // US Core Profile
        json organizationJson1 = {
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
                            "system": "http://hl7.org/fhir/organization-role",
                            "code": "payer",
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
        Organization organization1 = check parser:parse(organizationJson1, uscore700:USCoreOrganizationProfile).ensureType();
        organizations.push(organization1);

        json organizationJson2 = {
            "resourceType": "Organization",
            "id": "51",
            "meta": {
                "profile": [
                    "http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization"
                ]
            },
            "identifier": [
                {
                    "system": "http://hl7.org/fhir/sid/us-npi",
                    "value": "9876543210"
                }
            ],
            "active": true,
            "name": "SecureHealth Insurance",
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://hl7.org/fhir/organization-role",
                            "code": "payer",
                            "display": "Payer"
                        }
                    ]
                }
            ],
            "telecom": [
                {
                    "system": "phone",
                    "value": "+1 888-123-4567",
                    "use": "work"
                },
                {
                    "system": "email",
                    "value": "support@securehealth.com",
                    "use": "work"
                }
            ],
            "address": [
                {
                    "line": ["789 Protection Blvd"],
                    "city": "HealthCity",
                    "state": "NY",
                    "postalCode": "10001",
                    "country": "US"
                }
            ],
            "contact": [
                {
                    "name": {
                        "family": "Smith",
                        "given": ["Alice"]
                    },
                    "telecom": [
                        {
                            "system": "phone",
                            "value": "+1 888-987-6543",
                            "use": "work"
                        },
                        {
                            "system": "email",
                            "value": "alice.smith@securehealth.com",
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
        Organization organization2 = check parser:parse(organizationJson2, uscore700:USCoreOrganizationProfile).ensureType();
        organizations.push(organization2);

        json organizationJson3 = {
            "resourceType": "Organization",
            "id": "52",
            "meta": {
                "profile": [
                    "http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization"
                ]
            },
            "identifier": [
                {
                    "system": "http://hl7.org/fhir/sid/us-npi",
                    "value": "1928374650"
                }
            ],
            "active": true,
            "name": "MediTrust Insurance",
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://hl7.org/fhir/organization-role",
                            "code": "payer",
                            "display": "Payer"
                        }
                    ]
                }
            ],
            "telecom": [
                {
                    "system": "phone",
                    "value": "+1 877-999-7890",
                    "use": "work"
                },
                {
                    "system": "email",
                    "value": "help@meditrust.com",
                    "use": "work"
                }
            ],
            "address": [
                {
                    "line": ["123 Wellness Street"],
                    "city": "Caretown",
                    "state": "TX",
                    "postalCode": "75001",
                    "country": "US"
                }
            ],
            "contact": [
                {
                    "name": {
                        "family": "Johnson",
                        "given": ["Robert"]
                    },
                    "telecom": [
                        {
                            "system": "phone",
                            "value": "+1 877-555-9087",
                            "use": "work"
                        },
                        {
                            "system": "email",
                            "value": "robert.johnson@meditrust.com",
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
        Organization organization3 = check parser:parse(organizationJson3, uscore700:USCoreOrganizationProfile).ensureType();
        organizations.push(organization3);

        json organizationJson4 = {
            "resourceType": "Organization",
            "id": "53",
            "meta": {
                "profile": [
                    "http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization"
                ]
            },
            "identifier": [
                {
                    "system": "http://hl7.org/fhir/sid/us-npi",
                    "value": "5432109876"
                }
            ],
            "active": true,
            "name": "City General Hospital",
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://hl7.org/fhir/organization-role",
                            "code": "provider",
                            "display": "Provider"
                        }
                    ]
                }
            ],
            "telecom": [
                {
                    "system": "phone",
                    "value": "+1 800-111-2222",
                    "use": "work"
                },
                {
                    "system": "email",
                    "value": "info@citygeneralhospital.com",
                    "use": "work"
                }
            ],
            "address": [
                {
                    "line": ["123 Medical Lane"],
                    "city": "MedCity",
                    "state": "NY",
                    "postalCode": "10011",
                    "country": "US"
                }
            ],
            "contact": [
                {
                    "name": {
                        "family": "Williams",
                        "given": ["Michael"]
                    },
                    "telecom": [
                        {
                            "system": "phone",
                            "value": "+1 800-111-3333",
                            "use": "work"
                        },
                        {
                            "system": "email",
                            "value": "michael.williams@citygeneralhospital.com",
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
        Organization organization4 = check parser:parse(organizationJson4, uscore700:USCoreOrganizationProfile).ensureType();
        organizations.push(organization4);

        json organizationJson5 = {
            "resourceType": "Organization",
            "id": "54",
            "meta": {
                "profile": [
                    "http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization"
                ]
            },
            "identifier": [
                {
                    "system": "http://hl7.org/fhir/sid/us-npi",
                    "value": "6789054321"
                }
            ],
            "active": true,
            "name": "St. Mary's Regional Hospital",
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://hl7.org/fhir/organization-role",
                            "code": "provider",
                            "display": "Provider"
                        }
                    ]
                }
            ],
            "telecom": [
                {
                    "system": "phone",
                    "value": "+1 800-222-5555",
                    "use": "work"
                },
                {
                    "system": "email",
                    "value": "contact@stmarysregional.com",
                    "use": "work"
                }
            ],
            "address": [
                {
                    "line": ["789 Care Street"],
                    "city": "Healthville",
                    "state": "CA",
                    "postalCode": "90210",
                    "country": "US"
                }
            ],
            "contact": [
                {
                    "name": {
                        "family": "Johnson",
                        "given": ["Emma"]
                    },
                    "telecom": [
                        {
                            "system": "phone",
                            "value": "+1 800-222-7777",
                            "use": "work"
                        },
                        {
                            "system": "email",
                            "value": "emma.johnson@stmarysregional.com",
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
        Organization organization5 = check parser:parse(organizationJson5, uscore700:USCoreOrganizationProfile).ensureType();
        organizations.push(organization5);

        json organizationJson6 = {
            "resourceType": "Organization",
            "id": "55",
            "meta": {
                "profile": [
                    "http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization"
                ]
            },
            "identifier": [
                {
                    "system": "http://hl7.org/fhir/sid/us-npi",
                    "value": "1122334455"
                }
            ],
            "active": true,
            "name": "Green Valley Community Hospital",
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://hl7.org/fhir/organization-role",
                            "code": "provider",
                            "display": "Provider"
                        }
                    ]
                }
            ],
            "telecom": [
                {
                    "system": "phone",
                    "value": "+1 800-333-8888",
                    "use": "work"
                },
                {
                    "system": "email",
                    "value": "info@greenvalleyhospital.com",
                    "use": "work"
                }
            ],
            "address": [
                {
                    "line": ["456 Wellness Ave"],
                    "city": "Caretown",
                    "state": "TX",
                    "postalCode": "75002",
                    "country": "US"
                }
            ],
            "contact": [
                {
                    "name": {
                        "family": "Brown",
                        "given": ["David"]
                    },
                    "telecom": [
                        {
                            "system": "phone",
                            "value": "+1 800-333-9999",
                            "use": "work"
                        },
                        {
                            "system": "email",
                            "value": "david.brown@greenvalleyhospital.com",
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
        Organization organization6 = check parser:parse(organizationJson6, uscore700:USCoreOrganizationProfile).ensureType();
        organizations.push(organization6);

        // Davinci Plan Net
        json organizationJson7 = {
            "resourceType": "Organization",
            "id": "56",
            "meta": {
                "lastUpdated": "2020-07-07T13:26:22.0314215+00:00",
                "profile": ["http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Network"]
            },
            "language": "en-US",
            "text": {
                "status": "extensions",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en-US\" lang=\"en-US\"><p class=\"res-header-id\"><b>Generated Narrative: Organization AcmeofCTPremNet</b></p><a name=\"AcmeofCTPremNet\"> </a><a name=\"hcAcmeofCTPremNet\"> </a><a name=\"AcmeofCTPremNet-en-US\"> </a><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Last updated: 2020-07-07 13:26:22+0000; Language: en-US</p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-plannet-Network.html\">Plan-Net Network</a></p></div><p><b>Location Reference</b>: <a href=\"Location-StateOfCTLocation.html\">Location State of CT Area</a></p><p><b>active</b>: true</p><p><b>type</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/OrgTypeCS ntwk}\">Network</span></p><p><b>name</b>: ACME CT Premium Preferred Provider Network</p><p><b>partOf</b>: <a href=\"Organization-Acme.html\">Organization Acme of CT</a></p><h3>Contacts</h3><table class=\"grid\"><tr><td style=\"display: none\">-</td><td><b>Name</b></td><td><b>Telecom</b></td></tr><tr><td style=\"display: none\">*</td><td>Jane Kawasaki </td><td>-unknown-</td></tr></table></div>"
            },
            "extension": [
                {
                    "url": "http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/location-reference",
                    "valueReference": {
                        "reference": "Location/StateOfCTLocation"
                    }
                }
            ],
            "active": true,
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/OrgTypeCS",
                            "code": "ntwk",
                            "display": "Network"
                        }
                    ]
                }
            ],
            "name": "ACME CT Premium Preferred Provider Network",
            "partOf": {
                "reference": "Organization/Acme"
            },
            "contact": [
                {
                    "name": {
                        "family": "Kawasaki",
                        "given": ["Jane"]
                    },
                    "telecom": [
                        {
                            "extension": [
                                {
                                    "url": "http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/via-intermediary",
                                    "valueReference": {
                                        "reference": "Organization/Acme"
                                    }
                                }
                            ]
                        }
                    ]
                }
            ]
        };
        Organization organization7 = check parser:parse(organizationJson7, davinciplannet120:PlannetNetwork).ensureType();
        organizations.push(organization7.clone());

        json organizationJson8 = {
            "resourceType": "Organization",
            "id": "57",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Network"]
            },
            "language": "en-US",
            "text": {
                "status": "extensions",
                "div": "<div>Example Narrative for Network</div>"
            },
            "active": true,
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/OrgTypeCS",
                            "code": "ntwk",
                            "display": "Network"
                        }
                    ]
                }
            ],
            "name": "Example Network Organization",
            "partOf": {
                "reference": "Organization/ParentOrg1"
            },
            "contact": [
                {
                    "name": {
                        "family": "Doe",
                        "given": ["John"]
                    },
                    "telecom": [
                        {
                            "system": "phone",
                            "value": "+1 800-123-4567",
                            "use": "work"
                        }
                    ]
                }
            ]
        };
        Organization organization8 = check parser:parse(organizationJson8, davinciplannet120:PlannetNetwork).ensureType();
        organizations.push(organization8.clone());

        json organizationJson9 = {
            "resourceType": "Organization",
            "id": "58",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Network"]
            },
            "language": "en-US",
            "text": {
                "status": "extensions",
                "div": "<div>Example Narrative for Provider</div>"
            },
            "active": true,
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/OrgTypeCS",
                            "code": "prov",
                            "display": "Provider"
                        }
                    ]
                }
            ],
            "name": "Example Provider Organization",
            "partOf": {
                "reference": "Organization/ParentOrg2"
            },
            "contact": [
                {
                    "name": {
                        "family": "Smith",
                        "given": ["Alice"]
                    },
                    "telecom": [
                        {
                            "system": "email",
                            "value": "alice.smith@example.com",
                            "use": "work"
                        }
                    ]
                }
            ]
        };
        Organization organization9 = check parser:parse(organizationJson9, davinciplannet120:PlannetNetwork).ensureType();
        organizations.push(organization9.clone());

        json organizationJson10 = {
            "resourceType": "Organization",
            "id": "59",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Network"]
            },
            "language": "en-US",
            "text": {
                "status": "extensions",
                "div": "<div>Example Narrative for Payer</div>"
            },
            "active": true,
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/OrgTypeCS",
                            "code": "payer",
                            "display": "Payer"
                        }
                    ]
                }
            ],
            "name": "Example Payer Organization",
            "partOf": {
                "reference": "Organization/ParentOrg3"
            },
            "contact": [
                {
                    "name": {
                        "family": "Johnson",
                        "given": ["Robert"]
                    },
                    "telecom": [
                        {
                            "system": "phone",
                            "value": "+1 800-987-6543",
                            "use": "work"
                        }
                    ]
                }
            ]
        };
        Organization organization10 = check parser:parse(organizationJson10, davinciplannet120:PlannetNetwork).ensureType();
        organizations.push(organization10.clone());
    }

}

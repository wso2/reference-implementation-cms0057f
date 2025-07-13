// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).

// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore501;

isolated uscore501:USCoreOrganizationProfile[] organizations = [];
isolated int createOperationNextIdOrganization = 50;

public isolated function createOrganization(uscore501:USCoreOrganizationProfile organization) returns r4:FHIRError|uscore501:USCoreOrganizationProfile {
    uscore501:USCoreOrganizationProfile|error claim = parser:parseWithValidation(organization.toJson(), uscore501:USCoreOrganizationProfile).ensureType();

    if claim is error {
        return r4:createFHIRError(claim.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            claim.id = (++createOperationNextIdOrganization).toBalString();
        }

        lock {
            organizations.push(claim.clone());
        }

        return claim;
    }
}

public isolated function getByIdOrganization(string id) returns r4:FHIRError|uscore501:USCoreOrganizationProfile {
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

public isolated function updateOrganization(json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function patchResourceOrganization(string 'resource, string id, json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
}

public isolated function deleteOrganization(string 'resource, string id) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function searchOrganization(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        if searchParameters.keys().length() == 1 {
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
                    uscore501:USCoreOrganizationProfile byId = check getByIdOrganization(searchParameters.get('key)[0]);
                    bundle.entry = [
                        {
                            'resource: byId
                        }
                    ];
                    return bundle;
                }
                "type" => {
                    lock {
                        r4:Bundle bundleClone = bundle.clone();
                        r4:BundleEntry[] bundleEntry = [];
                        foreach var item in organizations {
                            r4:CodeableConcept[]? typeResult = item.'type;
                            if typeResult is r4:CodeableConcept[] {
                                r4:CodeableConcept typeRecord = typeResult[0];
                                r4:Coding[]? codings = typeRecord.coding;
                                if codings is r4:Coding[] {
                                    r4:Coding coding = codings[0];
                                    if coding.code == searchParameters.get('key)[0] {
                                        bundleEntry.push({
                                            'resource: item
                                        });
                                    }
                                }
                            }
                        }
                        bundleClone.entry = bundleEntry;
                        return bundleClone.clone();
                    }

                }
                _ => {
                    return r4:createFHIRError(string `Not supported search parameter: ${'key}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED)
                    ;
                }
            }
        }
    }

    return bundle;
}

function loadOrganizationData() returns error? {
    lock {
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
            "name": "KindCover Health Insurance",
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
                    "value": "support@kindcover.com",
                    "use": "work"
                }
            ],
            "address": [
                {
                    "line": ["456 Insurance Ave"],
                    "city": "Insuretown",
                    "state": "OH",
                    "postalCode": "43004",
                    "country": "US"
                }
            ],
            "contact": [
                {
                    "name": {
                        "family": "Adam",
                        "given": ["Nickman"]
                    },
                    "telecom": [
                        {
                            "system": "phone",
                            "value": "+1 800-555-5678",
                            "use": "work"
                        },
                        {
                            "system": "email",
                            "value": "adam@kindcover.com",
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
        uscore501:USCoreOrganizationProfile organization1 = check parser:parse(organizationJson1, uscore501:USCoreOrganizationProfile).ensureType();
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
        uscore501:USCoreOrganizationProfile organization2 = check parser:parse(organizationJson2, uscore501:USCoreOrganizationProfile).ensureType();
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
        uscore501:USCoreOrganizationProfile organization3 = check parser:parse(organizationJson3, uscore501:USCoreOrganizationProfile).ensureType();
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
        uscore501:USCoreOrganizationProfile organization4 = check parser:parse(organizationJson4, uscore501:USCoreOrganizationProfile).ensureType();
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
        uscore501:USCoreOrganizationProfile organization5 = check parser:parse(organizationJson5, uscore501:USCoreOrganizationProfile).ensureType();
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
        uscore501:USCoreOrganizationProfile organization6 = check parser:parse(organizationJson6, uscore501:USCoreOrganizationProfile).ensureType();
        organizations.push(organization6);

    }

}

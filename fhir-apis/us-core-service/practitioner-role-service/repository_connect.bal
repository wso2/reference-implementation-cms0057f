import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated uscore700:USCorePractitionerRoleProfile[] practitionerRoles = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|uscore700:USCorePractitionerRoleProfile {
    uscore700:USCorePractitionerRoleProfile|error practitionerRole = parser:parse(payload, uscore700:USCorePractitionerRoleProfile).ensureType();

    if practitionerRole is error {
        return r4:createFHIRError(practitionerRole.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            practitionerRole.id = (createOperationNextId).toBalString();
        }

        lock {
            practitionerRoles.push(practitionerRole.clone());
        }

        return practitionerRole;
    }
}

public isolated function getById(string id) returns r4:FHIRError|uscore700:USCorePractitionerRoleProfile {
    lock {
        foreach var item in practitionerRoles {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a practitionerRole resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    uscore700:USCorePractitionerRoleProfile byId = check getById(searchParameters.get('key)[0]);
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
        foreach var item in practitionerRoles {
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
        json practitionerRoleJson = {
            "resourceType": "PractitionerRole",
            "id": "12344",
            "meta": {
                "versionId": "1",
                "lastUpdated": "2025-03-20T12:00:00Z"
            },
            "identifier": [
                {
                    "use": "official",
                    "system": "http://example.org/practitioner-roles",
                    "value": "12344"
                }
            ],
            "active": true,
            "period": {
                "start": "2025-01-01",
                "end": "2025-12-31"
            },
            "practitioner": {
                "reference": "Practitioner/123",
                "display": "Dr. John Doe"
            },
            "organization": {
                "reference": "Organization/456",
                "display": "Healthcare Organization"
            },
            "code": [
                {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/practitioner-role",
                            "code": "doctor",
                            "display": "Doctor"
                        }
                    ]
                }
            ],
            "specialty": [
                {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/c80-practice-codes",
                            "code": "cardio",
                            "display": "Cardiology"
                        }
                    ]
                }
            ],
            "location": [
                {
                    "reference": "Location/789",
                    "display": "Main Hospital"
                }
            ],
            "healthcareService": [
                {
                    "reference": "HealthcareService/101112",
                    "display": "Cardiology Services"
                }
            ],
            "telecom": [
                {
                    "system": "phone",
                    "value": "+1-555-555-5555",
                    "use": "work"
                },
                {
                    "system": "email",
                    "value": "johndoe@example.org",
                    "use": "work"
                }
            ],
            "availableTime": [
                {
                    "daysOfWeek": ["mon", "tue", "wed", "thu", "fri"],
                    "availableStartTime": "09:00:00",
                    "availableEndTime": "17:00:00"
                }
            ],
            "notAvailable": [
                {
                    "description": "On vacation",
                    "during": {
                        "start": "2025-07-01",
                        "end": "2025-07-15"
                    }
                }
            ],
            "endpoint": [
                {
                    "reference": "Endpoint/131415",
                    "display": "FHIR Endpoint"
                }
            ]
        };
        uscore700:USCorePractitionerRoleProfile practitionerRole = check parser:parse(practitionerRoleJson, uscore700:USCorePractitionerRoleProfile).ensureType();
        practitionerRoles.push(practitionerRole.clone());
    }
}

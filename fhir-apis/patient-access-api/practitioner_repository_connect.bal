import ballerina/http;
import ballerina/regex;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore501;

isolated uscore501:USCorePractitionerProfile[] practitioners = [];
isolated int createOperationNextIdPractitioner = 457;

public isolated function createPractitioner(uscore501:USCorePractitionerProfile payload) returns r4:FHIRError|uscore501:USCorePractitionerProfile {
    uscore501:USCorePractitionerProfile|error practitioner = parser:parseWithValidation(payload.toJson(), uscore501:USCorePractitionerProfile).ensureType();

    if practitioner is error {
        return r4:createFHIRError(practitioner.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            practitioner.id = (++createOperationNextIdPractitioner).toBalString();
        }

        lock {
            practitioners.push(practitioner.clone());
        }

        return practitioner;
    }
}

public isolated function getByIdPractitioner(string id) returns r4:FHIRError|uscore501:USCorePractitionerProfile {
    lock {
        foreach var item in practitioners {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a Patient resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function updatePractitioner(json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function patchResourcePractitioner(string 'resource, string id, json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
}

public isolated function deletePractitioner(string 'resource, string id) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function searchPractitioner(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        if searchParameters.keys().length() == 1 {
            lock {
                r4:BundleEntry[] bundleEntries = [];
                foreach var item in practitioners {
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
                    uscore501:USCorePractitionerProfile byId = check getByIdPractitioner(searchParameters.get('key)[0]);
                    bundle.entry = [
                        {
                            'resource: byId
                        }
                    ];
                    return bundle;
                }

                "name" => {
                    lock {
                        foreach var item in practitioners {

                            uscore501:USCorePractitionerProfileName nameRecord = item.name[0];
                            string given = nameRecord.given is string[] ? (<string[]>nameRecord.given)[0] : "";
                            string fullName = string `${nameRecord.family} ${given}`;

                            string targetString = searchParameters.get('key)[0];
                            boolean matchesResult = regex:matches(fullName.toLowerAscii(), string `.*${targetString.toLowerAscii()}.*`);

                            if matchesResult {
                                r4:Bundle clonedBundle = bundle.clone();
                                clonedBundle.entry = [
                                    {
                                        'resource: item
                                    }
                                ];
                                return clonedBundle.clone();
                            }

                        }

                        return bundle.clone();
                    }

                }
                _ => {
                    return r4:createFHIRError(string `Not supported search parameter: ${'key}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
                }
            }
        }
    }

    return bundle;
}

function loadPractitionerData() returns error? {
    lock {
        json practitionerJson = {
            "resourceType": "Practitioner",
            "id": "456",
            "meta": {
                "profile": [
                    "http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner"
                ]
            },
            "identifier": [
                {
                    "system": "http://hl7.org/fhir/sid/us-npi",
                    "value": "9876543210"
                }
            ],
            "active": true,
            "name": [
                {
                    "family": "Smith",
                    "given": ["James"],
                    "prefix": ["Dr."]
                }
            ],
            "telecom": [
                {
                    "system": "phone",
                    "value": "+1 800-555-6789",
                    "use": "work"
                },
                {
                    "system": "email",
                    "value": "dr.james.smith@hospital.com",
                    "use": "work"
                }
            ],
            "address": [
                {
                    "line": ["123 Medical Plaza"],
                    "city": "MedCity",
                    "state": "CA",
                    "postalCode": "90410",
                    "country": "US"
                }
            ],
            "qualification": [
                {
                    "identifier": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/v2-2.7",
                            "value": "MD12345"
                        }
                    ],
                    "code": {
                        "coding": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/v2-0360/2.7",
                                "code": "MD",
                                "display": "Medical Doctor"
                            }
                        ]
                    },
                    "issuer": {
                        "display": "California Medical Board"
                    }
                }
            ]
        };
        uscore501:USCorePractitionerProfile practitioner = check parser:parse(practitionerJson, uscore501:USCorePractitionerProfile).ensureType();
        practitioners.push(practitioner);
    }

}

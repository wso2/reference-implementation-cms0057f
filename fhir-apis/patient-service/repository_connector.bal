import ballerina/http;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated uscore700:USCorePatientProfile[] patients = [];
isolated int createOperationNextId = 102;

public isolated function create(json payload) returns r4:FHIRError|uscore700:USCorePatientProfile {
    uscore700:USCorePatientProfile|error patient = parser:parse(payload, uscore700:USCorePatientProfile).ensureType();

    if patient is error {
        return r4:createFHIRError(patient.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            patient.id = (++createOperationNextId).toBalString();
        }

        lock {
            patients.push(patient.clone());
        }

        return patient;
    }
}

public isolated function getById(string id) returns r4:FHIRError|uscore700:USCorePatientProfile {
    lock {
        foreach var item in patients {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a Patient resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(string 'resource, map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        if searchParameters.keys().count() == 1 {
            lock {
                r4:BundleEntry[] bundleEntries = [];
                foreach var item in patients {
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
                    uscore700:USCorePatientProfile byId = check getById(searchParameters.get('key)[0]);
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

public isolated function update(json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function patchResource(string 'resource, string id, json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
}

public isolated function delete(string 'resource, string id) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

function init() returns error? {
    lock {
        json patientJson = {
            "resourceType": "Patient",
            "id": "101",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient"]
            },
            "identifier": [
                {
                    "system": "http://hospital.org/patients",
                    "value": "12345"
                }
            ],
            "name": [
                {
                    "use": "official",
                    "family": "Smith",
                    "given": ["John"]
                }
            ],
            "gender": "male",
            "birthDate": "1979-04-15",
            "address": [
                {
                    "line": ["123 Main St"],
                    "city": "Anytown",
                    "state": "CA",
                    "postalCode": "90210",
                    "country": "US"
                }
            ],
            "telecom": [
                {
                    "system": "phone",
                    "value": "+1 555-555-5555",
                    "use": "mobile"
                },
                {
                    "system": "email",
                    "value": "john@example.com"
                }
            ]
        };
        uscore700:USCorePatientProfile patient = check parser:parse(patientJson, uscore700:USCorePatientProfile).ensureType();
        patients.push(patient);
    }

}

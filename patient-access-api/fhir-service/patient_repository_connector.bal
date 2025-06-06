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

isolated uscore501:USCorePatientProfile[] patients = [];
isolated int createOperationNextId = 102;

public isolated function createPatient(json payload) returns r4:FHIRError|uscore501:USCorePatientProfile {
    uscore501:USCorePatientProfile|error patient = parser:parse(payload, uscore501:USCorePatientProfile).ensureType();

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

public isolated function getByIdPatient(string id) returns r4:FHIRError|uscore501:USCorePatientProfile {
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

public isolated function searchPatient(string 'resource, map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        if searchParameters.keys().length() == 1 {
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
                    uscore501:USCorePatientProfile byId = check getByIdPatient(searchParameters.get('key)[0]);
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

public isolated function updatePatient(json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function patchResourcePatient(string 'resource, string id, json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
}

public isolated function deletePatient(string 'resource, string id) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

function loadPatientData() returns error? {
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
                },
                {
                    "system": "urn:oid:wso2.healthcare.payer.memberID",
                    "value": "588675dc-e80e-4528-a78f-af10f9755f23",
                    "use": "secondary"
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
        uscore501:USCorePatientProfile patient = check parser:parse(patientJson, uscore501:USCorePatientProfile).ensureType();
        patients.push(patient);

        json patientJson2 = {
            "resourceType": "Patient",
            "id": "102",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient"]
            },
            "identifier": [
                {
                    "system": "http://hospital.org/patients",
                    "value": "54321"
                },
                {
                    "system": "urn:oid:wso2.healthcare.payer.memberID",
                    "value": "644d85af-aaf9-4068-ad23-1e55aedd5205",
                    "use": "secondary"
                }
            ],
            "name": [
                {
                    "use": "official",
                    "family": "Shaw",
                    "given": ["Jax"]
                }
            ],
            "gender": "female",
            "birthDate": "1985-08-22",
            "address": [
                {
                    "line": ["456 Elm Street"],
                    "city": "Oaktown",
                    "state": "NY",
                    "postalCode": "10001",
                    "country": "US"
                }
            ],
            "telecom": [
                {
                    "system": "phone",
                    "value": "+1 555-123-4567",
                    "use": "mobile"
                },
                {
                    "system": "email",
                    "value": "jax.shaw@example.com"
                }
            ]
        };
        uscore501:USCorePatientProfile patient2 = check parser:parse(patientJson2, uscore501:USCorePatientProfile).ensureType();
        patients.push(patient2);

    }

}

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
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.parser;

isolated international401:Coverage[] coverages = [];
isolated int createOperationNextIdCoverage = 367;

public isolated function createCoverage(international401:Coverage payload) returns r4:FHIRError|international401:Coverage {
    international401:Coverage|error coverage = parser:parseWithValidation(payload.toJson(), international401:Coverage).ensureType();

    if coverage is error {
        return r4:createFHIRError(coverage.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextIdCoverage += 1;
            coverage.id = (createOperationNextIdCoverage).toBalString();
        }

        lock {
            coverages.push(coverage.clone());
        }

        return coverage;
    }
}

public isolated function getByIdCoverage(string id) returns r4:FHIRError|international401:Coverage {
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

public isolated function updateCoverage(json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function patchResourceCoverage(string 'resource, string id, json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
}

public isolated function deleteCoverage(string 'resource, string id) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function searchCoverage(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        string? id = ();
        string? patient = ();

        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    id = searchParameters.get('key)[0];
                }
                "patient" => {
                    patient = searchParameters.get('key)[0];
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

        if id is string {
            international401:Coverage byId = check getByIdCoverage(id);

            bundle.entry = [
                {
                    'resource: byId
                }
            ];

            bundle.total = 1;
            return bundle;
        }

        international401:Coverage[] results;
        lock {
            results = coverages.clone();
        }

        if patient is string {
            results = getByPatientCoverage(patient, results);
        }

        r4:BundleEntry[] bundleEntries = [];

        foreach international401:Coverage item in results {
            r4:BundleEntry bundleEntry = {
                'resource: item
            };
            bundleEntries.push(bundleEntry);
        }
        bundle.entry = bundleEntries;
        bundle.total = results.length();
    }

    return bundle;
}

isolated function getByPatientCoverage(string patient, international401:Coverage[] targetArr) returns international401:Coverage[] {
    international401:Coverage[] filteredcoverages = [];
    foreach international401:Coverage coverage in targetArr {
        if coverage.beneficiary.reference == patient {
            filteredcoverages.push(coverage);
        }
    }
    return filteredcoverages;
}

function loadCoverageData() returns error? {
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
                "reference": "Patient/102"
            },
            "subscriberId": "UC-123456789",
            "beneficiary": {
                "reference": "Patient/102"
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
                "start": "2022-01-01",
                "end": "2026-12-31"
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

import ballerina/http;
import ballerina/log;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.parser;

isolated international401:DiagnosticReport[] diagReports = [];
isolated int createOperationNextId = 12344;

public isolated function createDiagnosticReport(international401:DiagnosticReport payload) returns r4:FHIRError|r4:FHIRParseError? {
    international401:DiagnosticReport|error diagReport = parser:parseWithValidation(payload.toJson(), international401:DiagnosticReport).ensureType();

    if diagReport is error {
        return r4:createFHIRError(diagReport.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId = createOperationNextId + 1;
            diagReport.id = createOperationNextId.toBalString();
        }

        lock {
            diagReports.push(diagReport.clone());
        }
    }
    return;
}

public isolated function getByIdDiagnosticReport(string id) returns r4:FHIRError|international401:DiagnosticReport {
    lock {
        foreach var item in diagReports {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a Patient resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function updateDiagnosticReport(json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function patchResourceDiagnosticReport(string 'resource, string id, json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
}

public isolated function deleteDiagnosticReport(string 'resource, string id) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function searchDiagnosticReport(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        if searchParameters.keys().count() == 0 {
            lock {
                r4:BundleEntry[] bundleEntries = [];
                foreach var item in diagReports {
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
                    international401:DiagnosticReport byId = check getByIdDiagnosticReport(searchParameters.get('key)[0]);
                    bundle.entry = [
                        {
                            'resource: byId
                        }
                    ];
                    return bundle;
                }
                "patient" => {

                    lock {
                        r4:BundleEntry[] bundleEntries = [];
                        foreach international401:DiagnosticReport item in diagReports {
                            string patientSearchParam = searchParameters.get('key)[0];
                            string patientReference = "";
                            if item.subject is r4:Reference {
                                patientReference = <string>(<r4:Reference>item.subject).reference;
                            }

                            log:printDebug(string `References are: ${patientSearchParam} and ${patientReference}`);

                            if patientSearchParam != patientReference {
                                continue;
                            }

                            r4:BundleEntry bundleEntry = {
                                'resource: item
                            };
                            bundleEntries.push(bundleEntry);

                        }
                        r4:Bundle bundleClone = bundle.clone();
                        bundleClone.entry = bundleEntries;
                        return bundleClone.clone();
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

function loadDiagnosticReportData() returns error? {
    lock {
        json patientJson1 = {
            "resourceType": "DiagnosticReport",
            "id": "lipids123",
            "identifier": [
                {
                    "system": "http://acme.com/lab/reports",
                    "value": "5234342"
                }
            ],
            "status": "final",
            "category": [
                {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/v2-0074",
                            "code": "HM"
                        }
                    ]
                }
            ],
            "code": {
                "coding": [
                    {
                        "system": "http://loinc.org",
                        "code": "24331-1",
                        "display": "Lipid 1996 panel - Serum or Plasma"
                    }
                ],
                "text": "Lipid Panel"
            },
            "subject": {
                "reference": "Patient/58c297c4-d684-4677-8024-01131d93835e"
            },
            "effectiveDateTime": "2011-03-04T08:30:00+11:00",
            "issued": "2013-01-27T11:45:33+11:00",
            "performer": [
                {
                    "reference": "Organization/1832473e-2fe0-452d-abe9-3cdb9879522f",
                    "display": "Acme Laboratory, Inc"
                }
            ],
            "result": [
                {
                    "id": "1",
                    "reference": "Observation/cholesterol"
                },
                {
                    "id": "2",
                    "reference": "Observation/triglyceride"
                }
            ]
        };

        json patientJson2 = {
            "resourceType": "DiagnosticReport",
            "id": "lipids456",
            "identifier": [
                {
                    "system": "http://acme.com/lab/reports",
                    "value": "5234342"
                }
            ],
            "status": "final",
            "category": [
                {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/v2-0074",
                            "code": "HM"
                        }
                    ]
                }
            ],
            "code": {
                "coding": [
                    {
                        "system": "http://loinc.org",
                        "code": "24331-1",
                        "display": "Lipid 1996 panel - Serum or Plasma"
                    }
                ],
                "text": "Lipid Panel"
            },
            "subject": {
                "reference": "Patient/58c297c4-d684-4677-8024-01131d93835e"
            },
            "effectiveDateTime": "2011-03-04T08:30:00+11:00",
            "issued": "2013-01-27T11:45:33+11:00",
            "performer": [
                {
                    "reference": "Organization/1832473e-2fe0-452d-abe9-3cdb9879522f",
                    "display": "Acme Laboratory, Inc"
                }
            ],
            "result": [
                {
                    "id": "1",
                    "reference": "Observation/cholesterol"
                },
                {
                    "id": "2",
                    "reference": "Observation/triglyceride"
                }
            ]
        };
        json patientJson3 = {
            "resourceType": "DiagnosticReport",
            "id": "lipids789",
            "identifier": [
                {
                    "system": "http://acme.com/lab/reports",
                    "value": "5234342"
                }
            ],
            "status": "final",
            "category": [
                {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/v2-0074",
                            "code": "HM"
                        }
                    ]
                }
            ],
            "code": {
                "coding": [
                    {
                        "system": "http://loinc.org",
                        "code": "24331-1",
                        "display": "Lipid 1996 panel - Serum or Plasma"
                    }
                ],
                "text": "Lipid Panel"
            },
            "subject": {
                "reference": "Patient/58c297c4-d684-4677-8024-01131d93835e"
            },
            "effectiveDateTime": "2011-03-04T08:30:00+11:00",
            "issued": "2013-01-27T11:45:33+11:00",
            "performer": [
                {
                    "reference": "Organization/1832473e-2fe0-452d-abe9-3cdb9879522f",
                    "display": "Acme Laboratory, Inc"
                }
            ],
            "result": [
                {
                    "id": "1",
                    "reference": "Observation/cholesterol"
                },
                {
                    "id": "2",
                    "reference": "Observation/triglyceride"
                }
            ]
        };
        international401:DiagnosticReport patient = check parser:parse(patientJson1, international401:DiagnosticReport).ensureType();
        international401:DiagnosticReport patient2 = check parser:parse(patientJson2, international401:DiagnosticReport).ensureType();
        international401:DiagnosticReport patient3 = check parser:parse(patientJson3, international401:DiagnosticReport).ensureType();

        diagReports.push(patient);
        diagReports.push(patient2);
        diagReports.push(patient3);
    }

}

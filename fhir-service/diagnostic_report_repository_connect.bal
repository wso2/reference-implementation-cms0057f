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
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;

isolated DiagnosticReport[] diagnosticReports = [];
isolated int createDiagnosticReportNextId = 87920;

public isolated function createDiagnosticReport(DiagnosticReport diagnosticReport) returns r4:FHIRError|DiagnosticReport {
    lock {
        createDiagnosticReportNextId = createDiagnosticReportNextId + 1;
        diagnosticReport.id = createDiagnosticReportNextId.toBalString();
    }

    lock {
        DiagnosticReport|error parsed = parser:parse(diagnosticReport.clone().toJson()).ensureType();
        if parsed is DiagnosticReport {
            diagnosticReports.push(parsed);
        }

    }
    return diagnosticReport;

}

public isolated function getByIdDiagnosticReport(string id) returns r4:FHIRError|DiagnosticReport {
    lock {
        foreach var item in diagnosticReports {
            if item.id == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a DiagnosticReport resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function searchDiagnosticReport(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
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
        DiagnosticReport[] results;
        lock {
            results = diagnosticReports.clone();
        }

        if id is string {
            DiagnosticReport byId = check getByIdDiagnosticReport(id);
            results.push(byId);
        }

        if patient is string {
            results = getByPatientDiagnosticReport(patient, results);
        }

        r4:BundleEntry[] bundleEntries = [];
        foreach DiagnosticReport item in results {
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

isolated function getByPatientDiagnosticReport(string patient, DiagnosticReport[] diagnosticReports) returns DiagnosticReport[] {
    DiagnosticReport[] filteredDiagnosticReport = [];
    foreach DiagnosticReport diagnosticReport in diagnosticReports {
        if diagnosticReport.subject.reference == string `Patient/${patient}` {
            filteredDiagnosticReport.push(diagnosticReport);
        }
    }
    return filteredDiagnosticReport;
}

function loadDiagnosticReportData() returns error? {
    lock {
        json diagnosticReportJson1 = {
            "resourceType": "DiagnosticReport",
            "id": "87920",
            "meta": {
                "profile": [
                    "http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-lab"
                ]
            },
            "status": "final",
            "category": [
                {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/v2-0074",
                            "code": "LAB",
                            "display": "Laboratory"
                        }
                    ]
                }
            ],
            "code": {
                "coding": [
                    {
                        "system": "http://loinc.org",
                        "code": "58410-2",
                        "display": "Complete blood count panel"
                    }
                ],
                "text": "Complete Blood Count (CBC)"
            },
            "subject": {
                "reference": "Patient/101"
            },
            "effectiveDateTime": "2025-06-05T10:00:00-05:00",
            "issued": "2025-06-05T12:00:00-05:00",
            "result": [
                {
                    "reference": "Observation/observation-wbc"
                },
                {
                    "reference": "Observation/observation-hemoglobin"
                }
            ]
        };

        json diagnosticReportJson2 = {
            "resourceType": "DiagnosticReport",
            "id": "87919",
            "meta": {
                "profile": [
                    "http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-lab"
                ]
            },
            "status": "final",
            "category": [
                {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/v2-0074",
                            "code": "LAB",
                            "display": "Laboratory"
                        }
                    ]
                }
            ],
            "code": {
                "coding": [
                    {
                        "system": "http://loinc.org",
                        "code": "24331-1",
                        "display": "Lipid panel with direct LDL"
                    }
                ],
                "text": "Lipid Panel"
            },
            "subject": {
                "reference": "Patient/101"
            },
            "effectiveDateTime": "2025-06-03T09:00:00-05:00",
            "issued": "2025-06-03T11:00:00-05:00",
            "result": [
                {
                    "reference": "Observation/observation-cholesterol"
                },
                {
                    "reference": "Observation/observation-ldl"
                },
                {
                    "reference": "Observation/observation-hdl"
                },
                {
                    "reference": "Observation/observation-triglycerides"
                }
            ]
        };

        json diagnosticReportJson3 = {
            "resourceType": "DiagnosticReport",
            "id": "87918",
            "meta": {
                "profile": [
                    "http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-note"
                ]
            },
            "status": "final",
            "category": [
                {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/v2-0074",
                            "code": "RAD",
                            "display": "Radiology"
                        }
                    ]
                }
            ],
            "code": {
                "coding": [
                    {
                        "system": "http://loinc.org",
                        "code": "30746-0",
                        "display": "Chest X-ray study"
                    }
                ],
                "text": "Chest X-ray"
            },
            "subject": {
                "reference": "Patient/102"
            },
            "effectiveDateTime": "2025-06-01T08:00:00-05:00",
            "issued": "2025-06-01T10:00:00-05:00",
            "presentedForm": [
                {
                    "contentType": "application/pdf",
                    "language": "en",
                    "title": "Chest X-ray Report",
                    "url": "http://example.org/fhir/Binary/chest-xray-report.pdf"
                }
            ],
            "conclusion": "Normal chest radiograph. No signs of pneumonia or pleural effusion."
        };

        DiagnosticReport diagnosticReport1 = check parser:parse(diagnosticReportJson1).ensureType();
        DiagnosticReport diagnosticReport2 = check parser:parse(diagnosticReportJson2).ensureType();
        DiagnosticReport diagnosticReport3 = check parser:parse(diagnosticReportJson3).ensureType();
        diagnosticReports.push(diagnosticReport1, diagnosticReport2, diagnosticReport3);
    }
}

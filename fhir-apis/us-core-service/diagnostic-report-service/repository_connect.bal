import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated uscore700:USCoreDiagnosticReportProfileLaboratoryReporting[] diagnosticReport = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|uscore700:USCoreDiagnosticReportProfileLaboratoryReporting {
    uscore700:USCoreDiagnosticReportProfileLaboratoryReporting|error careTeam = parser:parse(payload, uscore700:USCoreDiagnosticReportProfileLaboratoryReporting).ensureType();

    if careTeam is error {
        return r4:createFHIRError(careTeam.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            careTeam.id = (createOperationNextId).toBalString();
        }

        lock {
            diagnosticReport.push(careTeam.clone());
        }

        return careTeam;
    }
}

public isolated function getById(string id) returns r4:FHIRError|uscore700:USCoreDiagnosticReportProfileLaboratoryReporting {
    lock {
        foreach var item in diagnosticReport {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a careTeam resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    uscore700:USCoreDiagnosticReportProfileLaboratoryReporting byId = check getById(searchParameters.get('key)[0]);
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
        foreach var item in diagnosticReport {
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
        json careTeamJson = {
            "resourceType": "DiagnosticReport",
            "id": "12344",
            "meta": {
                "lastUpdated": "2005-07-06T15:29:58.597Z",
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-lab|7.0.0"]
            },
            "text": {
                "status": "generated",
                "div": string `<div xmlns="http://www.w3.org/1999/xhtml"><h2><span title="Codes: {http://loinc.org 58410-2}">CBC panel - Blood by Automated count</span> (<span title="Codes: {http://terminology.hl7.org/CodeSystem/v2-0074 LAB}">Laboratory</span>) </h2><table class="grid"><tr><td>Subject</td><td><b>Amy V. Baxter </b> female, DoB: 1987-02-20 ( Medical Record Number/1032702\u00a0(use:\u00a0usual))</td></tr><tr><td>When For</td><td>2005-07-05</td></tr><tr><td>Reported</td><td>2005-07-06 11:45:33+0000</td></tr></table><p><b>Report Details</b></p><table class="grid"><tr><td><b>Code</b></td><td><b>Value</b></td><td><b>Reference Range</b></td><td><b>Flags</b></td><td><b>When For</b></td></tr><tr><td><a href="Observation-cbc-leukocytes.html"><span title="Codes: {http://loinc.org 6690-2}">WBCs</span></a></td><td>10 10*3/uL</td><td><span title="Codes: {http://terminology.hl7.org/CodeSystem/referencerange-meaning normal}">Normal Range</span>: 4.5 10*3/uL - 11 10*3/uL</td><td><span title="Codes: {http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation N}">Normal</span></td><td>2005-07-05</td></tr><tr><td><a href="Observation-cbc-erythrocytes.html"><span title="Codes: {http://loinc.org 789-8}">Erythrocytes</span></a></td><td>4.58 10*6/uL</td><td><span title="Codes: {http://terminology.hl7.org/CodeSystem/referencerange-meaning normal}">Normal Range</span>: 4.1 10*6/uL - 6.1 10*6/uL</td><td><span title="Codes: {http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation N}">Normal</span></td><td>2005-07-05</td></tr><tr><td><a href="Observation-cbc-hemoglobin.html"><span title="Codes: {http://loinc.org 718-7}">Hemoglobin</span></a></td><td>17 g/dL</td><td><span title="Codes: {http://terminology.hl7.org/CodeSystem/referencerange-meaning normal}">Normal Range</span>: 16.5 g/dL - 21.5 g/dL</td><td><span title="Codes: {http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation N}">Normal</span></td><td>2005-07-05</td></tr><tr><td><a href="Observation-cbc-hematocrit.html"><span title="Codes: {http://loinc.org 4544-3}">Hematocrit</span></a></td><td>43 %</td><td><span title="Codes: {http://terminology.hl7.org/CodeSystem/referencerange-meaning normal}">Normal Range</span>: 46 % - 38 %</td><td><span title="Codes: {http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation N}">Normal</span></td><td>2005-07-05</td></tr><tr><td><a href="Observation-cbc-mcv.html"><span title="Codes: {http://loinc.org 787-2}">MCV</span></a></td><td>85 fL</td><td><span title="Codes: {http://terminology.hl7.org/CodeSystem/referencerange-meaning normal}">Normal Range</span>: 87.3 fL - 82.4 fL</td><td><span title="Codes: {http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation N}">Normal</span></td><td>2005-07-05</td></tr><tr><td><a href="Observation-cbc-mch.html"><span title="Codes: {http://loinc.org 785-6}">MCH</span></a></td><td>30 pg</td><td><span title="Codes: {http://terminology.hl7.org/CodeSystem/referencerange-meaning normal}">Normal Range</span>: 33.2 pg - 27.5 pg</td><td><span title="Codes: {http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation N}">Normal</span></td><td>2005-07-05</td></tr><tr><td><a href="Observation-cbc-mchc.html"><span title="Codes: {http://loinc.org 786-4}">MCHC</span></a></td><td>34.7 g/dL</td><td><span title="Codes: {http://terminology.hl7.org/CodeSystem/referencerange-meaning normal}">Normal Range</span>: 30 g/dL - 34 g/dL</td><td><span title="Codes: {http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation H}">High</span></td><td>2005-07-05</td></tr><tr><td><a href="Observation-cbc-platelets.html"><span title="Codes: {http://loinc.org 777-3}">Platelets</span></a></td><td>200 10*3/uL</td><td><span title="Codes: {http://terminology.hl7.org/CodeSystem/referencerange-meaning normal}">Normal Range</span>: 150 10*3/uL - 450 10*3/uL</td><td><span title="Codes: {http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation N}">Normal</span></td><td>2005-07-05</td></tr></table></div>`
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
                        "display": "CBC panel - Blood by Automated count"
                    }
                ]
            },
            "subject": {
                "reference": "Patient/example",
                "display": "Amy Shaw"
            },
            "encounter": {
                "reference": "Encounter/example-1",
                "display": "Office Visit"
            },
            "effectiveDateTime": "2005-07-05",
            "issued": "2005-07-06T11:45:33Z",
            "performer": [
                {
                    "reference": "Organization/acme-lab",
                    "display": "Acme Laboratory, Inc"
                }
            ],
            "result": [
                {
                    "reference": "Observation/cbc-leukocytes",
                    "display": "LEUKOCYTES"
                },
                {
                    "reference": "Observation/cbc-erythrocytes",
                    "display": "ERYTHROCYTES"
                },
                {
                    "reference": "Observation/cbc-hemoglobin",
                    "display": "HEMOGLOBIN"
                },
                {
                    "reference": "Observation/cbc-hematocrit",
                    "display": "HEMATOCRIT"
                },
                {
                    "reference": "Observation/cbc-mcv",
                    "display": "MCV"
                },
                {
                    "reference": "Observation/cbc-mch",
                    "display": "MCH"
                },
                {
                    "reference": "Observation/cbc-mchc",
                    "display": "MCHC"
                },
                {
                    "reference": "Observation/cbc-platelets",
                    "display": "PLATELETS"
                }
            ]
        };
        uscore700:USCoreDiagnosticReportProfileLaboratoryReporting careTeam = check parser:parse(careTeamJson, uscore700:USCoreDiagnosticReportProfileLaboratoryReporting).ensureType();
        diagnosticReport.push(careTeam.clone());
    }
}

import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincidrugformulary210;
import ballerinax/health.fhir.r4.parser;

isolated GraphDefinition[] graphDefinitions = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|GraphDefinition {
    GraphDefinition|error graphDefinition = parser:parse(payload, davincidrugformulary210:PayerInsurancePlanBulkDataGraphDefinition).ensureType();

    if graphDefinition is error {
        graphDefinition = parser:parse(payload, davincidrugformulary210:FormularyBulkDataGraphDefinition).ensureType();
    }

    if graphDefinition is error {
        return r4:createFHIRError(graphDefinition.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            graphDefinition.id = (createOperationNextId).toBalString();
        }

        lock {
            graphDefinitions.push(graphDefinition.clone());
        }

        return graphDefinition;
    }
}

public isolated function getById(string id) returns r4:FHIRError|GraphDefinition {
    lock {
        foreach var item in graphDefinitions {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a Patient resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    GraphDefinition byId = check getById(searchParameters.get('key)[0]);
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
        foreach var item in graphDefinitions {
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
        json payerInsurancePlanGraphDefinitionJson = {
            "resourceType": "GraphDefinition",
            "id": "12344",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-PayerInsurancePlanBulkDataGraphDefinition"]
            },
            "text": {
                "status": "extensions",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p class=\"res-header-id\"><b>Generated Narrative: GraphDefinition PayerInsurancePlanGraphDefinition</b></p><a name=\"PayerInsurancePlanGraphDefinition\"> </a><a name=\"hcPayerInsurancePlanGraphDefinition\"> </a><a name=\"PayerInsurancePlanGraphDefinition-en-US\"> </a><p><b>StructureDefinition Work Group</b>: phx</p><p><b>StructureDefinition Standards Status</b>: trial-use</p><p><b>version</b>: 2.0.1</p><p><b>name</b>: PayerInsurancePlanGraphDefinition</p><p><b>status</b>: Active</p><p><b>date</b>: 2023-11-03 19:55:21-0700</p><p><b>publisher</b>: HL7 International / Pharmacy</p><p><b>contact</b>: HL7 International / Pharmacy: <a href=\"http://www.hl7.org/Special/committees/medication\">http://www.hl7.org/Special/committees/medication</a>,<a href=\"mailto:pharmacy@lists.HL7.org\">pharmacy@lists.HL7.org</a></p><p><b>jurisdiction</b>: <span title=\"Codes:{urn:iso:std:iso:3166 US}\">United States of America</span></p><p><b>start</b>: InsurancePlan</p><p><b>profile</b>: <a href=\"StructureDefinition-usdf-PayerInsurancePlan.html\">Payer Insurance Plan</a></p><blockquote><p><b>link</b></p><p><b>path</b>: InsurancePlan.coverageArea</p><h3>Targets</h3><table class=\"grid\"><tr><td style=\"display: none\">-</td><td><b>Type</b></td><td><b>Profile</b></td></tr><tr><td style=\"display: none\">*</td><td>Location</td><td><a href=\"StructureDefinition-usdf-InsurancePlanLocation.html\">Insurance Plan Location</a></td></tr></table></blockquote><blockquote><p><b>link</b></p><p><b>path</b>: InsurancePlan.coverage.extension.where(url=http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-FormularyReference-extension).valueReference</p><blockquote><p><b>target</b></p><p><b>type</b>: InsurancePlan</p><p><b>profile</b>: <a href=\"StructureDefinition-usdf-Formulary.html\">Formulary</a></p><blockquote><p><b>link</b></p><blockquote><p><b>target</b></p><p><b>type</b>: Basic</p><p><b>params</b>: formulary={ref}</p><p><b>profile</b>: <a href=\"StructureDefinition-usdf-FormularyItem.html\">Formulary Item</a></p><blockquote><p><b>link</b></p><p><b>path</b>: Basic.subject</p><h3>Targets</h3><table class=\"grid\"><tr><td style=\"display: none\">-</td><td><b>Type</b></td><td><b>Profile</b></td></tr><tr><td style=\"display: none\">*</td><td>MedicationKnowledge</td><td><a href=\"StructureDefinition-usdf-FormularyDrug.html\">Formulary Drug</a></td></tr></table></blockquote></blockquote></blockquote></blockquote></blockquote></div>"
            },
            "extension": [
                {
                    "url": "http://hl7.org/fhir/StructureDefinition/structuredefinition-wg",
                    "valueCode": "phx"
                },
                {
                    "url": "http://hl7.org/fhir/StructureDefinition/structuredefinition-standards-status",
                    "valueCode": "trial-use"
                }
            ],
            "version": "2.0.1",
            "name": "PayerInsurancePlanGraphDefinition",
            "status": "active",
            "date": "2023-11-03T19:55:21-07:00",
            "publisher": "HL7 International / Pharmacy",
            "contact": [
                {
                    "name": "HL7 International / Pharmacy",
                    "telecom": [
                        {
                            "system": "url",
                            "value": "http://www.hl7.org/Special/committees/medication"
                        },
                        {
                            "system": "email",
                            "value": "pharmacy@lists.HL7.org"
                        }
                    ]
                }
            ],
            "jurisdiction": [
                {
                    "coding": [
                        {
                            "system": "urn:iso:std:iso:3166",
                            "code": "US"
                        }
                    ]
                }
            ],
            "start": "InsurancePlan",
            "profile": "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-PayerInsurancePlan",
            "link": [
                {
                    "path": "InsurancePlan.coverageArea",
                    "target": [
                        {
                            "type": "Location",
                            "profile": "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-InsurancePlanLocation"
                        }
                    ]
                },
                {
                    "path": "InsurancePlan.coverage.extension.where(url=http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-FormularyReference-extension).valueReference",
                    "target": [
                        {
                            "type": "InsurancePlan",
                            "profile": "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-Formulary",
                            "link": [
                                {
                                    "target": [
                                        {
                                            "type": "Basic",
                                            "params": "formulary={ref}",
                                            "profile": "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-FormularyItem",
                                            "link": [
                                                {
                                                    "path": "Basic.subject",
                                                    "target": [
                                                        {
                                                            "type": "MedicationKnowledge",
                                                            "profile": "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-FormularyDrug"
                                                        }
                                                    ]
                                                }
                                            ]
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                }
            ]
        };

        GraphDefinition graphDefinition = check parser:parse(payerInsurancePlanGraphDefinitionJson, davincidrugformulary210:PayerInsurancePlanBulkDataGraphDefinition).ensureType();
        graphDefinitions.push(graphDefinition.clone());
    }
}

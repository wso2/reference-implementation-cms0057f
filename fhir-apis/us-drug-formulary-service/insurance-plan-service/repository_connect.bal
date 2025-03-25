import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincidrugformulary210;
import ballerinax/health.fhir.r4.parser;

isolated InsurancePlan[] insurancePlans = [];
isolated int createOperationNextId = 12345;

public isolated function create(json payload) returns r4:FHIRError|InsurancePlan {
    InsurancePlan|error insurancePlan = parser:parse(payload, davincidrugformulary210:PayerInsurancePlan).ensureType();

    if insurancePlan is error {
        insurancePlan = parser:parse(payload, davincidrugformulary210:Formulary).ensureType();
    }

    if insurancePlan is error {
        return r4:createFHIRError(insurancePlan.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            insurancePlan.id = (createOperationNextId).toBalString();
        }

        lock {
            insurancePlans.push(insurancePlan.clone());
        }

        return insurancePlan;
    }
}

public isolated function getById(string id) returns r4:FHIRError|InsurancePlan {
    lock {
        foreach var item in insurancePlans {
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
                    InsurancePlan byId = check getById(searchParameters.get('key)[0]);
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
        foreach var item in insurancePlans {
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
        json insurancePlanJson = {
            "resourceType": "InsurancePlan",
            "id": "12344",
            "meta": {
                "lastUpdated": "2021-08-22T18:36:03.000+00:00",
                "profile": ["http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-PayerInsurancePlan"]
            },
            "text": {
                "status": "extensions",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p class=\"res-header-id\"><b>Generated Narrative: InsurancePlan PayerInsurancePlanA1002</b></p><a name=\"PayerInsurancePlanA1002\"> </a><a name=\"hcPayerInsurancePlanA1002\"> </a><a name=\"PayerInsurancePlanA1002-en-US\"> </a><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Last updated: 2021-08-22 18:36:03+0000</p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-usdf-PayerInsurancePlan.html\">Payer Insurance Plan</a></p></div><p><b>identifier</b>: A1002</p><p><b>status</b>: Active</p><p><b>type</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/InsuranceProductTypeCS mediadv}\">Medicare Advantage</span></p><p><b>name</b>: Sample Medicare Advantage Plan A1002</p><p><b>period</b>: 2021-01-01 --&gt; 2021-12-31</p><p><b>coverageArea</b>: <a href=\"Location-StateOfCTLocation.html\">Location State of CT Area</a></p><blockquote><p><b>contact</b></p><p><b>purpose</b>: <span title=\"Codes:{http://terminology.hl7.org/CodeSystem/contactentity-type PATINF}\">Patient</span></p><p><b>telecom</b>: <a href=\"tel:+1(888)555-1002\">+1 (888) 555-1002</a></p></blockquote><blockquote><p><b>contact</b></p><p><b>purpose</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-PlanContactTypeCS-TEMPORARY-TRIAL-USE MARKETING}\">Marketting</span></p><p><b>name</b>: Sample Medicare Advantage Plan Marketing Website</p><p><b>telecom</b>: <a href=\"http://url/to/health/plan/information\">http://url/to/health/plan/information</a></p></blockquote><blockquote><p><b>contact</b></p><p><b>purpose</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-PlanContactTypeCS-TEMPORARY-TRIAL-USE SUMMARY}\">Summary</span></p><p><b>name</b>: Sample Medicare Advantage Drug Plan Benefit Website</p><p><b>telecom</b>: <a href=\"http://url/to/health/plan/information\">http://url/to/health/plan/information</a></p></blockquote><blockquote><p><b>contact</b></p><p><b>purpose</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-PlanContactTypeCS-TEMPORARY-TRIAL-USE FORMULARY}\">Formulary</span></p><p><b>name</b>: Sample Medicare Advantage Drug Plan Formulary Website</p><p><b>telecom</b>: <a href=\"http://url/to/health/plan/information\">http://url/to/health/plan/information</a></p></blockquote><blockquote><p><b>coverage</b></p><p><b>Formulary Reference</b>: <a href=\"InsurancePlan-FormularyD1002.html\">InsurancePlan Sample Medicare Advantage Part D Formulary D1002</a></p><p><b>type</b>: <span title=\"Codes:{http://terminology.hl7.org/CodeSystem/v3-ActCode DRUGPOL}\">drug policy</span></p><h3>Benefits</h3><table class=\"grid\"><tr><td style=\"display: none\">-</td><td><b>Type</b></td></tr><tr><td style=\"display: none\">*</td><td><span title=\"Codes:{http://terminology.hl7.org/CodeSystem/insurance-plan-type drug}\">Drug</span></td></tr></table></blockquote><blockquote><p><b>plan</b></p><p><b>type</b>: <span title=\"Codes:{http://terminology.hl7.org/CodeSystem/insurance-plan-type drug}\">Drug</span></p><blockquote><p><b>specificCost</b></p><p><b>category</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-PharmacyBenefitTypeCS-TEMPORARY-TRIAL-USE 1-month-in-retail}\">1 month in network retail</span></p><blockquote><p><b>benefit</b></p><p><b>type</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-DrugTierCS-TEMPORARY-TRIAL-USE brand}\">Brand</span></p><blockquote><p><b>cost</b></p><p><b>type</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-BenefitCostTypeCS-TEMPORARY-TRIAL-USE copay}\">Copay</span></p><p><b>qualifiers</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-CostShareOptionCS-TEMPORARY-TRIAL-USE after-deductible}\">After Deductible</span></p><p><b>value</b>: 20 $<span style=\"background: LightGoldenRodYellow\"> (Details: unknown  codeUSD = 'United States dollar')</span></p></blockquote><blockquote><p><b>cost</b></p><p><b>type</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-BenefitCostTypeCS-TEMPORARY-TRIAL-USE coinsurance}\">Coinsurance</span></p><p><b>qualifiers</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-CostShareOptionCS-TEMPORARY-TRIAL-USE after-deductible}\">After Deductible</span></p><p><b>value</b>: 20 %<span style=\"background: LightGoldenRodYellow\"> (Details: UCUM  code% = '%')</span></p></blockquote></blockquote></blockquote></blockquote></div>"
            },
            "identifier": [
                {
                    "value": "A1002"
                }
            ],
            "status": "active",
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/InsuranceProductTypeCS",
                            "code": "mediadv"
                        }
                    ]
                }
            ],
            "name": "Sample Medicare Advantage Plan A1002",
            "period": {
                "start": "2021-01-01",
                "end": "2021-12-31"
            },
            "coverageArea": [
                {
                    "reference": "Location/StateOfCTLocation"
                }
            ],
            "contact": [
                {
                    "purpose": {
                        "coding": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/contactentity-type",
                                "code": "PATINF"
                            }
                        ]
                    },
                    "telecom": [
                        {
                            "system": "phone",
                            "value": "+1 (888) 555-1002"
                        }
                    ]
                },
                {
                    "purpose": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-PlanContactTypeCS-TEMPORARY-TRIAL-USE",
                                "code": "MARKETING"
                            }
                        ]
                    },
                    "name": {
                        "text": "Sample Medicare Advantage Plan Marketing Website"
                    },
                    "telecom": [
                        {
                            "system": "url",
                            "value": "http://url/to/health/plan/information"
                        }
                    ]
                },
                {
                    "purpose": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-PlanContactTypeCS-TEMPORARY-TRIAL-USE",
                                "code": "SUMMARY"
                            }
                        ]
                    },
                    "name": {
                        "text": "Sample Medicare Advantage Drug Plan Benefit Website"
                    },
                    "telecom": [
                        {
                            "system": "url",
                            "value": "http://url/to/health/plan/information"
                        }
                    ]
                },
                {
                    "purpose": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-PlanContactTypeCS-TEMPORARY-TRIAL-USE",
                                "code": "FORMULARY"
                            }
                        ]
                    },
                    "name": {
                        "text": "Sample Medicare Advantage Drug Plan Formulary Website"
                    },
                    "telecom": [
                        {
                            "system": "url",
                            "value": "http://url/to/health/plan/information"
                        }
                    ]
                }
            ],
            "coverage": [
                {
                    "extension": [
                        {
                            "url": "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-FormularyReference-extension",
                            "valueReference": {
                                "reference": "InsurancePlan/FormularyD1002"
                            }
                        }
                    ],
                    "type": {
                        "coding": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                                "code": "DRUGPOL"
                            }
                        ]
                    },
                    "benefit": [
                        {
                            "type": {
                                "coding": [
                                    {
                                        "system": "http://terminology.hl7.org/CodeSystem/insurance-plan-type",
                                        "code": "drug",
                                        "display": "Drug"
                                    }
                                ]
                            }
                        }
                    ]
                }
            ],
            "plan": [
                {
                    "type": {
                        "coding": [
                            {
                                "system": "http://terminology.hl7.org/CodeSystem/insurance-plan-type",
                                "code": "drug",
                                "display": "Drug"
                            }
                        ]
                    },
                    "specificCost": [
                        {
                            "category": {
                                "coding": [
                                    {
                                        "system": "http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-PharmacyBenefitTypeCS-TEMPORARY-TRIAL-USE",
                                        "code": "1-month-in-retail",
                                        "display": "1 month in network retail"
                                    }
                                ]
                            },
                            "benefit": [
                                {
                                    "type": {
                                        "coding": [
                                            {
                                                "system": "http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-DrugTierCS-TEMPORARY-TRIAL-USE",
                                                "code": "brand",
                                                "display": "Brand"
                                            }
                                        ]
                                    },
                                    "cost": [
                                        {
                                            "type": {
                                                "coding": [
                                                    {
                                                        "system": "http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-BenefitCostTypeCS-TEMPORARY-TRIAL-USE",
                                                        "code": "copay",
                                                        "display": "Copay"
                                                    }
                                                ]
                                            },
                                            "qualifiers": [
                                                {
                                                    "coding": [
                                                        {
                                                            "system": "http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-CostShareOptionCS-TEMPORARY-TRIAL-USE",
                                                            "code": "after-deductible",
                                                            "display": "After Deductible"
                                                        }
                                                    ]
                                                }
                                            ],
                                            "value": {
                                                "value": 20,
                                                "unit": "$",
                                                "system": "urn:iso:std:iso:4217",
                                                "code": "USD"
                                            }
                                        },
                                        {
                                            "type": {
                                                "coding": [
                                                    {
                                                        "system": "http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-BenefitCostTypeCS-TEMPORARY-TRIAL-USE",
                                                        "code": "coinsurance",
                                                        "display": "Coinsurance"
                                                    }
                                                ]
                                            },
                                            "qualifiers": [
                                                {
                                                    "coding": [
                                                        {
                                                            "system": "http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-CostShareOptionCS-TEMPORARY-TRIAL-USE",
                                                            "code": "after-deductible",
                                                            "display": "After Deductible"
                                                        }
                                                    ]
                                                }
                                            ],
                                            "value": {
                                                "value": 20,
                                                "system": "http://unitsofmeasure.org",
                                                "code": "%"
                                            }
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                }
            ]
        };

        // for PayerInsurancePlan
        InsurancePlan insurancePlan = check parser:parse(insurancePlanJson, davincidrugformulary210:PayerInsurancePlan).ensureType();
        insurancePlans.push(insurancePlan.clone());

        json formularyJson = {
            "resourceType": "InsurancePlan",
            "id": "12345",
            "meta": {
                "lastUpdated": "2021-08-22T18:36:03.000+00:00",
                "profile": ["http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-Formulary"]
            },
            "text": {
                "status": "generated",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p class=\"res-header-id\"><b>Generated Narrative: InsurancePlan FormularyD1002</b></p><a name=\"FormularyD1002\"> </a><a name=\"hcFormularyD1002\"> </a><a name=\"FormularyD1002-en-US\"> </a><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Last updated: 2021-08-22 18:36:03+0000</p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-usdf-Formulary.html\">Formulary</a></p></div><p><b>identifier</b>: D1002</p><p><b>status</b>: Active</p><p><b>type</b>: <span title=\"Codes:{http://terminology.hl7.org/CodeSystem/v3-ActCode DRUGPOL}\">drug policy</span></p><p><b>name</b>: Sample Medicare Advantage Part D Formulary D1002</p><p><b>period</b>: 2021-01-01 --&gt; 2021-12-31</p></div>"
            },
            "identifier": [
                {
                    "value": "D1002"
                }
            ],
            "status": "active",
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                            "code": "DRUGPOL"
                        }
                    ]
                }
            ],
            "name": "Sample Medicare Advantage Part D Formulary D1002",
            "period": {
                "start": "2021-01-01",
                "end": "2021-12-31"
            }
        };

        // for Formulary
        insurancePlan = check parser:parse(formularyJson, davincidrugformulary210:Formulary).ensureType();
        insurancePlans.push(insurancePlan.clone());
    }
}

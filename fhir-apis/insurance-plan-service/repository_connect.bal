import ballerina/http;
import ballerinax/health.fhir.r4 as r4;
import ballerinax/health.fhir.r4.davinciplannet120;
import ballerinax/health.fhir.r4.davincidrugformulary210;
import ballerinax/health.fhir.r4.parser;

isolated InsurancePlan[] insurancePlans = [];
isolated int createinsurancePlanNextId = 9002;

// Use davincidrugformulary210:Formulary profile is the default profile
final string DEFAULT_PROFILE = "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-Formulary";

public isolated function create(json payload) returns r4:FHIRError|InsurancePlan {
    InsurancePlan|error insurancePlan = parser:parse(payload, davincidrugformulary210:Formulary).ensureType();
    if insurancePlan is error {
        insurancePlan = parser:parse(payload, davincidrugformulary210:PayerInsurancePlan).ensureType();
    }
    if insurancePlan is error {
        insurancePlan = parser:parse(payload, davinciplannet120:PlannetInsurancePlan).ensureType();
    }

    if insurancePlan is error {
        return r4:createFHIRError(insurancePlan.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createinsurancePlanNextId += 1;
            insurancePlan.id = (createinsurancePlanNextId).toBalString();
        }
        lock {
            insurancePlans.push(insurancePlan.clone());
        }
        return insurancePlan;
    }
}

public isolated function getById(string id, InsurancePlan[]? targetInsurancePlanArr = ()) returns r4:FHIRError|InsurancePlan {
    InsurancePlan[] insurancePlanArr;
    if targetInsurancePlanArr is InsurancePlan[] {
        insurancePlanArr = targetInsurancePlanArr;
    } else {
        lock {
            insurancePlanArr = insurancePlans.clone();
        }
    }
    
    lock {
        foreach var item in insurancePlanArr {
            if item.id == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find an insurancePlan resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

isolated function getByProfile(string profile) returns r4:FHIRError|InsurancePlan[] {
    lock {
        InsurancePlan[] items = [];
        
        foreach var item in insurancePlans {
            r4:Meta? itemMeta = item.meta;

            if itemMeta is r4:Meta {
                r4:canonical[]? profileArray = itemMeta.profile;

                if profileArray is r4:canonical[] {
                    string profileValue = profileArray[0].toString();

                    if profileValue == profile {
                        items.push(item.clone());
                    }
                }
            }
        }

        return items.length() > 0 ? items.clone() : r4:createFHIRError(string `Cannot find a insurancePlans resource with profile: ${profile}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
    }
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };
    if (searchParameters is map<string[]>) {
        string? id = ();
        string? profile = ();

        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    id = searchParameters.get('key)[0];
                }
                "_profile" => {
                    profile = searchParameters.get('key)[0];
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

        InsurancePlan[] byProfile = check getByProfile(profile is string ? profile : DEFAULT_PROFILE);

        if id is string {
            InsurancePlan byId = check getById(id, byProfile);

            bundle.entry = [
                {
                    'resource: byId
                }
            ];
        } else {
            bundle.entry = [
                {
                    'resource: byProfile
                }
            ];
            bundle.total = byProfile.length();
        }

        return bundle;
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
        json insurancePlanJson1 = {
            "resourceType": "InsurancePlan",
            "id": "9000",
            "meta": {
                "lastUpdated": "2020-07-07T13:26:22.0314215+00:00",
                "profile": ["http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-InsurancePlan"]
            },
            "language": "en-US",
            "text": {
                "status": "generated",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en-US\" lang=\"en-US\"><p class=\"res-header-id\"><b>Generated Narrative: InsurancePlan AcmeQHPBronze</b></p><a name=\"AcmeQHPBronze\"> </a><a name=\"hcAcmeQHPBronze\"> </a><a name=\"AcmeQHPBronze-en-US\"> </a><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Last updated: 2020-07-07 13:26:22+0000; Language: en-US</p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-plannet-InsurancePlan.html\">Plan-Net InsurancePlan</a></p></div><p><b>status</b>: Active</p><p><b>type</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/InsuranceProductTypeCS qhp}\">Qualified Health Plan</span></p><p><b>name</b>: Acme of CT QHP Bronze</p><p><b>ownedBy</b>: <a href=\"Organization-Acme.html\">Organization Acme of CT</a></p><p><b>administeredBy</b>: <a href=\"Organization-Acme.html\">Organization Acme of CT</a></p><p><b>coverageArea</b>: <a href=\"Location-StateOfCTLocation.html\">Location State of CT Area</a></p><p><b>endpoint</b>: <a href=\"Endpoint-AcmeOfCTPortalEndpoint.html\">Endpoint Endpoint for Acme of CT Portal</a></p><p><b>network</b>: <a href=\"Organization-AcmeofCTStdNet.html\">Organization ACME CT Preferred Provider Network</a></p><h3>Plans</h3><table class=\"grid\"><tr><td style=\"display: none\">-</td><td><b>Type</b></td></tr><tr><td style=\"display: none\">*</td><td><span title=\"Codes:{http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/InsurancePlanTypeCS bronze}\">Bronze-QHP</span></td></tr></table></div>"
            },
            "status": "active",
            "type": [
                {
                    "coding": [
                        {
                            "system": "http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/InsuranceProductTypeCS",
                            "code": "qhp",
                            "display": "Qualified Health Plan"
                        }
                    ]
                }
            ],
            "name": "Acme of CT QHP Bronze",
            "ownedBy": {
                "reference": "Organization/Acme"
            },
            "administeredBy": {
                "reference": "Organization/Acme"
            },
            "coverageArea": [
                {
                    "reference": "Location/StateOfCTLocation"
                }
            ],
            "endpoint": [
                {
                    "reference": "Endpoint/AcmeOfCTPortalEndpoint"
                }
            ],
            "network": [
                {
                    "reference": "Organization/AcmeofCTStdNet"
                }
            ],
            "plan": [
                {
                    "type": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/davinci-pdex-plan-net/CodeSystem/InsurancePlanTypeCS",
                                "code": "bronze",
                                "display": "Bronze-QHP"
                            }
                        ]
                    }
                }
            ]
        };

        // for PayerInsurancePlan 1
        InsurancePlan insurancePlan1 = check parser:parse(insurancePlanJson1).ensureType();
        insurancePlans.push(insurancePlan1.clone());

        json insurancePlanJson2 = {
            "resourceType": "InsurancePlan",
            "id": "9001",
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

        // for PayerInsurancePlan 2
        InsurancePlan insurancePlan2 = check parser:parse(insurancePlanJson2, davincidrugformulary210:PayerInsurancePlan).ensureType();
        insurancePlans.push(insurancePlan2.clone());

        json formularyJson = {
            "resourceType": "InsurancePlan",
            "id": "9002",
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
        InsurancePlan insurancePlan = check parser:parse(formularyJson, davincidrugformulary210:Formulary).ensureType();
        insurancePlans.push(insurancePlan.clone());
    }
}

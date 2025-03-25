import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincidrugformulary210;
import ballerinax/health.fhir.r4.parser;

isolated davincidrugformulary210:FormularyItem[] basics = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|davincidrugformulary210:FormularyItem {
    davincidrugformulary210:FormularyItem|error basic = parser:parse(payload, davincidrugformulary210:FormularyItem).ensureType();

    if basic is error {
        return r4:createFHIRError(basic.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            basic.id = (createOperationNextId).toBalString();
        }

        lock {
            basics.push(basic.clone());
        }

        return basic;
    }
}

public isolated function getById(string id) returns r4:FHIRError|davincidrugformulary210:FormularyItem {
    lock {
        foreach var item in basics {
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
                    davincidrugformulary210:FormularyItem byId = check getById(searchParameters.get('key)[0]);
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
        foreach var item in basics {
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
        json basicJson = {
            "resourceType": "Basic",
            "id": "12344",
            "meta": {
                "lastUpdated": "2021-08-22T18:36:03.000+00:00",
                "profile": ["http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-FormularyItem"]
            },
            "text": {
                "status": "extensions",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p class=\"res-header-id\"><b>Generated Narrative: Basic FormularyItem-D1002-1000091</b></p><a name=\"FormularyItem-D1002-1000091\"> </a><a name=\"hcFormularyItem-D1002-1000091\"> </a><a name=\"FormularyItem-D1002-1000091-en-US\"> </a><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Last updated: 2021-08-22 18:36:03+0000</p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-usdf-FormularyItem.html\">Formulary Item</a></p></div><p><b>Formulary Reference</b>: <a href=\"InsurancePlan-FormularyD1002.html\">InsurancePlan Sample Medicare Advantage Part D Formulary D1002</a></p><p><b>Availability Status</b>: active</p><p><b>Pharmacy Benefit Type</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-PharmacyBenefitTypeCS-TEMPORARY-TRIAL-USE 1-month-in-retail}\">1 month in network retail</span></p><p><b>Pharmacy Benefit Type</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-PharmacyBenefitTypeCS-TEMPORARY-TRIAL-USE 1-month-in-mail}\">1 month in network mail order</span></p><p><b>Pharmacy Benefit Type</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-PharmacyBenefitTypeCS-TEMPORARY-TRIAL-USE 3-month-in-retail}\">3 month in network retail</span></p><p><b>Pharmacy Benefit Type</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-PharmacyBenefitTypeCS-TEMPORARY-TRIAL-USE 3-month-in-mail}\">3 month in network mail order</span></p><p><b>Drug Tier ID</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-DrugTierCS-TEMPORARY-TRIAL-USE generic}\">Generic</span></p><p><b>Availability Period</b>: 2021-01-01 --&gt; 2021-12-31</p><p><b>Prior Authorization</b>: false</p><p><b>Step Therapy Limit</b>: true</p><p><b>Step Therapy Limit New Starts Only</b>: true</p><p><b>Quantity Limit</b>: true</p><p><b>code</b>: <span title=\"Codes:{http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-InsuranceItemTypeCS formulary-item}\">Formulary Item</span></p><p><b>subject</b>: <a href=\"MedicationKnowledge-FormularyDrug-1000091.html\">MedicationKnowledge doxepin hydrochloride 50 MG/ML Topical Cream</a></p></div>"
            },
            "extension": [
                {
                    "url": "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-FormularyReference-extension",
                    "valueReference": {
                        "reference": "InsurancePlan/FormularyD1002"
                    }
                },
                {
                    "url": "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-AvailabilityStatus-extension",
                    "valueCode": "active"
                },
                {
                    "url": "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-PharmacyBenefitType-extension",
                    "valueCodeableConcept": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-PharmacyBenefitTypeCS-TEMPORARY-TRIAL-USE",
                                "code": "1-month-in-retail",
                                "display": "1 month in network retail"
                            }
                        ]
                    }
                },
                {
                    "url": "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-DrugTierID-extension",
                    "valueCodeableConcept": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-DrugTierCS-TEMPORARY-TRIAL-USE",
                                "code": "generic",
                                "display": "Generic"
                            }
                        ]
                    }
                },
                {
                    "url": "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-AvailabilityPeriod-extension",
                    "valuePeriod": {
                        "start": "2021-01-01",
                        "end": "2021-12-31"
                    }
                },
                {
                    "url": "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-PharmacyBenefitType-extension",
                    "valueCodeableConcept": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-PharmacyBenefitTypeCS-TEMPORARY-TRIAL-USE",
                                "code": "1-month-in-mail",
                                "display": "1 month in network mail order"
                            }
                        ]
                    }
                },
                {
                    "url": "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-PharmacyBenefitType-extension",
                    "valueCodeableConcept": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-PharmacyBenefitTypeCS-TEMPORARY-TRIAL-USE",
                                "code": "3-month-in-retail",
                                "display": "3 month in network retail"
                            }
                        ]
                    }
                },
                {
                    "url": "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-PharmacyBenefitType-extension",
                    "valueCodeableConcept": {
                        "coding": [
                            {
                                "system": "http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-PharmacyBenefitTypeCS-TEMPORARY-TRIAL-USE",
                                "code": "3-month-in-mail",
                                "display": "3 month in network mail order"
                            }
                        ]
                    }
                },
                {
                    "url": "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-PriorAuthorization-extension",
                    "valueBoolean": false
                },
                {
                    "url": "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-StepTherapyLimit-extension",
                    "valueBoolean": true
                },
                {
                    "url": "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-StepTherapyLimitNewStartsOnly-extension",
                    "valueBoolean": true
                },
                {
                    "url": "http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-QuantityLimit-extension",
                    "valueBoolean": true
                }
            ],
            "code": {
                "coding": [
                    {
                        "system": "http://hl7.org/fhir/us/davinci-drug-formulary/CodeSystem/usdf-InsuranceItemTypeCS",
                        "code": "formulary-item",
                        "display": "Formulary Item"
                    }
                ]
            },
            "subject": {
                "reference": "MedicationKnowledge/FormularyDrug-1000091"
            }
        };

        davincidrugformulary210:FormularyItem basic = check parser:parse(basicJson, davincidrugformulary210:FormularyItem).ensureType();
        basics.push(basic.clone());
    }
}

import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincidrugformulary210;
import ballerinax/health.fhir.r4.parser;

isolated davincidrugformulary210:FormularyDrug[] medicationKnowledges = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|davincidrugformulary210:FormularyDrug {
    davincidrugformulary210:FormularyDrug|error medicationKnowledge = parser:parse(payload, davincidrugformulary210:FormularyDrug).ensureType();

    if medicationKnowledge is error {
        return r4:createFHIRError(medicationKnowledge.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            medicationKnowledge.id = (createOperationNextId).toBalString();
        }

        lock {
            medicationKnowledges.push(medicationKnowledge.clone());
        }

        return medicationKnowledge;
    }
}

public isolated function getById(string id) returns r4:FHIRError|davincidrugformulary210:FormularyDrug {
    lock {
        foreach var item in medicationKnowledges {
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
                    davincidrugformulary210:FormularyDrug byId = check getById(searchParameters.get('key)[0]);
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
        foreach var item in medicationKnowledges {
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
        json medicationKnowledgeJson = {
            "resourceType": "MedicationKnowledge",
            "id": "12344",
            "meta": {
                "lastUpdated": "2021-08-22T18:36:03.000+00:00",
                "profile": ["http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-FormularyDrug"]
            },
            "text": {
                "status": "generated",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p class=\"res-header-id\"><b>Generated Narrative: MedicationKnowledge FormularyDrug-1000091</b></p><a name=\"FormularyDrug-1000091\"> </a><a name=\"hcFormularyDrug-1000091\"> </a><a name=\"FormularyDrug-1000091-en-US\"> </a><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Last updated: 2021-08-22 18:36:03+0000</p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-usdf-FormularyDrug.html\">Formulary Drug</a></p></div><p><b>code</b>: <span title=\"Codes:{http://www.nlm.nih.gov/research/umls/rxnorm 1000091}, {http://www.nlm.nih.gov/research/umls/rxnorm 1160770}\">doxepin hydrochloride 50 MG/ML Topical Cream</span></p><p><b>status</b>: Active</p></div>"
            },
            "code": {
                "coding": [
                    {
                        "system": "http://www.nlm.nih.gov/research/umls/rxnorm",
                        "code": "1000091",
                        "display": "doxepin hydrochloride 50 MG/ML Topical Cream"
                    },
                    {
                        "system": "http://www.nlm.nih.gov/research/umls/rxnorm",
                        "code": "1160770",
                        "display": "doxepin Topical Product"
                    }
                ]
            },
            "status": "active"
        };

        davincidrugformulary210:FormularyDrug medicationKnowledge = check parser:parse(medicationKnowledgeJson, davincidrugformulary210:FormularyDrug).ensureType();
        medicationKnowledges.push(medicationKnowledge.clone());
    }
}

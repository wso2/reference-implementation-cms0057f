import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.parser;

isolated international401:Parameters[] parameters = [];
isolated int createOperationNextId = 33;

public isolated function getById(string id) returns r4:FHIRError|international401:Parameters {
    lock {
        foreach var item in parameters {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a Questionnaire resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function create(international401:Parameters payload) returns r4:FHIRError|international401:Parameters {
    international401:Parameters|error parameters = parser:parseWithValidation(payload.toJson(), international401:Parameters).ensureType();

    if parameters is error {
        return r4:createFHIRError(parameters.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        return getById("32");
    }
}

function init() returns error? {
    lock {
        json questionnaireJson = {
            "resourceType": "Parameters",
            "id": "32",
            "parameter": [
                {
                    "name": "PackageBundle",
                    "resource": {
                        "resourceType": "Bundle",
                        "type": "collection",
                        "entry": [
                            {
                                "resource": {
                                    "resourceType": "Questionnaire",
                                    "id": "4",
                                    "status": "active",
                                    "title": "Prior Authorization for Aimovig 70 mg Injection",
                                    "subjectType": ["Patient"],
                                    "extension": [
                                        {
                                            "url": "http://hl7.org/fhir/StructureDefinition/cqf-library",
                                            "extension": [
                                                {
                                                    "url": "library",
                                                    "valueBase64Binary": "bGlicmFyeSBBaW1vdmlnUHJpb3JBdXRoIHZlcnNpb24gJzEuMC4wJwoKdXNpbmcgRkhJUiB2ZXJzaW9uICc0LjAuMScKCmluY2x1ZGUgRkhJUkhlbHBlcnMgdmVyc2lvbiAnNC4wLjEn..."
                                                }
                                            ]
                                        }
                                    ],
                                    "item": [
                                        {
                                            "linkId": "1",
                                            "text": "Has the patient been diagnosed with chronic migraines?",
                                            "type": "boolean"
                                        },
                                        {
                                            "linkId": "2",
                                            "text": "Has the patient tried other preventive migraine treatments?",
                                            "type": "boolean"
                                        },
                                        {
                                            "linkId": "3",
                                            "text": "Please list previous medications used for migraine prevention.",
                                            "type": "string"
                                        },
                                        {
                                            "linkId": "4",
                                            "text": "What is the frequency of migraines per month?",
                                            "type": "integer"
                                        },
                                        {
                                            "linkId": "5",
                                            "text": "Has the patient experienced side effects or lack of effectiveness with prior treatments?",
                                            "type": "boolean"
                                        },
                                        {
                                            "linkId": "6",
                                            "text": "Does the patient have any contraindications to other migraine medications?",
                                            "type": "boolean"
                                        },
                                        {
                                            "linkId": "7",
                                            "text": "Does the patient have insurance coverage for Aimovig?",
                                            "type": "boolean"
                                        }
                                    ]
                                }
                            }
                        ]
                    }
                }
            ]
        };

        international401:Parameters p = check parser:parse(questionnaireJson, international401:Parameters).ensureType();
        parameters.push(p);
    }

}

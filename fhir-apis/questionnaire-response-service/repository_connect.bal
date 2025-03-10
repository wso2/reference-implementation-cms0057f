import ballerina/http;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.parser;

isolated international401:QuestionnaireResponse[] questionnaireResponses = [];
isolated int createOperationNextId = 1122;

public isolated function create(international401:QuestionnaireResponse payload) returns r4:FHIRError|international401:QuestionnaireResponse {
    international401:QuestionnaireResponse|error questionnaireResponse = parser:parseWithValidation(payload.toJson(), international401:QuestionnaireResponse).ensureType();

    if questionnaireResponse is error {
        return r4:createFHIRError(questionnaireResponse.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            questionnaireResponse.id = (++createOperationNextId).toBalString();
        }

        lock {
            questionnaireResponses.push(questionnaireResponse.clone());
        }

        return questionnaireResponse;
    }
}

public isolated function getById(string id) returns r4:FHIRError|international401:QuestionnaireResponse {
    lock {
        foreach var item in questionnaireResponses {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a Patient resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function update(json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function patchResource(string 'resource, string id, json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
}

public isolated function delete(string 'resource, string id) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function search(string 'resource, map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        if searchParameters.keys().count() == 1 {
            lock {
                r4:BundleEntry[] bundleEntries = [];
                foreach var item in questionnaireResponses {
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
                    international401:QuestionnaireResponse byId = check getById(searchParameters.get('key)[0]);
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

    return bundle;
}

function init() returns error? {
    lock {
        json questionnaireResponseJson = {
            "resourceType": "QuestionnaireResponse",
            "id": "1121",
            "questionnaire": "Questionnaire/12",
            "status": "completed",
            "subject": {
                "reference": "Patient/123"
            },
            "author": {
                "reference": "PractitionerRole/456"
            },
            "item": [
                {
                    "linkId": "1",
                    "text": "Has the patient been diagnosed with chronic migraines?",
                    "answer": [
                        {
                            "valueQuestionnaireResponseBoolean": true
                        }
                    ]
                },
                {
                    "linkId": "2",
                    "text": "Has the patient tried other preventive migraine treatments?",
                    "answer": [
                        {
                            "valueQuestionnaireResponseBoolean": true
                        }
                    ]
                },
                {
                    "linkId": "3",
                    "text": "Please list previous medications used for migraine prevention.",
                    "answer": [
                        {
                            "valueQuestionnaireResponseString": "Propranolol, Topiramate, Botox"
                        }
                    ]
                },
                {
                    "linkId": "4",
                    "text": "What is the frequency of migraines per month?",
                    "answer": [
                        {
                            "valueQuestionnaireResponseInteger": 8
                        }
                    ]
                },
                {
                    "linkId": "5",
                    "text": "Has the patient experienced side effects or lack of effectiveness with prior treatments?",
                    "answer": [
                        {
                            "valueQuestionnaireResponseBoolean": true
                        }
                    ]
                },
                {
                    "linkId": "6",
                    "text": "Does the patient have any contraindications to other migraine medications?",
                    "answer": [
                        {
                            "valueQuestionnaireResponseBoolean": false
                        }
                    ]
                },
                {
                    "linkId": "7",
                    "text": "Does the patient have insurance coverage for Aimovig?",
                    "answer": [
                        {
                            "valueQuestionnaireResponseBoolean": true
                        }
                    ]
                }
            ]
        };

        international401:QuestionnaireResponse questionnaireResponse = check parser:parse(questionnaireResponseJson, international401:QuestionnaireResponse).ensureType();
        questionnaireResponses.push(questionnaireResponse);
    }

}

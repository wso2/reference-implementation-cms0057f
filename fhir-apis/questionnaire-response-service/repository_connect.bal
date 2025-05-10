import ballerina/http;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;
import ballerina/time;

isolated uscore700:USCoreQuestionnaireResponseProfile[] questionnaireResponses = [];
isolated int createOperationNextId = 1123;

public isolated function create(uscore700:USCoreQuestionnaireResponseProfile payload) returns r4:FHIRError|uscore700:USCoreQuestionnaireResponseProfile {
    uscore700:USCoreQuestionnaireResponseProfile|error questionnaireResponse = parser:parse(payload.toJson(), uscore700:USCoreQuestionnaireResponseProfile).ensureType();

    if questionnaireResponse is error {
        return r4:createFHIRError(questionnaireResponse.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            questionnaireResponse.id = (createOperationNextId).toBalString();
        }

        lock {
            questionnaireResponses.push(questionnaireResponse.clone());
        }

        return questionnaireResponse;
    }
}

public isolated function getById(string id) returns r4:FHIRError|uscore700:USCoreQuestionnaireResponseProfile {
    lock {
        foreach var item in questionnaireResponses {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a QuestionnaireResponse resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
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

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        string? id = ();
        string? subject = ();
        string? author = ();
        string? authored = ();

        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    id = searchParameters.get('key)[0];
                }
                "subject" => {
                    subject = searchParameters.get('key)[0];
                }
                "author" => {
                    author = searchParameters.get('key)[0];
                }
                "authored" => {
                    authored = searchParameters.get('key)[0];
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

        if id is string {
            QuestionnaireResponse byId = check getById(id);

            bundle.entry = [
                {
                    'resource: byId
                }
            ];

            bundle.total = 1;
            return bundle;
        }

        QuestionnaireResponse[] results = [];
        lock {
            results = questionnaireResponses.clone();
        }

        if subject is string {
            results = getBySubject(subject, results);
        }

        if author is string {
            results = getByAuthor(author, results);
        }

        if authored is string {
            results = check getByAutheredDate(authored, results);
        }

        // reorder the results as decending order by Authored date
        results = orderByAuthoredDate(results);

        r4:BundleEntry[] bundleEntries = [];

        foreach QuestionnaireResponse item in results {
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

isolated function orderByAuthoredDate(QuestionnaireResponse[] targetArr) returns QuestionnaireResponse[] {
    return from QuestionnaireResponse item in targetArr order by item.authored descending select item;
}

isolated function getByAutheredDate(string authored, QuestionnaireResponse[] targetArr) returns QuestionnaireResponse[]|r4:FHIRError {
    string operator = authored.substring(0, 2);
    r4:dateTime datetimeR4 = authored.substring(2);

    // convert r4:dateTime to time:Utc
    time:Utc|time:Error dateTimeUtc = time:utcFromString(datetimeR4.includes("T") ? datetimeR4 : datetimeR4 + "T00:00:00.000Z");
    if dateTimeUtc is time:Error {
        return r4:createFHIRError(string `Invalid date format: ${datetimeR4}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    time:Utc lowerBound = time:utcAddSeconds(dateTimeUtc, 86400);
    time:Utc upperBound = time:utcAddSeconds(dateTimeUtc, -86400);

    QuestionnaireResponse[] filteredResponses = [];
    foreach QuestionnaireResponse response in targetArr {
        // convert r4:dateTime to time:Utc to compare with the given date
        r4:dateTime responseDateTimeR4 = response.authored;
        time:Utc|time:Error responseDateTimeUtc = time:utcFromString(responseDateTimeR4.includes("T") ? responseDateTimeR4 : responseDateTimeR4 + "T00:00:00.000Z");
        if responseDateTimeUtc is time:Error {
            continue; // Skip invalid date formats
        }
        match operator {
            "eq" => {
                if responseDateTimeUtc == dateTimeUtc {
                    filteredResponses.push(response.clone());
                }
            }
            "ne" => {
                if responseDateTimeUtc != dateTimeUtc {
                    filteredResponses.push(response.clone());
                }
            }
            "lt" => {
                if responseDateTimeUtc < dateTimeUtc {
                    filteredResponses.push(response.clone());
                }
            }
            "gt" => {
                if responseDateTimeUtc > dateTimeUtc {
                    filteredResponses.push(response.clone());
                }
            }
            "ge" => {
                if responseDateTimeUtc >= dateTimeUtc {
                    filteredResponses.push(response.clone());
                }
            }
            "le" => {
                if responseDateTimeUtc <= dateTimeUtc {
                    filteredResponses.push(response.clone());
                }
            }
            "sa" => {
                if responseDateTimeUtc > dateTimeUtc {
                    filteredResponses.push(response.clone());
                }
            }
            "eb" => {
                if responseDateTimeUtc < dateTimeUtc {
                    filteredResponses.push(response.clone());
                }
            }
            "ap" => {
                // Approximation: Check if the response date is within 1 day of the given date
                if responseDateTimeUtc >= lowerBound && responseDateTimeUtc <= upperBound {
                    filteredResponses.push(response.clone());
                }
            }
            _ => {
                return r4:createFHIRError(string `Invalid operator: ${operator}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
            }
        }
    }
    return filteredResponses;
}

isolated function getBySubject(string subject, QuestionnaireResponse[] targetArr) returns QuestionnaireResponse[] {
    QuestionnaireResponse[] filteredResponses = [];
    foreach QuestionnaireResponse response in targetArr {
        if response.subject.reference == subject {
            filteredResponses.push(response.clone());
        }
    }
    return filteredResponses;
}

isolated function getByAuthor(string author, QuestionnaireResponse[] targetArr) returns QuestionnaireResponse[] {
    QuestionnaireResponse[] filteredResponses = [];
    foreach QuestionnaireResponse response in targetArr {
        if response.author?.reference == author {
            filteredResponses.push(response.clone());
        }
    }
    return filteredResponses;
}

function init() returns error? {
    lock {
        json questionnaireResponseJson = {
            "resourceType": "QuestionnaireResponse",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-questionnaireresponse"]
            },
            "id": "1121",
            "questionnaire": "Questionnaire/12",
            "status": "completed",
            "authored": "2023-08-14",
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
                            "valueBoolean": true
                        }
                    ]
                },
                {
                    "linkId": "2",
                    "text": "Has the patient tried other preventive migraine treatments?",
                    "answer": [
                        {
                            "valueBoolean": true
                        }
                    ]
                },
                {
                    "linkId": "3",
                    "text": "Please list previous medications used for migraine prevention.",
                    "answer": [
                        {
                            "valueString": "Propranolol, Topiramate, Botox"
                        }
                    ]
                },
                {
                    "linkId": "4",
                    "text": "What is the frequency of migraines per month?",
                    "answer": [
                        {
                            "valueInteger": 8
                        }
                    ]
                },
                {
                    "linkId": "5",
                    "text": "Has the patient experienced side effects or lack of effectiveness with prior treatments?",
                    "answer": [
                        {
                            "valueBoolean": true
                        }
                    ]
                },
                {
                    "linkId": "6",
                    "text": "Does the patient have any contraindications to other migraine medications?",
                    "answer": [
                        {
                            "valueBoolean": false
                        }
                    ]
                },
                {
                    "linkId": "7",
                    "text": "Does the patient have insurance coverage for Aimovig?",
                    "answer": [
                        {
                            "valueBoolean": true
                        }
                    ]
                }
            ]
        };

        QuestionnaireResponse questionnaireResponse = check parser:parse(questionnaireResponseJson, uscore700:USCoreQuestionnaireResponseProfile).ensureType();
        questionnaireResponses.push(questionnaireResponse);
    }
}

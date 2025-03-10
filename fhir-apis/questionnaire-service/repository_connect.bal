import ballerina/http;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.parser;

isolated international401:Questionnaire[] questionnaires = [];
isolated int createOperationNextId = 5;

public isolated function create(Questionnaire payload) returns r4:FHIRError|international401:Questionnaire {
    international401:Questionnaire|error patient = parser:parseWithValidation(payload.toJson(), international401:Questionnaire).ensureType();

    if patient is error {
        return r4:createFHIRError(patient.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            patient.id = (++createOperationNextId).toBalString();
        }

        lock {
            questionnaires.push(patient.clone());
        }

        return patient;
    }
}

public isolated function getById(string id) returns r4:FHIRError|international401:Questionnaire {
    lock {
        foreach var item in questionnaires {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a Questionnaire resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
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
                foreach var item in questionnaires {
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
                    international401:Questionnaire byId = check getById(searchParameters.get('key)[0]);
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
        json questionnaireJson = {
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
                            "valueBase64Binary": "bGlicmFyeSBBaW1vdmlnUHJpb3JBdXRoIHZlcnNpb24gJzEuMC4wJwoKdXNpbmcgRkhJUiB2ZXJzaW9uICc0LjAuMScKCmluY2x1ZGUgRkhJUkhlbHBlcnMgdmVyc2lvbiAnNC4wLjEnCgpjb250ZXh0IFBhdGllbnQKCi8vIERlZmluZSBDaHJvbmljIE1pZ3JhaW5lIERpYWdub3NpcwpkZWZpbmUgIkNocm9uaWMgTWlncmFpbmUgRGlhZ25vc2lzIjoKICBleGlzdHMgKAogICAgW0NvbmRpdGlvbjogIjM3Nzk2MDA5Il0gLy8gU05PTUVEIGNvZGUgZm9yIE1pZ3JhaW5lCiAgICB3aGVyZSBzdGF0dXMgPSAnYWN0aXZlJwogICkKCi8vIERlZmluZSBQcmV2aW91cyBQcmV2ZW50aXZlIE1pZ3JhaW5lIFRyZWF0bWVudHMKZGVmaW5lICJQcmV2aW91cyBQcmV2ZW50aXZlIFRyZWF0bWVudHMiOgogIGV4aXN0cyAoCiAgICBbTWVkaWNhdGlvblJlcXVlc3RdCiAgICB3aGVyZSBtZWRpY2F0aW9uIGluICgKICAgICAgJ1Byb3ByYW5vbG9sJywgJ1RvcGlyYW1hdGUnLCAnQW1pdHJpcHR5bGluZScsICdCb3RveCcsICdDR1JQIEluaGliaXRvcnMnCiAgICApCiAgICBhbmQgc3RhdHVzIGluICgnY29tcGxldGVkJywgJ2FjdGl2ZScpCiAgKQoKLy8gRGVmaW5lIE1pZ3JhaW5lIEZyZXF1ZW5jeSBDcml0ZXJpYQpkZWZpbmUgIk1pZ3JhaW5lIEZyZXF1ZW5jeSBIaWdoIjoKICBleGlzdHMgKAogICAgW09ic2VydmF0aW9uXQogICAgd2hlcmUgY29kZSA9ICdtaWdyYWluZS1mcmVxdWVuY3knIGFuZCB2YWx1ZVF1YW50aXR5LnZhbHVlID49IDQKICApCgovLyBEZWZpbmUgQ29udHJhaW5kaWNhdGlvbnMgdG8gT3RoZXIgTWlncmFpbmUgTWVkaWNhdGlvbnMKZGVmaW5lICJIYXMgQ29udHJhaW5kaWNhdGlvbnMiOgogIGV4aXN0cyAoCiAgICBbQ29uZGl0aW9uXQogICAgd2hlcmUgY29kZSBpbiAoCiAgICAgICdBbGxlcmd5IHRvIGJldGEgYmxvY2tlcnMnLCAnUmVuYWwgZGlzZWFzZScsICdMaXZlciBkaXNlYXNlJwogICAgKQogICkKCi8vIERlZmluZSBJbnN1cmFuY2UgQ292ZXJhZ2UgQ2hlY2sKZGVmaW5lICJJbnN1cmFuY2UgQ292ZXJhZ2UiOgogIGV4aXN0cyAoCiAgICBbQ292ZXJhZ2VdCiAgICB3aGVyZSBwYXlvci5yZWZlcmVuY2UgPSAnT3JnYW5pemF0aW9uL2luc3VyYW5jZS1vcmcnCiAgKQoKLy8gRGVmaW5lIENyaXRlcmlhIGZvciBBcHByb3ZhbApkZWZpbmUgIlByaW9yIEF1dGhvcml6YXRpb24gQXBwcm92ZWQiOgogICJDaHJvbmljIE1pZ3JhaW5lIERpYWdub3NpcyIgYW5kCiAgIlByZXZpb3VzIFByZXZlbnRpdmUgVHJlYXRtZW50cyIgYW5kCiAgIk1pZ3JhaW5lIEZyZXF1ZW5jeSBIaWdoIiBhbmQKICAoIkhhcyBDb250cmFpbmRpY2F0aW9ucyIgb3IgIkluc3VyYW5jZSBDb3ZlcmFnZSIp"
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
        };

        international401:Questionnaire questionnaire = check parser:parse(questionnaireJson, international401:Questionnaire).ensureType();
        questionnaires.push(questionnaire);
    }

}

import ballerina/http;

function getFHIRPatientById(string patientId) returns json|error {
    http:Response response = check fhirHttpClient->get(string`/Patient/${patientId}`, headers = {"Accept": "application/fhir+json"});
    json result = check response.getJsonPayload();
    return result;
}

import ballerina/http;
import ballerina/sql;

isolated function getFHIRPatientById(string patientId) returns json|error {
    http:Response response = check fhirHttpClient->get(string`/Patient/${patientId}`, headers = {"Accept": "application/fhir+json"});
    json result = check response.getJsonPayload();
    return result;
}

# Fetches the payer ID and member ID for a PDex exchange request from the database.
# + requestId - PDex exchange request ID
# + return - Minimal exchange record or error
isolated function getPdexExchangeRecord(string requestId) returns PdexExchangeRecord|error {
    sql:ParameterizedQuery query = `SELECT request_id AS requestId, payer_id AS payerId, member_id AS memberId
                                    FROM payer_data_exchange_requests
                                    WHERE request_id = ${requestId}`;
    stream<PdexExchangeRecord, sql:Error?> resultStream = dbClient->query(query);
    PdexExchangeRecord[]|error records = from PdexExchangeRecord rec in resultStream
        select rec;
    if records is error {
        return records;
    }
    if records.length() == 0 {
        return error(string`No exchange record found for request ID: ${requestId}`);
    }
    return records[0];
}

// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).

// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
import ballerina/sql;
import ballerina/uuid;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

configurable DatabaseConfig databaseConfig = ?;

final mysql:Client dbClient = check new (
    host = databaseConfig.host,
    port = databaseConfig.port,
    user = databaseConfig.user,
    password = databaseConfig.password,
    database = databaseConfig.database
);

public isolated function insertPayerDataExchangeRequest(PayerDataExchangeRequest request) returns string|error {
    string requestId = uuid:createType1AsString();
    sql:ParameterizedQuery query = `INSERT INTO payer_data_exchange_requests 
                                    (request_id, payer_id, member_id, old_payer_name, old_payer_state, old_coverage_id, coverage_start_date, coverage_end_date, consent_status) 
                                    VALUES (${requestId}, ${request.payerId}, ${request.memberId}, ${request.oldPayerName}, ${request.oldPayerState}, 
                                    ${request.oldCoverageId}, ${request.coverageStartDate}, ${request.coverageEndDate}, ${request.consent})`;

    sql:ExecutionResult result = check dbClient->execute(query);

    if result.affectedRowCount > 0 {
        return requestId;
    }
    return error("Failed to insert payer data exchange request");
}

public isolated function getPayerDataExchangeRequests(int 'limit = 10, int offset = 0) returns PayerDataExchangeRequestResult|error {
    sql:ParameterizedQuery countQuery = `SELECT COUNT(*) AS totalCount FROM payer_data_exchange_requests`;
    int totalCount = check dbClient->queryRow(countQuery);

    sql:ParameterizedQuery query = `SELECT request_id AS requestId, payer_id AS payerId, member_id AS memberId, old_payer_name AS oldPayerName, old_payer_state AS oldPayerState, 
                                    old_coverage_id AS oldCoverageId, coverage_start_date AS coverageStartDate, coverage_end_date AS coverageEndDate,
                                    bulk_data_sync_status AS bulkDataSyncStatus, consent_status AS consent, created_at AS createdDate
                                    FROM payer_data_exchange_requests
                                    ORDER BY CASE WHEN bulk_data_sync_status = 'PENDING' THEN 1 ELSE 2 END, request_id ASC
                                    LIMIT ${'limit} OFFSET ${offset}`;
    stream<PayerDataExchangeRequest, error?> resultStream = dbClient->query(query);
    PayerDataExchangeRequest[] requests = check from PayerDataExchangeRequest request in resultStream
        select request;

    return {totalCount: totalCount, requests: requests};
}

public isolated function updatePayerDataExchangeRequestStatus(string requestId, string status) returns string|error {
    sql:ParameterizedQuery query = `UPDATE payer_data_exchange_requests SET bulk_data_sync_status = ${status} WHERE request_id = ${requestId}`;
    sql:ExecutionResult result = check dbClient->execute(query);

    if result.affectedRowCount > 0 {
        return "Status updated successfully";
    }
    return error("Failed to update status. Request ID not found.");
}

public isolated function getPayerDataExchangeRequest(string requestId) returns PayerDataExchangeRequest|error {
    sql:ParameterizedQuery query = `SELECT request_id AS requestId, payer_id AS payerId, member_id AS memberId, old_payer_name AS oldPayerName, old_payer_state AS oldPayerState, 
                                    old_coverage_id AS oldCoverageId, coverage_start_date AS coverageStartDate, coverage_end_date AS coverageEndDate, 
                                    bulk_data_sync_status AS bulkDataSyncStatus, consent_status AS consent
                                    FROM payer_data_exchange_requests WHERE request_id = ${requestId}`;
    return dbClient->queryRow(query);
}

public isolated function getPayerConfig(string payerId) returns PayerConfig|error {
    sql:ParameterizedQuery query = `SELECT id AS payerId, name AS payerName, fhir_server_url AS baseUrl, token_url AS tokenUrl, 
                                    app_client_id AS clientId, app_client_secret AS clientSecret, scopes AS scopesStr
                                    FROM payers WHERE id = ${payerId}`;

    // We need to fetch into an intermediate record because scopes is stored as string but PayerConfig expects string[]
    record {|
        string payerId;
        string payerName;
        string baseUrl;
        string? tokenUrl;
        string? clientId;
        string? clientSecret;
        string? scopesStr;
    |} result = check dbClient->queryRow(query);

    string[] scopes = [];
    string? scopesStr = result.scopesStr;
    if scopesStr is string && scopesStr != "" {
        scopes = re `,`.split(scopesStr);
    }

    PayerConfig config = {
        payerId: result.payerId,
        payerName: result.payerName,
        baseUrl: result.baseUrl,
        tokenUrl: result.tokenUrl,
        clientId: result.clientId,
        clientSecret: result.clientSecret,
        scopes: scopes,
        fileServerUrl: (), // Not present in payers table
        authEnabled: true
    };
    return config;
}

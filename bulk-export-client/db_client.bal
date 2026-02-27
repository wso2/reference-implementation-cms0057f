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

import ballerina/log;
import ballerina/sql;
import ballerina/http;
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
                                    (request_id, payer_id, member_id, old_coverage_id, coverage_start_date, coverage_end_date, consent_status) 
                                    VALUES (${requestId}, ${request.payerId}, ${request.memberId}, 
                                    ${request.oldCoverageId}, ${request.coverageStartDate}, ${request.coverageEndDate}, ${request.consent})`;

    sql:ExecutionResult|sql:Error result = dbClient->execute(query);

    if result is sql:ExecutionResult {
        if result.affectedRowCount > 0 {
            return requestId;
        }
        return error("Failed to insert payer data exchange request.");
    } else {
        log:printError("Database error during insert", 'error = result);
        return error("An internal error occurred while processing the request.");
    }
}

public isolated function getPayerDataExchangeRequests(int 'limit = 10, int offset = 0) returns PayerDataExchangeRequestResult|error {
    sql:ParameterizedQuery countQuery = `SELECT COUNT(*) AS totalCount FROM payer_data_exchange_requests`;
    int|sql:Error totalCount = dbClient->queryRow(countQuery);

    if totalCount is sql:Error {
        log:printError("Database error fetching count", 'error = totalCount);
        return error("An internal error occurred while fetching the data.");
    }

    sql:ParameterizedQuery query = `SELECT 
                                        r.request_id AS requestId, 
                                        r.payer_id AS payerId, 
                                        r.member_id AS memberId, 
                                        p.name AS oldPayerName, 
                                        p.state AS oldPayerState, 
                                        r.old_coverage_id AS oldCoverageId, 
                                        r.coverage_start_date AS coverageStartDate, 
                                        r.coverage_end_date AS coverageEndDate,
                                        r.bulk_data_sync_status AS bulkDataSyncStatus, 
                                        r.consent_status AS consent, 
                                        r.created_at AS createdDate
                                    FROM payer_data_exchange_requests r
                                    LEFT JOIN payers p ON r.payer_id = p.id
                                    ORDER BY CASE WHEN r.bulk_data_sync_status = 'PENDING' THEN 1 ELSE 2 END, r.request_id ASC
                                    LIMIT ${'limit} OFFSET ${offset}`;
                                    
    stream<PayerDataExchangeRequest, sql:Error?> resultStream = dbClient->query(query);
    PayerDataExchangeRequest[]|error requests = from PayerDataExchangeRequest request in resultStream
        select request;

    if requests is error {
        log:printError("Database error fetching requests", 'error = requests);
        return error("An internal error occurred while fetching the data.");
    }

    return {totalCount: totalCount, requests: requests};
}

public isolated function updatePayerDataExchangeRequestStatus(string requestId, string status) returns string|error {
    sql:ParameterizedQuery query = `UPDATE payer_data_exchange_requests SET bulk_data_sync_status = ${status} WHERE request_id = ${requestId}`;
    sql:ExecutionResult|sql:Error result = dbClient->execute(query);

    if result is sql:ExecutionResult {
        if result.affectedRowCount > 0 {
            return "Status updated successfully";
        }
        return error("Failed to update status. Request ID not found.");
    } else {
        log:printError("Database error during status update", 'error = result);
        return error("An internal error occurred while updating the status.");
    }
}

public isolated function getPayerDataExchangeRequest(string requestId) returns PayerDataExchangeRequest|error {
    sql:ParameterizedQuery query = `SELECT 
                                        r.request_id AS requestId, 
                                        r.payer_id AS payerId, 
                                        r.member_id AS memberId, 
                                        p.name AS oldPayerName, 
                                        p.state AS oldPayerState, 
                                        r.old_coverage_id AS oldCoverageId, 
                                        r.coverage_start_date AS coverageStartDate, 
                                        r.coverage_end_date AS coverageEndDate, 
                                        r.bulk_data_sync_status AS bulkDataSyncStatus, 
                                        r.consent_status AS consent, 
                                        r.created_at AS createdDate
                                    FROM payer_data_exchange_requests r
                                    LEFT JOIN payers p ON r.payer_id = p.id
                                    WHERE r.request_id = ${requestId}`;
                                    
    PayerDataExchangeRequest|sql:Error result = dbClient->queryRow(query);
    
    if result is sql:Error {
        log:printError("Database error fetching request details", 'error = result);
        return error("An internal error occurred while fetching the request details.");
    }
    
    return result;
}

public isolated function getPayerConfig(string payerId) returns PayerConfig|error {
    sql:ParameterizedQuery query = `SELECT id AS payerId, name AS payerName, fhir_server_url AS baseUrl, smart_config_url AS smartConfigUrl,
                                    app_client_id AS clientId, app_client_secret AS clientSecret, scopes AS scopesStr
                                    FROM payers WHERE id = ${payerId}`;

    record {|
        string payerId;
        string payerName;
        string baseUrl;
        string smartConfigUrl;
        string clientId;
        string clientSecret;
        string? scopesStr;
    |}|sql:Error result = dbClient->queryRow(query);

    if result is sql:Error {
        log:printError("Database error fetching payer config", 'error = result);
        return error("An internal error occurred while fetching the payer configuration.");
    }

    string[] scopes = [];
    string? scopesStr = result.scopesStr;
    if scopesStr is string && scopesStr != "" {
        scopes = re `,`.split(scopesStr);
    }

    string defaultTokenUrl = result.baseUrl + "/token";
    // From the smartConfigUrl, call the .well-known/smart-configuration endpoint to get the token URL
    http:Client|error smartConfigClient = new (result.smartConfigUrl);
    if smartConfigClient is error {
        log:printError("Failed to create HTTP client for SMART configuration", 'error = smartConfigClient);
        log:printWarn("Falling back to default token URL");
    } else {
        http:Response|error smartConfigResponse = smartConfigClient->get("/.well-known/smart-configuration");
        if smartConfigResponse is http:Response {
            var payload = smartConfigResponse.getJsonPayload();
            if payload is json {
                map<json> payloadMap = <map<json>>payload;
                string tokenUrl = <string>payloadMap["token_endpoint"];
                if tokenUrl != "" {
                    defaultTokenUrl = tokenUrl;
                } else {
                    log:printWarn("Token endpoint not found in SMART configuration, falling back to default token URL");
                }
            } else {
                log:printWarn("Failed to parse SMART configuration response, falling back to default token URL");
            }
        } else {
            log:printWarn("Failed to fetch SMART configuration, falling back to default token URL");
        }
    }

    PayerConfig config = {
        payerId: result.payerId,
        payerName: result.payerName,
        baseUrl: result.baseUrl,
        tokenUrl: defaultTokenUrl,
        clientId: result.clientId,
        clientSecret: result.clientSecret,
        scopes: scopes,
        fileServerUrl: (),
        authEnabled: true
    };
    return config;
}

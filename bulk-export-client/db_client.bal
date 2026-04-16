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
                                        CAST(r.coverage_start_date AS CHAR) AS coverageStartDate,
                                        CAST(r.coverage_end_date AS CHAR) AS coverageEndDate,
                                        r.bulk_data_sync_status AS bulkDataSyncStatus,
                                        r.consent_status AS consent,
                                        DATE_FORMAT(r.created_at, '%Y-%m-%dT%TZ') AS createdDate,
                                        r.export_summary AS exportSummary,
                                        r.bulk_export_job_id AS bulkExportJobId
                                    FROM payer_data_exchange_requests r
                                    LEFT JOIN payers p ON r.payer_id = p.id
                                    ORDER BY CASE WHEN r.bulk_data_sync_status = 'PENDING' THEN 1 ELSE 2 END, r.created_at DESC
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
                                        CAST(r.coverage_start_date AS CHAR) AS coverageStartDate,
                                        CAST(r.coverage_end_date AS CHAR) AS coverageEndDate,
                                        r.bulk_data_sync_status AS bulkDataSyncStatus,
                                        r.consent_status AS consent,
                                        DATE_FORMAT(r.created_at, '%Y-%m-%dT%TZ') AS createdDate,
                                        r.export_summary AS exportSummary,
                                        r.bulk_export_job_id AS bulkExportJobId
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

public isolated function updatePayerDataExchangeRequestSummary(string requestId, string exportSummary) returns string|error {
    sql:ParameterizedQuery query = `UPDATE payer_data_exchange_requests SET export_summary = ${exportSummary} WHERE request_id = ${requestId}`;
    sql:ExecutionResult|sql:Error result = dbClient->execute(query);

    if result is sql:ExecutionResult {
        if result.affectedRowCount > 0 {
            return "Export summary updated successfully";
        }
        return error("Failed to update export summary. Request ID not found.");
    } else {
        log:printError("Database error during export summary update", 'error = result);
        return error("An internal error occurred while updating the export summary.");
    }
}

public isolated function queryPayers(int 'limit = 10, int page = 0, string? search = ()) returns Payer[]|error {
    stream<Payer, sql:Error?> dataStream;
    
    if search is string && search.trim().length() > 0 {
        string searchPattern = "%" + search + "%";
        dataStream = dbClient->query(
            `SELECT id, name, email, address, state
            FROM payers 
            WHERE name LIKE ${searchPattern}
            ORDER BY created_at DESC LIMIT ${'limit} OFFSET ${(page - 1) * 'limit}`,
            Payer
        );
    } else {
        dataStream = dbClient->query(
            `SELECT id, name, email, address, state
            FROM payers 
            ORDER BY created_at DESC LIMIT ${'limit} OFFSET ${(page - 1) * 'limit}`,
            Payer
        );
    }

    Payer[] payers = check from Payer payer in dataStream
        select payer;

    return payers;
}

public isolated function getTotalPayerCount() returns int|error {
    record {| int count; |} result = check dbClient->queryRow(`SELECT COUNT(*) AS count FROM payers`);
    return result.count;
}

public isolated function getPayerByDbId(string payerId) returns Payer|error {
    Payer result = check dbClient->queryRow(
        `SELECT id, name, email, address, state
         FROM payers WHERE id = ${payerId}`,
        Payer
    );
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

    boolean authEnabled = result.clientId.trim().length() > 0 && result.clientSecret.trim().length() > 0;

    PayerConfig config = {
        payerId: result.payerId,
        payerName: result.payerName,
        baseUrl: result.baseUrl,
        tokenUrl: defaultTokenUrl,
        clientId: result.clientId,
        clientSecret: result.clientSecret,
        scopes: scopes,
        fileServerUrl: (),
        authEnabled: authEnabled
    };
    return config;
}

// ============================================================================
// Bulk Export Job DB Functions
// ============================================================================

public isolated function insertBulkExportJob(BulkExportJob job) returns string|error {
    sql:ParameterizedQuery query = `INSERT INTO bulk_export_jobs (job_id, payer_id, status)
                                    VALUES (${job.jobId}, ${job.payerId}, ${job.status})`;
    sql:ExecutionResult|sql:Error result = dbClient->execute(query);
    if result is sql:ExecutionResult {
        if result.affectedRowCount > 0 {
            return job.jobId;
        }
        return error("Failed to insert bulk export job.");
    } else {
        log:printError("Database error during bulk export job insert", 'error = result);
        return error("An internal error occurred while creating the bulk export job.");
    }
}

public isolated function getBulkExportJob(string jobId) returns BulkExportJob|error {
    sql:ParameterizedQuery query = `SELECT
                                        job_id AS jobId,
                                        payer_id AS payerId,
                                        status,
                                        created_at AS createdAt,
                                        completed_at AS completedAt
                                    FROM bulk_export_jobs
                                    WHERE job_id = ${jobId}`;
    BulkExportJob|sql:Error result = dbClient->queryRow(query);
    if result is sql:Error {
        log:printError("Database error fetching bulk export job", 'error = result);
        return error("An internal error occurred while fetching the bulk export job.");
    }
    return result;
}

public isolated function updateBulkExportJobStatus(string jobId, string status) returns string|error {
    sql:ParameterizedQuery query;
    if status == "COMPLETED" || status == "FAILED" {
        query = `UPDATE bulk_export_jobs SET status = ${status}, completed_at = CURRENT_TIMESTAMP WHERE job_id = ${jobId}`;
    } else {
        query = `UPDATE bulk_export_jobs SET status = ${status} WHERE job_id = ${jobId}`;
    }
    sql:ExecutionResult|sql:Error result = dbClient->execute(query);
    if result is sql:ExecutionResult {
        if result.affectedRowCount > 0 {
            return "Bulk export job status updated successfully";
        }
        return error("Failed to update bulk export job status. Job ID not found.");
    } else {
        log:printError("Database error during bulk export job status update", 'error = result);
        return error("An internal error occurred while updating the bulk export job status.");
    }
}

public isolated function linkRequestsToBulkJob(string[] requestIds, string jobId) returns string|error {
    foreach string requestId in requestIds {
        sql:ParameterizedQuery query = `UPDATE payer_data_exchange_requests
                                        SET bulk_export_job_id = ${jobId}
                                        WHERE request_id = ${requestId}`;
        sql:ExecutionResult|sql:Error result = dbClient->execute(query);
        if result is sql:Error {
            log:printError("Database error linking request to bulk job", 'error = result, requestId = requestId);
            return error("An internal error occurred while linking request " + requestId + " to bulk export job.");
        }
        if result.affectedRowCount == 0 {
            log:printError("No rows updated when linking request to bulk job; requestId not found", requestId = requestId, jobId = jobId);
            return error("Request not found: " + requestId);
        }
    }
    return "Requests linked to bulk export job successfully";
}

public isolated function getRequestsByBulkJobId(string jobId) returns PayerDataExchangeRequest[]|error {
    sql:ParameterizedQuery query = `SELECT
                                        r.request_id AS requestId,
                                        r.payer_id AS payerId,
                                        r.member_id AS memberId,
                                        p.name AS oldPayerName,
                                        p.state AS oldPayerState,
                                        r.old_coverage_id AS oldCoverageId,
                                        CAST(r.coverage_start_date AS CHAR) AS coverageStartDate,
                                        CAST(r.coverage_end_date AS CHAR) AS coverageEndDate,
                                        r.bulk_data_sync_status AS bulkDataSyncStatus,
                                        r.consent_status AS consent,
                                        r.created_at AS createdDate,
                                        r.export_summary AS exportSummary,
                                        r.bulk_export_job_id AS bulkExportJobId
                                    FROM payer_data_exchange_requests r
                                    LEFT JOIN payers p ON r.payer_id = p.id
                                    WHERE r.bulk_export_job_id = ${jobId}
                                    ORDER BY r.created_at DESC`;
    stream<PayerDataExchangeRequest, sql:Error?> resultStream = dbClient->query(query);
    PayerDataExchangeRequest[]|error requests = from PayerDataExchangeRequest request in resultStream
        select request;
    if requests is error {
        log:printError("Database error fetching requests by bulk job ID", 'error = requests);
        return error("An internal error occurred while fetching requests for the bulk export job.");
    }
    return requests;
}

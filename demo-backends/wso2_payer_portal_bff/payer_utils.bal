// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).

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
import ballerina/uuid;

// ============================================
// Payer Management Utility Functions
// ============================================

function queryPayers(int page, int pageSize, string? search = ()) returns Payer[]|error {
    stream<Payer, sql:Error?> dataStream;
    
    if search is string && search.trim().length() > 0 {
        string searchPattern = "%" + search + "%";
        dataStream = dbClient->query(
            `SELECT id, name, email, state, fhir_server_url, app_client_id, app_client_secret, token_url, scopes, created_at, updated_at 
            FROM payers 
            WHERE name LIKE ${searchPattern} OR email LIKE ${searchPattern} OR state LIKE ${searchPattern}
            ORDER BY created_at DESC LIMIT ${pageSize} OFFSET ${(page - 1) * pageSize}`,
            Payer
        );
    } else {
        dataStream = dbClient->query(
            `SELECT id, name, email, state, fhir_server_url, app_client_id, app_client_secret, token_url, scopes, created_at, updated_at 
            FROM payers 
            ORDER BY created_at DESC LIMIT ${pageSize} OFFSET ${(page - 1) * pageSize}`,
            Payer
        );
    }
    
    // Using query expression automatically handles stream closing
    Payer[] payers = check from Payer payer in dataStream
        select payer;
    
    // Mask sensitive data
    foreach Payer payer in payers {
        payer.app_client_id = "****";
        payer.app_client_secret = "****";
    }
    
    return payers;
}

function getTotalPayers(string? search = ()) returns int|error {
    if search is string && search.trim().length() > 0 {
        string searchPattern = "%" + search + "%";
        record {| int count; |} result = check dbClient->queryRow(
            `SELECT COUNT(*) AS count FROM payers 
            WHERE name LIKE ${searchPattern} OR email LIKE ${searchPattern} OR state LIKE ${searchPattern}`
        );
        return result.count;
    } else {
        record {| int count; |} result = check dbClient->queryRow(`SELECT COUNT(*) AS count FROM payers`);
        return result.count;
    }
}

function getPayerById(string payerId) returns Payer|error? {
    Payer|error? payer = dbClient->queryRow(
        `SELECT id, name, email, state, fhir_server_url, app_client_id, app_client_secret, token_url, scopes, created_at, updated_at FROM payers WHERE id = ${payerId}`,
        Payer
    );
    if (payer is error) {
        log:printError("Error querying payer by ID: " + payer.message());
        return payer;
    }
    return payer;
}

function createPayer(PayerFormData payload) returns error? {
    string newPayerId = uuid:createType4AsString();
    sql:ParameterizedQuery query = `INSERT INTO payers (id, name, email, state, fhir_server_url, app_client_id, app_client_secret, token_url, scopes, created_at, updated_at) 
        VALUES (${newPayerId}, ${payload.name}, ${payload.email}, ${payload.state}, ${payload.fhir_server_url}, ${payload.app_client_id}, ${payload.app_client_secret}, ${payload.token_url}, ${payload.scopes}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`;
    _ = check dbClient->execute(query);
}

function updatePayer(string payerId, PayerFormData payload) returns error? {
    sql:ParameterizedQuery query = `UPDATE payers SET 
        name = ${payload.name}, 
        email = ${payload.email}, 
        state = ${payload.state}, 
        fhir_server_url = ${payload.fhir_server_url}, 
        app_client_id = ${payload.app_client_id}, 
        app_client_secret = ${payload.app_client_secret}, 
        token_url = ${payload.token_url}, 
        scopes = ${payload.scopes}, 
        updated_at = CURRENT_TIMESTAMP 
        WHERE id = ${payerId}`;
    
    sql:ExecutionResult|sql:Error result = dbClient->execute(query);
    if (result is sql:Error) {
        log:printError("Error updating payer: " + result.message());
        return result;
    }
}

function deletePayer(string payerId) returns error? {
    sql:ExecutionResult result = check dbClient->execute(`DELETE FROM payers WHERE id = ${payerId}`);
    
    if (result.affectedRowCount == 0) {
        return error("Payer not found");
    }
    
    return;
}

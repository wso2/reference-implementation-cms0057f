import ballerina/log;
import ballerina/sql;
import ballerina/uuid;

// ============================================
// Payer Management Utility Functions
// ============================================

function queryPayers(int page, int pageSize) returns Payer[]|error {
    Payer[] payers = [];
    do {
        stream<Payer, sql:Error?> dataStream = dbClient->query(
            `SELECT id, name, email, state, fhir_server_url, app_client_id, app_client_secret, token_url, scopes, created_at, updated_at FROM payers ORDER BY created_at DESC LIMIT ${pageSize} OFFSET ${(page - 1) * pageSize}`,
            Payer
        );
        var res = dataStream.next();
        while res is record {| Payer value; |}{
            payers.push(res.value);
            res = dataStream.next();
        }
    } on fail error e {
        log:printError("Error querying payers: " + e.message());
        return e;
    }
    return payers;
}

function getTotalPayers() returns int|error {
    record {| int count; |} result = check dbClient->queryRow(`SELECT COUNT(*) AS count FROM payers`);
    return result.count;
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

function createPayer(PayerFormData payload) returns Payer|error {
    string newPayerId = uuid:createType4AsString();
    sql:ParameterizedQuery query = `INSERT INTO payers (id, name, email, state, fhir_server_url, app_client_id, app_client_secret, token_url, scopes, created_at, updated_at) 
        VALUES (${newPayerId}, ${payload.name}, ${payload.email}, ${payload.state}, ${payload.fhir_server_url}, ${payload.app_client_id}, ${payload.app_client_secret}, ${payload.token_url}, ${payload.scopes}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) 
        RETURNING id, name, email, state, fhir_server_url, app_client_id, app_client_secret, token_url, scopes, created_at, updated_at`;
    Payer payer = check dbClient->queryRow(query, Payer);
    return payer;
}

function updatePayer(string payerId, PayerFormData payload) returns Payer|error? {
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
        WHERE id = ${payerId} 
        RETURNING id, name, email, state, fhir_server_url, app_client_id, app_client_secret, token_url, scopes, created_at, updated_at`;
    
    Payer|error? payer = dbClient->queryRow(query, Payer);
    if (payer is error) {
        log:printError("Error updating payer: " + payer.message());
        return payer;
    }
    return payer;
}

function deletePayer(string payerId) returns error? {
    sql:ExecutionResult result = check dbClient->execute(`DELETE FROM payers WHERE id = ${payerId}`);
    
    if (result.affectedRowCount == 0) {
        return error("Payer not found");
    }
    
    return;
}

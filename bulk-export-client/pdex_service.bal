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
import ballerina/http;
import ballerina/log;
import ballerina/url;
import ballerinax/health.fhir.r4.international401;

public listener http:Listener bulkExportListener = new (8091);

isolated service /pdex on bulkExportListener {

    // Resource function to capture payer data exchange request.
    //
    // @param payload - The payload containing the payer data exchange request.
    // @return The response indicating the success or failure of the operation.
    isolated resource function post 'capture\-pdex\-data(@http:Payload PayerDataExchangeRequest payload) returns json|error {
        string|error result = insertPayerDataExchangeRequest(payload);
        if result is error {
            log:printError("Error occurred while inserting payer data exchange request", result);
            return result;
        }
        return {requestId: result, message: "Payer data exchange request captured successfully"};
    }

    // Resource function to retrieve payer data exchange requests.
    //
    // @param 'limit - The number of records to retrieve (default 10).
    // @param offset - The number of records to skip (default 0).
    // @return The list of payer data exchange requests with pagination details.
    isolated resource function get 'pdex\-data\-requests(int 'limit = 10, int offset = 0) returns json|error {
        PayerDataExchangeRequestResult|error result = getPayerDataExchangeRequests('limit, offset);
        if result is error {
            log:printError("Error occurred while retrieving payer data exchange requests", result);
            return result;
        }

        string baseUrl = clientServiceConfig.baseUrl + "/pdex/pdex-data-requests";
        string? next = ();
        string? previous = ();

        if (offset + 'limit) < result.totalCount {
            next = string `${baseUrl}?limit=${'limit}&offset=${offset + 'limit}`;
        }

        if offset > 0 {
            int prevOffset = (offset - 'limit) > 0 ? (offset - 'limit) : 0;
            previous = string `${baseUrl}?limit=${'limit}&offset=${prevOffset}`;
        }

        return {
            count: result.totalCount,
            next: next,
            previous: previous,
            results: result.requests
        };
    }

    // Resource function to update payer data exchange request status.
    //
    // @param requestId - The ID of the request to update.
    // @param payload - The payload containing the new status.
    // @return The response indicating the success or failure of the operation.
    isolated resource function patch 'pdex\-data\-requests/[string requestId]/status(@http:Payload map<string> payload) returns json|error {
        string? status = payload["status"];
        if status is () {
            return error("Status is required in the payload");
        }
        string|error result = updatePayerDataExchangeRequestStatus(requestId, status);
        if result is error {
            log:printError("Error occurred while updating payer data exchange request status", result);
            return result;
        }
        return {message: result};
    }

    // Resource function to trigger payer data exchange.
    //
    // @param requestId - The ID of the request to trigger.
    // @return The response indicating the success or failure of the operation.
    isolated resource function post 'trigger\-data\-exchange/[string requestId]() returns json|error {

        PayerDataExchangeRequest|error request = getPayerDataExchangeRequest(requestId);
        if request is error {
            log:printError("Error occurred while fetching payer data exchange request", request);
            return error("Request ID not found");
        }

        if request.consent != "APPROVED" {
            return error("Consent not approved for data exchange.");
        }

        if request.bulkDataSyncStatus == "IN_PROGRESS" || request.bulkDataSyncStatus == "COMPLETED" {
            return error("Data exchange is already " + (request.bulkDataSyncStatus ?: "processed"));
        }

        // 1. Fetch request details - Done (request variable)

        // 2. Perform $member-match operation
        // We need the payer's old member ID and other details to construct the match request.
        // Fetch payer configuration/connection details from DB.

        PayerConfig payerConfig = check getPayerConfig(request.payerId);

        // Map PayerConfig to BulkExportServerConfig
        // Ideally we should use PayerConfig everywhere but for now mapping to existing type.
        BulkExportServerConfig serverConfig = {
            baseUrl: payerConfig.baseUrl,
            tokenUrl: payerConfig.tokenUrl,
            clientId: payerConfig.clientId,
            clientSecret: payerConfig.clientSecret,
            scopes: payerConfig.scopes,
            fileServerUrl: payerConfig.fileServerUrl,
            authEnabled: false
        };

        http:Client httpClient = check createHttpClient(serverConfig);

        international401:Parameters memberMatchParams = check createMemberMatchParams(request, httpClient);

        // Call $member-match
        http:Response|http:ClientError matchResponse = httpClient->post("/Patient/$member-match", memberMatchParams, mediaType = "application/fhir+json");

        if matchResponse is http:ClientError {
            log:printError("Error calling $member-match", matchResponse);
            return error("Error calling $member-match: " + matchResponse.message());
        }

        if matchResponse.statusCode < 200 || matchResponse.statusCode >= 300 {
            log:printError("Member match failed with status: " + matchResponse.statusCode.toString());
            return error("Member match failed");
        }

        json matchPayload = check matchResponse.getJsonPayload();
        // Extract MatchedPatient from response
        MatchedPatient matchedPatient = check extractMatchedPatient(matchPayload, payerConfig.baseUrl);

        string? _outputFormat = ();
        string? _since = request.coverageStartDate;

        // Defining types to export, maybe configurable or fixed for PDEX.
        string _type = "Patient,ExplanationOfBenefit,Coverage,AllergyIntolerance,Condition,Immunization,Procedure,Encounter,Observation";

        map<string> context = {
            "oldPayerName": request.oldPayerName,
            "payerId": request.payerId
        };

        json|error exportResult = triggerBulkExport([matchedPatient], _outputFormat, _since, _type, true, serverConfig, context);

        if exportResult is error {
            return exportResult;
        }

        // Update status to IN_PROGRESS
        _ = check updatePayerDataExchangeRequestStatus(requestId, "IN_PROGRESS");

        return exportResult;
    }

    // Resource function to retrieve synced data.
    //
    // @param payerId - The payer ID (old payer name/system)
    // @param memberId - The member ID
    // @param resourceTypes - Optional list of resource types to check.
    // @return The synced data from FHIR server.
    isolated resource function get 'synced\-data(string payerId, string memberId, string[]? resourceTypes) returns json|error {
        // Query FHIR server for resources with the specific tag and maybe memberId
        http:Client fhirClient = clientFhirClient;
        json[] results = [];
        string[] resourcesToCheck = ["ExplanationOfBenefit", "Coverage", "Condition", "Immunization", "Procedure", "Encounter", "Observation"];

        if resourceTypes is string[] && resourceTypes.length() > 0 {
            resourcesToCheck = resourceTypes;
        }

        foreach string resType in resourcesToCheck {
            string encodedMemberId = check url:encode(memberId, "UTF-8");
            string path = string `/${resType}?patient=${encodedMemberId}&_tag=http://wso2.com/fhir/pdex-source|old-payer-data`;
            http:Response|http:ClientError resp = fhirClient->get(path);
            if resp is http:Response && resp.statusCode == 200 {
                json|error payload = resp.getJsonPayload();
                if payload is json {
                    // Extract entry
                    map<json>|error bundle = payload.ensureType();
                    if bundle is map<json> && bundle.hasKey("entry") {
                        json|error entries = bundle.get("entry");
                        if entries is json[] {
                            foreach json entry in entries {
                                map<json>|error entryMap = entry.ensureType();
                                if entryMap is map<json> && entryMap.hasKey("resource") {
                                    results.push(entryMap.get("resource"));
                                }
                            }
                        }
                    }
                }
            }
        }

        return results;
    }
}

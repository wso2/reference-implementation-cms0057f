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
}

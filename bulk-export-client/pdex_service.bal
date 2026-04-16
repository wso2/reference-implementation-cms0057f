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
import ballerina/uuid;
import ballerinax/health.fhir.r4.international401;

public listener http:Listener bulkExportListener = new (8091);

isolated service /pdex on bulkExportListener {

    // Resource function to capture payer data exchange request.
    //
    // @param payload - The payload containing the payer data exchange request.
    // @return The response indicating the success or failure of the operation.
    isolated resource function post 'capture\-pdex\-data(@http:Payload PayerDataExchangeRequest payload) returns json|error {
        log:printDebug("Capturing payer data exchange request.", payerId = payload.payerId, oldPayerName = payload.oldPayerName);
        string|error result = insertPayerDataExchangeRequest(payload);
        if result is error {
            log:printError("Error occurred while inserting payer data exchange request", result);
            return result;
        }
        log:printDebug("Payer data exchange request captured.", requestId = result);
        return {requestId: result, message: "Payer data exchange request captured successfully"};
    }

    // Resource function to retrieve payer data exchange requests.
    //
    // @param 'limit - The number of records to retrieve (default 10).
    // @param offset - The number of records to skip (default 0).
    // @return The list of payer data exchange requests with pagination details.
    isolated resource function get 'pdex\-data\-requests(int 'limit = 10, int offset = 0) returns json|error {
        log:printDebug("Fetching payer data exchange requests.", pageLimit = 'limit.toString(), offset = offset.toString());
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

        log:printDebug("Returning payer data exchange request page.", resultCount = result.requests.length().toString(), totalCount = result.totalCount.toString());

        return {
            count: result.totalCount,
            next: next,
            previous: previous,
            results: result.requests
        };
    }

    // Resource function to retrieve a specific payer data exchange request.
    //
    // @param requestId - The ID of the request to retrieve.
    // @return The payer data exchange request details.
    isolated resource function get 'pdex\-data\-requests/[string requestId]() returns json|error {
        log:printDebug("Fetching payer data exchange request by ID.", requestId = requestId);
        PayerDataExchangeRequest|error request = getPayerDataExchangeRequest(requestId);
        if request is error {
            log:printError("Error occurred while fetching payer data exchange request", request);
            return error("Request ID not found");
        }
        return request;
    }

    // Resource function to update payer data exchange request status.
    //
    // @param requestId - The ID of the request to update.
    // @param payload - The payload containing the new status.
    // @return The response indicating the success or failure of the operation.
    isolated resource function patch 'pdex\-data\-requests/[string requestId]/status(@http:Payload map<string> payload) returns json|error {
        log:printDebug("Updating payer data exchange request status.", requestId = requestId);
        string? status = payload["status"];
        if status is () {
            return error("Status is required in the payload");
        }
        string|error result = updatePayerDataExchangeRequestStatus(requestId, status);
        if result is error {
            log:printError("Error occurred while updating payer data exchange request status", result);
            return result;
        }
        log:printDebug("Payer data exchange request status updated.", requestId = requestId, status = status);
        return {message: result};
    }

    // Resource function to trigger payer data exchange.
    //
    // @param requestId - The ID of the request to trigger.
    // @return The response indicating the success or failure of the operation.
    isolated resource function post 'trigger\-data\-exchange/[string requestId]() returns json|error {
        log:printDebug("Trigger data exchange invoked.", requestId = requestId);

        PayerDataExchangeRequest|error request = getPayerDataExchangeRequest(requestId);
        if request is error {
            log:printError("Error occurred while fetching payer data exchange request", request);
            return error("Request ID not found");
        }

        log:printDebug("Loaded payer data exchange request.", requestId = requestId, payerId = request.payerId, consent = request.consent ?: "");

        if !(request.consent ?: "").equalsIgnoreCaseAscii("APPROVED") {
            error consentError = error("Consent not approved for data exchange.");
            string|error dbResult = updatePayerDataExchangeRequestStatus(requestId, "FAILED");
            if dbResult is error {
                log:printError("Failed to update request status after consent rejection", dbResult, requestId = requestId);
            }
            return consentError;
        }

        if request.bulkDataSyncStatus == "IN_PROGRESS" || request.bulkDataSyncStatus == "COMPLETED" {
            return error("Data exchange is already " + (request.bulkDataSyncStatus ?: "processed"));
        }

        // 1. Fetch request details - Done (request variable)

        // 2. Perform $member-match operation
        // We need the payer's old member ID and other details to construct the match request.
        // Fetch payer configuration/connection details from DB.

        PayerConfig payerConfig = check getPayerConfig(request.payerId);
        log:printDebug("Loaded payer configuration for member match.", requestId = requestId, payerId = request.payerId, baseUrl = payerConfig.baseUrl);

        // Map PayerConfig to BulkExportServerConfig
        // Ideally we should use PayerConfig everywhere but for now mapping to existing type.
        BulkExportServerConfig serverConfig = {
            baseUrl: payerConfig.baseUrl,
            tokenUrl: payerConfig.tokenUrl,
            clientId: payerConfig.clientId,
            clientSecret: payerConfig.clientSecret,
            scopes: payerConfig.scopes,
            fileServerUrl: payerConfig.fileServerUrl,
            authEnabled: payerConfig.authEnabled
        };

        http:Client|error httpClient = createHttpClient(serverConfig);
        if httpClient is error {
            log:printError("Error creating HTTP client for member match", httpClient);
            string|error dbResult = updatePayerDataExchangeRequestStatus(requestId, "FAILED");
            if dbResult is error {
                log:printError("Failed to update request status after HTTP client creation error", dbResult, requestId = requestId);
            }
            return error("Error creating HTTP client: " + httpClient.message());
        }

        international401:Parameters memberMatchParams = check createMemberMatchParams(request, httpClient);
        log:printDebug("Created member match parameters.", requestId = requestId);

        // Call $member-match
        log:printDebug("Calling member-match endpoint.", requestId = requestId, path = "/Patient/$member-match");
        http:Response|http:ClientError matchResponse = httpClient->post("/Patient/$member-match", memberMatchParams, mediaType = "application/fhir+json");

        if matchResponse is http:ClientError {
            log:printError("Error calling $member-match", matchResponse);
            error memberMatchError = error("Error calling $member-match: " + matchResponse.message());
            string|error dbResult = updatePayerDataExchangeRequestStatus(requestId, "FAILED");
            if dbResult is error {
                log:printError("Failed to update request status after $member-match client error", dbResult, requestId = requestId);
            }
            return memberMatchError;
        }

        if matchResponse.statusCode < 200 || matchResponse.statusCode >= 300 {
            log:printError("Member match failed with status: " + matchResponse.statusCode.toString());
            error memberMatchError = error("Member match failed");
            string|error dbResult = updatePayerDataExchangeRequestStatus(requestId, "FAILED");
            if dbResult is error {
                log:printError("Failed to update request status after $member-match failure", dbResult, requestId = requestId);
            }
            return memberMatchError;
        }

        log:printDebug("Member match succeeded.", requestId = requestId, statusCode = matchResponse.statusCode.toString());

        json matchPayload = check matchResponse.getJsonPayload();
        // Extract MatchedPatient from response
        MatchedPatient matchedPatient = check extractMatchedPatient(matchPayload, payerConfig.baseUrl);
        log:printDebug("Extracted matched patient.", requestId = requestId, patientId = matchedPatient.id, systemId = matchedPatient.systemId ?: "");

        string? _outputFormat = ();
        string? _since = ();
        // string? _since = request.coverageStartDate;
        // TODO: _since parameter is not supported for /Patient/ID/$export in fhir repository
        // Issue: https://github.com/wso2-enterprise/open-healthcare/issues/2005

        // Defining types to export, maybe configurable or fixed for PDEX.
        string _type = "Patient,ExplanationOfBenefit,Coverage,AllergyIntolerance,Condition,Immunization,Procedure,Encounter,Observation";

        map<string> context = {
            "oldPayerName": request.oldPayerName,
            "payerId": request.payerId,
            "requestId": requestId
        };

        log:printDebug("Triggering bulk export for matched patient.", requestId = requestId, exportTypes = _type);

        json|error exportResult = triggerBulkExport([matchedPatient], _outputFormat, _since, _type, true, serverConfig, context);

        if exportResult is error {
            return exportResult;
        }

        // Update status to IN_PROGRESS
        _ = check updatePayerDataExchangeRequestStatus(requestId, "IN_PROGRESS");
        log:printDebug("Updated data exchange status to IN_PROGRESS.", requestId = requestId);

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
        log:printDebug("Fetching synced data.", payerId = payerId, memberId = memberId);
        http:Client fhirClient = clientFhirClient;
        json[] results = [];
        string[] resourcesToCheck = ["ExplanationOfBenefit", "Coverage", "Condition", "Immunization", "Procedure", "Encounter", "Observation"];

        if resourceTypes is string[] && resourceTypes.length() > 0 {
            resourcesToCheck = resourceTypes;
        }

        log:printDebug("Resolved resource types to query.", resourceCount = resourcesToCheck.length().toString());

        foreach string resType in resourcesToCheck {
            string encodedMemberId = check url:encode(memberId, "UTF-8");
            string path = string `/${resType}?patient=${encodedMemberId}`;
            log:printDebug("Querying resource type for synced data.", resourceType = resType, path = path);
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
            } else if resp is http:Response {
                log:printDebug("FHIR query returned non-200 status.", resourceType = resType, statusCode = resp.statusCode.toString());
            } else {
                log:printDebug("FHIR query failed.", resourceType = resType, reason = resp.message());
            }
        }

        log:printDebug("Completed synced data fetch.", resultCount = results.length().toString());

        return results;
    }

    // Resource function to reset a stuck IN_PROGRESS request back to PENDING.
    //
    // @param requestId - The ID of the request to reset.
    // @return The response indicating the success or failure of the operation.
    isolated resource function post 'pdex\-data\-requests/[string requestId]/reset()
            returns json|http:BadRequest|http:NotFound|error {
        log:printDebug("Reset request invoked.", requestId = requestId);
        PayerDataExchangeRequest|error req = getPayerDataExchangeRequest(requestId);
        if req is error {
            return <http:NotFound>{body: {message: "Request not found", requestId: requestId}};
        }
        if req.bulkDataSyncStatus != "IN_PROGRESS" {
            return <http:BadRequest>{body: {
                message: "Only IN_PROGRESS requests can be reset",
                requestId: requestId,
                currentStatus: req.bulkDataSyncStatus
            }};
        }
        string|error result = updatePayerDataExchangeRequestStatus(requestId, "PENDING");
        if result is error {
            log:printError("Failed to reset request status to PENDING", result, requestId = requestId);
            return result;
        }
        log:printInfo("Request reset to PENDING.", requestId = requestId);
        return {message: "Request reset to PENDING", requestId: requestId};
    }

    // Resource function to trigger bulk payer data exchange using $bulk-member-match.
    //
    // @param payload - List of requestIds to batch into a single $bulk-member-match call.
    // @return batchId and status, or error.
    isolated resource function post 'trigger\-bulk\-data\-exchange(
        @http:Payload TriggerBulkDataExchangeRequest payload
    ) returns http:Response|http:BadRequest|http:Conflict|error {

        string[] requestIds = payload.requestIds;
        if requestIds.length() == 0 {
            return <http:BadRequest>{body: {message: "At least one requestId is required"}};
        }

        // 1. Load and validate all requests
        PayerDataExchangeRequest[] requests = [];
        foreach string reqId in requestIds {
            PayerDataExchangeRequest req = check getPayerDataExchangeRequest(reqId);
            if !(req.consent ?: "").equalsIgnoreCaseAscii("APPROVED") {
                return <http:BadRequest>{body: {
                    message: "Consent not approved for requestId: " + reqId,
                    requestId: reqId
                }};
            }
            if req.bulkDataSyncStatus == "IN_PROGRESS" || req.bulkDataSyncStatus == "COMPLETED" {
                return <http:Conflict>{body: {
                    message: "Request " + reqId + " is already " + (req.bulkDataSyncStatus ?: "processed"),
                    requestId: reqId,
                    currentStatus: req.bulkDataSyncStatus
                }};
            }
            requests.push(req);
        }

        // 2. Validate all requests belong to same payer
        string payerId = requests[0].payerId;
        foreach PayerDataExchangeRequest req in requests {
            if req.payerId != payerId {
                return <http:BadRequest>{body: {
                    message: "All requestIds must belong to the same payer",
                    requestId: req.requestId ?: ""
                }};
            }
        }

        // 3. Load payer config + build serverConfig
        PayerConfig payerConfig = check getPayerConfig(payerId);
        BulkExportServerConfig serverConfig = {
            baseUrl: payerConfig.baseUrl,
            tokenUrl: payerConfig.tokenUrl,
            clientId: payerConfig.clientId,
            clientSecret: payerConfig.clientSecret,
            scopes: payerConfig.scopes,
            fileServerUrl: payerConfig.fileServerUrl,
            authEnabled: payerConfig.authEnabled
        };

        // 4. Create HTTP client pointed at old payer, fetch Patient resources from LOCAL FHIR server
        http:Client httpClient = check createHttpClient(serverConfig);

        // 5. Build bulk member match Parameters JSON
        BulkMatchParamsResult paramsResult = check buildBulkMemberMatchParams(requests, clientFhirClient);

        // 6. POST to $bulk-member-match (async)
        http:Response|http:ClientError matchResponse = httpClient->post(
            "/Group/$bulk-member-match",
            paramsResult.params,
            headers = {"Prefer": "respond-async"},
            mediaType = "application/fhir+json"
        );
        if matchResponse is http:ClientError {
            return error("Error calling $bulk-member-match: " + matchResponse.message());
        }
        if matchResponse.statusCode != 202 {
            return error("$bulk-member-match returned unexpected status: "
                + matchResponse.statusCode.toString());
        }

        // 7. Get polling URL from Content-Location header
        string pollingUrl = check matchResponse.getHeader("content-location");

        // 8. Persist the bulk export job and link requests to it
        string jobId = uuid:createType1AsString();
        BulkExportJob newJob = {
            jobId: jobId,
            payerId: payerId,
            status: "INITIATED"
        };
        _ = check insertBulkExportJob(newJob);
        _ = check linkRequestsToBulkJob(requestIds, jobId);
        _ = check updateBulkExportJobStatus(jobId, "BULK_MATCH_POLLING");

        log:printInfo("$bulk-member-match accepted.",
            jobId = jobId, pollingUrl = pollingUrl,
            memberCount = paramsResult.memberIdToRequestIdMap.length());
        log:printDebug("$bulk-member-match request payload.",
            jobId = jobId, payload = paramsResult.params.toJsonString());

        // 9. Schedule Stage 1 background polling task
        _ = check scheduleBulkMatchJob(
            new BulkMatchPollingTask(
                jobId,
                pollingUrl,
                serverConfig,
                paramsResult.memberIdToRequestIdMap,
                requestIds,
                payerId,
                requests[0].oldPayerName
            ),
            clientServiceConfig.defaultIntervalInSec
        );

        // 10. Update all requests to BULK_MATCH_SUBMITTED
        foreach string reqId in requestIds {
            _ = check updatePayerDataExchangeRequestStatus(reqId, "BULK_MATCH_SUBMITTED");
        }

        log:printInfo("Bulk member match initiated.", jobId = jobId, requestCount = requestIds.length());
        string statusUrl = clientServiceConfig.baseUrl + "/pdex/bulk-export-jobs/" + jobId;
        http:Response resp = new;
        resp.statusCode = 202;
        resp.setHeader("Content-Location", statusUrl);
        resp.setJsonPayload({
            jobId: jobId,
            message: "Bulk member match initiated",
            requestCount: requestIds.length(),
            statusUrl: statusUrl
        });
        return resp;
    }

    // Resource function to poll bulk export job status.
    //
    // @param jobId - The bulk export job ID returned by trigger-bulk-data-exchange.
    // @return Combined job status and individual request statuses.
    isolated resource function get 'bulk\-export\-jobs/[string jobId]()
            returns BulkExportJobStatusResponse|http:NotFound|error {
        log:printDebug("Fetching bulk export job status.", jobId = jobId);
        BulkExportJob|error job = getBulkExportJob(jobId);
        if job is error {
            return <http:NotFound>{body: {message: "Bulk export job not found", jobId: jobId}};
        }
        PayerDataExchangeRequest[]|error requests = getRequestsByBulkJobId(jobId);
        if requests is error {
            log:printError("Error fetching requests for bulk job", requests, jobId = jobId);
            return requests;
        }
        return {job: job, requests: requests};
    }
}

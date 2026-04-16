// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
// Licensed under the Apache License, Version 2.0.

import ballerina/http;
import ballerina/log;
import ballerina/task;

// ─── helpers ────────────────────────────────────────────────────────────────

isolated function updateJobStatus(string jobId, string status) {
    string|error res = updateBulkExportJobStatus(jobId, status);
    if res is error {
        log:printError("Failed to update bulk export job status.", res, jobId = jobId, status = status);
    }
}

isolated function markAllFailed(string[] requestIds, string label) {
    foreach string reqId in requestIds {
        string|error res = updatePayerDataExchangeRequestStatus(reqId, "FAILED");
        if res is error {
            log:printError("Failed to mark request FAILED (" + label + ").", res, requestId = reqId);
        }
    }
}

isolated function safeUnschedule(task:JobId scheduledId, string label) {
    error? res = unscheduleJob(scheduledId);
    if res is error {
        log:printError("Error unscheduling job (" + label + ").", res);
    }
}

// ─── Stage 1: poll $bulk-member-match ───────────────────────────────────────

const int BULK_MATCH_MAX_POLLS = 60;

public class BulkMatchPollingTask {
    *task:Job;

    string jobId;
    string pollingUrl;
    BulkExportServerConfig serverConfig;
    map<string> memberIdToRequestIdMap;
    string[] requestIds;
    string payerId;
    string oldPayerName;
    task:JobId scheduledJobId = {id: 0};
    int pollCount = 0;

    public isolated function init(
        string jobId,
        string pollingUrl,
        BulkExportServerConfig serverConfig,
        map<string> memberIdToRequestIdMap,
        string[] requestIds,
        string payerId,
        string oldPayerName
    ) {
        self.jobId = jobId;
        self.pollingUrl = pollingUrl;
        self.serverConfig = serverConfig;
        self.memberIdToRequestIdMap = memberIdToRequestIdMap;
        self.requestIds = requestIds;
        self.payerId = payerId;
        self.oldPayerName = oldPayerName;
    }

    public function execute() {
        do {
            self.pollCount += 1;
            log:printDebug("BulkMatchPollingTask poll attempt.",
                jobId = self.jobId,
                pollCount = self.pollCount,
                maxPolls = BULK_MATCH_MAX_POLLS,
                pollingUrl = self.pollingUrl);

            if self.pollCount > BULK_MATCH_MAX_POLLS {
                log:printError("BulkMatchPollingTask timed out — max polls exceeded.",
                    jobId = self.jobId, polls = self.pollCount);
                updateJobStatus(self.jobId, "FAILED");
                markAllFailed(self.requestIds, "polling-timeout");
                safeUnschedule(self.getScheduledJobId(), "BulkMatchPollingTask-timeout");
                return;
            }

            BulkExportServerConfig pollingConfig = check self.serverConfig.cloneWithType();
            pollingConfig.baseUrl = self.pollingUrl;
            http:Client pollingClient = check createHttpClient(pollingConfig);
            http:Response resp = check pollingClient->/;

            int statusCode = resp.statusCode;
            log:printDebug("BulkMatchPollingTask poll response.",
                jobId = self.jobId,
                pollCount = self.pollCount,
                statusCode = statusCode);

            if statusCode == 202 {
                log:printDebug("Bulk match still processing.", jobId = self.jobId);
                return;
            }

            // Unschedule Stage 1 — terminal response (200 or error)
            safeUnschedule(self.getScheduledJobId(), "BulkMatchPollingTask");

            if statusCode != 200 {
                log:printError("Bulk match polling unexpected status.",
                    statusCode = statusCode, jobId = self.jobId);
                updateJobStatus(self.jobId, "FAILED");
                markAllFailed(self.requestIds, "unexpected-status");
                return;
            }

            // 200 — parse result
            json payload = check resp.getJsonPayload();
            log:printDebug("Bulk match 200 response payload.",
                jobId = self.jobId, payload = payload.toJsonString());
            BulkMatchResponseResult result = check extractBulkMatchResult(
                payload, self.memberIdToRequestIdMap);
            log:printDebug("Bulk match result extracted.",
                jobId = self.jobId,
                matchedGroupId = result.matchedGroupId,
                matchedCount = result.matchedRequestIds.length(),
                nonMatchedCount = result.nonMatchedRequestIds.length(),
                consentConstrainedCount = result.consentConstrainedRequestIds.length(),
                matchedRequestIds = result.matchedRequestIds.toString(),
                nonMatchedRequestIds = result.nonMatchedRequestIds.toString(),
                consentConstrainedRequestIds = result.consentConstrainedRequestIds.toString());

            // Update job status
            updateJobStatus(self.jobId, "BULK_MATCH_COMPLETED");

            // Set granular statuses for non-matched / consent-constrained
            foreach string reqId in result.nonMatchedRequestIds {
                string|error res = updatePayerDataExchangeRequestStatus(reqId, "NOT_MATCHED");
                if res is error {
                    log:printError("Failed to mark request NOT_MATCHED.", res, requestId = reqId);
                }
            }
            foreach string reqId in result.consentConstrainedRequestIds {
                string|error res = updatePayerDataExchangeRequestStatus(reqId, "CONSENT_CONSTRAINED");
                if res is error {
                    log:printError("Failed to mark request CONSENT_CONSTRAINED.", res, requestId = reqId);
                }
            }

            // Detect requests absent from all categories — correlation failure or omitted by old payer.
            // These are process errors, not genuine non-matches, so mark them FAILED.
            string[] coveredIds = [];
            foreach string id in result.matchedRequestIds { coveredIds.push(id); }
            foreach string id in result.nonMatchedRequestIds { coveredIds.push(id); }
            foreach string id in result.consentConstrainedRequestIds { coveredIds.push(id); }

            boolean hadUnaccountedRequests = false;
            foreach string reqId in self.requestIds {
                if coveredIds.indexOf(reqId) == () {
                    hadUnaccountedRequests = true;
                    log:printError("Request not accounted for in bulk match response — marking FAILED.",
                        requestId = reqId, jobId = self.jobId);
                    string|error res = updatePayerDataExchangeRequestStatus(reqId, "FAILED");
                    if res is error {
                        log:printError("Failed to mark unaccounted request FAILED.", res, requestId = reqId);
                    }
                }
            }

            if result.matchedRequestIds.length() == 0 {
                string finalJobStatus = hadUnaccountedRequests ? "FAILED" : "COMPLETED";
                log:printInfo("No matched members — closing job.",
                    jobId = self.jobId, status = finalJobStatus);
                updateJobStatus(self.jobId, finalJobStatus);
                return;
            }

            // Mark matched requests as EXPORT_IN_PROGRESS
            foreach string reqId in result.matchedRequestIds {
                string|error res = updatePayerDataExchangeRequestStatus(reqId, "EXPORT_IN_PROGRESS");
                if res is error {
                    log:printError("Failed to mark request EXPORT_IN_PROGRESS.", res, requestId = reqId);
                }
            }

            // Kick off $davinci-data-export
            http:Client exportClient = check createHttpClient(self.serverConfig);
            http:Response|http:ClientError exportResp = exportClient->post(
                "/Group/" + result.matchedGroupId + "/$davinci-data-export",
                (),
                headers = {"Prefer": "respond-async"},
                mediaType = "application/fhir+json"
            );

            if exportResp is http:ClientError {
                log:printError("$davinci-data-export call failed.", exportResp, jobId = self.jobId);
                updateJobStatus(self.jobId, "FAILED");
                markAllFailed(result.matchedRequestIds, "export-client-error");
                return;
            }

            if exportResp.statusCode != 202 {
                string|error errBody = exportResp.getTextPayload();
                log:printError("$davinci-data-export unexpected status.",
                    statusCode = exportResp.statusCode, jobId = self.jobId,
                    body = errBody is string ? errBody : "(no body)");
                updateJobStatus(self.jobId, "FAILED");
                markAllFailed(result.matchedRequestIds, "export-status-error");
                return;
            }

            string exportPollingUrl = check exportResp.getHeader("content-location");
            log:printInfo("$davinci-data-export accepted.",
                jobId = self.jobId, pollingUrl = exportPollingUrl);

            // Advance job to EXPORT_POLLING stage
            updateJobStatus(self.jobId, "EXPORT_POLLING");

            error? schedErr = scheduleDaVinciExportJob(
                new DaVinciExportPollingTask(
                    self.jobId, exportPollingUrl, self.serverConfig,
                    result.matchedRequestIds, self.payerId, self.oldPayerName
                ),
                clientServiceConfig.defaultIntervalInSec
            );
            if schedErr is error {
                log:printError("Failed to schedule DaVinci export polling.", schedErr, jobId = self.jobId);
                updateJobStatus(self.jobId, "FAILED");
                markAllFailed(result.matchedRequestIds, "schedule-error");
            }

        } on fail var e {
            log:printError("BulkMatchPollingTask error. Marking all FAILED.", e, jobId = self.jobId);
            updateJobStatus(self.jobId, "FAILED");
            markAllFailed(self.requestIds, "task-on-fail");
            safeUnschedule(self.getScheduledJobId(), "BulkMatchPollingTask-on-fail");
        }
    }

    public isolated function setId(task:JobId scheduledId) {
        lock {
            self.scheduledJobId = scheduledId;
        }
    }

    public isolated function getScheduledJobId() returns task:JobId {
        lock {
            return self.scheduledJobId;
        }
    }
}

// ─── Stage 2: poll $davinci-data-export ─────────────────────────────────────

const int DAVINCI_EXPORT_MAX_POLLS = 60;

public class DaVinciExportPollingTask {
    *task:Job;

    string jobId;
    string pollingUrl;
    BulkExportServerConfig serverConfig;
    string[] matchedRequestIds;
    string payerId;
    string oldPayerName;
    task:JobId scheduledJobId = {id: 0};
    int pollCount = 0;

    public isolated function init(
        string jobId,
        string pollingUrl,
        BulkExportServerConfig serverConfig,
        string[] matchedRequestIds,
        string payerId,
        string oldPayerName
    ) {
        self.jobId = jobId;
        self.pollingUrl = pollingUrl;
        self.serverConfig = serverConfig;
        self.matchedRequestIds = matchedRequestIds;
        self.payerId = payerId;
        self.oldPayerName = oldPayerName;
    }

    public function execute() {
        do {
            self.pollCount += 1;
            log:printDebug("DaVinciExportPollingTask poll attempt.",
                jobId = self.jobId,
                pollCount = self.pollCount,
                maxPolls = DAVINCI_EXPORT_MAX_POLLS,
                pollingUrl = self.pollingUrl);

            if self.pollCount > DAVINCI_EXPORT_MAX_POLLS {
                log:printError("DaVinciExportPollingTask timed out — max polls exceeded.",
                    jobId = self.jobId, polls = self.pollCount);
                updateJobStatus(self.jobId, "FAILED");
                markAllFailed(self.matchedRequestIds, "davinci-polling-timeout");
                safeUnschedule(self.getScheduledJobId(), "DaVinciExportPollingTask-timeout");
                return;
            }

            BulkExportServerConfig pollingConfig = check self.serverConfig.cloneWithType();
            pollingConfig.baseUrl = self.pollingUrl;
            http:Client pollingClient = check createHttpClient(pollingConfig);
            http:Response resp = check pollingClient->/;

            int statusCode = resp.statusCode;
            log:printDebug("DaVinciExportPollingTask poll response.",
                jobId = self.jobId,
                pollCount = self.pollCount,
                statusCode = statusCode);

            if statusCode == 202 {
                log:printDebug("DaVinci export still processing.", jobId = self.jobId);
                return;
            }

            // Unschedule Stage 2 — terminal response
            safeUnschedule(self.getScheduledJobId(), "DaVinciExportPollingTask");

            if statusCode != 200 {
                log:printError("DaVinci export polling unexpected status.",
                    statusCode = statusCode, jobId = self.jobId);
                updateJobStatus(self.jobId, "FAILED");
                markAllFailed(self.matchedRequestIds, "davinci-unexpected-status");
                return;
            }

            // 200 — advance to SYNCING and sync data
            updateJobStatus(self.jobId, "SYNCING");
            foreach string reqId in self.matchedRequestIds {
                string|error res = updatePayerDataExchangeRequestStatus(reqId, "SYNCING");
                if res is error {
                    log:printError("Failed to mark request SYNCING.", res, requestId = reqId);
                }
            }

            json payload = check resp.getJsonPayload();
            log:printDebug("DaVinci export manifest received.",
                jobId = self.jobId, manifest = payload.toJsonString());
            map<string> context = {
                "jobId": self.jobId,
                "payerId": self.payerId,
                "oldPayerName": self.oldPayerName
            };

            error? syncErr = syncDataToFhirServer(self.jobId, payload, self.serverConfig, context);
            if syncErr is error {
                log:printError("Sync failed.", syncErr, jobId = self.jobId);
                updateJobStatus(self.jobId, "FAILED");
                markAllFailed(self.matchedRequestIds, "sync-error");
                return;
            }

            // Sync succeeded — mark COMPLETED
            updateJobStatus(self.jobId, "COMPLETED");
            foreach string reqId in self.matchedRequestIds {
                string|error res = updatePayerDataExchangeRequestStatus(reqId, "COMPLETED");
                if res is error {
                    log:printError("Failed to mark request COMPLETED.", res, requestId = reqId);
                } else {
                    log:printInfo("Request marked COMPLETED.", requestId = reqId, jobId = self.jobId);
                }
            }

        } on fail var e {
            log:printError("DaVinciExportPollingTask error. Marking matched FAILED.", e, jobId = self.jobId);
            updateJobStatus(self.jobId, "FAILED");
            markAllFailed(self.matchedRequestIds, "davinci-task-on-fail");
            safeUnschedule(self.getScheduledJobId(), "DaVinciExportPollingTask-on-fail");
        }
    }

    public isolated function setId(task:JobId scheduledId) {
        lock {
            self.scheduledJobId = scheduledId;
        }
    }

    public isolated function getScheduledJobId() returns task:JobId {
        lock {
            return self.scheduledJobId;
        }
    }
}

// ─── Schedulers ─────────────────────────────────────────────────────────────

public isolated function scheduleBulkMatchJob(
    BulkMatchPollingTask job,
    decimal interval
) returns error? {
    task:JobId id = check task:scheduleJobRecurByFrequency(job, interval);
    job.setId(id);
}

public isolated function scheduleDaVinciExportJob(
    DaVinciExportPollingTask job,
    decimal interval
) returns error? {
    task:JobId id = check task:scheduleJobRecurByFrequency(job, interval);
    job.setId(id);
}

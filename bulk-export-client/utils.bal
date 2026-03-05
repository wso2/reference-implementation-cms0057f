import ballerina/file;
// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
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
import ballerina/ftp;
import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/task;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;

# Create HTTP client with optional authentication.
#
# + serverConfig - Server configuration containing auth details
# + return - HTTP client instance or error
public isolated function createHttpClient(BulkExportServerConfig|ClientFhirServerConfig|PayerConfig serverConfig) returns http:Client|error {
    map<json> configMap = check serverConfig.cloneWithType();

    boolean authEnabled = false;
    if configMap.hasKey("authEnabled") {
        authEnabled = check configMap.get("authEnabled").ensureType();
    }

    string baseUrl = "";
    if configMap.hasKey("baseUrl") {
        baseUrl = check configMap.get("baseUrl").ensureType();
    }

    if authEnabled {
        string tokenUrl = "";
        if configMap.hasKey("tokenUrl") {
            tokenUrl = check configMap.get("tokenUrl").ensureType();
        }
        if tokenUrl.length() == 0 {
            return error("Missing required field: tokenUrl for OAuth2 authentication.");
        }

        string clientId = "";
        if configMap.hasKey("clientId") {
            clientId = check configMap.get("clientId").ensureType();
        }
        if clientId.length() == 0 {
            return error("Missing required field: clientId for OAuth2 authentication.");
        }

        string clientSecret = "";
        if configMap.hasKey("clientSecret") {
            clientSecret = check configMap.get("clientSecret").ensureType();
        }

        string[]? scopes = ();
        if configMap.hasKey("scopes") {
            json scopesJson = configMap.get("scopes");
            if scopesJson is json[] {
                scopes = check scopesJson.cloneWithType();
            }
        }

        http:OAuth2ClientCredentialsGrantConfig config = {
            tokenUrl: tokenUrl,
            clientId: clientId,
            clientSecret: clientSecret,
            scopes: scopes
        };
        return check new (baseUrl, auth = config);
    } else {
        return check new (baseUrl);
    }
}

# Fetch target payer config dynamically.
#
# + payerId - Payer ID to retrieve configuration for.
# + return - PayerConfig instance or error
public isolated function getTargetPayerConfig(string payerId) returns PayerConfig|error {
    string bffUrl = clientServiceConfig.bffUrl;
    http:Client bffClient = check new (bffUrl);

    // Call <BFF_URL>/payers/<payer_id>
    http:Response|error bffResponse = bffClient->get("/payers/" + payerId);
    if bffResponse is error {
        log:printError("Error fetching payer config from BFF", 'error = bffResponse);
        return error("Failed to retrieve payer config from BFF.");
    }

    if bffResponse.statusCode != 200 {
        return error("BFF returned non-200 status code: " + bffResponse.statusCode.toString());
    }

    json payload = check bffResponse.getJsonPayload();
    map<json> payloadMap = <map<json>>payload;

    string payerName = <string>payloadMap["name"];
    string fhirServerUrl = <string>payloadMap["fhir_server_url"];
    string clientId = <string>payloadMap["app_client_id"];
    string clientSecret = <string>payloadMap["app_client_secret"];
    string smartConfigUrl = <string>payloadMap["smart_config_url"];

    string[] scopes = [];
    if payloadMap["scopes"] != null {
        // Handle scopes appropriately if needed. Assuming comma separated if present.
        string scopesStr = <string>payloadMap["scopes"];
        if scopesStr != "" {
            scopes = re `,`.split(scopesStr);
        }
    }

    string defaultTokenUrl = fhirServerUrl + "/token";
    http:Client|error smartConfigClient = new (smartConfigUrl);
    if smartConfigClient is error {
        log:printWarn("Failed to create HTTP client for SMART configuration", 'error = smartConfigClient);
    } else {
        http:Response|error smartConfigResponse = smartConfigClient->get("/.well-known/smart-configuration");
        if smartConfigResponse is http:Response {
            var smartPayload = smartConfigResponse.getJsonPayload();
            if smartPayload is json {
                map<json> smartPayloadMap = <map<json>>smartPayload;
                string tokenUrl = <string>smartPayloadMap["token_endpoint"];
                if tokenUrl != "" {
                    defaultTokenUrl = tokenUrl;
                }
            }
        }
    }

    PayerConfig config = {
        payerId: payerId,
        payerName: payerName,
        baseUrl: fhirServerUrl,
        tokenUrl: defaultTokenUrl,
        clientId: clientId,
        clientSecret: clientSecret,
        scopes: scopes,
        fileServerUrl: (),
        authEnabled: true
    };
    return config;
}

# Schedule Ballerina task .
#
# + job - Polling task to be executed  
# + interval - interval to execute the job
# + return - assigned job id
public isolated function executeJob(PollingTask job, decimal interval) returns task:JobId|error? {

    // Implement the job execution logic here
    task:JobId id = check task:scheduleJobRecurByFrequency(job, interval);
    job.setId(id);
    return id;
}

# Terminate periodic task.
#
# + id - job id to be terminated
# + return - error if failed to terminate the job
public isolated function unscheduleJob(task:JobId id) returns error? {

    // Implement the job termination logic here
    log:printDebug("Unscheduling the job.", Jobid = id);
    task:Error? unscheduleJob = task:unscheduleJob(id);
    if unscheduleJob is task:Error {
        log:printError("Error occurred while unscheduling the job.", unscheduleJob);
    }
    return null;
}

# Get ndjson content as stream.
#
# + downloadLink - file location
# + statusClientV2 - http Client instance
# + return - byte array stream of content
public isolated function getFileAsStream(string downloadLink, http:Client statusClientV2) returns stream<byte[], io:Error?>|error? {

    http:Response|http:ClientError statusResponse = statusClientV2->get("/");
    if statusResponse is http:Response {
        int status = statusResponse.statusCode;
        if status == 200 {
            stream<byte[], io:Error?>|error? byteStream = statusResponse.getByteStream();
            if byteStream is stream<byte[], io:Error?> {
                return byteStream;
            } else {
                log:printError("Byte stream is not available as payload");
            }
        } else {
            log:printError("Error occurred while getting the status.");
        }
    } else {
        log:printError("Error occurred while getting the status.", statusResponse);
    }
    return null;
}

# Write file into file system.
#
# + downloadLink - file location  
# + fileName - file name
# + return - error if failed
public isolated function saveFileInFS(string downloadLink, string fileName) returns error? {

    http:Client statusClientV2 = check new (downloadLink);
    stream<byte[], io:Error?> streamer = check getFileAsStream(downloadLink, statusClientV2) ?: new ();

    check io:fileWriteBlocksFromStream(fileName, streamer);
    check streamer.close();
    log:printDebug(string `Successfully downloaded the file. File name: ${fileName}`);
}

# Send file from file system to a file server via ftp.
#
# + config - server config
# + sourcePath - file path
# + fileName - file name
# + return - error if failed
public isolated function sendFileFromFSToFTP(TargetServerConfig config, string sourcePath, string fileName) returns error? {
    // Implement the FTP server logic here.
    ftp:Client fileClient = check new ({
        host: config.host ?: "",
        auth: {
            credentials: {
                username: config.username ?: "",
                password: config.password ?: ""
            }
        }
    });
    stream<io:Block, io:Error?> fileStream
        = check io:fileReadBlocksAsStream(sourcePath, 1024);
    check fileClient->put(string `${config.directory ?: ""}/${fileName}`, fileStream);
    check fileStream.close();
}

# Util method to handle file download.
#
# + exportSummary - metadata of the export
# + exportId - assigned export id, (local reference)
# + return - error if failed
public isolated function downloadFiles(json exportSummary, string exportId) returns error? {

    ExportSummary exportSummary1 = check exportSummary.cloneWithType(ExportSummary);

    foreach OutputFile item in exportSummary1.output {
        log:printDebug("Downloading the file.", url = item.url);
        error? downloadFileResult = saveFileInFS(item.url, string `${clientServiceConfig.targetDirectory}${file:pathSeparator}${exportId}${file:pathSeparator}${item.'type}-exported.ndjson`);
        if downloadFileResult is error {
            log:printError("Error occurred while downloading the file.", downloadFileResult);
        }
        if targetServerConfig.'type == "ftp" {
            // download the file to the FTP server
            // implement the FTP server logic
            error? uploadFileResult = sendFileFromFSToFTP(targetServerConfig, string `${clientServiceConfig.targetDirectory}${file:pathSeparator}${item.'type}-exported.ndjson`, string `${item.'type}-exported.ndjson`);
            if uploadFileResult is error {
                log:printError("Error occurred while sending the file to ftp.", downloadFileResult);

            }
        }
    }
    lock {
        boolean _ = updateExportTaskStatusInMemory(taskMap = exportTasks, exportTaskId = exportId, newStatus = "Downloaded");
    }
    log:printInfo("All files downloaded successfully.");
    return null;
}

# Result has to deliver as OperationOutcome resources, this method populate OpOutcome with relavant info.
#
# + severity - severity of the outcome
# + code - code of the outcome
# + message - text description of the outcome
# + return - FHIR:R4 OperationOutcome resource
public isolated function createOpereationOutcome(string severity, string code, string message) returns r4:OperationOutcome {
    r4:OperationOutcomeIssueSeverity severityType;
    do {
        severityType = check severity.cloneWithType(r4:OperationOutcomeIssueSeverity);
    } on fail var e {
        log:printError("Error occurred while creating the operation outcome. Error in severity type", e);
        r4:OperationOutcome operationOutcomeError = {
            issue: [
                {severity: "error", code: "exception", diagnostics: "Error occurred while creating the operation outcome. Error in severity type"}
            ]
        };
        return operationOutcomeError;

    }
    r4:OperationOutcome operationOutcome = {
        issue: [
            {severity: severityType, code: code, diagnostics: message}
        ]
    };
    return operationOutcome;
}

# Create R4:Parameters resource with given info.
#
# + parameters - parameter description
# + return - R4:Parameters resource
public isolated function createR4Parameters(map<string> parameters) returns international401:Parameters {
    international401:Parameters r4Parameters = {'parameter: []};
    international401:ParametersParameter[] paramsArr = [];
    foreach string key in parameters.keys() {
        international401:ParametersParameter parameterToAdd = {
            name: key,
            valueString: parameters.get(key)
        };
        paramsArr.push(parameterToAdd);
    }
    r4Parameters.'parameter = paramsArr;
    return r4Parameters;
}

# Create R4:Parameters resource to query member-match operation..
#
# + matchedPatients - parameter description  
# + _outputFormat - parameter description  
# + _since - parameter description  
# + _type - parameter description
# + return - return value description
public isolated function populateParamsResource(MatchedPatient[] matchedPatients, string? _outputFormat, string? _since, string? _type) returns international401:Parameters {

    international401:Parameters r4Parameters = {'parameter: []};
    international401:ParametersParameter[] paramsArr = [];

    if matchedPatients != [] {
        foreach MatchedPatient patient in matchedPatients {
            string patientReference = string `Patient/${patient.id}`;
            r4:Reference patientRef = {reference: patientReference};
            paramsArr.push({name: "patient", valueReference: patientRef});
        }
    }

    if _outputFormat is string {
        paramsArr.push({name: "_outputFormat", valueString: _outputFormat});

    }
    if _since is string {
        paramsArr.push({name: "_since", valueInstant: _since});
    }
    if _type is string {
        paramsArr.push({name: "_type", valueString: _type});
    }

    r4Parameters.'parameter = paramsArr;
    return r4Parameters;
}

# Populate query string for export operation.
#
# + _outputFormat - value of _outputFormat  
# + _since - value of _since
# + _type - value of _type
# + return - complete query string
public isolated function populateQueryString(string? _outputFormat, string? _since, string? _type) returns string {

    string queryString = "";

    if _outputFormat is string {
        queryString = string `?_outputFormat=${_outputFormat}`;
    }
    if _since is string {
        queryString = addQueryParam(queryString, "_since", _since);
    }
    if _type is string {
        queryString = addQueryParam(queryString, "_type", _type);
    }
    return queryString;
}

# Util function to append param to query string.
#
# + queryString - current string  
# + key - new param key
# + value - new param value
# + return - updated string
public isolated function addQueryParam(string queryString, string key, string value) returns string {
    if queryString == "" {
        return string `?${key}=${value}`;
    } else {
        return string `${queryString}&${key}=${value}`;
    }
}

isolated function submitBackgroundJob(string taskId, http:Response|http:ClientError status, BulkExportServerConfig serverConfig, boolean sync = false, map<string> context = {}) {
    if status is http:Response {
        log:printDebug(status.statusCode.toBalString());

        // get the location of the status check
        do {
            string location = check status.getHeader("content-location");
            log:printDebug("Scheduling polling task.", exportId = taskId, location = location, sync = sync.toString(), authEnabled = serverConfig.authEnabled.toString());
            task:JobId|() _ = check executeJob(new PollingTask(taskId, location, "In-progress", serverConfig, sync, context), clientServiceConfig.defaultIntervalInSec);
            log:printDebug("Polling location recieved: " + location);
        } on fail var e {
            log:printError("Error occurred while getting the location or scheduling the Job", e);
            // if location is available, can retry the task
        }
    } else {
        log:printError("Error occurred while sending the kick-off request to the bulk export server.", status);
    }
}

# This class holds information related to the Ballerina task that used to poll the status endpoint.
public class PollingTask {

    *task:Job;
    string exportId;
    string lastStatus;
    string location;
    BulkExportServerConfig serverConfig;
    boolean sync;
    map<string> context;
    task:JobId jobId = {id: 0};

    public function execute() {
        do {
            BulkExportServerConfig pollingServerConfig = check self.serverConfig.cloneWithType();
            pollingServerConfig.baseUrl = self.location;
            log:printDebug("Creating polling HTTP client.", exportId = self.exportId, location = self.location, authEnabled = pollingServerConfig.authEnabled.toString());
            http:Client statusClientV2 = check createHttpClient(pollingServerConfig);

            log:printDebug("Polling the export task status.", exportId = self.exportId);
            if self.lastStatus == "In-progress" {
                // update the status
                // update the export task

                http:Response|http:ClientError statusResponse;
                statusResponse = statusClientV2->/;
                addPollingEvent addPollingEventFuntion = addPollingEventToMemory;
                if statusResponse is http:Response {
                    int status = statusResponse.statusCode;
                    log:printDebug("Received polling status response.", exportId = self.exportId, statusCode = status.toString());
                    if status == 200 {
                        // update the status
                        // extract payload
                        // unschedule the job
                        self.setLastStaus("Completed");
                        lock {
                            boolean _ = updateExportTaskStatusInMemory(taskMap = exportTasks, exportTaskId = self.exportId, newStatus = "Export Completed. Processing files.");
                        }
                        json payload = check statusResponse.getJsonPayload();
                        log:printDebug("Export task completed.", exportId = self.exportId, payload = payload);
                        
                        // Store export summary in database if requestId is available
                        if self.context.hasKey("requestId") {
                            string requestId = self.context.get("requestId");
                            string|error summaryUpdateResult = updatePayerDataExchangeRequestSummary(requestId, payload.toJsonString());
                            if summaryUpdateResult is error {
                                log:printError("Failed to update export summary.", summaryUpdateResult);
                            } else {
                                log:printDebug("Export summary updated in database.", requestId = requestId, exportId = self.exportId);
                            }
                        }
                        
                        error? unscheduleJobResult = unscheduleJob(self.jobId);
                        if unscheduleJobResult is error {
                            log:printError("Error occurred while unscheduling the job.", unscheduleJobResult);
                        }

                        if self.sync {
                            // Sync data to FHIR server
                            log:printDebug("Starting sync path for completed export.", exportId = self.exportId);
                            error? syncResult = syncDataToFhirServer(self.exportId, payload, self.serverConfig, self.context);
                            if syncResult is error {
                                log:printError("Error in syncing files", syncResult);
                                lock {
                                    _ = updateExportTaskStatusInMemory(taskMap = exportTasks, exportTaskId = self.exportId, newStatus = "Sync Failed");
                                }
                                if self.context.hasKey("requestId") {
                                    string requestId = self.context.get("requestId");
                                    string|error updateResult = updatePayerDataExchangeRequestStatus(requestId, "FAILED");
                                    if updateResult is error {
                                        log:printError("Failed to update data exchange status to FAILED.", updateResult);
                                    }
                                }
                            } else {
                                log:printDebug("Completed sync path for export.", exportId = self.exportId);
                                lock {
                                    _ = updateExportTaskStatusInMemory(taskMap = exportTasks, exportTaskId = self.exportId, newStatus = "Synced");
                                }
                                if self.context.hasKey("requestId") {
                                    string requestId = self.context.get("requestId");
                                    _ = check updatePayerDataExchangeRequestStatus(requestId, "COMPLETED");
                                    log:printDebug("Updated data exchange status to COMPLETED.", requestId = requestId, exportId = self.exportId);
                                } else {
                                    log:printDebug("Skipping data exchange status update as requestId is unavailable.", exportId = self.exportId);
                                }
                            }
                        } else {
                            // download the files
                            log:printDebug("Starting download path for completed export.", exportId = self.exportId);
                            error? downloadFilesResult = downloadFiles(payload, self.exportId);
                            if downloadFilesResult is error {
                                log:printError("Error in downloading files", downloadFilesResult);
                            } else {
                                log:printDebug("Completed download path for export.", exportId = self.exportId);
                            }
                        }

                    } else if status == 202 {
                        // update the status
                        log:printDebug("Export task in-progress.", exportId = self.exportId);
                        string progress = "";
                        if statusResponse.hasHeader("X-Progress") {
                            progress = check statusResponse.getHeader("X-Progress");
                        }

                        PollingEvent pollingEvent = {id: self.exportId, eventStatus: "Success", exportStatus: progress};

                        lock {
                            // persisting event
                            boolean _ = addPollingEventFuntion(exportTasks, pollingEvent.clone());
                        }
                        self.setLastStaus("In-progress");
                    }
                } else {
                    log:printError("Error occurred while getting the status.", statusResponse);
                    lock {
                        // statusResponse
                        PollingEvent pollingEvent = {id: self.exportId, eventStatus: "Failed"};
                        boolean _ = addPollingEventFuntion(exportTasks, pollingEvent.cloneReadOnly());
                    }
                }
            } else if self.lastStatus == "Completed" {
                // This is a rare occurance; if the job is not unscheduled properly, it will keep polling the status.
                log:printDebug("Export task completed.", exportId = self.exportId);
            } else {
                log:printDebug("Polling task encountered unexpected status.", exportId = self.exportId, lastStatus = self.lastStatus);
            }
        } on fail var e {
            log:printError("Error occurred while polling the export task status.", e);
        }
    }

    isolated function init(string exportId, string location, string lastStatus = "In-progress", BulkExportServerConfig serverConfig = {baseUrl: ""}, boolean sync = false, map<string> context = {}) {
        self.exportId = exportId;
        self.lastStatus = lastStatus;
        self.location = location;
        self.serverConfig = serverConfig;
        self.sync = sync;
        self.context = context;
    }

    public function setLastStaus(string newStatus) {
        self.lastStatus = newStatus;
    }

    public isolated function setId(task:JobId jobId) {
        self.jobId = jobId;
    }
}

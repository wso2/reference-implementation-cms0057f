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
import ballerina/task;
import ballerinax/health.fhir.r4;
import ballerina/time;
import ballerina/http;
import ballerina/io;

# Execute export task.
#
# + exportTaskId - Id of the exportTask instance in memory  
# + sourceConfig - The configuration related to the search source server
# + serverConfig - The configuration related to the export server
# + return - error while scheduling job
public isolated function executeJob(string exportTaskId, SearchServerConfig sourceConfig, BulkExportServerConfig serverConfig) returns error? {
    FileCreateTask fileCreateTask = new FileCreateTask(exportTaskId, sourceConfig, serverConfig);
    task:JobId|error id = task:scheduleOneTimeJob(fileCreateTask, time:utcToCivil(time:utcAddSeconds(time:utcNow(1),2)));
    if id is error {
        return id;
    }
}

# This class holds information related to the Ballerina task that is used to get resource information and write them to files.
public class FileCreateTask {

    *task:Job;
    string exportTaskId;
    OutputFile[] outputFiles = [];
    OutputFile[] errorFiles = [];
    r4:OperationOutcome[] errors = [];
    SearchServerConfig sourceConfig;
    BulkExportServerConfig serverConfig;

    public function execute() {
        do {
            // Initialize the HTTP client
            http:Client clientEp;
            if self.sourceConfig.authEnabled {
                clientEp = check new (self.sourceConfig.searchUrl, 
                    auth = {
                        tokenUrl: self.sourceConfig.tokenUrl,
                        clientId: self.sourceConfig.clientId,
                        clientSecret: self.sourceConfig.clientSecret,
                        scopes: self.sourceConfig.scopes
                    }
                );
            } else {
                clientEp = check new (self.sourceConfig.searchUrl);
            }
            
            string [] types = searchServerConfig.types;

            foreach string resourceType in types {
                    do {
                    // Make the POST _search request
                    json response = check clientEp->post(path="/fhir/r4/" + resourceType + "/_search", message = {},
                        headers={"Accept": "application/fhir+json", "Content-Type": "application/fhir+json"}
                    );

                    r4:Bundle bundle = check response.cloneWithType(r4:Bundle);
                    r4:BundleEntry[]? entries = bundle.entry;
                    if entries !is () {
                        check self.storeResult(entries, resourceType);
                    } else {
                        log:printError("No records for resource type: " + resourceType + " proceeding other types.");
                        self.errors.push(createOpereationOutcome(r4:CODE_SEVERITY_INFORMATION, r4:PROCESSING, "No records for resource type: " + resourceType));
                    }
                } on fail error e {
                    log:printError("Error occurred while reading and storing resource type: " + resourceType + " proceeding other types.", e);
                    self.errors.push(createOpereationOutcome(r4:CODE_SEVERITY_ERROR, r4:PROCESSING, "Error in retrieving " + resourceType + " resources"));
                }
            }
            ///The errors array needs to be populated to a seperate ndjson and responded under error in the status get
            if self.errors.length() > 0 {
                check self.storeError();
            }
            updateExportResultCompletion(self.exportTaskId, self.outputFiles, self.errorFiles);
        } on fail error e {
            log:printError("Error occurred while creating files for export task id: " + self.exportTaskId, e);
            updateExportResultError(self.exportTaskId);
        }
    }

    public isolated function storeResult(r4:BundleEntry[] content, string recordType) returns error? {

        string filePath = string `${self.serverConfig.targetDirectory}/${self.exportTaskId}/${recordType}.ndjson`;
        string[] lines = [];

        foreach r4:BundleEntry entry in content {
            //Check if entry has a resource since resource is an optional field
            if (entry.hasKey("resource")) {
                // Write each entry as a separate line for the NDJSON file
                lines.push(entry?.'resource.toJsonString());
            }
        }

        io:Error? fileResult = io:fileWriteLines(filePath, lines);
        if fileResult is io:Error {
            log:printError(string `Error writing to NDJSON file: ${fileResult.message()}`);
            return fileResult;
        }

        OutputFile result = {
            url: self.serverConfig.baseUrl + "/" + self.exportTaskId + "/fhir/bulkfiles/" + recordType + ".ndjson",
            count: content.length(),
            'type: recordType
        };
        self.outputFiles.push(result);
    }

    public isolated function storeError() returns error? {

        string filePath = string `${self.serverConfig.targetDirectory}/${self.exportTaskId}/error_file.ndjson`;
        string[] lines = [];

        foreach r4:OperationOutcome errorOutcome in self.errors {
            lines.push(errorOutcome.toJsonString());
        }

        io:Error? fileResult = io:fileWriteLines(filePath, lines);
        if fileResult is io:Error {
            log:printError(string `Error writing to NDJSON file: ${fileResult.message()}`);
            return fileResult;
        }

        OutputFile result = {
            url: self.serverConfig.baseUrl + "/" + self.exportTaskId + "/fhir/bulkfiles/error_file.ndjson",
            count: self.errors.length(),
            'type: "OperationOutcome"
        };
        self.errorFiles.push(result);
    }

    public isolated function init(string exportTaskId, SearchServerConfig sourceConfig, BulkExportServerConfig serverConfig) {
        self.exportTaskId = exportTaskId;
        self.sourceConfig = sourceConfig;
        self.serverConfig = serverConfig;
    }
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

import ballerina/io;
import ballerina/log;
import ballerina/task;
import ballerina/time;
import ballerinax/health.fhir.r4;

isolated function getQueryParamsMap(map<r4:RequestSearchParameter[] & readonly> requestSearchParameters) returns map<string[]> {
    //TODO: Should provide ability to get the query parameters from the context as it is from the http request. 
    //Refer : https://github.com/wso2-enterprise/open-healthcare/issues/1369
    map<string[]> queryParameters = {};
    foreach var key in requestSearchParameters.keys() {
        r4:RequestSearchParameter[] & readonly searchParameters = requestSearchParameters[key] ?: [];
        foreach var searchParameter in searchParameters {
            string name = searchParameter.name;
            if queryParameters[name] is string[] {
                (<string[]>queryParameters[name]).push(searchParameter.value);
            } else {
                queryParameters[name] = [searchParameter.value];
            }
        }
    }
    return queryParameters;
}

# Execute export task.
#
# + exportTaskId - Id of the exportTask instance in memory  
# + sourceConfig - The configuration related to the search source server
# + serverConfig - The configuration related to the export server
# + patientId - Id of the patient that data need to be exported.
# + return - error while scheduling job
public isolated function executeJob(string exportTaskId, SearchServerConfig sourceConfig, BulkExportServerConfig serverConfig, string? patientId) returns error? {

    log:printDebug(string `Executing Job ${exportTaskId}`);
    FileCreateTask fileCreateTask = new FileCreateTask(exportTaskId, sourceConfig, serverConfig, patientId);
    task:JobId|error id = task:scheduleOneTimeJob(fileCreateTask, time:utcToCivil(time:utcAddSeconds(time:utcNow(1), 2)));
    if id is error {
        return id;
    }
}

# This class holds information related to the Ballerina task that is used to get resource information and write them to files.
public class FileCreateTask {

    *task:Job;
    string exportTaskId;
    string patientId = "101";
    OutputFile[] outputFiles = [];
    OutputFile[] errorFiles = [];
    r4:OperationOutcome[] errors = [];
    SearchServerConfig sourceConfig;
    BulkExportServerConfig serverConfig;

    public isolated function init(string exportTaskId, SearchServerConfig sourceConfig, BulkExportServerConfig serverConfig, string? patientId) {
        self.exportTaskId = exportTaskId;
        self.sourceConfig = sourceConfig;
        self.serverConfig = serverConfig;

        if patientId is string {
            self.patientId = patientId;
        }
    }

    public function execute() {
        string[] types = searchServerConfig.types;
        do {
            log:printDebug(string `Task initialted for ${self.sourceConfig?.searchUrl ?: ""}`);

            map<string[]> searchParams = {"patient": [self.patientId]};
            foreach var 'type in types {
                match ('type) {
                    ENCOUNTER => {
                        r4:Bundle bundle = check searchEncounter(searchParams);
                        r4:BundleEntry[]? entries = bundle.entry;
                        if entries !is () {
                            check self.storeResult(entries, ENCOUNTER);
                        } else {
                            log:printError("No records for resource type: " + ENCOUNTER + " proceeding other types.");
                            self.errors.push(createOpereationOutcome(r4:CODE_SEVERITY_INFORMATION, r4:PROCESSING, "No records for resource type: " + ENCOUNTER));
                        }
                    }
                    _ => {

                    }
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

    // Internal method used by execute method
    isolated function storeResult(r4:BundleEntry[] content, string recordType) returns error? {

        string filePath = string `${self.serverConfig.targetDirectory}/${self.exportTaskId}/${recordType}.ndjson`;
        string[] lines = [];

        foreach r4:BundleEntry entry in content {
            //Check if entry has a resource since resource is an optional field
            if (entry.hasKey("resource")) {
                // Write each entry as a separate line for the NDJSON file
                lines.push(entry?.'resource.toJsonString());
            }
        }

        log:printDebug(string `Content Extracted ${recordType}`);

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

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

import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/regex;
import ballerina/task;
import ballerina/time;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincihrex100;
import ballerinax/health.fhir.r4.uscore501;

# Execute export task.
#
# + exportTaskId - Id of the exportTask instance in memory  
# + serverConfig - The configuration related to the export server
# + patientId - Id of the patient that data need to be exported.
# + return - error while scheduling job
public isolated function executeJob(string exportTaskId, BulkExportServerConfig serverConfig, string? patientId) returns error? {

    log:printDebug(string `Executing Job ${exportTaskId}`);
    FileCreateTask fileCreateTask = new FileCreateTask(exportTaskId, serverConfig, patientId);
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
    BulkExportServerConfig serverConfig;

    public isolated function init(string exportTaskId, BulkExportServerConfig serverConfig, string? patientId) {
        self.exportTaskId = exportTaskId;
        self.serverConfig = serverConfig;

        if patientId is string {
            self.patientId = patientId;
        }
    }

    public function execute() {
        string[] types = self.serverConfig.types;
        do {
            log:printDebug(string `Task initialted for ${self.exportTaskId}`);

            // Here the self.patientId value is Patient/100, so will split and get only the id
            string[] result = regex:split(self.patientId, "/");

            foreach var 'type in types {
                match ('type) {
                    ENCOUNTER => {
                        r4:Bundle bundle = check fhirServiceClient->/Encounter(patient = result[1]);
                        check self.storeResult(bundle, ENCOUNTER);
                    }

                    DIAGNOSTIC_REPORT => {
                        r4:Bundle bundle = check fhirServiceClient->/DiagnosticReport(patient = result[1]);
                        check self.storeResult(bundle, DIAGNOSTIC_REPORT);
                    }

                    CLAIM => {
                        r4:Bundle bundle = check fhirServiceClient->/Claim(patient = result[1]);
                        check self.storeResult(bundle, CLAIM);
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
    isolated function storeResult(r4:Bundle bundle, string recordType) returns error? {

        r4:BundleEntry[]? entries = bundle.entry;
        if entries !is () {
            string filePath = string `${self.serverConfig.targetDirectory}/${self.exportTaskId}/${recordType}.ndjson`;
            string[] lines = [];

            foreach r4:BundleEntry entry in entries {
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
                url: self.serverConfig.fileServerBaseUrl + "/" + self.exportTaskId + "/files/" + recordType + ".ndjson",
                count: entries.length(),
                'type: recordType
            };
            self.outputFiles.push(result);

        } else {
            log:printError("No records for resource type: " + recordType + " proceeding other types.");
            self.errors.push(createOpereationOutcome(r4:CODE_SEVERITY_INFORMATION, r4:PROCESSING, "No records for resource type: " + recordType));
        }
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
            url: self.serverConfig.fileServerBaseUrl + "/" + self.exportTaskId + "/fhir/bulkfiles/error_file.ndjson",
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

# Debug logger.
#
# + msg - debug message 
public isolated function LogDebug(string msg) {
    log:printDebug(msg);
}

# Error logger.
#
# + err - error to be logged
public isolated function LogError(error err) {
    log:printError(err.message(), stacktrace = err.stackTrace().toString());
}

# Info logger.
#
# + msg - info message 
public isolated function LogInfo(string msg) {
    log:printInfo(msg);
}

# Warn logger.
#
# + msg - warn message 
public isolated function LogWarn(string msg) {
    log:printWarn(msg);
}

# Input parameters of the member match operation.
enum MemberMatchParameter {
    MEMBER_PATIENT = "MemberPatient",
    CONSENT = "Consent",
    COVERAGE_TO_MATCH = "CoverageToMatch",
    COVERAGE_TO_LINK = "CoverageToLink"
};

# Constant symbols
const AMPERSAND = "&";
const SLASH = "/";
const QUOTATION_MARK = "\"";
const QUESTION_MARK = "?";
const EQUALS_SIGN = "=";
const COMMA = ",";
# FHIR  parameters 
const _FORMAT = "_format";
const _SUMMARY = "_summary";
const _HISTORY = "_history";
const METADATA = "metadata";
const MODE = "mode";
# Request Headers
const ACCEPT_HEADER = "Accept";
const PREFER_HEADER = "Prefer";
const LOCATION = "Location";
const CONTENT_TYPE = "Content-Type";
const CONTENT_LOCATION = "Content-Location";

# Map of `ParameterInfo` to hold information about member match parameters.
final map<ParameterInfo> & readonly MEMBER_MATCH_PARAMETERS_INFO = {
    [MEMBER_PATIENT]: {profile: "USCorePatientProfile", typeDesc: uscore501:USCorePatientProfile},
    [CONSENT]: {profile: "HRexConsent", typeDesc: davincihrex100:HRexConsent},
    [COVERAGE_TO_MATCH]: {profile: "HRexCoverage", typeDesc: davincihrex100:HRexCoverage},
    [COVERAGE_TO_LINK]: {profile: "HrexCoverage", typeDesc: davincihrex100:HRexCoverage}
};

isolated function setSearchParams(map<string[]>? qparams) returns string {
    string url = "";
    if (qparams is map<string[]>) {
        foreach string key in qparams.keys() {
            foreach string param in qparams.get(key) {
                url += key + EQUALS_SIGN + param + AMPERSAND;
            }
        }
    }
    return url.endsWith("&") ? url.substring(0, url.length() - 1) : url;
}

isolated function getBundleResponse(http:Response response) returns fhir:FHIRResponse|fhir:FHIRError {
    do {
        int statusCode = response.statusCode;
        json|xml responseBody = check response.getJsonPayload();

        if statusCode == 200 {
            fhir:FHIRResponse fhirResponse = {httpStatusCode: statusCode, 'resource: responseBody, serverResponseHeaders: {}};
            return fhirResponse;
        } else {
            fhir:FHIRServerError fhirServerError = error("FHIR_SERVER_ERROR", httpStatusCode = statusCode, 'resource = responseBody, serverResponseHeaders = {});
            return fhirServerError;
        }
    } on fail var e {
        return error(string `FHIR_CONNECTOR_ERROR: ${e.message()}`, errorDetails = e);
    }
}

isolated function getFhirResourceResponse(http:Response response) returns fhir:FHIRResponse|fhir:FHIRError {
    do {
        xml|json responseBody = check response.getJsonPayload();
        int statusCode = response.statusCode;
        if statusCode == 200 {
            return {httpStatusCode: statusCode, 'resource: responseBody, serverResponseHeaders: {}};
        } else {
            return error("FHIR_SERVER_ERROR", httpStatusCode = statusCode, 'resource = responseBody, serverResponseHeaders = {});
        }
    } on fail var e {
        return error(string `FHIR_CONNECTOR_ERROR: ${e.message()}`, errorDetails = e);
    }

}

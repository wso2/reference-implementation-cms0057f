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
import ballerina/time;
import ballerina/uuid;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;

configurable SearchServerConfig searchServerConfig = ?;
configurable BulkExportServerConfig exportServiceConfig = ?;

service /bulk on new http:Listener(8090) {
    isolated resource function get fhir/export() returns r4:OperationOutcome|r4:FHIRError {
        string exportTaskId = uuid:createType1AsString();
        error? executionResult = executeJob(exportTaskId, searchServerConfig, exportServiceConfig, ());
        if executionResult is error {
            log:printError("Error occurred: ", executionResult);
            return r4:createFHIRError("Server Error", r4:ERROR, r4:PROCESSING, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
        addExportTasktoMemory(exportTaskId, time:utcNow());

        return createOpereationOutcome("information", "processing",
                "Your request has been accepted. You can check its status at " + exportServiceConfig.baseUrl + "/bulk/fhir/bulkstatus/" + exportTaskId);
    }

    isolated resource function post fhir/export(
            @http:Payload international401:Parameters parameters,
            @http:Query string? _outputFormat,
            @http:Query string? _since,
            @http:Query string? _type
    ) returns r4:OperationOutcome|r4:FHIRError {
        string exportTaskId = uuid:createType1AsString();
        international401:ParametersParameter[] selectedPatients = <international401:ParametersParameter[]>parameters.'parameter;
        string patientId = <string>(<r4:Reference>selectedPatients[0].valueReference).reference;
        log:printDebug(string `Exporting data for ID: ${patientId}`);
        error? executionResult = executeJob(exportTaskId, searchServerConfig, exportServiceConfig, patientId);
        if executionResult is error {
            log:printError("Error occurred: ", executionResult);
            return r4:createFHIRError("Server Error", r4:ERROR, r4:PROCESSING, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
        addExportTasktoMemory(exportTaskId, time:utcNow());

        return createOpereationOutcome("information", "processing",
                "Your request has been accepted. You can check its status at " + exportServiceConfig.baseUrl + "/fhir/bulkstatus/" + exportTaskId);
    }

    isolated resource function get fhir/bulkstatus/[string exportTaskId]() returns json|r4:FHIRError|http:Response {
        ExportTask|error exportTask = getExportTaskFromMemory(exportTaskId);

        if exportTask is error {
            http:Response response = new;
            response.statusCode = http:STATUS_BAD_REQUEST;
            response.setPayload(exportTask.message());
            return response;
        }

        if exportTask.lastStatus == "in-progress" {
            return;
        } else if exportTask.lastStatus == "completed" {
            return {
                //todo: check if the start time format here is what the specification exactly needs
                transactionTime: time:utcToString(exportTask.startTime),
                request: exportServiceConfig.baseUrl + "/fhir/Patient/$export",
                requiresAccessToken: false,
                outputOrganizedBy: "",
                deleted: [],
                output: exportTask.results,
                'error: exportTask.errors
            };
        }
        //Handles the lastStauts "failed" scenario
        return r4:createFHIRError("Server Error", r4:ERROR, r4:PROCESSING, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }

    isolated resource function get [string exportId]/fhir/bulkfiles/[string fileName]() returns http:Response|error {
        string filePath = string `${exportServiceConfig.targetDirectory}/${exportId}/${fileName}`;

        // Create new response
        http:Response response = new;

        // Try to read the file
        byte[]|io:Error fileContent = io:fileReadBytes(filePath);

        if fileContent is io:Error {
            log:printError("Error reading file", fileContent);
            response.statusCode = http:STATUS_NOT_FOUND;
            response.setPayload("File not found");
            return response;
        }

        // Set headers and payload
        response.setHeader("Content-Type", "application/ndjson");
        response.setHeader("Content-Disposition", string `attachment; filename=${fileName}`);
        response.setBinaryPayload(fileContent);

        return response;
    }
}

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
import ballerina/time;

//This file represents the in-memory storage of the export tasks.

final isolated map<ExportTask> exportResults = {};

//Add an export task to memory.
isolated function addExportTasktoMemory(string id, time:Utc startTime) {
    lock {
        exportResults[id] = {id: id, startTime: startTime, lastStatus: "in-progress", results: [], errors: []};
    }
}

//Update an export task ended successfully.
isolated function updateExportResultCompletion(string exportTaskId, OutputFile[] outputFiles, OutputFile[] errorFiles) {

    lock {
        ExportTask exportTask = exportResults.get(exportTaskId);
        exportTask.lastStatus = "completed";
        exportTask.results = outputFiles.clone();
        exportTask.errors = errorFiles.clone();
    }
}

//Update an export task ended in an error.
isolated function updateExportResultError(string exportTaskId) {

    lock {
        ExportTask exportTask = exportResults.get(exportTaskId);
        exportTask.lastStatus = "failed";
    }
}

//Get an export task that we have stored in memory.
isolated function getExportTaskFromMemory(string exportId) returns ExportTask|error {
    // get the export task from the memory
    lock {
        if exportResults.hasKey(exportId) {
            return exportResults.get(exportId).clone();
        }
    }
    return error("Task ID unavaiable");
}

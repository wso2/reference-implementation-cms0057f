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
import ballerina/test;
import ballerina/time;

@test:Config {
    enable: true
}
function testAddExportTaskToMemory() {
    map<ExportTask> testMap = {};
    ExportTask testTask = {
        id: "test-id",
        lastUpdated: time:utcNow(),
        lastStatus: "Pending",
        pollingEvents: []
    };

    boolean result = addExportTasktoMemory(testMap, testTask);
    test:assertTrue(result);
    test:assertTrue(testMap.hasKey("test-id"));
    test:assertEquals(testMap.get("test-id").id, "test-id");
    test:assertFalse(testMap.get("test-id").lastUpdated < testTask.lastUpdated);
}

@test:Config {
    enable: true
}
function testAddPollingEventToMemory() {
    ExportTask testTask = {
        id: "test-id",
        lastUpdated: time:utcNow(),
        lastStatus: "Pending",
        pollingEvents: []
    };
    map<ExportTask> testMap = {"test-id": testTask};

    PollingEvent testEvent = {
        id: "test-id",
        exportStatus: "In-progress"
        ,
        eventStatus: ""
    };

    boolean result = addPollingEventToMemory(testMap, testEvent);
    test:assertTrue(result);
    test:assertEquals(testMap.get("test-id").lastStatus, "In-progress");
    test:assertEquals(testMap.get("test-id").pollingEvents.length(), 1);
    test:assertEquals(testMap.get("test-id").pollingEvents[0], testEvent);
    test:assertFalse(testMap.get("test-id").lastUpdated < testTask.lastUpdated);
}

@test:Config {
    enable: true
}
function testUpdateExportTaskStatusInMemory() {
    ExportTask testTask = {
        id: "test-id",
        lastUpdated: time:utcNow(),
        lastStatus: "Pending",
        pollingEvents: []
    };
    map<ExportTask> testMap = {"test-id": testTask};

    boolean result = updateExportTaskStatusInMemory(testMap, "test-id", "Completed");
    test:assertTrue(result);
    test:assertEquals(testMap.get("test-id").lastStatus, "Completed");
    test:assertFalse(testMap.get("test-id").lastUpdated < testTask.lastUpdated);
}

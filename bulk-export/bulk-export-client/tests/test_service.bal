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
import ballerina/http;
import ballerina/io;
import ballerina/test;
import ballerinax/health.fhir.r4;

@test:Config {
    enable: true
}
function testGetFileAsStream() returns error? {
    // Mock HTTP Client
    http:Client mockClient = test:mock(http:Client);

    // Test case 1: Successful response
    http:Response mockResponse1 = new;
    mockResponse1.statusCode = 200;
    stream<io:Block, io:Error?> fileReadBlocksAsStream = check io:fileReadBlocksAsStream("tests/resources/exportedData.json", 1024);
    mockResponse1.setByteStream(fileReadBlocksAsStream);
    test:prepare(mockClient).when("get").withArguments("/").thenReturn(mockResponse1);

    stream<byte[], io:Error?>|error? result1 = getFileAsStream("http://example.com", mockClient);
    if (result1 is stream<byte[], io:Error?>) {
        if fileReadBlocksAsStream is stream<io:Block, io:Error?> {
            if fileReadBlocksAsStream.toString() == result1.toString() {
                test:assertTrue(true, "Expected a byte stream, but got an empty string");
            }
        }
    } else {
        test:assertFail("Expected a byte stream, but got an error or null");
    }

    // todo: Test case 2: Error response
}

@test:Config {
    enable: true
}
function testCreateOperationOutcome() {
    // Test case 1: Valid input
    r4:OperationOutcome result1 = createOpereationOutcome("warning", "invalid", "Invalid input provided");
    test:assertEquals(result1.issue[0].severity, "warning");
    test:assertEquals(result1.issue[0].code, "invalid");
    test:assertEquals(result1.issue[0].diagnostics, "Invalid input provided");

    r4:OperationOutcome result2 = createOpereationOutcome("invalid_severity", "invalid", "Test message");
    test:assertEquals(result2.issue[0].severity, "error");
    test:assertEquals(result2.issue[0].code, "exception");
    test:assertEquals(result2.issue[0].diagnostics, "Error occurred while creating the operation outcome. Error in severity type");

    // Test case 3: Empty inputs
    r4:OperationOutcome result3 = createOpereationOutcome("", "", "");
    test:assertEquals(result3.issue[0].severity, "error");
    test:assertEquals(result3.issue[0].code, "exception");
    test:assertEquals(result3.issue[0].diagnostics, "Error occurred while creating the operation outcome. Error in severity type");
}

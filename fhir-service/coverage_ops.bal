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

import ballerina/log;
import ballerinax/health.clients.fhir as fhirClient;

# Create Coverage in FHIR Server
#
# + fhirConnector - FHIR Connector instance
# + coverage - Coverage resource to create
# + return - Created Coverage ID or error
public isolated function createCoverage(fhirClient:FHIRConnector fhirConnector, json coverage) returns string|error {
    fhirClient:FHIRResponse|fhirClient:FHIRError response = fhirConnector->create(coverage);

    if response is fhirClient:FHIRError {
        log:printError(string `Failed to create Coverage: ${response.message()}`);
        return error(string `Failed to create Coverage: ${response.message()}`);
    }

    if response.'resource is json {
        json|error id = (<json>response.'resource).id;
        if id is string {
            return id;
        }
    }

    return error("Failed to retrieve created Coverage ID");
}

# Get Coverage by ID from FHIR Server
#
# + fhirConnector - FHIR Connector instance
# + coverageId - Coverage ID
# + return - Coverage JSON or error
public isolated function getCoverage(fhirClient:FHIRConnector fhirConnector, string coverageId) returns json|error {
    fhirClient:FHIRResponse|fhirClient:FHIRError response = fhirConnector->getById("Coverage", coverageId);

    if response is fhirClient:FHIRError {
        return error(string `Coverage ${coverageId} not found: ${response.message()}`);
    }

    return <json>response.'resource;
}

# Search Coverage resources
#
# + fhirConnector - FHIR Connector instance
# + searchParams - Search parameters
# + return - Array of Coverage resources or error
public isolated function searchCoverage(fhirClient:FHIRConnector fhirConnector, map<string[]> searchParams) returns json[]|error {
    fhirClient:FHIRResponse|fhirClient:FHIRError response = fhirConnector->search(
        "Coverage",
        searchParameters = searchParams
    );

    if response is fhirClient:FHIRError {
        return error(string `Failed to search Coverage: ${response.message()}`);
    }

    return extractResourcesFromBundle(<json>response.'resource);
}

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
import ballerinax/health.clients.fhir as fhirClient;
import ballerinax/health.fhir.r4;

public isolated function create(fhirClient:FHIRConnector fhirConnector, ResourceType resourceType, json payload) returns r4:DomainResource|r4:FHIRError {
    fhirClient:FHIRResponse|fhirClient:FHIRError response = fhirConnector->create(payload, returnPreference = "representation");

    if response is fhirClient:FHIRError {
        return r4:createFHIRError(response.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    if response.'resource is json {
        r4:DomainResource|error resourceResult = response.'resource.cloneWithType();
        if resourceResult is error {
            return r4:createFHIRError("Failed to clone resource: " + resourceResult.message(), r4:ERROR, r4:PROCESSING, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
        return resourceResult;
    }

    return r4:createFHIRError("Failed to create resource", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
}

public isolated function getById(fhirClient:FHIRConnector fhirConnector, ResourceType resourceType, string id) returns r4:DomainResource|r4:FHIRError {
    fhirClient:FHIRResponse|fhirClient:FHIRError response = fhirConnector->getById(resourceType, id);

    if response is fhirClient:FHIRError {
        return r4:createFHIRError(response.message(), r4:ERROR, r4:PROCESSING_NOT_FOUND, httpStatusCode = http:STATUS_NOT_FOUND);
    }

    if response.'resource is json {
        r4:DomainResource|error resourceResult = response.'resource.cloneWithType();
        if resourceResult is error {
            return r4:createFHIRError("Failed to clone resource: " + resourceResult.message(), r4:ERROR, r4:PROCESSING, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
        return resourceResult;
    }

    return r4:createFHIRError("Failed to retrieve resource", r4:ERROR, r4:PROCESSING, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
}

public isolated function search(fhirClient:FHIRConnector fhirConnector, ResourceType resourceType, map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    fhirClient:FHIRResponse|fhirClient:FHIRError response = fhirConnector->search(resourceType, searchParameters = searchParameters);

    if response is fhirClient:FHIRError {
        return r4:createFHIRError(response.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    if response.'resource is json {
        r4:Bundle|error resourceResult = response.'resource.cloneWithType();
        if resourceResult is error {
            return r4:createFHIRError("Failed to clone resource: " + resourceResult.message(), r4:ERROR, r4:PROCESSING, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
        return resourceResult;
    }

    return r4:createFHIRError("Failed to search resources", r4:ERROR, r4:PROCESSING, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
}

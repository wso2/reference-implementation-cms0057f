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

import ballerina/http;
import ballerina/url;

// ============================================
// FHIR Library & ValueSet Utility Functions
// ============================================

const string LIBRARY = "/Library";
const string VALUESET = "/ValueSet";

# Get a FHIR Library resource by its ID
#
# + libraryId - Unique Library identifier
# + return - Library resource as JSON or error
function getFHIRLibraryById(string libraryId) returns json|error {
    string path = LIBRARY + "/" + libraryId;
    json result = check fhirHttpClient->get(path, headers = {"Content-Type": "application/fhir+json"});
    return result;
}

# Search for a FHIR Library by its canonical URL
#
# + libraryUrl - Canonical URL of the Library
# + return - Library resource as JSON or error
function getFHIRLibraryByUrl(string libraryUrl) returns json|error {
    string encodedUrl = check url:encode(libraryUrl, "UTF-8");
    string path = LIBRARY + "?url=" + encodedUrl;
    json bundle = check fhirHttpClient->get(path, headers = {"Content-Type": "application/fhir+json"});

    json|error totalJson = bundle.total;
    if totalJson is int && totalJson == 0 {
        return error("Library not found for URL: " + libraryUrl);
    }

    json|error entriesJson = bundle.entry;
    if entriesJson is json[] && entriesJson.length() > 0 {
        json|error resourceJson = entriesJson[0].'resource;
        if resourceJson is json {
            return resourceJson;
        }
    }
    return error("Library not found for URL: " + libraryUrl);
}

# Create a new FHIR Library resource
#
# + library - FHIR Library resource as JSON
# + return - Created Library resource as JSON or error
function createFHIRLibrary(json library) returns json|error {
    http:Response response = check fhirHttpClient->post(LIBRARY, library, headers = {"Content-Type": "application/fhir+json"});
    json result = check response.getJsonPayload();
    return result;
}

# Update an existing FHIR Library resource
#
# + libraryId - Unique Library identifier
# + library - Updated FHIR Library resource as JSON
# + return - Updated Library resource as JSON or error
function updateFHIRLibrary(string libraryId, json library) returns json|error {
    string path = LIBRARY + "/" + libraryId;
    http:Response response = check fhirHttpClient->put(path, library, headers = {"Content-Type": "application/fhir+json"});
    json result = check response.getJsonPayload();
    return result;
}

# Delete a FHIR Library resource
#
# + libraryId - Unique Library identifier
# + return - Error if operation fails, () if successful
function deleteFHIRLibrary(string libraryId) returns error? {
    string path = LIBRARY + "/" + libraryId;
    http:Response response = check fhirHttpClient->delete(path, headers = {"Content-Type": "application/fhir+json"});
    int statusCode = response.statusCode;
    if statusCode != 200 && statusCode != 204 {
        return error("Failed to delete library: HTTP " + statusCode.toString());
    }
    return;
}

# Search for a FHIR ValueSet by its canonical URL
#
# + valueSetUrl - Canonical URL of the ValueSet
# + return - ValueSet resource as JSON or error
function getFHIRValueSetByUrl(string valueSetUrl) returns json|error {
    string encodedUrl = check url:encode(valueSetUrl, "UTF-8");
    string path = VALUESET + "?url=" + encodedUrl;
    json bundle = check fhirHttpClient->get(path, headers = {"Content-Type": "application/fhir+json"});

    json|error totalJson = bundle.total;
    if totalJson is int && totalJson == 0 {
        return error("ValueSet not found for URL: " + valueSetUrl);
    }

    json|error entriesJson = bundle.entry;
    if entriesJson is json[] && entriesJson.length() > 0 {
        json|error resourceJson = entriesJson[0].'resource;
        if resourceJson is json {
            return resourceJson;
        }
    }
    return error("ValueSet not found for URL: " + valueSetUrl);
}

# Create a new FHIR ValueSet resource
#
# + valueSet - FHIR ValueSet resource as JSON
# + return - Created ValueSet resource as JSON or error
function createFHIRValueSet(json valueSet) returns json|error {
    http:Response response = check fhirHttpClient->post(VALUESET, valueSet, headers = {"Content-Type": "application/fhir+json"});
    json result = check response.getJsonPayload();
    return result;
}

# Update an existing FHIR ValueSet resource
#
# + valueSetId - Unique ValueSet identifier
# + valueSet - Updated FHIR ValueSet resource as JSON
# + return - Updated ValueSet resource as JSON or error
function updateFHIRValueSet(string valueSetId, json valueSet) returns json|error {
    string path = VALUESET + "/" + valueSetId;
    http:Response response = check fhirHttpClient->put(path, valueSet, headers = {"Content-Type": "application/fhir+json"});
    json result = check response.getJsonPayload();
    return result;
}

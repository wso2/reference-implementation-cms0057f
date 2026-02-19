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
import ballerina/http;

// ============================================
// FHIR Questionnaire Utility Functions
// ============================================

# Query questionnaires from FHIR server with pagination
#
# + page - Page number (1-indexed)
# + pageSize - Number of items per page
# + search - Search by questionnaire title or description
# + status - Filter by questionnaire status
# + return - Tuple containing questionnaires array and total count, or error
function queryFHIRQuestionnaires(
    int page, 
    int pageSize,
    string? search,
    QuestionnaireStatus? status
) returns [QuestionnaireListItem[], int]|error {
    
    string searchPath = string `/Questionnaire?_count=${pageSize.toString()}&page=${page.toString()}`;
    
    if status is QuestionnaireStatus {
        searchPath += "&status=" + status;
    }
    
    if search is string && search.trim().length() > 0 {
        searchPath += "&title:contains=" + search;
    }
    
    // Execute HTTP GET search
    json bundle = check fhirHttpClient->get(searchPath);
    
    // Extract total count from bundle
    int totalCount = 0;
    json|error totalJson = bundle.total;
    if (totalJson is int) {
        totalCount = totalJson;
    }
    
    // Parse bundle entries to extract questionnaire metadata
    QuestionnaireListItem[] questionnaires = [];
    json|error entriesJson = bundle.entry;
    
    if entriesJson is json[] {
        foreach json entry in entriesJson {
            json|error resourceJson = entry.'resource;
            if resourceJson is json {
                QuestionnaireListItem|error item = parseQuestionnaireListItem(resourceJson);
                if item is QuestionnaireListItem {
                    questionnaires.push(item);
                } else {
                    log:printWarn("Failed to parse questionnaire item: " + item.message());
                }
            }
        }
    }
    
    return [questionnaires, totalCount];
}

# Parse FHIR Questionnaire resource to QuestionnaireListItem
#
# + fhirResource - FHIR Questionnaire resource as JSON
# + return - QuestionnaireListItem or error
function parseQuestionnaireListItem(json fhirResource) returns QuestionnaireListItem|error {
    string id = let var idVal = fhirResource.id in idVal is string ? idVal : "";
    string title = let var titleVal = fhirResource.title in titleVal is string ? titleVal : "";
    string? description = let var descVal = fhirResource.description in descVal is string ? descVal : ();
    
    string statusStr = let var statVal = fhirResource.status in statVal is string ? statVal : "unknown";
    QuestionnaireStatus status;
    match statusStr {
        "active" => { status = "active"; }
        "draft" => { status = "draft"; }
        "retired" => { status = "retired"; }
        _ => { status = "unknown"; }
    }
    
    string? createdAt = ();
    string? updatedAt = ();
    
    json|error metaJson = fhirResource.meta;
    if metaJson is json {
        json|error lastUpdatedJson = metaJson.lastUpdated;
        if (lastUpdatedJson is string) {
            updatedAt = lastUpdatedJson;
            createdAt = lastUpdatedJson; // Use lastUpdated as created if no specific created date
        }
    }
    
    return {
        id: id,
        title: title,
        description: description,
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt
    };
}

# Get a specific questionnaire by ID from FHIR server
#
# + questionnaireId - Unique questionnaire identifier
# + return - FHIR Questionnaire resource as JSON or error
function getFHIRQuestionnaireById(string questionnaireId) returns json|error {
    string path = "/Questionnaire/" + questionnaireId;
    json result = check fhirHttpClient->get(path);
    return result;
}

# Create a new questionnaire in FHIR server
#
# + questionnaire - FHIR Questionnaire resource as JSON
# + return - Created questionnaire resource as JSON or error
function createFHIRQuestionnaire(json questionnaire) returns json|error {
    http:Response response = check fhirHttpClient->post("/Questionnaire", questionnaire);
    json result = check response.getJsonPayload();
    return result;
}

# Update an existing questionnaire in FHIR server
#
# + questionnaireId - Unique questionnaire identifier
# + questionnaire - Updated FHIR Questionnaire resource as JSON
# + return - Updated questionnaire resource as JSON or error
function updateFHIRQuestionnaire(string questionnaireId, json questionnaire) returns json|error {
    string path = "/Questionnaire/" + questionnaireId;
    http:Response response = check fhirHttpClient->put(path, questionnaire);
    json result = check response.getJsonPayload();
    return result;
}

# Delete a questionnaire from FHIR server
#
# + questionnaireId - Unique questionnaire identifier
# + return - Error if operation fails, () if successful
function deleteFHIRQuestionnaire(string questionnaireId) returns error? {
    string path = "/Questionnaire/" + questionnaireId;
    http:Response response = check fhirHttpClient->delete(path);
    // Check if delete was successful (HTTP 204 or 200)
    int statusCode = response.statusCode;
    if statusCode != 200 && statusCode != 204 {
        return error("Failed to delete questionnaire: HTTP " + statusCode.toString());
    }
    return;
}

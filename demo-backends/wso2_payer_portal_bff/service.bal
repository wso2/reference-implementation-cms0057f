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

listener http:Listener bff_listener = new (6091);

service /v1 on bff_listener {

    # List all payers
    #
    # + page - Page number (1-indexed)
    # + 'limit - Number of items per page
    # + search - Search by payer name or email
    # + return - returns can be any of following types
    # http:Ok (Successful response)
    # http:InternalServerError (Internal server error)
    isolated resource function get payers(string? search, int page = 1, int 'limit = 10) returns PayerListResponse|http:InternalServerError {
        Payer[]|error payers = queryPayers(page, 'limit, search);
        if (payers is error) {
            log:printError("Failed to retrieve payers: " + payers.message());
            auditLogger.printError("Failed to retrieve payers: " + payers.message());
            return http:INTERNAL_SERVER_ERROR;
        }
        int|error totalCount = getTotalPayers(search);
        if (totalCount is error) {
            log:printError("Failed to retrieve total payers count: " + totalCount.message());
            auditLogger.printError("Failed to retrieve total payers count: " + totalCount.message());
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("Payers listed" + (search is string ? ", search: " + search : ""));
        return {
            data: payers,
            pagination: {
                page: page,
                'limit: 'limit,
                totalCount: totalCount,
                totalPages: (totalCount + 'limit - 1) / 'limit
            }
        };
    }

    # Get payer details
    #
    # + payerId - Unique payer identifier
    # + return - returns can be any of following types
    # http:Ok (Successful response)
    # http:Unauthorized (Unauthorized - Authentication required)
    # http:NotFound (Resource not found)
    # http:InternalServerError (Internal server error)
    isolated resource function get payers/[string payerId]() returns Payer|http:NotFound|http:InternalServerError {
        Payer|error? payer = getPayerById(payerId);
        if (payer is error) {
            log:printError("Failed to retrieve payer: " + payer.message());
            auditLogger.printError("Failed to retrieve payer: " + payer.message());
            return http:INTERNAL_SERVER_ERROR;
        }
        if (payer is ()) {
            log:printWarn("Payer with ID " + payerId + " not found");
            auditLogger.printWarn("Payer with ID " + payerId + " not found");
            return http:NOT_FOUND;
        }
        auditLogger.printInfo("Payer details retrieved", payerId = payerId);
        return payer;
    }

    # Create a new payer
    #
    # + return - returns can be any of following types
    # http:Created (Payer created successfully)
    # http:Conflict (Conflict - Payer with this email already exists)
    # http:InternalServerError (Internal server error)
    isolated resource function post payers(@http:Payload PayerFormData payload) returns http:Created|http:Conflict|http:InternalServerError {
        error? result = createPayer(payload);
        if (result is error) {
            log:printError("Failed to create payer: " + result.message());
            auditLogger.printError("Failed to create payer: " + result.message());
            if (result.message().includes("duplicate") || result.message().includes("unique")) {
                return http:CONFLICT;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("Payer created", name = payload.name, email = payload.email, state = payload.state);
        return http:CREATED;
    }

    # Update a payer
    #
    # + payerId - Unique payer identifier
    # + return - returns can be any of following types
    # http:Ok (Payer updated successfully)
    # http:NotFound (Resource not found)
    # http:InternalServerError (Internal server error)
    isolated resource function put payers/[string payerId](@http:Payload PayerFormData payload) returns Payer|http:Conflict|http:InternalServerError {
        Payer|error? result = updatePayer(payerId, payload);
        if (result is error) {
            log:printError("Failed to update payer: " + result.message());
            auditLogger.printError("Failed to update payer: " + result.message());
            if (result.message().includes("duplicate") || result.message().includes("unique")) {
                return http:CONFLICT;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        if (result is ()) {
            log:printWarn("Payer with ID " + payerId + " not found");
            auditLogger.printWarn("Payer with ID " + payerId + " not found");
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("Payer updated", payerId = payerId, name = payload.name, email = payload.email);
        return result;
    }

    # Delete a payer
    #
    # + payerId - Unique payer identifier
    # + return - returns can be any of following types
    # http:NoContent (Payer deleted successfully)
    # http:Unauthorized (Unauthorized - Authentication required)
    # http:NotFound (Resource not found)
    # http:InternalServerError (Internal server error)
    isolated resource function delete payers/[string payerId]() returns http:NoContent|http:NotFound|http:InternalServerError {
        error? result = deletePayer(payerId);
        if (result is error) {
            log:printError("Failed to delete payer: " + result.message());
            auditLogger.printError("Failed to delete payer: " + result.message());
            if (result.message().includes("not found")) {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("Payer deleted", payerId = payerId);
        return http:NO_CONTENT;
    }

    # List all questionnaires
    #
    # + page - Page number (1-indexed)
    # + 'limit - Number of items per page
    # + search - Search by questionnaire title or description
    # + status - Filter by questionnaire status
    # + return - returns can be any of following types
    # http:Ok (Successful response)
    # http:InternalServerError (Internal server error)
    isolated resource function get questionnaires(string? search, QuestionnaireStatus? status, int page = 1, int 'limit = 10) returns QuestionnaireListResponse|http:InternalServerError {
        [QuestionnaireListItem[], int]|error result = queryFHIRQuestionnaires(page, 'limit, search, status);
        if (result is error) {
            log:printError("Failed to retrieve questionnaires: " + result.message());
            auditLogger.printError("Failed to retrieve questionnaires: " + result.message());
            return http:INTERNAL_SERVER_ERROR;
        }
        [QuestionnaireListItem[], int] [questionnaires, totalCount] = result;
        auditLogger.printInfo("Questionnaires listed" + (search is string ? ", search: " + search : "") + (status is QuestionnaireStatus ? ", status: " + status.toString() : ""));
        return {
            data: questionnaires,
            pagination: {
                page: page,
                'limit: 'limit,
                totalCount: totalCount,
                totalPages: (totalCount + 'limit - 1) / 'limit
            }
        };
    }

    # Get questionnaire details
    #
    # + questionnaireId - Unique questionnaire identifier (UUID)
    # + return - returns can be any of following types
    # http:Ok (Successful response)
    # http:NotFound (Resource not found)
    # http:InternalServerError (Internal server error)
    isolated resource function get questionnaires/[string questionnaireId]() returns json|http:NotFound|http:InternalServerError {
        json|error questionnaire = getFHIRQuestionnaireById(questionnaireId);
        if (questionnaire is error) {
            log:printError("Failed to retrieve questionnaire: " + questionnaire.message());
            auditLogger.printError("Failed to retrieve questionnaire: " + questionnaire.message());
            if (questionnaire.message().includes("not found") || questionnaire.message().includes("404")) {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("Questionnaire details retrieved", questionnaireId = questionnaireId);
        return questionnaire;
    }

    # Create a new questionnaire
    #
    # + return - returns can be any of following types
    # http:Created (Questionnaire created successfully)
    # http:InternalServerError (Internal server error)
    isolated resource function post questionnaires(@http:Payload json payload) returns http:Created|http:InternalServerError {
        json|error questionnaire = createFHIRQuestionnaire(payload);
        if (questionnaire is error) {
            log:printError("Failed to create questionnaire: " + questionnaire.message());
            auditLogger.printError("Failed to create questionnaire: " + questionnaire.message());
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("Questionnaire created");
        return http:CREATED;
    }

    # Update a questionnaire
    #
    # + questionnaireId - Unique questionnaire identifier (UUID)
    # + return - returns can be any of following types
    # http:Ok (Questionnaire updated successfully)
    # http:NotFound (Resource not found)
    # http:InternalServerError (Internal server error)
    isolated resource function put questionnaires/[string questionnaireId](@http:Payload json payload) returns json|http:NotFound|http:InternalServerError {
        json|error questionnaire = updateFHIRQuestionnaire(questionnaireId, payload);
        if (questionnaire is error) {
            log:printError("Failed to update questionnaire: " + questionnaire.message());
            auditLogger.printError("Failed to update questionnaire: " + questionnaire.message());
            if (questionnaire.message().includes("not found") || questionnaire.message().includes("404")) {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("Questionnaire updated", questionnaireId = questionnaireId);
        return questionnaire;
    }

    # Delete a questionnaire
    #
    # + questionnaireId - Unique questionnaire identifier (UUID)
    # + return - returns can be any of following types
    # http:NoContent (Questionnaire deleted successfully)
    # http:NotFound (Resource not found)
    # http:InternalServerError (Internal server error)
    isolated resource function delete questionnaires/[string questionnaireId]() returns http:NoContent|http:NotFound|http:InternalServerError {
        error? result = deleteFHIRQuestionnaire(questionnaireId);
        if (result is error) {
            log:printError("Failed to delete questionnaire: " + result.message());
            auditLogger.printError("Failed to delete questionnaire: " + result.message());
            if (result.message().includes("not found") || result.message().includes("404")) {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("Questionnaire deleted", questionnaireId = questionnaireId);
        return http:NO_CONTENT;
    }

    # List all PA requests
    #
    # + search - Search by patient ID or request ID
    # + urgency - Filter by urgency levels
    # + status - Filter by processing status (default: Pending only)
    # + page - Page number (1-indexed)
    # + 'limit - Number of items per page (max 10, recommended 5)
    # + return - returns can be any of following types
    # http:Ok (Successful response)
    # http:InternalServerError (Internal server error)
    isolated resource function get pa\-requests(string? search, PARequestUrgency[]? urgency, PARequestProcessingStatus[]? status, int page = 1, int 'limit = 5) returns PARequestListResponse|http:InternalServerError {
        [PARequestListItem[], int]|error result = queryPARequests(page, 'limit, search, urgency, status);
        if (result is error) {
            log:printError("Failed to retrieve PA requests: " + result.message());
            auditLogger.printError("Failed to retrieve PA requests: " + result.message());
            return http:INTERNAL_SERVER_ERROR;
        }
        [PARequestListItem[], int] [paRequests, totalCount] = result;

        PARequestAnalytics|error analyticsResult = getPARequestAnalytics();
        if (analyticsResult is error) {
            log:printError("Failed to retrieve PA request analytics: " + analyticsResult.message());
            auditLogger.printError("Failed to retrieve PA request analytics: " + analyticsResult.message());
            return http:INTERNAL_SERVER_ERROR;
        }
        PARequestListResponse response = {
            data: paRequests,
            pagination: {
                page: page,
                'limit: 'limit,
                totalCount: totalCount,
                totalPages: (totalCount + 'limit - 1) / 'limit
            },
            analytics: analyticsResult
        };
        string logMessage = "PA requests listed"
            + (search is string ? ", search: " + search : "")
            + (urgency is PARequestUrgency[] ? ", urgency: " + urgency.toString() : "")
            + (status is PARequestProcessingStatus[] ? ", status: " + status.toString() : "");
        auditLogger.printInfo(logMessage);
        return response;
    }

    # Get PA request details
    #
    # + requestId - Unique PA request identifier
    # + return - returns can be any of following types
    # http:Ok (Successful response with PA request details)
    # http:NotFound (PA request not found)
    # http:InternalServerError (Internal server error)
    isolated resource function get pa\-requests/[string requestId]() returns PARequestDetail|http:NotFound|http:InternalServerError {
        PARequestDetail|error detail = getPARequestDetail(requestId);
        if (detail is error) {
            log:printError("Failed to retrieve PA request detail: " + detail.message());
            auditLogger.printError("Failed to retrieve PA request detail: " + detail.message());
            if (detail.message().includes("not found") || detail.message().includes("404")) {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("PA request details retrieved", requestId = requestId);
        return detail;
    }

    # Submit adjudication decision for a PA request
    #
    # + requestId - Unique PA request identifier
    # + return - returns can be any of following types
    # http:Ok (Adjudication submitted successfully)
    # http:NotFound (PA request not found)
    # http:InternalServerError (Internal server error)
    isolated resource function post pa\-requests/[string requestId]/adjudication(@http:Payload AdjudicationSubmission payload) returns AdjudicationResponse|http:NotFound|http:InternalServerError {
        AdjudicationResponse|error response = submitPARequestAdjudication(requestId, payload);
        if (response is error) {
            log:printError("Failed to submit adjudication: " + response.message());
            auditLogger.printError("Failed to submit adjudication: " + response.message());
            if (response.message().includes("not found") || response.message().includes("404")) {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("PA adjudication submitted", requestId = requestId, decision = payload.decision);
        return response;
    }

    # Request additional information for a PA request
    #
    # + requestId - PA claim response identifier
    # + return - returns can be any of following types
    # http:Ok (Adjudication submitted successfully)
    # http:NotFound (PA request not found)
    # http:InternalServerError (Internal server error)
    isolated resource function post pa\-requests/[string requestId]/additional\-info(@http:Payload AdditionalInformation payload)
        returns http:Ok|http:NotFound|http:InternalServerError {

        AdditionalInfoResponse|error result = submitPARequestAdditionalInfo(requestId, payload);
        if (result is error) {
            log:printError("Failed to submit additional info: " + result.message());
            auditLogger.printError("Failed to submit additional info: " + result.message());
            if (result.message().includes("not found") || result.message().includes("404")) {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("PA additional info requested", requestId = requestId, priority = payload.priority);
        return http:OK;
    }

    isolated resource function get patients/[string patientId]() returns json|http:NotFound|http:InternalServerError {
        json|error patient = getFHIRPatientById(patientId);
        if (patient is error) {
            log:printError("Failed to retrieve patient: " + patient.message());
            auditLogger.printError("Failed to retrieve patient: " + patient.message());
            if (patient.message().includes("not found") || patient.message().includes("404")) {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("Patient details retrieved", patientId = patientId);
        return patient;
    }

    // ============================================================
    // CQL Library endpoints
    // ============================================================

    # Get a FHIR Library by ID
    #
    # + libraryId - Unique Library identifier
    # + return - Library resource or error status
    isolated resource function get libraries/[string libraryId]() returns json|http:NotFound|http:InternalServerError {
        json|error library = getFHIRLibraryById(libraryId);
        if library is error {
            log:printError("Failed to retrieve library: " + library.message());
            auditLogger.printError("Failed to retrieve library: " + library.message());
            if library.message().includes("not found") || library.message().includes("404") {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("FHIR Library retrieved", libraryId = libraryId);
        return library;
    }

    # Search for a FHIR Library by canonical URL
    #
    # + url - Canonical URL of the Library
    # + return - Library resource or error status
    isolated resource function get libraries(string? url) returns json|http:NotFound|http:InternalServerError {
        if url is () {
            return http:NOT_FOUND;
        }
        json|error library = getFHIRLibraryByUrl(url);
        if library is error {
            log:printError("Failed to retrieve library by URL: " + library.message());
            auditLogger.printError("Failed to retrieve library by URL: " + library.message());
            if library.message().includes("not found") {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("FHIR Library retrieved by URL", url = url);
        return library;
    }

    # Create a new FHIR Library
    #
    # + return - Created Library resource or error status
    isolated resource function post libraries(@http:Payload json payload) returns json|http:InternalServerError {
        json|error result = createFHIRLibrary(payload);
        if result is error {
            log:printError("Failed to create library: " + result.message());
            auditLogger.printError("Failed to create library: " + result.message());
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("FHIR Library created");
        return result;
    }

    # Update an existing FHIR Library
    #
    # + libraryId - Unique Library identifier
    # + return - Updated Library resource or error status
    isolated resource function put libraries/[string libraryId](@http:Payload json payload) returns json|http:NotFound|http:InternalServerError {
        json|error result = updateFHIRLibrary(libraryId, payload);
        if result is error {
            log:printError("Failed to update library: " + result.message());
            auditLogger.printError("Failed to update library: " + result.message());
            if result.message().includes("not found") || result.message().includes("404") {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("FHIR Library updated", libraryId = libraryId);
        return result;
    }

    # Delete a FHIR Library
    #
    # + libraryId - Unique Library identifier
    # + return - No content or error status
    isolated resource function delete libraries/[string libraryId]() returns http:NoContent|http:NotFound|http:InternalServerError {
        error? result = deleteFHIRLibrary(libraryId);
        if result is error {
            log:printError("Failed to delete library: " + result.message());
            auditLogger.printError("Failed to delete library: " + result.message());
            if result.message().includes("not found") || result.message().includes("404") {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("FHIR Library deleted", libraryId = libraryId);
        return http:NO_CONTENT;
    }

    // ============================================================
    // ValueSet endpoints
    // ============================================================

    # Search for a FHIR ValueSet by canonical URL
    #
    # + url - Canonical URL of the ValueSet
    # + return - ValueSet resource or error status
    isolated resource function get value\-sets(string? url) returns json|http:NotFound|http:InternalServerError {
        if url is () {
            return http:NOT_FOUND;
        }
        json|error valueSet = getFHIRValueSetByUrl(url);
        if valueSet is error {
            log:printError("Failed to retrieve value set by URL: " + valueSet.message());
            auditLogger.printError("Failed to retrieve value set by URL: " + valueSet.message());
            if valueSet.message().includes("not found") {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("FHIR ValueSet retrieved by URL", url = url);
        return valueSet;
    }

    # Create a new FHIR ValueSet
    #
    # + return - Created ValueSet resource or error status
    isolated resource function post value\-sets(@http:Payload json payload) returns json|http:InternalServerError {
        json|error result = createFHIRValueSet(payload);
        if result is error {
            log:printError("Failed to create value set: " + result.message());
            auditLogger.printError("Failed to create value set: " + result.message());
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("FHIR ValueSet created");
        return result;
    }

    # Update an existing FHIR ValueSet
    #
    # + valueSetId - Unique ValueSet identifier
    # + return - Updated ValueSet resource or error status
    isolated resource function put value\-sets/[string valueSetId](@http:Payload json payload) returns json|http:NotFound|http:InternalServerError {
        json|error result = updateFHIRValueSet(valueSetId, payload);
        if result is error {
            log:printError("Failed to update value set: " + result.message());
            auditLogger.printError("Failed to update value set: " + result.message());
            if result.message().includes("not found") || result.message().includes("404") {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("FHIR ValueSet updated", valueSetId = valueSetId);
        return result;
    }

    // ============================================================
    // Audit log query endpoint
    // ============================================================

    # Query audit logs with optional time-window and keyword filters
    #
    # + timeFilter - Time window: PAST_10_MIN | PAST_30_MIN | PAST_1_HOUR | PAST_2_HOURS | PAST_12_HOURS | PAST_24_HOURS
    # + keyword    - Case-insensitive keyword to match anywhere in a log entry
    # + return - Filtered log entries or error
    isolated resource function get logs(string? timeFilter, string? keyword) returns LogsResponse|http:BadRequest|http:InternalServerError {
        TimeFilter? tf = ();
        if timeFilter is string {
            TimeFilter|error parsed = timeFilter.fromJsonWithType();
            if parsed is error {
                log:printWarn("Invalid timeFilter value: " + timeFilter);
                auditLogger.printWarn("Invalid timeFilter value: " + timeFilter);
                return http:BAD_REQUEST;
            }
            tf = parsed;
        }

        json[]|error logs = getAuditLogs(tf, keyword);
        if logs is error {
            log:printError("Failed to read audit logs: " + logs.message());
            auditLogger.printError("Failed to read audit logs: " + logs.message());
            return http:INTERNAL_SERVER_ERROR;
        }
        return {
            logs: logs,
            totalCount: logs.length(),
            timeFilter: timeFilter,
            keyword: keyword
        };
    }

}

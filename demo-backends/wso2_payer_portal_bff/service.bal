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
            return http:INTERNAL_SERVER_ERROR;
        }
        int|error totalCount = getTotalPayers(search);
        if (totalCount is error) {
            log:printError("Failed to retrieve total payers count: " + totalCount.message());
            return http:INTERNAL_SERVER_ERROR;
        }
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
            return http:INTERNAL_SERVER_ERROR;
        }
        if (payer is ()) {
            log:printWarn("Payer with ID " + payerId + " not found");
            return http:NOT_FOUND;
        }
        return payer;
    }

    # Create a new payer
    #
    # + return - returns can be any of following types
    # http:Created (Payer created successfully)
    # http:Conflict (Conflict - Payer with this email already exists)
    # http:InternalServerError (Internal server error)
    isolated resource function post payers(http:Request req, @http:Payload PayerFormData payload) returns http:Created|http:Conflict|http:InternalServerError {
        ActorInfo actor = getActorFromRequest(req);
        error? result = createPayer(payload);
        if (result is error) {
            log:printError("Failed to create payer: " + result.message());
            auditLogger.printError("Failed to create payer",
                eventType = "PAYER", action = "CREATE", outcome = "FAILURE",
                actor = actor.toJson(),
                details = {payerName: payload.name, payerEmail: payload.email, errorMessage: result.message()}.toJson()
            );
            if (result.message().includes("duplicate") || result.message().includes("unique")) {
                return http:CONFLICT;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("Payer created",
            eventType = "PAYER", action = "CREATE", outcome = "SUCCESS",
            actor = actor.toJson(),
            details = {payerName: payload.name, payerEmail: payload.email, state: payload.state}.toJson()
        );
        return http:CREATED;
    }

    # Update a payer
    #
    # + payerId - Unique payer identifier
    # + return - returns can be any of following types
    # http:Ok (Payer updated successfully)
    # http:NotFound (Resource not found)
    # http:InternalServerError (Internal server error)
    isolated resource function put payers/[string payerId](http:Request req, @http:Payload PayerFormData payload) returns Payer|http:Conflict|http:InternalServerError|http:NotFound {
        ActorInfo actor = getActorFromRequest(req);
        Payer|error? result = updatePayer(payerId, payload);
        if (result is error) {
            log:printError("Failed to update payer: " + result.message());
            auditLogger.printError("Failed to update payer",
                eventType = "PAYER", action = "UPDATE", outcome = "FAILURE",
                actor = actor.toJson(),
                details = {payerId: payerId, errorMessage: result.message()}.toJson()
            );
            if (result.message().includes("duplicate") || result.message().includes("unique")) {
                return http:CONFLICT;
            }
            return http:NOT_FOUND;
        }
        if (result is ()) {
            log:printWarn("Payer with ID " + payerId + " not found");
            auditLogger.printWarn("Payer not found",
                eventType = "PAYER", action = "UPDATE", outcome = "FAILURE",
                actor = actor.toJson(),
                details = {payerId: payerId}.toJson()
            );
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("Payer updated",
            eventType = "PAYER", action = "UPDATE", outcome = "SUCCESS",
            actor = actor.toJson(),
            details = {payerId: payerId, payerName: payload.name, payerEmail: payload.email}.toJson()
        );
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
    isolated resource function delete payers/[string payerId](http:Request req) returns http:NoContent|http:NotFound|http:InternalServerError {
        ActorInfo actor = getActorFromRequest(req);
        error? result = deletePayer(payerId);
        if (result is error) {
            log:printError("Failed to delete payer: " + result.message());
            auditLogger.printError("Failed to delete payer",
                eventType = "PAYER", action = "DELETE", outcome = "FAILURE",
                actor = actor.toJson(),
                details = {payerId: payerId, errorMessage: result.message()}.toJson()
            );
            if (result.message().includes("not found")) {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("Payer deleted",
            eventType = "PAYER", action = "DELETE", outcome = "SUCCESS",
            actor = actor.toJson(),
            details = {payerId: payerId}.toJson()
        );
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
            return http:INTERNAL_SERVER_ERROR;
        }
        [QuestionnaireListItem[], int] [questionnaires, totalCount] = result;
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
            if (questionnaire.message().includes("not found") || questionnaire.message().includes("404")) {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        return questionnaire;
    }

    # Create a new questionnaire
    #
    # + return - returns can be any of following types
    # http:Created (Questionnaire created successfully)
    # http:InternalServerError (Internal server error)
    isolated resource function post questionnaires(http:Request req, @http:Payload json payload) returns http:Created|http:InternalServerError {
        ActorInfo actor = getActorFromRequest(req);
        json|error questionnaire = createFHIRQuestionnaire(payload);
        if (questionnaire is error) {
            log:printError("Failed to create questionnaire: " + questionnaire.message());
            auditLogger.printError("Failed to create questionnaire",
                eventType = "QUESTIONNAIRE", action = "CREATE", outcome = "FAILURE",
                actor = actor.toJson(),
                details = {errorMessage: questionnaire.message()}.toJson()
            );
            return http:INTERNAL_SERVER_ERROR;
        }
        json qAuditDetails;
        do {
            qAuditDetails = {
                questionnaireId: (check questionnaire?.id ?: "unknown").toString(),
                title: check questionnaire?.title,
                status: check questionnaire?.status,
                newVersionId: check (check questionnaire?.meta)?.versionId
            };
        } on fail {
            qAuditDetails = {questionnaireId: "unknown"};
        }
        auditLogger.printInfo("Questionnaire created",
            eventType = "QUESTIONNAIRE", action = "CREATE", outcome = "SUCCESS",
            actor = actor.toJson(),
            details = qAuditDetails
        );
        return http:CREATED;
    }

    # Update a questionnaire
    #
    # + questionnaireId - Unique questionnaire identifier (UUID)
    # + return - returns can be any of following types
    # http:Ok (Questionnaire updated successfully)
    # http:NotFound (Resource not found)
    # http:InternalServerError (Internal server error)
    isolated resource function put questionnaires/[string questionnaireId](http:Request req, @http:Payload json payload) returns json|http:NotFound|http:InternalServerError {
        ActorInfo actor = getActorFromRequest(req);
        json|error questionnaire = updateFHIRQuestionnaire(questionnaireId, payload);
        if (questionnaire is error) {
            log:printError("Failed to update questionnaire: " + questionnaire.message());
            auditLogger.printError("Failed to update questionnaire",
                eventType = "QUESTIONNAIRE", action = "UPDATE", outcome = "FAILURE",
                actor = actor.toJson(),
                details = {questionnaireId: questionnaireId, errorMessage: questionnaire.message()}.toJson()
            );
            if (questionnaire.message().includes("not found") || questionnaire.message().includes("404")) {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        json qUpdAuditDetails;
        do {
            qUpdAuditDetails = {
                questionnaireId: questionnaireId,
                title: check questionnaire?.title,
                status: check questionnaire?.status,
                newVersionId: check (check questionnaire?.meta)?.versionId
            };
        } on fail {
            qUpdAuditDetails = {questionnaireId: questionnaireId};
        }
        auditLogger.printInfo("Questionnaire updated",
            eventType = "QUESTIONNAIRE", action = "UPDATE", outcome = "SUCCESS",
            actor = actor.toJson(),
            details = qUpdAuditDetails
        );
        return questionnaire;
    }

    # Delete a questionnaire
    #
    # + questionnaireId - Unique questionnaire identifier (UUID)
    # + return - returns can be any of following types
    # http:NoContent (Questionnaire deleted successfully)
    # http:NotFound (Resource not found)
    # http:InternalServerError (Internal server error)
    isolated resource function delete questionnaires/[string questionnaireId](http:Request req) returns http:NoContent|http:NotFound|http:InternalServerError {
        ActorInfo actor = getActorFromRequest(req);
        error? result = deleteFHIRQuestionnaire(questionnaireId);
        if (result is error) {
            log:printError("Failed to delete questionnaire: " + result.message());
            auditLogger.printError("Failed to delete questionnaire",
                eventType = "QUESTIONNAIRE", action = "DELETE", outcome = "FAILURE",
                actor = actor.toJson(),
                details = {questionnaireId: questionnaireId, errorMessage: result.message()}.toJson()
            );
            if (result.message().includes("not found") || result.message().includes("404")) {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("Questionnaire deleted",
            eventType = "QUESTIONNAIRE", action = "DELETE", outcome = "SUCCESS",
            actor = actor.toJson(),
            details = {questionnaireId: questionnaireId}.toJson()
        );
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
            return http:INTERNAL_SERVER_ERROR;
        }
        [PARequestListItem[], int] [paRequests, totalCount] = result;

        PARequestAnalytics|error analyticsResult = getPARequestAnalytics();
        if (analyticsResult is error) {
            log:printError("Failed to retrieve PA request analytics: " + analyticsResult.message());
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
            if (detail.message().includes("not found") || detail.message().includes("404")) {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        return detail;
    }

    # Submit adjudication decision for a PA request
    #
    # + requestId - Unique PA request identifier
    # + return - returns can be any of following types
    # http:Ok (Adjudication submitted successfully)
    # http:NotFound (PA request not found)
    # http:InternalServerError (Internal server error)
    isolated resource function post pa\-requests/[string requestId]/adjudication(http:Request req, @http:Payload AdjudicationSubmission payload) returns AdjudicationResponse|http:NotFound|http:InternalServerError {
        ActorInfo actor = getActorFromRequest(req);
        AdjudicationResponse|error response = submitPARequestAdjudication(requestId, payload, req);
        if (response is error) {
            log:printError("Failed to submit adjudication: " + response.message());
            auditLogger.printError("Failed to submit adjudication",
                eventType = "PA_ADJUDICATION", action = "SUBMIT", outcome = "FAILURE",
                actor = actor.toJson(),
                details = {claimId: requestId, decision: payload.decision, errorMessage: response.message()}.toJson()
            );
            if (response.message().includes("not found") || response.message().includes("404")) {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        decimal totalApproved = 0d;
        foreach ItemAdjudicationSubmission item in payload.itemAdjudications {
            decimal? adjAmt = item.approvedAmount;
            if adjAmt is decimal { totalApproved += adjAmt; }
        }
        PAAdjudicationDetails adjDetails = {
            claimId: requestId,
            decision: payload.decision,
            adjudicationAmount: totalApproved > 0d ? totalApproved : (),
            comments: payload.reviewerNotes,
            itemAdjudications: payload.itemAdjudications
        };
        auditLogger.printInfo("PA adjudication submitted",
            eventType = "PA_ADJUDICATION", action = "SUBMIT", outcome = "SUCCESS",
            actor = actor.toJson(),
            details = adjDetails.toJson()
        );
        return response;
    }

    # Request additional information for a PA request
    #
    # + requestId - PA claim response identifier
    # + return - returns can be any of following types
    # http:Ok (Adjudication submitted successfully)
    # http:NotFound (PA request not found)
    # http:InternalServerError (Internal server error)
    isolated resource function post pa\-requests/[string requestId]/additional\-info(http:Request req, @http:Payload AdditionalInformation payload)
        returns http:Ok|http:NotFound|http:InternalServerError {

        ActorInfo actor = getActorFromRequest(req);
        AdditionalInfoResponse|error result = submitPARequestAdditionalInfo(requestId, payload, req);
        if (result is error) {
            log:printError("Failed to submit additional info: " + result.message());
            auditLogger.printError("Failed to submit additional info",
                eventType = "PA_ADDITIONAL_INFO", action = "SUBMIT", outcome = "FAILURE",
                actor = actor.toJson(),
                details = {claimId: requestId, errorMessage: result.message()}.toJson()
            );
            if (result.message().includes("not found") || result.message().includes("404")) {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        string? rcText = ();
        json? rcJson = payload.reasonCode;
        if rcJson is map<json> {
            json rcTextJ = rcJson["text"] ?: "";
            string rcStr = rcTextJ.toString();
            if rcStr != "" { rcText = rcStr; }
        }
        PAAdditionalInfoDetails addlDetails = {
            claimId: requestId,
            priority: payload.priority,
            informationCodes: payload.informationCodes,
            reasonCode: rcText,
            communicationRequestId: result.id
        };
        auditLogger.printInfo("PA additional info requested",
            eventType = "PA_ADDITIONAL_INFO", action = "SUBMIT", outcome = "SUCCESS",
            actor = actor.toJson(),
            details = addlDetails.toJson()
        );
        return http:OK;
    }

    isolated resource function get patients/[string patientId]() returns json|http:NotFound|http:InternalServerError {
        json|error patient = getFHIRPatientById(patientId);
        if (patient is error) {
            log:printError("Failed to retrieve patient: " + patient.message());
            if (patient.message().includes("not found") || patient.message().includes("404")) {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
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
            if library.message().includes("not found") || library.message().includes("404") {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
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
            if library.message().includes("not found") {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        return library;
    }

    # Create a new FHIR Library
    #
    # + return - Created Library resource or error status
    isolated resource function post libraries(http:Request req, @http:Payload json payload) returns json|http:InternalServerError {
        ActorInfo actor = getActorFromRequest(req);
        json|error result = createFHIRLibrary(payload);
        if result is error {
            log:printError("Failed to create library: " + result.message());
            auditLogger.printError("Failed to create library",
                eventType = "LIBRARY", action = "CREATE", outcome = "FAILURE",
                actor = actor.toJson(),
                details = {errorMessage: result.message()}.toJson()
            );
            return http:INTERNAL_SERVER_ERROR;
        }
        json libAuditDetails;
        do {
            libAuditDetails = {
                libraryId: (check result?.id ?: "unknown").toString(),
                libraryUrl: check result?.url
            };
        } on fail {
            libAuditDetails = {libraryId: "unknown"};
        }
        auditLogger.printInfo("FHIR Library created",
            eventType = "LIBRARY", action = "CREATE", outcome = "SUCCESS",
            actor = actor.toJson(),
            details = libAuditDetails
        );
        return result;
    }

    # Update an existing FHIR Library
    #
    # + libraryId - Unique Library identifier
    # + return - Updated Library resource or error status
    isolated resource function put libraries/[string libraryId](http:Request req, @http:Payload json payload) returns json|http:NotFound|http:InternalServerError {
        ActorInfo actor = getActorFromRequest(req);
        json|error result = updateFHIRLibrary(libraryId, payload);
        if result is error {
            log:printError("Failed to update library: " + result.message());
            auditLogger.printError("Failed to update library",
                eventType = "LIBRARY", action = "UPDATE", outcome = "FAILURE",
                actor = actor.toJson(),
                details = {libraryId: libraryId, errorMessage: result.message()}.toJson()
            );
            if result.message().includes("not found") || result.message().includes("404") {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("FHIR Library updated",
            eventType = "LIBRARY", action = "UPDATE", outcome = "SUCCESS",
            actor = actor.toJson(),
            details = {libraryId: libraryId}.toJson()
        );
        return result;
    }

    # Delete a FHIR Library
    #
    # + libraryId - Unique Library identifier
    # + return - No content or error status
    isolated resource function delete libraries/[string libraryId](http:Request req) returns http:NoContent|http:NotFound|http:InternalServerError {
        ActorInfo actor = getActorFromRequest(req);
        error? result = deleteFHIRLibrary(libraryId);
        if result is error {
            log:printError("Failed to delete library: " + result.message());
            auditLogger.printError("Failed to delete library",
                eventType = "LIBRARY", action = "DELETE", outcome = "FAILURE",
                actor = actor.toJson(),
                details = {libraryId: libraryId, errorMessage: result.message()}.toJson()
            );
            if result.message().includes("not found") || result.message().includes("404") {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("FHIR Library deleted",
            eventType = "LIBRARY", action = "DELETE", outcome = "SUCCESS",
            actor = actor.toJson(),
            details = {libraryId: libraryId}.toJson()
        );
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
            if valueSet.message().includes("not found") {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        return valueSet;
    }

    # Create a new FHIR ValueSet
    #
    # + return - Created ValueSet resource or error status
    isolated resource function post value\-sets(http:Request req, @http:Payload json payload) returns json|http:InternalServerError {
        ActorInfo actor = getActorFromRequest(req);
        json|error result = createFHIRValueSet(payload);
        if result is error {
            log:printError("Failed to create value set: " + result.message());
            auditLogger.printError("Failed to create value set",
                eventType = "VALUE_SET", action = "CREATE", outcome = "FAILURE",
                actor = actor.toJson(),
                details = {errorMessage: result.message()}.toJson()
            );
            return http:INTERNAL_SERVER_ERROR;
        }
        json vsAuditDetails;
        do {
            vsAuditDetails = {valueSetId: (check result?.id ?: "unknown").toString()};
        } on fail {
            vsAuditDetails = {valueSetId: "unknown"};
        }
        auditLogger.printInfo("FHIR ValueSet created",
            eventType = "VALUE_SET", action = "CREATE", outcome = "SUCCESS",
            actor = actor.toJson(),
            details = vsAuditDetails
        );
        return result;
    }

    # Update an existing FHIR ValueSet
    #
    # + valueSetId - Unique ValueSet identifier
    # + return - Updated ValueSet resource or error status
    isolated resource function put value\-sets/[string valueSetId](http:Request req, @http:Payload json payload) returns json|http:NotFound|http:InternalServerError {
        ActorInfo actor = getActorFromRequest(req);
        json|error result = updateFHIRValueSet(valueSetId, payload);
        if result is error {
            log:printError("Failed to update value set: " + result.message());
            auditLogger.printError("Failed to update value set",
                eventType = "VALUE_SET", action = "UPDATE", outcome = "FAILURE",
                actor = actor.toJson(),
                details = {valueSetId: valueSetId, errorMessage: result.message()}.toJson()
            );
            if result.message().includes("not found") || result.message().includes("404") {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        auditLogger.printInfo("FHIR ValueSet updated",
            eventType = "VALUE_SET", action = "UPDATE", outcome = "SUCCESS",
            actor = actor.toJson(),
            details = {valueSetId: valueSetId}.toJson()
        );
        return result;
    }

    // ============================================================
    // Payer to Payer data Exchange proxy endpoints
    // ============================================================

    isolated resource function get 'pdex\-data\-requests(int 'limit = 10, int offset = 0) returns json|error {
        json|error response = pdexHttpClient->get("/pdex-data-requests?limit=" + 'limit.toString() + "&offset=" + offset.toString());
        if response is error {
            log:printError("Failed to retrieve Payer Data Exchange requests: " + response.message());
            return response;
        }
        return response;
    }

    isolated resource function get 'pdex\-data\-requests/[string requestId]() returns json|error {
        json|error response = pdexHttpClient->get("/pdex-data-requests/" + requestId);
        if response is error {
            log:printError("Failed to retrieve Payer Data Exchange request detail: " + response.message());
            return response;
        }
        return response;
    }

    isolated resource function post 'trigger\-data\-exchange/[string requestId](http:Request req) returns json|error {
        ActorInfo actor = getActorFromRequest(req);

        // Fetch exchange context from DB for audit enrichment
        string? payerId = ();
        string? patientId = ();
        PdexExchangeRecord|error exchangeRecord = getPdexExchangeRecord(requestId);
        if exchangeRecord is error {
            log:printError("Failed to retrieve PDex exchange record for audit context: " + exchangeRecord.message());
            return error("Failed to retrieve PDex exchange record: " + exchangeRecord.message());
        }
        payerId = exchangeRecord.payerId;
        patientId = exchangeRecord.memberId;

        json|error response = pdexHttpClient->post("/trigger-data-exchange/" + requestId, message = ());
        if response is error {
            log:printError("Failed to trigger Payer Data Exchange: " + response.message());
            auditLogger.printError("Failed to trigger PDex exchange",
                eventType = "PDEX_EXCHANGE", action = "SUBMIT", outcome = "FAILURE",
                actor = actor.toJson(),
                details = (<PdexExchangeDetails>{
                    exchangeId: requestId,
                    status: "failed",
                    payerId: payerId,
                    patientId: patientId
                }).toJson()
            );
            return response;
        }
        auditLogger.printInfo("PDex exchange initiated",
            eventType = "PDEX_EXCHANGE", action = "SUBMIT", outcome = "SUCCESS",
            actor = actor.toJson(),
            details = (<PdexExchangeDetails>{
                exchangeId: requestId,
                status: "initiated",
                payerId: payerId,
                patientId: patientId
            }).toJson()
        );
        return response;
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
                return http:BAD_REQUEST;
            }
            tf = parsed;
        }

        json[]|error logs = getAuditLogs(tf, keyword);
        if logs is error {
            log:printError("Failed to read audit logs: " + logs.message());
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

// import ballerina/io;
import ballerina/log;
import ballerina/http;
// import ballerinax/health.fhir.r4.validator;
// import ballerinax/health.fhir.r4.davincidtr210;
// // import ballerinax/health.fhir.r4.international401;
// import ballerinax/health.fhir.r4.parser as fhirParser;

listener http:Listener bff_listener = new (6091);

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"],
        allowMethods: ["GET", "POST", "OPTIONS", "PUT"],
        allowHeaders: ["Content-Type", "Authorization", "Accept", "Origin"],
        allowCredentials: true,
        maxAge: 84900
    }
}
service /v1 on bff_listener {
    
    # List all payers
    #
    # + page - Page number (1-indexed)
    # + 'limit - Number of items per page
    # + search - Search by payer name or email
    # + return - returns can be any of following types 
    # http:Ok (Successful response)
    # http:InternalServerError (Internal server error)
    resource function get payers(string? search, int page = 1, int 'limit = 10) returns PayerListResponse|http:InternalServerError {
        Payer[]|error payers = queryPayers(page, 'limit);
        if (payers is error) {
            log:printError("Failed to retrieve payers: " + payers.message());
            return http:INTERNAL_SERVER_ERROR;
        }

        int|error totalCount = getTotalPayers();
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
    resource function get payers/[string payerId]() returns Payer|http:NotFound|http:InternalServerError {
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
    resource function post payers(@http:Payload PayerFormData payload) returns Payer|http:Conflict|http:InternalServerError {
        Payer|error payer = createPayer(payload);
        
        if (payer is error) {
            log:printError("Failed to create payer: " + payer.message());
            
            // Check if it's a unique constraint violation (email already exists)
            if (payer.message().includes("duplicate") || payer.message().includes("unique")) {
                return http:CONFLICT;
            }
            
            return http:INTERNAL_SERVER_ERROR;
        }
        
        return payer;
    }

    # Update a payer
    #
    # + payerId - Unique payer identifier
    # + return - returns can be any of following types 
    # http:Ok (Payer updated successfully)
    # http:NotFound (Resource not found)
    # http:InternalServerError (Internal server error)
    resource function put payers/[string payerId](@http:Payload PayerFormData payload) returns Payer|http:NotFound|http:Conflict|http:InternalServerError {
        Payer|error? payer = updatePayer(payerId, payload);
        
        if (payer is error) {
            log:printError("Failed to update payer: " + payer.message());
            
            // Check if it's a unique constraint violation (email already exists)
            if (payer.message().includes("duplicate") || payer.message().includes("unique")) {
                return http:CONFLICT;
            }
            
            return http:INTERNAL_SERVER_ERROR;
        }
        
        if (payer is ()) {
            log:printWarn("Payer with ID " + payerId + " not found");
            return http:NOT_FOUND;
        }
        
        return payer;
    }

    # Delete a payer
    #
    # + payerId - Unique payer identifier
    # + return - returns can be any of following types 
    # http:NoContent (Payer deleted successfully)
    # http:Unauthorized (Unauthorized - Authentication required)
    # http:NotFound (Resource not found)
    # http:InternalServerError (Internal server error)
    resource function delete payers/[string payerId]() returns http:NoContent|http:NotFound|http:InternalServerError {
        error? result = deletePayer(payerId);
        
        if (result is error) {
            log:printError("Failed to delete payer: " + result.message());
            
            if (result.message().includes("not found")) {
                return http:NOT_FOUND;
            }
            
            return http:INTERNAL_SERVER_ERROR;
        }
        
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
    resource function get questionnaires(string? search, QuestionnaireStatus? status, int page = 1, int 'limit = 10) returns QuestionnaireListResponse|http:InternalServerError {
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
    resource function get questionnaires/[string questionnaireId]() returns json|http:NotFound|http:InternalServerError {
        json|error questionnaire = getFHIRQuestionnaireById(questionnaireId);
        
        if (questionnaire is error) {
            log:printError("Failed to retrieve questionnaire: " + questionnaire.message());
            
            // Check if it's a not found error
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
    resource function post questionnaires(@http:Payload json payload) returns http:Created|http:InternalServerError {
        json|error questionnaire = createFHIRQuestionnaire(payload);
        
        if (questionnaire is error) {
            log:printError("Failed to create questionnaire: " + questionnaire.message());
            return http:INTERNAL_SERVER_ERROR;
        }
        
        return http:CREATED;
    }

    # Update a questionnaire
    #
    # + questionnaireId - Unique questionnaire identifier (UUID)
    # + return - returns can be any of following types 
    # http:Ok (Questionnaire updated successfully)
    # http:NotFound (Resource not found)
    # http:InternalServerError (Internal server error)
    resource function put questionnaires/[string questionnaireId](@http:Payload json payload) returns json|http:NotFound|http:InternalServerError {
        json|error questionnaire = updateFHIRQuestionnaire(questionnaireId, payload);
        
        if (questionnaire is error) {
            log:printError("Failed to update questionnaire: " + questionnaire.message());
            
            // Check if it's a not found error
            if (questionnaire.message().includes("not found") || questionnaire.message().includes("404")) {
                return http:NOT_FOUND;
            }
            
            return http:INTERNAL_SERVER_ERROR;
        }
        
        return questionnaire;
    }

    # Delete a questionnaire
    #
    # + questionnaireId - Unique questionnaire identifier (UUID)
    # + return - returns can be any of following types 
    # http:NoContent (Questionnaire deleted successfully)
    # http:NotFound (Resource not found)
    # http:InternalServerError (Internal server error)
    resource function delete questionnaires/[string questionnaireId]() returns http:NoContent|http:NotFound|http:InternalServerError {
        error? result = deleteFHIRQuestionnaire(questionnaireId);
        
        if (result is error) {
            log:printError("Failed to delete questionnaire: " + result.message());
            
            // Check if it's a not found error
            if (result.message().includes("not found") || result.message().includes("404")) {
                return http:NOT_FOUND;
            }
            
            return http:INTERNAL_SERVER_ERROR;
        }
        
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
    resource function get pa\-requests(string? search, PARequestUrgency[]? urgency, PARequestProcessingStatus[]? status, int page = 1, int 'limit = 5) returns PARequestListResponse|http:InternalServerError {
        // Query PA requests from FHIR
        [PARequestListItem[], int]|error result = queryPARequests(page, 'limit, search, urgency, status);
        
        if (result is error) {
            log:printError("Failed to retrieve PA requests: " + result.message());
            return http:INTERNAL_SERVER_ERROR;
        }
        
        [PARequestListItem[], int] [paRequests, totalCount] = result;

        // Get analytics from PostgreSQL
        // PARequestAnalytics|error analyticsResult = getPARequestAnalytics();
        // TODO: Discuss and implement analytics - For now, return dummy analytics data
        PARequestAnalytics analytics = {
            urgentCount: 0,
            standardCount: 0,
            reAuthorizationCount: 0,
            appealCount: 0
        };
        
        PARequestListResponse response = {
            data: paRequests,
            pagination: {
                page: page,
                'limit: 'limit,
                totalCount: totalCount,
                totalPages: (totalCount + 'limit - 1) / 'limit
            },
            analytics: analytics
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
    resource function get pa\-requests/[string requestId]() returns PARequestDetail|http:NotFound|http:InternalServerError {
        PARequestDetail|error detail = getPARequestDetail(requestId);
        
        if (detail is error) {
            log:printError("Failed to retrieve PA request detail: " + detail.message());
            
            // Check if it's a not found error
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
    resource function post pa\-requests/[string requestId]/adjudication(@http:Payload AdjudicationSubmission payload) returns AdjudicationResponse|http:NotFound|http:InternalServerError {
        AdjudicationResponse|error response = submitPARequestAdjudication(requestId, payload);
        
        if (response is error) {
            log:printError("Failed to submit adjudication: " + response.message());
            
            // Check if it's a not found error
            if (response.message().includes("not found") || response.message().includes("404")) {
                return http:NOT_FOUND;
            }
            
            return http:INTERNAL_SERVER_ERROR;
        }
        
        return response;
    }

}

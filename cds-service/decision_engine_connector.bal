import ballerinax/health.fhir.cds;

# ====================================== Please do your implementations to the below methods ===========================
#
# Consider the below steps while do your implementations.
#
# 1. Map the received CdsRequest/ Feedback request to the custom payload format, if needed (Optional).
# 2. Implement the connectivity with your external decision support systems.
# 3. Send the CdsRequest/ Feedback request to appropriate external systems.
# 4. Get the response.
# 5. Map the received response to the CdsCards and Cds actions.
# 6. Return the CdsResponse to the client.
#
# ======================================================================================================================

# Handle decision service connectivity.
#
# + cdsRequest - CdsRequest to sent to the backend.
# + hookId - ID of the hook being invoked.
# + return - return CdsResponse or CdsError
isolated function connectDecisionSystemForPrescirbeMedication(cds:CdsRequest cdsRequest, string hookId) returns cds:CdsResponse|cds:CdsError {
    return {
        cards: [
            {
                "summary": "Prior Authorization Required",
                "indicator": "warning",
                "detail": "This medication (Aimovig 70 mg) requires prior authorization from XYZ Health Insurance. Please complete the required documentation.",
                "source": {
                    "label": "UnitedCare Health Insurance ePA Service",
                    "url": "https://xyzhealth.com/prior-auth"
                },
                "suggestions": [
                    {
                        "label": "Submit e-Prior Authorization",
                        "uuid": "submit-epa",
                        "actions": [
                            {
                                "type": "create",
                                "description": "Submit an electronic prior authorization request for Aimovig 70 mg.",
                                "resource": {
                                    "resourceType": "Task",
                                    "status": "requested",
                                    "intent": "order",
                                    "code": {
                                        "coding": [
                                            {
                                                "system": "http://terminology.hl7.org/CodeSystem/task-code",
                                                "code": "prior-authorization",
                                                "display": "Submit Prior Authorization"
                                            }
                                        ]
                                    },
                                    "for": {
                                        "reference": "Patient/101"
                                    },
                                    "owner": {
                                        "reference": "Organization/50"
                                    }
                                }
                            }
                        ]
                    }
                ],
                "links": [
                    {
                        "label": "Check PA Status",
                        "url": "https://xyzhealth.com/check-pa-status",
                        "type": "absolute"
                    },
                    {
                        "label": "Launch SMART App for DTR",
                        "url": "http://localhost:5173/dashboard/drug-order-v2/prior-auth?questionnaireId=4",
                        "type": "smart"
                    }
                ]
            }
        ]
    };
}

# Handle feedback service connectivity.
#
# + feedback - Feedback record to be processed.
# + hookId - ID of the hook being invoked.
# + return - return CdsError, if any.
isolated function connectFeedbackSystemForPrescirbeMedication(cds:Feedbacks feedback, string hookId) returns cds:CdsError? {
    return cds:createCdsError(string `Rule repository backend not implemented/ connected yet for ${hookId}`, 501);
}

# Handle decision service connectivity.
#
# + cdsRequest - CdsRequest to sent to the backend.
# + hookId - ID of the hook being invoked.
# + return - return CdsResponse or CdsError
isolated function connectDecisionSystemForRadiology(cds:CdsRequest cdsRequest, string hookId) returns cds:CdsResponse|cds:CdsError {
    return cds:createCdsError(string `Rule repository backend not implemented/ connected yet for ${hookId}`, 501);
}

# Handle feedback service connectivity.
#
# + feedback - Feedback record to be processed.
# + hookId - ID of the hook being invoked.
# + return - return CdsError, if any.
isolated function connectFeedbackSystemForRadiology(cds:Feedbacks feedback, string hookId) returns cds:CdsError? {
    return cds:createCdsError(string `Rule repository backend not implemented/ connected yet for ${hookId}`, 501);
}

# Handle decision service connectivity.
#
# + cdsRequest - CdsRequest to sent to the backend.
# + hookId - ID of the hook being invoked.
# + return - return CdsResponse or CdsError
isolated function connectDecisionSystemForRadiologyOrder(cds:CdsRequest cdsRequest, string hookId) returns cds:CdsResponse|cds:CdsError {
    return cds:createCdsError(string `Rule repository backend not implemented/ connected yet for ${hookId}`, 501);
}

# Handle feedback service connectivity.
#
# + feedback - Feedback record to be processed.
# + hookId - ID of the hook being invoked.
# + return - return CdsError, if any.
isolated function connectFeedbackSystemForRadiologyOrder(cds:Feedbacks feedback, string hookId) returns cds:CdsError? {
    return cds:createCdsError(string `Rule repository backend not implemented/ connected yet for ${hookId}`, 501);
}

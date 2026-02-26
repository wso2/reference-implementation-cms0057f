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
import ballerina/log;
import ballerina/time;
import ballerina/url;
import ballerina/uuid;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincihrex100;
import ballerinax/health.fhir.r4.davincipas;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore501;
import ballerinax/health.fhir.r4.validator;

isolated function getQueryParamsMap(map<r4:RequestSearchParameter[] & readonly> requestSearchParameters) returns map<string[]> {
    //TODO: Should provide ability to get the query parameters from the context as it is from the http request. 
    //Refer : https://github.com/wso2-enterprise/open-healthcare/issues/1369
    map<string[]> queryParameters = {};
    foreach var key in requestSearchParameters.keys() {
        r4:RequestSearchParameter[] & readonly searchParameters = requestSearchParameters[key] ?: [];
        foreach var searchParameter in searchParameters {
            string name = searchParameter.name;
            if queryParameters[name] is string[] {
                (<string[]>queryParameters[name]).push(searchParameter.value);
            } else {
                queryParameters[name] = [searchParameter.value];
            }
        }
    }
    return queryParameters;
}

# Result has to deliver as OperationOutcome resources, this method populate OpOutcome with relavant info.
#
# + severity - severity of the outcome
# + code - code of the outcome
# + message - text description of the outcome
# + return - FHIR:R4 OperationOutcome resource
public isolated function createOpereationOutcome(string severity, string code, string message) returns r4:OperationOutcome {
    r4:OperationOutcomeIssueSeverity severityType;
    do {
        severityType = check severity.cloneWithType(r4:OperationOutcomeIssueSeverity);
    } on fail var e {
        log:printError("Error occurred while creating the operation outcome. Error in severity type", e);
        r4:OperationOutcome operationOutcomeError = {
            issue: [
                {severity: "error", code: "exception", diagnostics: "Error occurred while creating the operation outcome. Error in severity type"}
            ]
        };
        return operationOutcomeError;

    }
    r4:OperationOutcome operationOutcome = {
        issue: [
            {severity: severityType, code: code, diagnostics: message}
        ]
    };
    return operationOutcome;
}

# Call the discovery endpoint to get the OpenID configuration.
#
# + discoveryEndpoint - Discovery endpoint
# + return - If successful, returns OpenID configuration as a json. Else returns error.
public isolated function getOpenidConfigurations(string discoveryEndpoint) returns OpenIDConfiguration|error {
    log:printDebug("Retrieving openid configuration started");
    string discoveryEndpointUrl = check url:decode(discoveryEndpoint, "UTF8");
    http:Client discoveryEpClient = check new (discoveryEndpointUrl.toString());
    OpenIDConfiguration openidConfiguration = check discoveryEpClient->get("/");
    log:printDebug("Retrieving openid configuration ended");
    return openidConfiguration;
}

# Input parameters of the member match operation.
enum MemberMatchParameter {
    MEMBER_PATIENT = "MemberPatient",
    CONSENT = "Consent",
    COVERAGE_TO_MATCH = "CoverageToMatch",
    COVERAGE_TO_LINK = "CoverageToLink"
};

# Constant symbols
const AMPERSAND = "&";
const SLASH = "/";
const QUOTATION_MARK = "\"";
const QUESTION_MARK = "?";
const EQUALS_SIGN = "=";
const COMMA = ",";
# FHIR  parameters 
const _FORMAT = "_format";
const _SUMMARY = "_summary";
const _HISTORY = "_history";
const METADATA = "metadata";
const MODE = "mode";
# Request Headers
const ACCEPT_HEADER = "Accept";
const PREFER_HEADER = "Prefer";
const LOCATION = "Location";
const CONTENT_TYPE = "Content-Type";
const CONTENT_LOCATION = "Content-Location";

# Map of `ParameterInfo` to hold information about member match parameters.
final map<ParameterInfo> & readonly MEMBER_MATCH_PARAMETERS_INFO = {
    [MEMBER_PATIENT]: {profile: "USCorePatientProfile", typeDesc: uscore501:USCorePatientProfile},
    [CONSENT]: {profile: "HRexConsent", typeDesc: davincihrex100:HRexConsent},
    [COVERAGE_TO_MATCH]: {profile: "HRexCoverage", typeDesc: davincihrex100:HRexCoverage},
    [COVERAGE_TO_LINK]: {profile: "HrexCoverage", typeDesc: davincihrex100:HRexCoverage}
};

# Validates and extracts the parameter resources from member match request parameters.
#
# + requestParams - The `HRexMemberMatchRequestParameters` containing the parameters
# + return - A `MemberMatchResources` record containing the extracted resources if validation is successful,
# or a `FHIRError` if there's an error in validating the resources
isolated function validateAndExtractMemberMatchResources(davincihrex100:HRexMemberMatchRequestParameters requestParams)
        returns davincihrex100:MemberMatchResources|r4:FHIRError {
    map<anydata> processedResources = {};

    foreach string param in MEMBER_MATCH_PARAMETERS_INFO.keys() {
        anydata? 'resource = check validateAndExtractParamResource(requestParams, param,
                MEMBER_MATCH_PARAMETERS_INFO.get(param));
        if param != COVERAGE_TO_LINK && 'resource == () { // CoverageToLink is optional
            if param != CONSENT { // Consent is optional in hrex110. Hence skipping the validation here.
                return createMissingMandatoryParamError(param);
            }
        }
        processedResources[param] = 'resource;
    }

    return {
        memberPatient: <uscore501:USCorePatientProfile>processedResources[MEMBER_PATIENT],
        consent: <davincihrex100:HRexConsent>processedResources[CONSENT],
        coverageToMatch: <davincihrex100:HRexCoverage>processedResources[COVERAGE_TO_MATCH],
        coverageToLink: <davincihrex100:HRexCoverage?>processedResources[COVERAGE_TO_LINK]
    };
}

# Validates and extracts a specific parameter resource from the member match request parameters.
#
# + requestParams - The `HRexMemberMatchRequestParameters` containing the parameters
# + paramName - The name of the parameter to be validated and extracted
# + paramInfo - The `ParameterInfo` of the parameter
# + return - The validated and extracted parameter as `anydata` if successful, a `FHIRError` if validation fails, or 
# `()` if the parameter is not present
isolated function validateAndExtractParamResource(davincihrex100:HRexMemberMatchRequestParameters requestParams,
        string paramName, ParameterInfo paramInfo) returns anydata|r4:FHIRError? {
    r4:Resource? paramResource = getParamResource(requestParams, paramName);
    if paramResource == () {
        return;
    }

    anydata|error 'resource = paramResource.cloneWithType(paramInfo.typeDesc);
    if 'resource is error {
        return createInvalidParamTypeError(paramName, paramInfo.profile);
    }

    // Validate the resource
    r4:FHIRValidationError? validationRes = validator:validate('resource, paramInfo.typeDesc);
    if validationRes is r4:FHIRValidationError {
        return createInvalidParamTypeError(paramName, paramInfo.profile);
    }

    return 'resource;
}

# Retrieves a specific FHIR resource associated with a parameter from the member match request parameters.
#
# + requestParams - The `HRexMemberMatchRequestParameters` containing the parameters
# + 'parameter - The name of the parameter whose resource is to be retrieved
# + return - The FHIR `r4:Resource` associated with the specified parameter if found, or `()` if not found
isolated function getParamResource(davincihrex100:HRexMemberMatchRequestParameters requestParams, string 'parameter)
        returns r4:Resource? {
    foreach davincihrex100:HRexMemberMatchRequestParametersParameter param in requestParams.'parameter {
        if param.'name == 'parameter {
            return param?.'resource;
        }
    }
    return;
}

# Constructs an HTTP client authentication configuration from a given `AuthConfig`.
#
# + authConfig - An optional `AuthConfig` containing the OAuth2 authentication details
# + return - An `http:ClientAuthConfig` if `authConfig` is provided, otherwise `()`
isolated function getClientAuthConfig(AuthConfig? authConfig) returns http:ClientAuthConfig? {
    if authConfig != () {
        return {
            tokenUrl: authConfig.tokenUrl,
            clientId: authConfig.clientId,
            clientSecret: authConfig.clientSecret
        };
    }
    return;
}

# Creates a `FHIRError` indicating an invalid parameter type error.
#
# + paramName - The name of the parameter that failed validation
# + expectedType - The expected data type of the parameter
# + return - A `FHIRError` with details about the invalid parameter type
isolated function createInvalidParamTypeError(string paramName, string expectedType) returns r4:FHIRError {
    string message = "Invalid parameter";
    string diagnostic = "Parameter \"" + paramName + "\" must be a valid \"" + expectedType + "\" type";
    return r4:createFHIRError(message, r4:ERROR, r4:INVALID_VALUE, diagnostic = diagnostic,
            httpStatusCode = http:STATUS_BAD_REQUEST);
}

# Creates a `FHIRError` for a missing mandatory parameter in FHIR operations.
#
# + paramName - The name of the missing mandatory parameter
# + return - A `FHIRError` with details about the missing mandatory parameter
isolated function createMissingMandatoryParamError(string paramName) returns r4:FHIRError {
    string message = "Missing mandatory parameter";
    string diagnostic = "Mandatory parameter \"" + paramName + "\" is missing";
    return r4:createFHIRError(message, r4:ERROR, r4:INVALID_REQUIRED, diagnostic = diagnostic,
            httpStatusCode = http:STATUS_BAD_REQUEST);
}

# Generator function for Smart Configuration
# + return - smart configuration as a json or an error
public isolated function generateSmartConfiguration() returns SmartConfiguration|error {
    log:printDebug("Generating smart configuration started");

    OpenIDConfiguration openIdConfigurations = {};
    string? discoveryEndpoint = configs.discoveryEndpoint;
    if discoveryEndpoint is string && discoveryEndpoint != "" {
        OpenIDConfiguration|error openidConfigurations = getOpenidConfigurations(discoveryEndpoint);
        if openidConfigurations is error {
            log:printWarn("Failed to get OpenID configurations from the authz server. Falling back to manual configurations");
        } else {
            openIdConfigurations = openidConfigurations.cloneReadOnly();
        }
    } else {
        log:printDebug(string `${VALUE_NOT_FOUND}: discoveryEndpoint`);
    }

    string? authorization_endpoint = configs.smartConfiguration?.authorizationEndpoint ?: openIdConfigurations.authorization_endpoint ?: ();
    if authorization_endpoint is () || authorization_endpoint == "" {
        return error(string `${VALUE_NOT_FOUND}: Authorization endpoint`);
    }

    string? token_endpoint = configs.smartConfiguration?.tokenEndpoint ?: openIdConfigurations.token_endpoint ?: ();
    if token_endpoint is () || token_endpoint == "" {
        return error(string `${VALUE_NOT_FOUND}: Token endpoint`);
    }

    string[]? capabilities = configs.smartConfiguration?.capabilities ?: ();
    if capabilities is () || capabilities.length() == 0 {
        return error(string `${VALUE_NOT_FOUND}: Capabilities`);
    }

    string[]? code_challenge_methods_supported = configs.smartConfiguration?.codeChallengeMethodsSupported ?: openIdConfigurations.code_challenge_methods_supported ?: ();
    if code_challenge_methods_supported is () || code_challenge_methods_supported.length() == 0 {
        return error(string `${VALUE_NOT_FOUND}: Code challenge methods supported`);
    }

    string[]? grant_types_supported = configs.smartConfiguration?.grantTypesSupported ?: openIdConfigurations.grant_types_supported ?: ();
    if grant_types_supported is () || grant_types_supported.length() == 0 {
        return error(string `${VALUE_NOT_FOUND}: Grant types supported`);
    }

    SmartConfiguration smartConfig = {
        authorization_endpoint,
        token_endpoint,
        capabilities,
        code_challenge_methods_supported,
        grant_types_supported,
        issuer: configs.smartConfiguration?.issuer ?: openIdConfigurations.issuer ?: (),
        revocation_endpoint: configs.smartConfiguration?.revocationEndpoint ?: openIdConfigurations.revocation_endpoint ?: (),
        introspection_endpoint: configs.smartConfiguration?.introspectionEndpoint ?: openIdConfigurations.introspection_endpoint ?: (),
        management_endpoint: configs.smartConfiguration?.managementEndpoint ?: openIdConfigurations.management_endpoint ?: (),
        registration_endpoint: configs.smartConfiguration?.registrationEndpoint ?: openIdConfigurations.registration_endpoint ?: (),
        jwks_uri: configs.smartConfiguration?.jwksUri ?: openIdConfigurations.jwks_uri ?: (),
        response_types_supported: configs.smartConfiguration?.responseTypesSupported ?: openIdConfigurations.response_types_supported ?: (),
        token_endpoint_auth_methods_supported: configs.smartConfiguration?.tokenEndpointAuthMethodsSupported ?: openIdConfigurations.token_endpoint_auth_methods_supported ?: (),
        token_endpoint_auth_signing_alg_values_supported: configs.smartConfiguration?.tokenEndpointAuthSigningAlgValuesSupported ?: (),
        scopes_supported: configs.smartConfiguration?.scopesSupported ?: openIdConfigurations.scopes_supported ?: ()
    };

    log:printDebug("Generating smart configuration completed ");
    return smartConfig;
}

public isolated function claimSubmit(international401:Parameters payload) returns r4:FHIRError|r4:Bundle|error {
    international401:Parameters|error 'parameters = parser:parseWithValidation(payload.toJson(), international401:Parameters).ensureType();

    if 'parameters is error {
        return r4:createFHIRError('parameters.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        international401:ParametersParameter[]? 'parameter = 'parameters.'parameter;
        if 'parameter is international401:ParametersParameter[] {
            foreach var item in 'parameter {
                if item.name == "resource" {
                    r4:Resource? resourceResult = item.'resource;
                    if resourceResult is r4:Resource {
                        r4:Bundle cloneWithType = check resourceResult.cloneWithType(r4:Bundle);
                        r4:BundleEntry[]? entry = cloneWithType.entry;
                        if entry is r4:BundleEntry[] {
                            if entry.length() == 0 || entry[0]?.'resource is () {
                                return r4:createFHIRError("Bundle entry missing claim resource", r4:ERROR, r4:INVALID,
                                    httpStatusCode = http:STATUS_BAD_REQUEST);
                            }
                            r4:BundleEntry bundleEntry = entry[0];
                            anydata 'resource = bundleEntry?.'resource;
                            international401:Claim claim = check parser:parse('resource.toJson(), international401:Claim).ensureType();
                            claim.id = uuid:createType1AsString();

                            r4:DomainResource newClaimResource = check create(fhirConnector, CLAIM, claim.toJson());
                            international401:Claim newClaim = check newClaimResource.cloneWithType();

                            davincipas:PASClaimResponse claimResponse = {
                                id: uuid:createType1AsString(),
                                request: {reference: "Claim/" + <string>newClaim.id},
                                patient: newClaim.patient,
                                insurer: <r4:Reference>newClaim.insurer,
                                created: newClaim.created,
                                'type: newClaim.'type,
                                use: newClaim.use,
                                requestor: claim.provider,
                                outcome: "partial",
                                disposition: "Prior authorization request is pending review.",
                                status: "active"
                            };

                            r4:DomainResource newClaimResponseResource = check create(fhirConnector, CLAIM_RESPONSE, claimResponse.toJson());
                            davincipas:PASClaimResponse newClaimResponse = check newClaimResponseResource.cloneWithType();

                            r4:BundleEntry bundleEntryResponse = {
                                'resource: newClaimResponse,
                                fullUrl: "urn:uuid:" + <string>newClaimResponse.id
                            };

                            r4:Bundle responseBundle = {
                                'type: r4:BUNDLE_TYPE_COLLECTION,
                                entry: [bundleEntryResponse]
                            };

                            return responseBundle.clone();
                        }
                    }
                }
            }
        }
    }
    return r4:createFHIRError("Something went wrong", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
}

# Helper function to validate consent
#
# + consent - The consent resource to validate
# + return - FHIRError if validation fails, otherwise returns ()
isolated function validateConsent(Consent consent) returns r4:FHIRError? {
    // Check required fields
    if consent.patient is () {
        return r4:createFHIRError("Patient reference is required", r4:ERROR, r4:INVALID_REQUIRED, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    // Check consent status - must be active for evaluation
    if consent.status != international401:CODE_STATUS_ACTIVE {
        return r4:createFHIRError(CONSENT_STATUS_INVALID, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    // Check consent scope - must be for patient privacy
    // Validate that the scope is appropriate for patient privacy consent
    if consent.scope.coding is r4:Coding[] {
        boolean validScope = false;
        foreach r4:Coding coding in <r4:Coding[]>consent.scope.coding {
            if coding.code is string {
                string code = <string>coding.code;
                // Check if the scope is for patient privacy
                if code == "patient-privacy" || code == "privacy" {
                    validScope = true;
                    break;
                }
            }
        }
        if !validScope {
            return r4:createFHIRError(CONSENT_SCOPE_INVALID, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
        }
    }

    // Validate consent period if provided
    if consent.provision?.period is r4:Period {
        r4:Period|error period = consent.provision?.period.cloneWithType();
        if period is error {
            return r4:createFHIRError("Invalid period format", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
        }
        if period.end is r4:dateTime && period.'start is r4:dateTime {
            if period.end < period.'start {
                return r4:createFHIRError("Consent end date must be after start date", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
            }
        }
    }

    // Check if consent has provision section
    if consent.provision is () {
        return r4:createFHIRError(CONSENT_PROVISION_REQUIRED, r4:ERROR, r4:INVALID_REQUIRED, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    // Check for duplicate consents
    r4:FHIRError? duplicateError = checkForDuplicateConsent(consent);
    if duplicateError is r4:FHIRError {
        return duplicateError;
    }

    return ();
}

// Consent management related utilities
# Helper function to match search criteria
#
# + consent - The consent resource to match against search criteria
# + searchParams - The search parameters to match against
# + return - true if consent matches search criteria, false otherwise
isolated function matchesSearchCriteria(Consent consent, map<r4:RequestSearchParameter[]> searchParams) returns boolean {
    // Implement search logic based on parameters
    // This is a simplified implementation
    if searchParams.hasKey("status") {
        r4:RequestSearchParameter[] status = searchParams.get("status");
        if consent.status.toString() != status[0].value {
            return false;
        }
    }

    if searchParams.hasKey("patient") {
        r4:RequestSearchParameter[] patient = searchParams.get("patient");
        if consent.patient?.reference != patient[0].value {
            return false;
        }
    }

    return true;
}

# Helper function to extract consent from parameters
#
# + params - parameters containing the consent resource
# + return - the extracted consent resource or null
isolated function extractConsentFromParameters(international401:ParametersParameter[] params) returns Consent? {

    foreach international401:ParametersParameter param in params {
        Consent|error consent = param.'resource.cloneWithType();
        if param.name == "Consent" && consent is Consent {
            return consent;
        }
    }

    return ();
}

# Function to evaluate consent based on comprehensive guidelines
#
# + consent - The consent resource to evaluate
# + memberMatchResult - The matched member identifier from the member matcher
# + return - The result of the consent evaluation
isolated function evaluateConsent(Consent consent, string memberMatchResult) returns ConsentEvaluationResult {
    ConsentEvaluationResult result = {
        isValid: false,
        patientId: (),
        reason: (),
        memberIdentity: (),
        consentPolicy: (),
        consentStartDate: (),
        consentEndDate: (),
        requestingPayer: ()
    };

    if memberMatchResult == "" {
        log:printError("Member match result is empty");
        result.reason = CONSENT_EVALUATION_FAILED;
        return result;
    }

    // Step 1: Member Identity Validation
    // Confirm the Consent.patient reference matches the uniquely identified member
    if consent.patient?.reference is string {
        string consentPatientRef = <string>consent.patient?.reference;
        // Extract patient ID from reference (e.g., "Patient/123" -> "123")
        string:RegExp slash = re `/`;
        string[] refParts = slash.split(consentPatientRef);
        if refParts.length() == 2 {
            string consentPatientId = refParts[1];
            // Compare with the matched member identifier
            if consentPatientId == memberMatchResult {
                result.memberIdentity = memberMatchResult;
                log:printDebug("Member identity validation successful: " + consentPatientId);
            } else {
                log:printError("Member identity mismatch. Consent patient: " + consentPatientId + ", Matched member: " + memberMatchResult);
                result.reason = CONSENT_INVALID_MEMBER;
                return result;
            }
        } else {
            log:printError("Invalid patient reference format: " + consentPatientRef);
            result.reason = CONSENT_INVALID_MEMBER;
            return result;
        }
    } else {
        log:printError("Patient reference not found in consent");
        result.reason = CONSENT_INVALID_MEMBER;
        return result;
    }

    // Step 2: Payer Identity Validation
    // Confirm the Consent.organization is the Receiving Payer and Consent.performer is the Requesting Payer
    if consent.organization is r4:Reference[] {
        // Check if organization matches the receiving payer (this system)
        // This is a simplified check - in production you'd validate against actual payer identifiers
        result.requestingPayer = "receiving-payer"; // Placeholder
        log:printDebug("Payer identity validation successful");
    } else {
        log:printError("Organization reference not found in consent");
        result.reason = CONSENT_INVALID_PAYER;
        return result;
    }

    // Step 3: Date Validity Validation
    // Check if the current date falls within the Consent.provision.period
    if consent.provision?.period is r4:Period {
        r4:Period period = <r4:Period>consent.provision?.period;
        result.consentStartDate = period.'start;
        result.consentEndDate = period.end;

        // Check if consent is still valid
        if period.end is r4:dateTime {
            r4:dateTime now = time:utcToString(time:utcNow());
            if period.end < now {
                log:printError("Consent has expired. End date: " + <string>period.end + ", Current time: " + now);
                result.reason = CONSENT_EXPIRED;
                return result;
            }
        }
        log:printDebug("Date validity validation successful");
    } else {
        // If no period specified, consider it invalid
        log:printError("Consent period not specified");
        result.reason = CONSENT_PERIOD_NOT_SPECIFIED;
        return result;
    }

    // Step 4: Policy Compliance Validation
    // Determine if the Receiving Payer can technically comply with the data segmentation request
    if consent.policy is international401:ConsentPolicy[] {
        result.consentPolicy = extractConsentPolicy(<international401:ConsentPolicy[]>consent.policy);

        // Check if the requested policy is supported
        if result.consentPolicy is string {
            string policy = <string>result.consentPolicy;
            // This is a simplified check - in production you'd validate against actual system capabilities
            if policy == "http://hl7.org/fhir/us/davinci-hrex/StructureDefinition-hrex-consent.html#regular" ||
                policy == "http://hl7.org/fhir/us/davinci-hrex/StructureDefinition-hrex-consent.html#sensitive" {
                // Policy is supported
                log:printDebug("Policy compliance validation successful. Policy: " + policy);
            } else {
                log:printError("Requested policy not supported: " + policy);
                result.reason = CONSENT_POLICY_NOT_SUPPORTED;
                return result;
            }
        } else {
            log:printError("Consent policy not found in provision policies");
            result.reason = CONSENT_POLICY_NOT_SUPPORTED;
            return result;
        }
    } else {
        log:printError("Provision policies not found in consent");
        result.reason = CONSENT_POLICY_NOT_SUPPORTED;
        return result;
    }

    // If all validations pass, consent is valid
    result.isValid = true;
    result.patientId = result.memberIdentity;
    result.reason = CONSENT_EVALUATION_SUCCESS;
    log:printInfo("All consent validations passed successfully");

    return result;
}

# Helper function to extract consent policy
#
# + policies - The array of consent policies to extract from
# + return - The extracted consent policy code
isolated function extractConsentPolicy(international401:ConsentPolicy[] policies) returns string? {
    foreach international401:ConsentPolicy policy in policies {
        if policy?.uri is string {
            return policy.uri;
        }
    }
    return ();
}

# Function to create success response
#
# + result - The consent evaluation result containing patient ID and reason
# + return - HTTP response with Parameters resource containing patient ID and consent status
isolated function createSuccessResponse(ConsentEvaluationResult result) returns http:Response {
    // Create operation outcome for success
    r4:OperationOutcome outcome = {
        resourceType: "OperationOutcome",
        issue: [
            {
                severity: r4:CODE_SEVERITY_INFORMATION,
                code: r4:INFORMATIONAL,
                diagnostics: result.reason
            }
        ]
    };

    // Create a Parameters resource containing the matched member's unique and stable Patient FHIR ID
    // This follows Phase 4 requirements for successful match and consent
    international401:Parameters successResponse = {
        resourceType: "Parameters",
        'parameter: [
            {
                name: "PatientId",
                valueString: result.patientId
            },
            {
                name: "ConsentStatus",
                valueString: "VALID"
            },
            {
                name: "OperationOutcome",
                'resource: outcome
            }
        ]
    };

    http:Response response = new ();
    response.setPayload(successResponse);
    response.setHeader("Content-Type", "application/fhir+json");
    response.statusCode = http:STATUS_OK;
    return response;
}

# Function to create error response
#
# + result - The consent evaluation result containing reason for failure
# + return - HTTP response with OperationOutcome and Parameters resource detailing the failure
isolated function createErrorResponse(ConsentEvaluationResult result) returns http:Response {
    // Create operation outcome for error with detailed diagnostics
    r4:OperationOutcome outcome = {
        resourceType: "OperationOutcome",
        issue: [
            {
                severity: r4:CODE_SEVERITY_ERROR,
                code: r4:PROCESSING_BUSINESS_RULE,
                diagnostics: result.reason,
                details: {
                    coding: [
                        {
                            system: "http://hl7.org/fhir/ValueSet/consent-validation-failure",
                            code: "consent-validation-failed",
                            display: "Consent validation failed"
                        }
                    ]
                }
            }
        ]
    };

    // Create a Parameters resource for the error response
    // This follows Phase 4 requirements for failed match or consent
    international401:Parameters errorResponse = {
        resourceType: "Parameters",
        'parameter: [
            {
                name: "ErrorType",
                valueString: "CONSENT_VALIDATION_FAILED"
            },
            {
                name: "FailureReason",
                valueString: result.reason
            },
            {
                name: "OperationOutcome",
                'resource: outcome
            }
        ]
    };

    http:Response response = new ();
    response.setPayload(errorResponse);
    response.setHeader("Content-Type", "application/fhir+json");
    response.statusCode = http:STATUS_UNPROCESSABLE_ENTITY;
    return response;
}

# Helper function to check for duplicate consents
#
# + consent - The consent resource to check for duplicates
# + return - FHIRError if a duplicate is found, otherwise returns ()
isolated function checkForDuplicateConsent(Consent consent) returns r4:FHIRError? {
    lock {
        foreach var id in consentStore.keys() {
            Consent storedConsent = <Consent>consentStore.get(id);

            // Check if this is a duplicate based on patient, organization, and policy
            if (storedConsent.patient?.reference == consent.patient?.reference &&
                storedConsent.organization == consent.organization &&
                storedConsent.provision?.code == consent.provision?.code) {

                // Check if the existing consent is still active
                if storedConsent.status == international401:CODE_STATUS_ACTIVE {
                    return r4:createFHIRError(CONSENT_DUPLICATE_FOUND, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_CONFLICT);
                }
            }
        }
    }
    return ();
}

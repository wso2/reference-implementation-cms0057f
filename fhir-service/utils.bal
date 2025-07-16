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
import ballerina/url;
import ballerina/io;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincihrex100;
import ballerinax/health.fhir.r4.uscore501;
import ballerinax/health.fhir.r4.validator;
import ballerinax/health.fhir.r4.davincipas;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.parser;

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


public isolated function claimSubmit(international401:Parameters payload) returns r4:FHIRError|international401:Parameters|error {
    international401:Parameters|error 'parameters = parser:parseWithValidation(payload.toJson(), international401:Parameters).ensureType();

    json claimResponseJson = check io:fileReadJson("resources/claim-response.json");

    if parameters is error {
        return r4:createFHIRError(parameters.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        international401:ParametersParameter[]? 'parameter = parameters.'parameter;
        if 'parameter is international401:ParametersParameter[] {
            foreach var item in 'parameter {
                if item.name == "resource" {
                    r4:Resource? resourceResult = item.'resource;
                    if resourceResult is r4:Resource {
                        // r4:Bundle bundle = check parser:parse(resourceResult.toJson(), r4:Bundle).ensureType();
                        r4:Bundle cloneWithType = check resourceResult.cloneWithType(r4:Bundle);
                        r4:BundleEntry[]? entry = cloneWithType.entry;
                        if entry is r4:BundleEntry[] {
                            r4:BundleEntry bundleEntry = entry[0];
                            anydata 'resource = bundleEntry?.'resource;
                            davincipas:PASClaim claim = check parser:parse('resource.toJson(), davincipas:PASClaim).ensureType();

                            r4:DomainResource newClaimResource = check create(CLAIM, claim.toJson());
                            davincipas:PASClaim newClaim = check newClaimResource.cloneWithType();

                            davincipas:PASClaimResponse claimResponse = check parser:parse(claimResponseJson, davincipas:PASClaimResponse).ensureType();
                            
                            claimResponse.patient = newClaim.patient;
                            claimResponse.insurer = newClaim.insurer;
                            claimResponse.created = newClaim.created;
                            claimResponse.request = {reference: "Claim/" + <string>newClaim.id};

                            r4:DomainResource newClaimResponseResource = check create(CLAIM_RESPONSE, claimResponse.toJson());
                            davincipas:PASClaimResponse newClaimResponse = check newClaimResponseResource.cloneWithType();

                            international401:ParametersParameter p = {
                                name: "return",
                                'resource: newClaimResponse
                            };

                            international401:Parameters parameterResponse = {
                                'parameter: [p]
                            };
                            return parameterResponse.clone();
                        }
                    }
                }
            }
        }
    }
    return r4:createFHIRError("Something went wrong", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
}

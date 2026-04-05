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
import ballerina/sql;
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
import ballerinax/health.clients.fhir as fhirClient;

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

# Function to invoke the X12 translation service and create an audit record for the transaction.
# 
# + url - The endpoint URL of the X12 translation service
# + payload - The payload to be sent to the X12 translation service
# + claimId - The ID of the claim being processed, used for audit record correlation
# + fhirConnector - The FHIR connector used to create the audit record in the FHIR server
# 
# + return - An error if the X12 service call fails or if audit record creation fails, otherwise returns ()
isolated function invokeX12ServiceAndCreateAuditRecord(string url, string payload, string claimId, fhirClient:FHIRConnector fhirConnector) returns error? {
    
    if x12ConnectionConfig.enable {
        http:Client?|error x12Client = ();
        lock {
            x12Client = x12ConnectionClient;
        }
        if x12Client is () || x12Client is error {
            return error("X12 connection client is not initialized");
        }
        
        http:Response response = check x12Client->post(url, payload);
        if response.statusCode == http:STATUS_OK {
            string responsePayload = check response.getTextPayload();

            // Create Audit Record
            international401:AuditEvent auditEvent = {
                id: claimId,
                'source: {
                    observer: {
                        "display": "FHIR Service"
                    }
                }, 
                agent: [], 
                recorded: time:utcToString(time:utcNow()), 
                'type: {
                    system: "http://terminology.hl7.org/CodeSystem/audit-event-type",
                    code: "x12",
                    display: "X12 Request"
                },
                outcome: responsePayload
            };
            _ = check create(fhirConnector, AUDIT_EVENT, auditEvent.toJson());
            log:printDebug("Audit event created for the converted X12 message.");
        } else {
            return error("X12 service call failed with status code: " + response.statusCode.toString());
        }
    }
}

# Extract the logical ID from a FHIR reference string (e.g. "Patient/123" → "123").
#
# + reference - FHIR reference string, may be null
# + return - Logical ID or null if reference is null/empty
isolated function extractRefId(string? reference) returns string? {
    if reference is () || reference == "" {
        return ();
    }
    string[] parts = re`/`.split(reference);
    return parts[parts.length() - 1];
}

# Map a FHIR Claim priority coding to the PA request priority string.
# "stat" → "Urgent", "deferred" → "Deferred", anything else → "Standard".
#
# + claimJson - Claim resource as JSON
# + return - Priority string: "Urgent", "Standard", or "Deferred"
isolated function mapClaimPriority(json claimJson) returns string {
    json|error codings = claimJson.priority.coding;
    if codings is json[] && codings.length() > 0 {
        json|error code = codings[0].code;
        if code is string {
            string lower = code.toLowerAscii();
            if lower == "stat" {
                return "Urgent";
            } else if lower == "deferred" {
                return "Deferred";
            }
        } else {
            log:printWarn("Claim priority coding code is not a string. Defaulting to Standard. Value: " + (<error>code).toString());
        }
    }
    return "Standard";
}

# Detect whether a Claim represents an appeal by checking extensions whose URL
# contains "appeal". The extension value is used when present (valueBoolean),
# otherwise the presence of a matching URL is treated as an implicit true.
#
# Note: related.relationship.coding code "prior" is intentionally NOT used as
# an appeal signal — "prior" only indicates a predecessor claim, not an appeal.
#
# + claimJson - Claim resource as JSON
# + return - true if the claim is an appeal
isolated function detectIsAppeal(json claimJson) returns boolean {
    json|error extensions = claimJson.extension;
    if extensions is json[] {
        foreach json ext in extensions {
            json|error urlJson = ext.url;
            if urlJson is string && urlJson.toLowerAscii().includes("appeal") {
                json|error vb = ext.valueBoolean;
                return vb is boolean ? vb : true;
            }
        }
    }
    return false;
}

# Resolve practitioner ID and provider name from a Claim resource.
# Resolution order:
# 1. careTeam entries (PractitionerRole → practitioner + org, or Practitioner directly)
# 2. claim.provider reference (PractitionerRole, Organization, or Practitioner)
# 3. Fallback to claim.provider.display
#
# + fhirConnector - FHIR connector for fetching related resources
# + claimJson - Claim resource as JSON
# + return - Tuple of [practitioner_id, provider_name], either may be null
isolated function resolveProviderInfo(fhirClient:FHIRConnector fhirConnector, international401:Claim claimJson) returns [string?, string?] {
    string? practitionerId = ();
    string? providerName = ();

    // 1. Check careTeam entries
    international401:ClaimCareTeam[]? careTeamJson = claimJson.careTeam;
    if careTeamJson is international401:ClaimCareTeam[] {
        foreach international401:ClaimCareTeam member in careTeamJson {
            if practitionerId is string && providerName is string {
                break;
            }
            string? providerRef = member.provider.reference;
            if providerRef is (){
                log:printWarn("CareTeam member is missing provider reference");
                continue;
            }
            if providerRef.includes("PractitionerRole/") {
                string? prId = extractRefId(providerRef);
                if prId is () {
                    log:printWarn("CareTeam member provider reference includes PractitionerRole but ID is empty");
                    continue;
                }
                r4:DomainResource|r4:FHIRError prRes = getById(fhirConnector, PRACTITIONER_ROLE, prId);
                if prRes is r4:FHIRError {
                    log:printWarn("Failed to retrieve PractitionerRole resource with ID " + prId + ": " + prRes.toString());
                    continue;
                }
                international401:PractitionerRole|error pr = prRes.cloneWithType(international401:PractitionerRole);
                if pr is error {
                    log:printWarn("Failed to convert PractitionerRole resource with ID " + prId + " to international401:PractitionerRole: " + pr.toString());
                    continue;
                }
                if practitionerId is () {
                    practitionerId = extractRefId(pr.practitioner?.reference);
                }
                if providerName is () && pr.organization is r4:Reference {
                    string? orgId = extractRefId((<r4:Reference>pr.organization).reference);
                    if orgId is () {
                        log:printWarn("Organization reference in PractitionerRole with ID " + prId + " is empty");
                        continue;
                    }
                    r4:DomainResource|r4:FHIRError orgRes = getById(fhirConnector, ORGANIZATION, orgId);
                    if orgRes is r4:FHIRError {
                        log:printWarn("Failed to retrieve Organization resource with ID " + orgId + ": " + orgRes.toString());
                        continue;
                    }
                    international401:Organization|error org = orgRes.cloneWithType(international401:Organization);
                    if org is error {
                        log:printWarn("Failed to convert Organization resource with ID " + orgId + " to international401:Organization: " + org.toString());
                        continue;
                    }
                    providerName = org.name;
                }
                break;
            } else if providerRef.includes("Practitioner/") {
                practitionerId = extractRefId(providerRef);
                break;
            }
        }
    }

    // 2. Check claim.provider reference
    string? providerRef = claimJson.provider.reference;
    string? providerDisplay = claimJson.provider.display;

    if providerRef is string {
        if providerRef.includes("PractitionerRole") {
            string? prId = extractRefId(providerRef);
            if prId is () {
                log:printWarn("Claim provider reference includes PractitionerRole but ID is empty");
                return [practitionerId, providerName];
            }
            r4:DomainResource|r4:FHIRError prRes = getById(fhirConnector, PRACTITIONER_ROLE, prId);
            if prRes is r4:FHIRError {
                log:printWarn("Failed to retrieve PractitionerRole resource with ID " + prId + ": " + prRes.toString());
                return [practitionerId, providerName];
            }
            international401:PractitionerRole|error pr = prRes.cloneWithType(international401:PractitionerRole);
            if pr is error {
                log:printWarn("Failed to convert PractitionerRole resource with ID " + prId + " to international401:PractitionerRole: " + pr.toString());
                return [practitionerId, providerName];
            }
            if practitionerId is () {
                practitionerId = extractRefId(pr.practitioner?.reference);
            }
            if providerName is () && pr.organization is r4:Reference {
                string? orgId = extractRefId((<r4:Reference>pr.organization).reference);
                if orgId is string {
                    r4:DomainResource|r4:FHIRError orgRes = getById(fhirConnector, ORGANIZATION, orgId);
                    if orgRes is r4:FHIRError {
                        log:printWarn("Failed to retrieve Organization resource with ID " + orgId + ": " + orgRes.toString());
                        return [practitionerId, providerName];
                    }
                    international401:Organization|error org = orgRes.cloneWithType(international401:Organization);
                    if org is international401:Organization {
                        providerName = org.name;
                    }
                }
            }
        } else if providerRef.includes("Organization") && providerName is () {
            string? orgId = extractRefId(providerRef);
            if orgId is string {
                r4:DomainResource|r4:FHIRError orgRes = getById(fhirConnector, ORGANIZATION, orgId);
                if orgRes is r4:FHIRError {
                    log:printWarn("Failed to retrieve Organization resource with ID " + orgId + ": " + orgRes.toString());
                    return [practitionerId, providerName];
                }
                international401:Organization|error org = orgRes.cloneWithType(international401:Organization);
                if org is international401:Organization {
                    providerName = org.name;
                }
            }
        } else if providerRef.includes("Practitioner") && practitionerId is () {
            practitionerId = extractRefId(providerRef);
        }
    }

    // 3. Fallback: use display field
    if providerName is () && providerDisplay is string {
        providerName = providerDisplay;
    }

    return [practitionerId, providerName];
}

public isolated function claimSubmit(r4:Bundle|international401:Parameters payload) returns r4:FHIRError|r4:Bundle|error {
    r4:Bundle submissionBundle;
    if payload is r4:Bundle {
        submissionBundle = payload;
    } else {
        // international401:Parameters parameters = <international401:Parameters>payload;
        // international401:ParametersParameter[]? 'parameter = parameters.'parameter;
        // if 'parameter is international401:ParametersParameter[] {
        //     r4:Bundle? foundBundle = ();
        //     foreach var item in 'parameter {
        //         if item.name == "resource" {
        //             r4:Resource? resourceResult = item.'resource;
        //             if resourceResult is r4:Bundle {
        //                 foundBundle = resourceResult;
        //             } else if resourceResult is r4:Resource {
        //                 foundBundle = check resourceResult.cloneWithType(r4:Bundle);
        //             }
        //             break;
        //         }
        //     }
        //     if foundBundle is r4:Bundle {
        //         submissionBundle = foundBundle;
        //     } else {
        //         return r4:createFHIRError("Bundle not found in parameters", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
        //     }
        // } else {
        //     return r4:createFHIRError("Invalid parameters", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
        // }
    }
    submissionBundle = check payload.cloneWithType(r4:Bundle);
    r4:BundleEntry[]? entries = submissionBundle.entry;
    if entries is r4:BundleEntry[] && entries.length() > 0 {
        international401:Claim? claim = ();
        foreach var entry in entries {
            anydata 'resource = entry?.'resource;
            if 'resource is international401:Claim {
                claim = 'resource;
                break;
            } else if 'resource is map<anydata> {
                map<anydata> resourceMap = <map<anydata>>'resource;
                anydata resourceType = resourceMap["resourceType"];
                if resourceType is string && resourceType == "Claim" {
                    international401:Claim|error c = 'resource.cloneWithType(international401:Claim);
                    if c is international401:Claim {
                        claim = c;
                        break;
                    }
                }
            }
        }

        if claim is international401:Claim {
            string claimId = uuid:createType1AsString();
            claim.id = claimId;

            r4:DomainResource newClaimResource = check create(fhirConnector, CLAIM, claim.toJson());
            international401:Claim newClaim = check newClaimResource.cloneWithType();

            if x12ConnectionConfig.enable {

                FhirToX12ServicePayload x12Payload = {
                    payload: submissionBundle.toJson(),
                    x12Headers: x12Header
                };

                log:printInfo("Starting FHIR to X12 translation for the Bundle");
                error? result = invokeX12ServiceAndCreateAuditRecord(FHIR_TO_X12_API_RESOURCE, x12Payload.toJsonString(), claimId, fhirConnector);
                if result is error {
                    return r4:createFHIRError(result.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
                } else {
                    log:printDebug("X12 translation and audit record creation successful");
                }
            }

            davincipas:PASClaimResponse claimResponse = {
                id: uuid:createType1AsString(),
                request: {reference: "Claim/" + <string>newClaim.id},
                patient: newClaim?.patient,
                insurer: <r4:Reference>newClaim?.insurer,
                created: newClaim?.created,
                'type: newClaim?.'type,
                use: newClaim?.use,
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

            // Insert PA request record into the database
            string responseId = <string>newClaimResponse.id;
            json claimJson = claim.toJson();
            string mappedPriority = mapClaimPriority(claimJson);
            json|error patientRefJson = claimJson.patient.reference;
            string patientId = patientRefJson is string ? (extractRefId(patientRefJson) ?: "") : "";
            [string?, string?] providerInfo = resolveProviderInfo(fhirConnector, claim);
            string? practitionerId = providerInfo[0];
            string? providerName = providerInfo[1];
            boolean isAppeal = detectIsAppeal(claimJson);
            time:Utc now = time:utcNow();
            time:Civil civil = time:utcToCivil(now);
            int sec = <int>(civil.second ?: 0.0d);
            string dateSubmitted = string `${civil.year}-${civil.month < 10 ? "0" : ""}${civil.month}-${civil.day < 10 ? "0" : ""}${civil.day} ${civil.hour < 10 ? "0" : ""}${civil.hour}:${civil.minute < 10 ? "0" : ""}${civil.minute}:${sec < 10 ? "0" : ""}${sec}`;

            sql:ParameterizedQuery insertQuery = `INSERT INTO pa_requests
                (request_id, response_id, priority, status, ai_summary, patient_id, practitioner_id, provider_name, is_appeal, date_submitted)
                VALUES (${claimId}, ${responseId}, ${mappedPriority}, 'QUEUED', NULL, ${patientId}, ${practitionerId}, ${providerName}, ${isAppeal}, ${dateSubmitted})`;
            sql:ExecutionResult|sql:Error dbResult = dbClient->execute(insertQuery);
            if dbResult is sql:Error {
                string errMsg = string `Failed to insert PA request into database: request_id=${claimId}, response_id=${responseId}: ${dbResult.message()}`;
                log:printError(errMsg, dbResult);
                r4:OperationOutcome|r4:FHIRError deleteResponseResult = deleteResource(fhirConnector, CLAIM_RESPONSE, responseId);
                if deleteResponseResult is r4:FHIRError {
                    log:printError("Compensating delete of ClaimResponse failed: response_id=" + responseId, deleteResponseResult);
                }
                r4:OperationOutcome|r4:FHIRError deleteClaimResult = deleteResource(fhirConnector, CLAIM, claimId);
                if deleteClaimResult is r4:FHIRError {
                    log:printError("Compensating delete of Claim failed: claim_id=" + claimId, deleteClaimResult);
                }
                return error(errMsg);
            }
            log:printDebug("PA request inserted into database: request_id=" + claimId + ", response_id=" + responseId);

            return responseBundle.clone();
        } else {
            return r4:createFHIRError("Claim resource not found in bundle", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
        }
    }
    return r4:createFHIRError("Bundle entries missing or empty", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
}

public isolated function submitAttachments(international401:Parameters payload) 
    returns r4:FHIRError|davincipas:PASClaimSupportingInfo[]|error {

    international401:Parameters|error 'parameters = 
        parser:parseWithValidation(payload.toJson(), international401:Parameters).ensureType();

    if 'parameters is error {
        return r4:createFHIRError('parameters.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        string trackingId = "";
        international401:ParametersParameter[]? 'parameter = 'parameters.'parameter;
        davincipas:PASClaimSupportingInfo[] supportingInfoList = [];
        if 'parameter is international401:ParametersParameter[] {
            foreach var item in 'parameter {
                if item.name == "Attachment" {
                    r4:ParametersParameter[]? parts = item.part;
                    if parts is () {
                        return r4:createFHIRError("Attachment parameter must have parts", r4:ERROR, r4:INVALID, 
                            httpStatusCode = http:STATUS_BAD_REQUEST);
                    }
                    foreach r4:ParametersParameter part in parts {
                        r4:Resource? resourceResult = part.'resource;
                        if resourceResult is r4:Resource {
                            // if resource type is DocumentReference, then create a DocumentReference 
                            // resource in the FHIR server.
                            if resourceResult.resourceType == "DocumentReference" {
                                international401:DocumentReference documentReferenceResource = 
                                    check parser:parse(resourceResult.toJson(), international401:DocumentReference)
                                    .ensureType();
                                documentReferenceResource.id = uuid:createType1AsString();
                                // create document reference resource in the FHIR server
                                r4:DomainResource _ = check create(fhirConnector, DOCUMENT_REFERENCE, 
                                    documentReferenceResource.toJson());
                                // create supporting info
                                davincipas:PASClaimSupportingInfo supportingInfo = {
                                    valueReference: {reference: "DocumentReference/" + 
                                        <string>documentReferenceResource.id},
                                    sequence: 1, // todo
                                    category: {
                                        coding: [
                                            {
                                                system: "http://terminology.hl7.org/CodeSystem/claiminformationcategory",
                                                code: "info",
                                                display: "Supporting Information"
                                            }
                                        ]
                                    }
                                };
                                supportingInfoList.push(supportingInfo);

                            } else if resourceResult.resourceType == "QuestionnaireResponse" {
                                international401:QuestionnaireResponse questionnaireResponseResource = 
                                    check parser:parse(resourceResult.toJson(), international401:QuestionnaireResponse)
                                    .ensureType();

                                davincipas:PASClaimSupportingInfo supportingInfo = {
                                    valueReference: {reference: "QuestionnaireResponse/" + 
                                        <string>questionnaireResponseResource.id},
                                    sequence: 1,
                                    category: {
                                        coding: [
                                            {
                                                system: "http://terminology.hl7.org/CodeSystem/claiminformationcategory",
                                                code: "info",
                                                display: "Supporting Information"
                                            }
                                        ]
                                    }
                                };
                                supportingInfoList.push(supportingInfo);
                            }
                        }
                    }
                }
                if item.name == "TrackingId" {
                    if item.valueString is string {
                        trackingId = item.valueString ?: "";
                    }
                }
            }
        }
        if trackingId == "" {
            return r4:createFHIRError("TrackingId parameter is missing", r4:ERROR, r4:INVALID, 
                httpStatusCode = http:STATUS_BAD_REQUEST);
        }
        if supportingInfoList.length() > 0 {
            return supportingInfoList.clone();
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
# + inputPatientId - The `id` of the input MemberPatient resource from the request. Per HRex spec,
#                   Consent.patient SHALL be a local reference (e.g. "Patient/1") that resolves to
#                   the MemberPatient parameter — NOT the matched patient ID in this payer's system.
#                   Ref: https://hl7.org/fhir/us/davinci-hrex/STU1/OperationDefinition-member-match.html
# + return - The result of the consent evaluation
isolated function evaluateConsent(Consent consent, string inputPatientId) returns ConsentEvaluationResult {
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

    if inputPatientId == "" {
        log:printError("Input patient id is empty");
        result.reason = CONSENT_EVALUATION_FAILED;
        return result;
    }

    // Status check — consent must be active
    if consent.status != international401:CODE_STATUS_ACTIVE {
        log:printError("Consent is not active. Status: " + consent.status);
        result.reason = CONSENT_STATUS_INVALID;
        return result;
    }

    // Scope check — HRex Consent requires scope = "patient-privacy" (Must Support fixed value)
    // Ref: https://hl7.org/fhir/us/davinci-hrex/STU1.1/StructureDefinition-hrex-consent.html
    r4:Coding[]? scopeCodings = consent.scope?.coding;
    if scopeCodings is r4:Coding[] {
        boolean validScope = scopeCodings.some(c => c.code == "patient-privacy");
        if !validScope {
            log:printError("Consent scope is not 'patient-privacy'");
            result.reason = CONSENT_SCOPE_INVALID;
            return result;
        }
    } else {
        log:printError("Consent scope is missing");
        result.reason = CONSENT_SCOPE_REQUIRED;
        return result;
    }

    // Step 1: Member Identity Validation
    // Consent.patient SHALL be a local reference to the input MemberPatient (e.g. "Patient/1").
    // Compare its id segment against the input patient's id — never against the matched patient id.
    if consent.patient?.reference is string {
        string consentPatientRef = <string>consent.patient?.reference;
        // Extract patient ID from reference (e.g., "Patient/123" or "http://server/Patient/123" -> "123")
        string:RegExp slash = re `/`;
        string[] refParts = slash.split(consentPatientRef);
        // use last segment to support both relative ("Patient/id") and absolute URLs
        if refParts.length() >= 1 {
            string consentPatientId = refParts[refParts.length() - 1];
            // Compare with the input MemberPatient id
            if consentPatientId == inputPatientId {
                result.memberIdentity = inputPatientId;
                log:printDebug("Member identity validation successful: " + consentPatientId);
            } else {
                log:printError("Member identity mismatch. Consent patient: " + consentPatientId + ", Input patient: " + inputPatientId);
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
    // Per HRex Consent profile (STU1.1), payer roles are expressed via provision.actor slices
    // (Must Support, cardinality 2..*). Consent.organization is NOT part of HRex Consent.
    //   - role code "performer" → requesting/source payer (authorized to disclose)
    //   - role code "IRCP"      → receiving payer (authorized to receive data)
    // Ref: https://hl7.org/fhir/us/davinci-hrex/STU1.1/StructureDefinition-hrex-consent.html
    international401:ConsentProvisionActor[]? actors = consent.provision?.actor;
    if actors is international401:ConsentProvisionActor[] && actors.length() >= 2 {
        boolean hasPerformer = false;
        boolean hasRecipient = false;
        string requestingPayerRef = "";
        foreach international401:ConsentProvisionActor actor in actors {
            r4:Coding[]? codings = actor.role.coding;
            if codings is r4:Coding[] {
                foreach r4:Coding coding in codings {
                    if coding.code == "performer" {
                        hasPerformer = true;
                        requestingPayerRef = actor.reference.reference ?: "";
                    } else if coding.code == "IRCP" {
                        hasRecipient = true;
                    }
                }
            }
        }
        if hasPerformer && hasRecipient {
            result.requestingPayer = requestingPayerRef;
            log:printDebug("Payer identity validation successful — source: " + requestingPayerRef);
        } else {
            log:printError("Missing required provision.actor role(s). performer=" + hasPerformer.toString() + " IRCP=" + hasRecipient.toString());
            result.reason = CONSENT_INVALID_PAYER;
            return result;
        }
    } else {
        log:printError("provision.actor missing or has fewer than 2 entries");
        result.reason = CONSENT_INVALID_PAYER;
        return result;
    }

    // Provision rules validation — HRex Consent fixed values (Must Support)
    // provision.type must be "permit" and provision.action must include "disclose"
    // Ref: https://hl7.org/fhir/us/davinci-hrex/STU1.1/StructureDefinition-hrex-consent.html
    if consent.provision?.'type != international401:CODE_TYPE_PERMIT {
        log:printError("Consent provision type is not 'permit'. Got: " + (consent.provision?.'type ?: "missing").toString());
        result.reason = CONSENT_PROVISION_TYPE_INVALID;
        return result;
    }
    r4:CodeableConcept[]? actions = consent.provision?.action;
    boolean hasDisclose = actions is r4:CodeableConcept[] &&
        actions.some(a => (a.coding is r4:Coding[]) &&
            (<r4:Coding[]>a.coding).some(c => c.code == "disclose"));
    if !hasDisclose {
        log:printError("Consent provision does not include a 'disclose' action");
        result.reason = CONSENT_PROVISION_ACTION_INVALID;
        return result;
    }

    // Step 3: Date Validity Validation
    // Check if the current date falls within the Consent.provision.period
    if consent.provision?.period is r4:Period {
        r4:Period period = <r4:Period>consent.provision?.period;
        result.consentStartDate = period.'start;
        result.consentEndDate = period.end;

        // Use proper UTC timestamp comparison instead of string lexicographic comparison.
        // Normalize date-only values (FHIR dateTime may omit the time component).
        if period.end is r4:dateTime {
            string endStr = <string>period.end;
            string endNormalized = endStr.includes("T") ? endStr : endStr + "T23:59:59Z";
            time:Utc|error endUtc = time:utcFromString(endNormalized);
            if endUtc is error || endUtc < time:utcNow() {
                log:printError("Consent has expired. End date: " + endStr);
                result.reason = CONSENT_EXPIRED;
                return result;
            }
        }

        // Also verify consent has already started
        if period.'start is r4:dateTime {
            string startStr = <string>period.'start;
            string startNormalized = startStr.includes("T") ? startStr : startStr + "T00:00:00Z";
            time:Utc|error startUtc = time:utcFromString(startNormalized);
            if startUtc is time:Utc && startUtc > time:utcNow() {
                log:printError("Consent not yet in effect. Start date: " + startStr);
                result.reason = CONSENT_NOT_YET_EFFECTIVE;
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
    // Check both consent.policy[].uri and consent.policyRule.coding[] (HRex uses policyRule)
    if consent.policy is international401:ConsentPolicy[] {
        result.consentPolicy = extractConsentPolicy(<international401:ConsentPolicy[]>consent.policy);
    }
    // Also check policyRule as a fallback (HRex consent uses policyRule with hrex-temp codes)
    if result.consentPolicy is () && consent.policyRule is r4:CodeableConcept {
        r4:CodeableConcept pRule = <r4:CodeableConcept>consent.policyRule;
        if pRule.coding is r4:Coding[] {
            foreach r4:Coding coding in <r4:Coding[]>pRule.coding {
                if coding.code is string {
                    string code = <string>coding.code;
                    if code == "regular" || code == "sensitive" {
                        result.consentPolicy = code;
                        break;
                    }
                }
            }
        }
    }

    if result.consentPolicy is string {
        string policy = <string>result.consentPolicy;
        // Accept both full HRex policy URIs and short hrex-temp CodeSystem codes
        if policy == "http://hl7.org/fhir/us/davinci-hrex/StructureDefinition-hrex-consent.html#regular" ||
            policy == "http://hl7.org/fhir/us/davinci-hrex/StructureDefinition-hrex-consent.html#sensitive" ||
            policy == "regular" || policy == "sensitive" {
            log:printDebug("Policy compliance validation successful. Policy: " + policy);
        } else {
            log:printError("Requested policy not supported: " + policy);
            result.reason = CONSENT_POLICY_NOT_SUPPORTED;
            return result;
        }
    } else {
        log:printError("Consent policy not found in policy[] or policyRule");
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

 
isolated function updateCommunicationRequestAndClaim(international401:Parameters parameters,
    davincipas:PASClaimSupportingInfo[] supportingInfo, r4:FHIRContext fhirContext) returns r4:OperationOutcome|error {

    international401:ParametersParameter[]? 'parameter = 'parameters.'parameter;
    string commReqId = "";
    if 'parameter is international401:ParametersParameter[] {
        foreach var item in 'parameter {
            if item.name == "TrackingId" && item.valueString is string {
                commReqId = item.valueString ?: "";
                break;
            }
        }
    }
    if commReqId == "" {
        log:printError("TrackingId parameter is missing");
        fhirContext.setResponseStatusCode(400);
        return createOpereationOutcome(r4:CODE_SEVERITY_ERROR, r4:ERROR, "TrackingId parameter is missing");
    }

    r4:DomainResource communicationRequestJson = check getById(fhirConnector, COMMUNICATION_REQUEST, commReqId);
    davincipas:PASCommunicationRequest communicationRequest = check communicationRequestJson.cloneWithType();

    if communicationRequest.status == "completed" {
        log:printError(string `CommunicationRequest ${commReqId} is already completed`);
        fhirContext.setResponseStatusCode(400);
        return createOpereationOutcome(r4:CODE_SEVERITY_ERROR, r4:ERROR, 
            string `CommunicationRequest ${commReqId} is already completed`);
    }

    // get claim id
    string claimId = "";
    r4:Reference[]? about = communicationRequest.about;
    if about is r4:Reference[] && about.length() > 0 {
        string? calimRef = about[0].reference;
        if calimRef is string {
            string:RegExp slash = re `/`;
            string[] refParts = slash.split(calimRef);
            if refParts.length() == 2 {
                claimId = refParts[1];
            }
        }
    }
    if claimId == "" {
        log:printError("Failed to find linked claim reference in CommunicationRequest");
        fhirContext.setResponseStatusCode(400);
        return createOpereationOutcome(r4:CODE_SEVERITY_ERROR, r4:ERROR, 
            "Failed to find linked claim reference in CommunicationRequest");
    }


    r4:DomainResource claimResource = check getById(fhirConnector, CLAIM, claimId);
    davincipas:PASClaim claim = check claimResource.cloneWithType();

    davincipas:PASClaimSupportingInfo[] existingSupportingInfo = claim.supportingInfo ?: [];
    // get last supporting info sequence number and increment for new supporting info.
    // sort supporting info by sequence number and then add new supporting info to the end of the list.
    int maxSequence = 0;
    foreach davincipas:PASClaimSupportingInfo info in existingSupportingInfo {
        if info.sequence is int {
            if info.sequence > maxSequence {
                maxSequence = info.sequence;
            }
        }
    }
    foreach davincipas:PASClaimSupportingInfo info in supportingInfo {
        maxSequence += 1;
        info.sequence = maxSequence;
        existingSupportingInfo.push(info);
    }
    claim.supportingInfo = existingSupportingInfo;

    _ = check update(fhirConnector, CLAIM, claimId, claim.toJson());
    log:printDebug(string `Claim ${claimId} updated successfully`);

    communicationRequest.status = "completed";
    r4:DomainResource|r4:FHIRError updatedComReqJson =
        check update(fhirConnector, COMMUNICATION_REQUEST, commReqId, communicationRequest.toJson());
    if updatedComReqJson is r4:FHIRError {
        log:printError("Failed to update CommunicationRequest: " + updatedComReqJson.message());
        fhirContext.setResponseStatusCode(500);
        return createOpereationOutcome(r4:CODE_SEVERITY_ERROR, r4:ERROR, 
            "Failed to update CommunicationRequest");
    }
    log:printDebug(string `CommunicationRequest ${commReqId} updated to completed status successfully`);

    // Check if all CommunicationRequests linked to this claim's ClaimResponse are now completed.
    // If so, move the PA request back to PENDING_ON_PAYER.
    r4:Bundle|r4:FHIRError crSearchResult = search(fhirConnector, CLAIM_RESPONSE, {"request": ["Claim/" + claimId]});
    if crSearchResult is r4:Bundle {
        r4:BundleEntry[]? crEntries = crSearchResult.entry;
        if crEntries is r4:BundleEntry[] && crEntries.length() > 0 {
            international401:ClaimResponse|error claimResponse = (crEntries[0]?.'resource).cloneWithType(international401:ClaimResponse);
            if claimResponse is international401:ClaimResponse && claimResponse.communicationRequest is r4:Reference[] {
                r4:Reference[] allCommRefs = <r4:Reference[]>claimResponse.communicationRequest;
                boolean allCompleted = true;
                foreach r4:Reference commRef in allCommRefs {
                    string? refStr = commRef.reference;
                    if refStr is string {
                        string? otherCrId = extractRefId(refStr);
                        if otherCrId is string && otherCrId != commReqId {
                            // Fetch the other CommunicationRequest and check its status
                            r4:DomainResource|r4:FHIRError otherCrRes = getById(fhirConnector, COMMUNICATION_REQUEST, otherCrId);
                            if otherCrRes is r4:DomainResource {
                                json otherCrJson = otherCrRes.toJson();
                                json|error statusJson = otherCrJson.status;
                                if !(statusJson is string && statusJson == "completed") {
                                    allCompleted = false;
                                    break;
                                }
                            } else {
                                allCompleted = false;
                                break;
                            }
                        }
                        // commReqId was just set to "completed" above, so it counts as completed
                    }
                }
                if allCompleted {
                    sql:ParameterizedQuery updateStatusQuery = `UPDATE pa_requests SET status = 'PENDING_ON_PAYER' WHERE request_id = ${claimId}`;
                    sql:ExecutionResult|sql:Error dbResult = dbClient->execute(updateStatusQuery);
                    if dbResult is sql:Error {
                        log:printError("Failed to update PA request status in database: " + dbResult.message());
                    } else {
                        log:printDebug("All CommunicationRequests completed; PA request status set to PENDING_ON_PAYER for request_id: " + claimId);
                    }
                }
            }
        }
    } else {
        log:printWarn("Could not find ClaimResponse for claim " + claimId + "; skipping pa_requests status update");
    }

    r4:OperationOutcome outcome = {
        resourceType: "OperationOutcome",
        issue: [
            {
                severity: r4:CODE_SEVERITY_INFORMATION,
                code: r4:INFORMATIONAL,
                diagnostics: "Submit attachment successful. CommunicationRequest status updated to " +
                    " completed."
            }
        ]
    };
    fhirContext.setResponseStatusCode(200);
    return outcome;
}

# Validates that the Prefer header is present and contains the required value.
# Returns () when valid, or a 400 FHIRError when the header is absent or the value does not match.
#
# + httpReq       - the raw HTTP request from FHIRContext; may be nil
# + requiredValue - the configured required token ("respond-async" | "respond-sync")
# + return        - () if valid, r4:FHIRError otherwise
isolated function validatePreferHeader(r4:HTTPRequest? httpReq, string requiredValue)
        returns r4:FHIRError? {

    string[]? preferValues = ();
    if httpReq !is () {
        preferValues = httpReq.headers["prefer"] ?: httpReq.headers["Prefer"];
    }
    if preferValues is () {
        return r4:createFHIRError(
                BULK_MATCH_MISSING_PREFER_HEADER,
                r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    // Parse comma-separated token list (e.g., "respond-async, handling=strict").
    foreach string pv in preferValues {
        foreach string token in re `,`.split(pv) {
            if token.trim().toLowerAscii() == requiredValue.toLowerAscii() {
                return ();
            }
        }
    }

    return r4:createFHIRError(
            "The 'Prefer' header value must be '" + requiredValue + "'",
            r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
}

# Determines the type of the claim. Whether the claim is a standard claim or an expedited claim.
# This function takes the related claim of the claim response and the claim response and checks
# the claim.priority field. If the priority is "stat", then it is an expedited claim, otherwise it is a standard claim.
# 
# + claimResponse - The claim response resource to determine the type of
# + claim - The claim of the claim response
# 
# + return - The type of the claim. "standard" for standard claims and "expedited" for expedited claims.
isolated function determineClaimType(ClaimResponse claimResponse, international401:Claim claim) returns int {

    if claim.priority?.coding is r4:Coding[] {
        foreach r4:Coding coding in <r4:Coding[]>claim.priority?.coding {
            if coding.code is string && coding.code == STAT {
                log:printDebug(string `Claim type is: Expedited`);
                return EXPEDITED;
            }
        }
    }
    log:printDebug(string `Claim type is: Standard`);
    return STANDARD;
}

# Determines the status of the claim based on the claim response outcome and the item approvals.
# Assumes that if the outcome is "complete", then the claim has finished processing and payer made the final decision. 
# It will not be processed further. Only "completed" claims are considered.
# 
# The following strings are returned when the "outcome" is "complete",
# 1. "approved" if all items are approved.
# 2. "denied" if all items are denied. 
# 3. "partially-approved" if a subset of items are approved. 
# 
# NOTE: If there are no items present in a completed claim, 
# * If a "preAuthRef" is present in claim response, it is assumed that the claim is approved without needing to review items.
# * If a "preAuthRef" is not present, it is assumed that the claim is rejected.
# 
# The approval/denial is decided based on the reviewActionCode of each item adjudication.
# https://hl7.org/fhir/us/davinci-pas/STU2/StructureDefinition-extension-reviewAction.html
# 
# + claimResponse - The claim response resource to determine the status of
# 
# + return - returns 3 if approved, 5 if denied, 4 if partially approved. This should be fixed after the issue
# https://github.com/wso2-enterprise/moesif-internal/issues/7
isolated function determineClaimStatus(ClaimResponse claimResponse) returns int {
 
    log:printDebug(string `Outcome of the claim response is: ${claimResponse.outcome}`);

    int numberOfItems = 0;
    int numberOfApprovedAdjudications = 0;

    davincipas:PASClaimResponseItem[]? items = claimResponse.item;

    if items is davincipas:PASClaimResponseItem[] {
            
        numberOfItems = items.length();
        log:printDebug(string `Claim response has ${numberOfItems} items.`);

        if numberOfItems == 0 {

            // When a completed claim doesn't have items, if a "preAuthRef" is present, this can mean the whole 
            // request is approved and no item review was required.
            if claimResponse.preAuthRef is string {
                log:printDebug(string `Number of items: ${numberOfItems}`);
                log:printDebug(string `Number of approved adjudications: ${numberOfApprovedAdjudications}`);
                log:printDebug(string `Aggregated status: Approved`);
                return APPROVED;
            }
            // When there are no items present in a "completed" claim, this can mean the request is rejected.
            log:printDebug(string `Number of items: ${numberOfItems}`);
            log:printDebug(string `Number of approved adjudications: ${numberOfApprovedAdjudications}`);
            log:printDebug(string `Aggregated status: Denied`);
            return DENIED;
        }

        foreach davincipas:PASClaimResponseItem item in items {
            davincipas:PASClaimResponseAdjudication[]? adjudications = item.adjudication;
            
            if adjudications is davincipas:PASClaimResponseAdjudication[] {
                foreach davincipas:PASClaimResponseAdjudication adjudication in adjudications {
                
                    r4:Extension[]? adjudicationExtensions = adjudication.extension;
                    if adjudicationExtensions is r4:Extension[] {
                        
                        foreach r4:Extension adjudicationExtension in adjudicationExtensions {
                            if adjudicationExtension.url == REVIEW_ACTION_URL {
                                
                                r4:Extension[]? reviewActionExtensions = adjudicationExtension.extension;
                                if reviewActionExtensions is r4:Extension[] {
                                    
                                    foreach r4:Extension reviewActionExtension in reviewActionExtensions {
                                        if reviewActionExtension.url == REVIEW_ACTION_CODE_URL {
                                            
                                            r4:CodeableConceptExtension|error reviewActionCodeableConceptExtension = reviewActionExtension.cloneWithType();
                                            if reviewActionCodeableConceptExtension is r4:CodeableConceptExtension {
                                                r4:CodeableConcept reviewActionCodeableConcept = reviewActionCodeableConceptExtension.valueCodeableConcept;
                                                r4:Coding[]? reviewActionCodings = reviewActionCodeableConcept.coding;
                                                
                                                if reviewActionCodings is r4:Coding[] {
                                                    foreach r4:Coding reviewActionCoding in reviewActionCodings {
                                                        r4:code? code = reviewActionCoding.code;
                                                        if code is string && code == A1 {
                                                                numberOfApprovedAdjudications += 1;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        log:printDebug(string `Number of items: ${numberOfItems}`);
        log:printDebug(string `Number of approved adjudications: ${numberOfApprovedAdjudications}`);
        if numberOfItems == numberOfApprovedAdjudications {
            log:printDebug(string `Aggregated status: Approved`);
            return APPROVED;
        }
        if numberOfApprovedAdjudications == 0 {
            log:printDebug(string `Aggregated status: Denied`);
            return DENIED;
        }
        if numberOfItems > numberOfApprovedAdjudications {
            log:printDebug(string `Aggregated status: Partially Approved`);
            return PARTIALLY_APPROVED;
        }
    }
    // When a completed claim doesn't have items, if a "preAuthRef" is present, this can mean the whole 
    // request is approved and no item review was required.
    if claimResponse.preAuthRef is string {
        log:printDebug(string `Number of items: ${numberOfItems}`);
        log:printDebug(string `Number of approved adjudications: ${numberOfApprovedAdjudications}`);
        log:printDebug(string `Aggregated status: Approved`);
        return APPROVED;
    }
    log:printDebug(string `Number of items: ${numberOfItems}`);
    log:printDebug(string `Number of approved adjudications: ${numberOfApprovedAdjudications}`);
    // When there are no items present in a "completed" claim, this can mean the request is rejected.
    log:printDebug(string `Aggregated status: Denied`);
    return DENIED;
}

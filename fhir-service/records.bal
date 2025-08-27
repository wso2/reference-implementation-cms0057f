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

import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;

public enum ResourceType {
    ALLERGY_INTOLERENCE = "AllergyIntolerance",
    CARE_PLAN = "CarePlan",
    CLAIM = "Claim",
    CLAIM_RESPONSE = "ClaimResponse",
    CONDITION = "Condition",
    COVERAGE = "Coverage",
    DEVICE = "Device",
    DIAGNOSTIC_REPORT = "DiagnosticReport",
    DOCUMENT_REFERENCE = "DocumentReference",
    ENCOUNTER = "Encounter",
    GOAL = "Goal",
    IMMUNIZATION = "Immunization",
    MEDICATION_REQUEST = "MedicationRequest",
    OBSERVATION = "Observation",
    ORGANIZATION = "Organization",
    PATIENT = "Patient",
    PRACTITIONER = "Practitioner",
    PROCEDURE = "Procedure",
    QUESTIONNAIRE = "Questionnaire",
    QUESTIONNAIRE_PACKAGE = "QuestionnairePackage",
    QUESTIONNAIRE_RESPONSE = "QuestionnaireResponse",
    EXPLANATION_OF_BENEFIT = "ExplanationOfBenefit"
}

# Holds information for OAuth2 authentication.
#
# + tokenUrl - Token URL of the token endpoint
# + clientId - Client ID of the client authentication
# + clientSecret - Client secret of the client authentication
type AuthConfig record {|
    string tokenUrl;
    string clientId;
    string clientSecret;
|};

# Holds member match parameter information.
#
# + profile - The parameter profile 
# + typeDesc - The Ballerina type descriptor for the parameter
type ParameterInfo record {|
    readonly string profile;
    readonly typedesc<anydata> typeDesc;
|};

// ######################################################################################################################
// # Model Configs                                                                                                      #
// ######################################################################################################################

# Configs for server
#
# + url - Canonical identifier for this capability statement, represented as a URI (globally unique)
# + 'version - Business version of the capability statement
# + name - Name for this capability statement (computer friendly)  
# + title - Name for this capability statement (human friendly)
# + status - Code: draft | active | retired | unknown
# + experimental - For testing purposes, not real usage
# + date - Date last changed
# + kind - Code: instance | capability | requirements
# + implementationUrl - Base URL for the installation
# + implementationDescription - Describes this specific instance
# + fhirVersion - FHIR Version the system supports
# + format - formats supported (xml | json | ttl | mime type)
# + patchFormat - Patch formats supported
public type ConfigFHIRServer record {|
    string url?;
    string 'version?;
    string name?;
    string title?;
    international401:CapabilityStatementStatus status;
    boolean experimental?;
    string date?;
    international401:CapabilityStatementKind kind;
    string implementationUrl?;
    string implementationDescription;
    string fhirVersion;
    international401:CapabilityStatementFormat[] format;
    string[] patchFormat?;
|};

# If the endpoint is a RESTful one
# Rule: A given resource can only be described once per RESTful mode.
#
# + mode - Code: client | server  
# + documentation - General description of implementation  
# + security - Information about security of implementation  
# + resourceFilePath - Path to the file containing resources
# + interaction - Operations supported  
# + searchParam - Search parameters for searching all resources
public type ConfigRest record {|
    string? mode = REST_MODE_SERVER;
    string documentation?;
    ConfigSecurity security?;
    string resourceFilePath?;
    string[] interaction?;
    string[] searchParam?;
|};

# Configs for server security
#
# + cors - Enable cors or not  
# + discoveryEndpoint - Discovery endpoint for the FHIR server  
# + tokenEndpoint - Token endpoint for the FHIR server  
# + revocationEndpoint - Revoke endpoint for the FHIR server  
# + authorizeEndpoint - Authorization endpoint for the FHIR server  
# + introspectEndpoint - Introspect endpoint for the FHIR server  
# + managementEndpoint - Manage endpoint for the FHIR server  
# + registrationEndpoint - Register endpoint for the FHIR server
public type ConfigSecurity record {
    boolean cors?;
    string discoveryEndpoint?;
    string tokenEndpoint?;
    string revocationEndpoint?;
    string authorizeEndpoint?;
    string introspectEndpoint?;
    string managementEndpoint?;
    string registrationEndpoint?;
};

# Configs for resource.
#
# + 'type - A resource type that is supported
# + versioning - no-version | versioned | versioned-update
# + conditionalCreate - If allows/uses conditional create
# + conditionalRead - not-supported | modified-since | not-match | full-support
# + conditionalUpdate - If allows/uses conditional update
# + conditionalDelete - not-supported | single | multiple - how conditional delete is supported
# + referencePolicy - literal | logical | resolves | enforced | local
# + searchInclude - _include values supported by the server
# + searchRevInclude - _revinclude values supported by the server
# + supportedProfile - Use-case specific profiles
# + interaction - Operations supported
# + searchParamNumber - Numeric search parameters supported by implementation
# + searchParamDate - Date search parameters supported by implementation
# + searchParamString - String search parameters supported by implementation
# + searchParamToken - Token search parameters supported by implementation
# + searchParamReference - Reference search parameters supported by implementation
# + searchParamComposite - Composite search parameters supported by implementation
# + searchParamQuantity - Quantity search parameters supported by implementation
# + searchParamURI - URI search parameters supported by implementation
# + searchParamSpecial - Special search parameters supported by implementation
public type ConfigResource record {
    string 'type;
    string versioning?;
    boolean conditionalCreate?;
    string conditionalRead?;
    boolean conditionalUpdate?;
    string conditionalDelete?;
    string[] referencePolicy?;
    string[] searchInclude?;
    string[] searchRevInclude?;
    string[] supportedProfile?;
    string[] interaction?;
    string[] searchParamNumber?;
    string[] searchParamDate?;
    string[] searchParamString?;
    string[] searchParamToken?;
    string[] searchParamReference?;
    string[] searchParamComposite?;
    string[] searchParamQuantity?;
    string[] searchParamURI?;
    string[] searchParamSpecial?;
};

# Smart configuration record
#
# + discoveryEndpoint - Smart configuration discoveryEndpoint
# + smartConfiguration - Smart configuration
public type Configs record {|
    string discoveryEndpoint?;
    ConfigSmartConfiguration smartConfiguration?;
|};

# Smart configuration record
#
# + issuer - Smart configuration issuer  
# + jwksUri - Smart configuration jwks_uri  
# + authorizationEndpoint - Smart configuration authorization_endpoint  
# + grantTypesSupported - Smart configuration grant_type_supported  
# + tokenEndpoint - Smart configuration token_endpoint  
# + tokenEndpointAuthMethodsSupported - Smart configuration token_endpoint_auth_methods_supported  
# + tokenEndpointAuthSigningAlgValuesSupported - Smart configuration token endpoint auth signing alg values supported
# + registrationEndpoint - Smart configuration registration_endpoint  
# + scopesSupported - Smart configuration scopes_supported  
# + responseTypesSupported - Smart configuration response_type_supported  
# + managementEndpoint - Smart configuration management_endpoint  
# + introspectionEndpoint - Smart configuration introspection_endpoint  
# + revocationEndpoint - Smart configuration revocation_endpoint  
# + capabilities - Smart configuration capabilities  
# + codeChallengeMethodsSupported - Smart configuration code_challenge_methods_supported
public type ConfigSmartConfiguration record {|
    string issuer?;
    string jwksUri?;
    string authorizationEndpoint?;
    string[] grantTypesSupported?;
    string tokenEndpoint?;
    string[] tokenEndpointAuthMethodsSupported?;
    string[] tokenEndpointAuthSigningAlgValuesSupported?;
    string registrationEndpoint?;
    string[] scopesSupported?;
    string[] responseTypesSupported?;
    string managementEndpoint?;
    string introspectionEndpoint?;
    string revocationEndpoint?;
    string[] capabilities;
    string[] codeChallengeMethodsSupported?;
|};

// ######################################################################################################################
// # OpenID configuration.                                                                                              #
// ######################################################################################################################

# OpenID configuration.
#
# + token_endpoint - token endpoint
# + authorization_endpoint - authorization endpoint
# + revocation_endpoint - revocation endpoint  
# + introspection_endpoint - introspection endpoint  
# + registration_endpoint - registration endpoint
# + management_endpoint - management endpoint
# + issuer - issuer  
# + device_authorization_endpoint - device authorization endpoint  
# + userinfo_endpoint - userinfo endpoint
# + jwks_uri - jwks uri
# + grant_types_supported - grant types supported
# + response_types_supported - response types supported
# + subject_types_supported - subject types supported
# + id_token_signing_alg_values_supported - id token signing alg values supported
# + scopes_supported - scopes supported
# + token_endpoint_auth_methods_supported - token endpoint auth methods supported
# + claims_supported - claims supported
# + code_challenge_methods_supported - code challenge methods supported

public type OpenIDConfiguration record {
    string token_endpoint?;
    string authorization_endpoint?;
    string revocation_endpoint?;
    string introspection_endpoint?;
    string registration_endpoint?;
    string management_endpoint?;
    string issuer?;
    string device_authorization_endpoint?;
    string userinfo_endpoint?;
    string jwks_uri?;
    string[] grant_types_supported?;
    string[] response_types_supported?;
    string[] subject_types_supported?;
    string[] id_token_signing_alg_values_supported?;
    string[] scopes_supported?;
    string[] token_endpoint_auth_methods_supported?;
    string[] claims_supported?;
    string[] code_challenge_methods_supported?;
};

# Smart configuration record
#
# + issuer - Smart configuration issuer  
# + jwks_uri - Smart configuration jwks_uri  
# + authorization_endpoint - Smart configuration authorization_endpoint  
# + grant_types_supported - Smart configuration grant_type_supported  
# + token_endpoint - Smart configuration token_endpoint  
# + token_endpoint_auth_methods_supported - Smart configuration token_endpoint_auth_methods_supported  
# + token_endpoint_auth_signing_alg_values_supported - Smart configuration token endpoint auth signing alg values supported
# + registration_endpoint - Smart configuration registration_endpoint  
# + scopes_supported - Smart configuration scopes_supported  
# + response_types_supported - Smart configuration response_type_supported  
# + management_endpoint - Smart configuration management_endpoint  
# + introspection_endpoint - Smart configuration introspection_endpoint  
# + revocation_endpoint - Smart configuration revocation_endpoint  
# + capabilities - Smart configuration capabilities  
# + code_challenge_methods_supported - Smart configuration code_challenge_methods_supported
public type SmartConfiguration record {|
    string issuer?;
    string jwks_uri?;
    string authorization_endpoint;
    string[] grant_types_supported;
    string token_endpoint;
    string[] token_endpoint_auth_methods_supported?;
    string[] token_endpoint_auth_signing_alg_values_supported?;
    string registration_endpoint?;
    string[] scopes_supported?;
    string[] response_types_supported?;
    string management_endpoint?;
    string introspection_endpoint?;
    string revocation_endpoint?;
    string[] capabilities;
    string[] code_challenge_methods_supported;
|};

# Record for consent evaluation result
#
# + isValid - Indicates if the consent is valid
# + patientId - The ID of the patient associated with the consent
# + reason - The reason for the consent evaluation result
# + memberIdentity - The identity of the member associated with the consent
# + consentPolicy - The policy under which the consent was obtained
# + consentStartDate - The start date of the consent period
# + consentEndDate - The end date of the consent period
# + requestingPayer - The identity of the requesting payer
public type ConsentEvaluationResult record {|
    boolean isValid;
    string? patientId;
    string? reason;
    string? memberIdentity;
    string? consentPolicy;
    r4:dateTime? consentStartDate;
    r4:dateTime? consentEndDate;
    string? requestingPayer;
|};

// Supporting type definitions for the response
type ConsentEvaluationResponse record {
    int statusCode;
    boolean success;
    international401:Parameters? parameters = ();
    r4:OperationOutcome? operationOutcome = ();
};

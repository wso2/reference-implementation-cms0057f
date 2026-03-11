// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/jwt;
import ballerina/log;

// OAuth Client Authentication Exception
type OAuthClientAuthnException record {|
    string message;
    string errorCode?;
|};

type ClientAssertionValidationResponse record {|
    boolean isValid;
    string clientId?;
    string clientSecret?;
|};

type AsgAppResponse record {
    Application[] applications;
};

type Application record {
    string id;
    string clientId;
    AdvancedConfigurations advancedConfigurations;
};

type AdvancedConfigurations record {
    json[] additionalSpProperties;
};

type OIDCInboundProtocolConfig record {
    string clientId;
    string clientSecret;
};

// JWT validation function - Ballerina equivalent of the Java isValidAssertion method
isolated function isValidAssertion(string? jwtString) returns ClientAssertionValidationResponse|OAuthClientAuthnException {
    
    if jwtString is () {
        string errorMessage = "No valid JWT assertion found for JWT Bearer Grant Type";
        return logAndThrowException(errorMessage, ());
    }

    do {
        [jwt:Header, jwt:Payload] [_, payload] = check jwt:decode(jwtString);
        string jwtSubject = resolveSubject(payload) ?: "";

        // get jwks uri from asgardeo
        AsgAppResponse|http:ClientError appData = 
            asgAdminClient->get(string `api/server/v1/applications?filter=clientId+co+${jwtSubject}=&attributes=advancedConfigurations`);
        if appData is http:ClientError {
            string errorMessage = "Error while retrieving application details for clientId: " + jwtSubject;
            return logAndThrowException(errorMessage, ());
        }
        string appId = appData.applications[0].id;
        string jwksUri = "";
        json[] additionalSpProperties = appData.applications[0].advancedConfigurations.additionalSpProperties;
        foreach json item in additionalSpProperties {
            if (check item.name).toString() == "jwksURI" {
                jwksUri = (check item.value).toString();
                break;
            }
        }

        jwt:ValidatorConfig validatorConfig = {
            issuer: jwtSubject,
            audience: audience,
            clockSkew: 60,
            signatureConfig: {
                jwksConfig: {
                    url: jwksUri
                }
            }
        };

        // Validates the created JWT and extracts clientId clientSecret.
        jwt:Payload validatedPayload = check jwt:validate(jwtString, validatorConfig);
        log:printDebug("JWT is valid. Payload: " + validatedPayload.toJsonString());
        string clientId = validatedPayload.hasKey("sub") ? validatedPayload.get("sub").toString() : "";

        OIDCInboundProtocolConfig|http:ClientError oidcProtocols = 
            asgAdminClient->get(string `api/server/v1/applications/${appId}/inbound-protocols/oidc`);
        if oidcProtocols is http:ClientError {
            string errorMessage = "Error while retrieving OIDC protocol details for clientId: " + jwtSubject;
            return logAndThrowException(errorMessage, ());
        }

        string clientSecret = oidcProtocols.clientSecret;
        log:printDebug("JWT assertion validated successfully for clientId: " + clientId);
        return {isValid: true, clientId: clientId, clientSecret: clientSecret};
    } on fail error e {
        string errorMessage = "JWT validation failed: " + e.message();
        return logAndThrowException(errorMessage, "invalid_client");
    }
}

isolated function resolveSubject(jwt:Payload payload) returns string? {
    return payload.hasKey("sub") ? payload.get("sub").toString() : ();
}

isolated function logAndThrowException(string message, string? errorCode) returns OAuthClientAuthnException {
    log:printError(message);
    return {
        message: message,
        errorCode: errorCode ?: "server_error"
    };
}

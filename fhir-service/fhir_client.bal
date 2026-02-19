// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).

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
import ballerinax/health.clients.fhir as fhirClient;

# FHIR configuration parameters (read from Config.toml)
configurable string baseUrl = ?;
configurable string? tokenUrl = ();
configurable string? clientId = ();
configurable string? clientSecret = ();
configurable string[]? scopes = ();

# Get FHIR Connector configuration for Azure Health Data Services
#
# + return - FHIR Connector configuration
public isolated function getFhirConnectorConfig() returns fhirClient:FHIRConnectorConfig {

    fhirClient:FHIRConnectorConfig fhirConfig = {
        baseURL: baseUrl,
        mimeType: fhirClient:FHIR_JSON
    };

    string? tokenUrlVal = tokenUrl;
    string? clientIdVal = clientId;
    string? clientSecretVal = clientSecret;
    string[]? scopesVal = scopes;

    if tokenUrlVal is string && clientIdVal is string && clientSecretVal is string {
        http:OAuth2ClientCredentialsGrantConfig authConfig = {
            tokenUrl: tokenUrlVal,
            clientId: clientIdVal,
            clientSecret: clientSecretVal,
            scopes: scopesVal ?: [],
            optionalParams: {
                "resource": baseUrl
            }
        };
        fhirConfig.authConfig = authConfig;
    }
    return fhirConfig;
}

# Initialize the FHIR Connector
#
# + return - FHIR Connector instance or error
public function initFhirConnector() returns fhirClient:FHIRConnector|error {
    fhirClient:FHIRConnectorConfig config = getFhirConnectorConfig();
    return new fhirClient:FHIRConnector(config, enableCapabilityStatementValidation = false);
}

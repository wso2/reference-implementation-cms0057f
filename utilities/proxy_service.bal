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
import ballerina/lang.array;
import ballerina/log;

final http:Client fhirClient = check new (fhirServerUrl);
final http:Client asgAdminClient = check new (asgServerUrl,
    auth = {
        tokenUrl: tokenEp,
        clientId: adminAppClientId,
        clientSecret: adminAppClientSecret,
        scopes: "internal_application_mgt_view"
    }
);
final http:Client asgClient = check new (asgServerUrl);

service / on new http:Listener(proxyServerPort) {

    isolated resource function get [string... path](http:Request httpRequest) returns http:Response|error {
        if path[path.length() -1] == "authorize" {
            // Redirect to ASG authorize endpoint
            // Extract raw query string to preserve encoding (e.g., + signs in timestamps)
            string rawPath = httpRequest.rawPath;
            string queryString = "";
            int? queryIndex = rawPath.indexOf("?");
            if queryIndex is int && queryIndex >= 0 {
                queryString = rawPath.substring(queryIndex + 1);
            }
            string fullPath = queryString != "" ? "oauth2/authorize?" + queryString : "oauth2/authorize";
            log:printDebug(string `Forwarding authorize GET request to ASG server. Path: ${fullPath}`);
            return asgClient->get(fullPath, {});
        }
        return handleRequest(httpRequest, path, "GET");
    }

    isolated resource function post [string... path](http:Request httpRequest) returns http:Response|error {
        if path[path.length() - 1] == "token" {
            // Redirect to ASG token endpoint
            // Get the raw form payload to preserve Content-Type
            string payload = check httpRequest.getTextPayload();
            map<string> formParams = check httpRequest.getFormParams();
            map<string[]> headers = extractHeaders(httpRequest);

            string? grant_type = formParams.hasKey("grant_type") ? formParams["grant_type"] : "";

            // Handle pwt key jwt assertions. 
            if formParams.hasKey("client_assertion") {
                string? client_assertion_type = formParams["client_assertion_type"];
                if client_assertion_type is () || client_assertion_type != 
                    "urn:ietf:params:oauth:client-assertion-type:jwt-bearer" {
                    log:printError("Invalid client_assertion_type for JWT Bearer Grant Type");
                    http:Response unauthorizedResponse = new;
                    unauthorizedResponse.statusCode = 400;
                    unauthorizedResponse.setJsonPayload({"error": "Bad request: Invalid client_assertion_type"});
                    return unauthorizedResponse;
                }
                string? jwt = formParams["client_assertion"];
                ClientAssertionValidationResponse|OAuthClientAuthnException client_assertion = isValidAssertion(jwt);
                if client_assertion is OAuthClientAuthnException || !client_assertion.isValid {
                    log:printError("Invalid JWT Assertion", errorMsg = client_assertion.toBalString());
                    http:Response unauthorizedResponse = new;
                    unauthorizedResponse.statusCode = 401;
                    unauthorizedResponse.setJsonPayload({"error": "Unauthorized: Invalid JWT Assertion"});
                    return unauthorizedResponse;
                }

                // Remove client_assertion from form params and rebuild payload
                _ = formParams.remove("client_assertion");
                _ = formParams.remove("client_assertion_type");
                
                // Rebuild the form-encoded payload without client_assertion
                string[] payloadParts = [];
                foreach [string, string] [key, value] in formParams.entries() {
                    payloadParts.push(key + "=" + value);
                }
                payload = string:'join("&", ...payloadParts);
                
                headers = addBasicAuthHeader({}, client_assertion.clientId ?: "", client_assertion.clientSecret ?: "");
            } else {
                // remove any unnecessary headers and forward only authorization header
                string[] authHeader = headers.hasKey("Authorization") ? headers.get("Authorization") : 
                    (headers.hasKey("authorization") ? headers.get("authorization") : []);
                
                string[] userAgent = headers.hasKey("User-Agent") ? headers.get("User-Agent") : 
                    (headers.hasKey("user-agent") ? headers.get("user-agent") : ["Mozilla/5.0 (Ballerina)"]);
                
                // Always include Content-Type for form data and User-Agent
                headers = {
                    "Content-Type": ["application/x-www-form-urlencoded"],
                    "User-Agent": userAgent
                };
                
                if authHeader.length() > 0 {
                    headers["Authorization"] = authHeader;
                }
            }
            http:Response|http:ClientError res = asgClient->post("oauth2/token", payload, headers);
            if res is http:Response && res.statusCode == 200 && grant_type == "authorization_code" {
                map<json> resPayload = check res.getJsonPayload().ensureType();
                if smart_style_url != "" {
                    resPayload["smart_style_url"] = smart_style_url;
                }
                resPayload["need_patient_banner"] = need_patient_banner;
                // id token fhiruser claim
                resPayload["patient"] = patient_id;
                res.setJsonPayload(resPayload);
            }
            return res;
        }
        return handleRequest(httpRequest, path, "POST");
    }

    isolated resource function patch [string... path](http:Request httpRequest) returns http:Response|error {
        return handleRequest(httpRequest, path, "PATCH");
    }

    isolated resource function put [string... path](http:Request httpRequest) returns http:Response|error {
        return handleRequest(httpRequest, path, "PUT");
    }

    isolated resource function delete [string... path](http:Request httpRequest) returns http:Response|error {
        return handleRequest(httpRequest, path, "DELETE");
    }
}

// Extract headers from HTTP request
isolated function extractHeaders(http:Request httpRequest) returns map<string[]> {
    map<string[]> headers = {};
    foreach string headerName in httpRequest.getHeaderNames() {
        string[]|http:HeaderNotFoundError headerResult = httpRequest.getHeaders(headerName);
        if headerResult is string[] {
            headers[headerName] = headerResult;
        }
    }
    return headers;
}

// Add basic auth header if credentials are configured
isolated function addBasicAuthHeader(map<string[]> headers, string basicAuthUsername, string basicAuthPassword)
    returns map<string[]> {
    if basicAuthUsername != "" && basicAuthPassword != "" {
        string credentials = basicAuthUsername + ":" + basicAuthPassword;
        string encodedCredentials = array:toBase64(credentials.toBytes());
        headers["Authorization"] = ["Basic " + encodedCredentials];
    }
    return headers;
}

// Create unauthorized response
isolated function createUnauthorizedResponse() returns http:Response {
    http:Response unauthorizedResponse = new;
    unauthorizedResponse.statusCode = 401;
    unauthorizedResponse.setJsonPayload({"error": "Unauthorized: Invalid organization"});
    return unauthorizedResponse;
}

// Common request handler to eliminate code duplication
isolated function handleRequest(http:Request httpRequest, string[] path, string method) returns http:Response|error {
    string reqPath = string:'join("/", ...path);

    // Extract headers
    map<string[]> headers = extractHeaders(httpRequest);

    // Extract raw query string to preserve encoding (e.g., + signs in timestamps)
    string rawPath = httpRequest.rawPath;
    string queryString = "";
    int? queryIndex = rawPath.indexOf("?");
    if queryIndex is int && queryIndex >= 0 {
        queryString = rawPath.substring(queryIndex + 1);
    }
    string fullPath = queryString != "" ? reqPath + "?" + queryString : reqPath;

    log:printDebug(string `Forwarding ${method} request to FHIR server. Path: ${fullPath}, Headers: ${headers.toString()}`);
    
    // Make the appropriate HTTP call based on method
    match method {
        "GET" => {
            return fhirClient->get(fullPath, headers);
        }
        "DELETE" => {
            return fhirClient->delete(fullPath, headers);
        }
        "POST"|"PATCH"|"PUT" => {

            // Extract payload based on content type
            string|json payload;
            string|http:HeaderNotFoundError contentTypeResult = httpRequest.getHeader("Content-Type");
            string contentType = contentTypeResult is string ? contentTypeResult : "";

            if contentType.toLowerAscii().includes("application/x-www-form-urlencoded") {
                payload = check httpRequest.getTextPayload();
            } else {
                payload = check httpRequest.getJsonPayload();
            }

            match method {
                "POST" => {
                    return fhirClient->post(fullPath, payload, headers);
                }
                "PATCH" => {
                    return fhirClient->patch(fullPath, payload, headers);
                }
                "PUT" => {
                    return fhirClient->put(fullPath, payload, headers);
                }
                _ => {
                    http:Response methodNotAllowedResponse = new;
                    methodNotAllowedResponse.statusCode = 405;
                    methodNotAllowedResponse.setJsonPayload({"error": "Method Not Allowed"});
                    return methodNotAllowedResponse;
                }
            }
        }
        _ => {
            http:Response methodNotAllowedResponse = new;
            methodNotAllowedResponse.statusCode = 405;
            methodNotAllowedResponse.setJsonPayload({"error": "Method Not Allowed"});
            return methodNotAllowedResponse;
        }
    }
}

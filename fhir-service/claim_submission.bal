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
import ballerina/io;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincipas;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.parser;

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

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

import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincipas;

# Extract NPIs from Claim resource
#
# + claim - Claim resource
# + return - Array of NPIs
public function extractNPIsFromClaim(Claim claim) returns string[] {
    string[] npis = [];

    // Extract provider NPI
    if claim.provider.identifier is Identifier {
        Identifier id = <Identifier>claim.provider.identifier;
        if id.value is string {
            npis.push(<string>id.value);
        }
    }

    // Extract careTeam NPIs
    // if claim.careTeam is ClaimCareTeam[] {
    //     foreach ClaimCareTeam member in <ClaimCareTeam[]>claim.careTeam {
    //         if member.provider.identifier is Identifier {
    //             Identifier id = <Identifier>member.provider.identifier;
    //             if id.value is string {
    //                 npis.push(<string>id.value);
    //             }
    //         }
    //     }
    // }

    return npis;
}

# Create OperationOutcome
#
# + severity - Severity level
# + code - Issue code
# + diagnostics - Diagnostic message
# + return - OperationOutcome
public function createOperationOutcome(
        string severity,
        string code,
        string diagnostics
) returns r4:OperationOutcome {
    return {
        resourceType: "OperationOutcome",
        issue: [
            {
                severity: <r4:OperationOutcomeIssueSeverity>severity,
                code: code,
                diagnostics: diagnostics
            }
        ]
    };
}

# Validate ClaimResponse status change
#
# + oldStatus - Previous status
# + newStatus - New status
# + return - True if valid transition
public function isValidStatusTransition(string oldStatus, string newStatus) returns boolean {
    // Pended to complete/partial is valid
    if (oldStatus == "pended" || oldStatus == "queued") &&
        (newStatus == "complete" || newStatus == "partial") {
        return true;
    }

    return false;
}

# Extract authorization header from PASSubscription channel headers
#
# + subscription - PASSubscription resource
# + return - Authorization header value or nil
public isolated function extractAuthHeader(davincipas:PASSubscription subscription) returns string? {
    string[]? headers = subscription.channel.header;
    if headers is string[] {
        foreach string header in headers {
            if header.startsWith("Authorization:") {
                return header.substring(14).trim();
            }
        }
    }
    return ();
}

# Extract payload type from PASSubscription channel extensions
#
# + subscription - PASSubscription resource
# + return - Payload type (defaults to "full-resource")
public isolated function extractPayloadType(davincipas:PASSubscription subscription) returns string {
    r4:Extension[]? extensions = subscription.channel.extension;
    if extensions is r4:Extension[] {
        foreach r4:Extension ext in extensions {
            if ext.url.endsWith("backport-payload-content") {
                if ext is r4:CodeExtension {
                    r4:code? code = ext.valueCode;
                    if code is r4:code {
                        return code;
                    }
                }
            }
        }
    }
    return "full-resource";
}

# Extract organization ID from PASSubscription extensions
#
# + subscription - PASSubscription resource
# + return - Organization ID or error
public isolated function extractOrganizationId(davincipas:PASSubscription subscription) returns string|error {
    // First check main extensions for organization-identifier
    r4:Extension[]? extensions = subscription.extension;
    if extensions is r4:Extension[] {
        foreach r4:Extension ext in extensions {
            if ext.url.endsWith("organization-identifier") && ext is r4:StringExtension {
                string? valueStr = ext.valueString;
                if valueStr is string {
                    return valueStr;
                }
            }
            // Also check for backport-filter-criteria extension
            if ext.url.endsWith("backport-filter-criteria") && ext is r4:StringExtension {
                string? valueStr = ext.valueString;
                if valueStr is string {
                    // Parse "org-identifier=1234567890" or "ClaimResponse?insurer:identifier=1234567890"
                    int? eqIndex = valueStr.indexOf("=");
                    if eqIndex is int {
                        return valueStr.substring(eqIndex + 1);
                    }
                }
            }
        }
    }
    return error("Organization ID not found in subscription extensions");
}

# Extract resources from FHIR Bundle
#
# + bundle - FHIR Bundle resource
# + return - Array of resources
public isolated function extractResourcesFromBundle(json bundle) returns json[]|error {
    json[] resources = [];
    json|error entries = bundle.entry;

    if entries is json[] {
        foreach json entry in entries {
            json|error 'resource = entry.'resource;
            if 'resource is json {
                resources.push('resource);
            }
        }
    }

    return resources;
}

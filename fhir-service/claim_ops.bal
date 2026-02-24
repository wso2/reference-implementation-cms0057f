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

import ballerina/log;
import ballerinax/health.clients.fhir as fhirClient;

# Create Claim in FHIR Server
#
# + fhirConnector - FHIR Connector instance
# + claim - Claim resource to create
# + return - Created Claim ID or error
public isolated function createClaim(fhirClient:FHIRConnector fhirConnector, json claim) returns string|error {
    fhirClient:FHIRResponse|fhirClient:FHIRError response = fhirConnector->create(claim);

    if response is fhirClient:FHIRError {
        log:printError(string `Failed to create Claim: ${response.message()}`);
        return error(string `Failed to create Claim: ${response.message()}`);
    }

    if response.'resource is json {
        json|error id = (<json>response.'resource).id;
        if id is string {
            return id;
        }
    }

    return error("Failed to retrieve created Claim ID");
}

# Store ClaimResponse in FHIR Server
#
# + fhirConnector - FHIR Connector instance
# + claimId - Claim ID
# + organizationId - Organization NPI
# + patientMemberId - Patient member identifier
# + status - Current status
# + payload - Full ClaimResponse JSON
# + claimResponseId - Optional ClaimResponse ID
# + return - Created ClaimResponse ID or error
public isolated function storeClaimResponse(
        fhirClient:FHIRConnector fhirConnector,
        string claimId,
        string organizationId,
        string patientMemberId,
        string status,
        json payload,
        string? claimResponseId = ()
) returns string|error {

    // Add organization identifier extension for filtering
    json claimResponseWithMeta = check addOrganizationExtension(payload, organizationId, patientMemberId);
    map<json> payloadMap = <map<json>>claimResponseWithMeta;

    if claimResponseId is string {
        payloadMap["id"] = claimResponseId;
    } else {
        _ = payloadMap.remove("id");
    }

    fhirClient:FHIRResponse|fhirClient:FHIRError response = fhirConnector->create(
        payloadMap
    );

    if response is fhirClient:FHIRError {
        // log:printError(string `Failed to store ClaimResponse: ${response.message()}`);
        return error(string `Failed to store ClaimResponse: ${response.message()}`);
    }

    if response.'resource is json {
        json|error id = (<json>response.'resource).id;
        if id is string {
            log:printInfo(string `Stored ClaimResponse ${id} for org ${organizationId} in FHIR`);
            return id;
        }
    }

    return error("Failed to retrieve created ClaimResponse ID");
}

# Update ClaimResponse status in FHIR Server
#
# + fhirConnector - FHIR Connector instance
# + claimResponseId - ClaimResponse ID
# + payload - Updated ClaimResponse JSON
# + return - Organization ID for correlation or error
public isolated function updateClaimResponse(
        fhirClient:FHIRConnector fhirConnector,
        string claimResponseId,
        json payload
) returns string|error {

    // First, get existing ClaimResponse to retrieve organization ID
    fhirClient:FHIRResponse|fhirClient:FHIRError getResponse = fhirConnector->getById("ClaimResponse", claimResponseId);

    if getResponse is fhirClient:FHIRError {
        return error(string `ClaimResponse ${claimResponseId} not found: ${getResponse.message()}`);
    }

    // Extract organization ID from extension
    string organizationId = check extractOrganizationIdFromResource(<json>getResponse.'resource);

    // Update the ClaimResponse
    fhirClient:FHIRResponse|fhirClient:FHIRError updateResponse = fhirConnector->update(payload, returnPreference = "representation");

    if updateResponse is fhirClient:FHIRError {
        log:printError(string `Failed to update ClaimResponse ${claimResponseId}: ${updateResponse.message()}`);
        return error(string `Failed to update ClaimResponse: ${updateResponse.message()}`);
    }
    return organizationId;
}

# Get ClaimResponse by ID from FHIR Server
#
# + fhirConnector - FHIR Connector instance
# + claimResponseId - ClaimResponse ID
# + return - ClaimResponse record or error
public isolated function getClaimResponse(fhirClient:FHIRConnector fhirConnector, string claimResponseId)
        returns ClaimRecord|error {

    fhirClient:FHIRResponse|fhirClient:FHIRError response = fhirConnector->getById("ClaimResponse", claimResponseId);

    if response is fhirClient:FHIRError {
        return error(string `ClaimResponse ${claimResponseId} not found: ${response.message()}`);
    }

    // Convert FHIR resource to internal ClaimRecord format
    return toClaimRecord(<json>response.'resource);
}

# Get Claim by ID from FHIR Server
#
# + fhirConnector - FHIR Connector instance
# + claimId - Claim ID
# + return - Claim JSON or error
public isolated function getClaim(fhirClient:FHIRConnector fhirConnector, string claimId) returns json|error {
    fhirClient:FHIRResponse|fhirClient:FHIRError response = fhirConnector->getById("Claim", claimId);

    if response is fhirClient:FHIRError {
        return error(string `Claim ${claimId} not found: ${response.message()}`);
    }

    return <json>response.'resource;
}

# Search ClaimResponses by organization
#
# + fhirConnector - FHIR Connector instance
# + organizationId - Organization NPI
# + return - Array of ClaimResponse resources or error
public isolated function getClaimResponsesByOrg(fhirClient:FHIRConnector fhirConnector, string organizationId) returns json[]|error {
    // Search using extension filter for organization ID
    map<string[]> searchParams = {
        "requestor:identifier": [organizationId]
    };

    fhirClient:FHIRResponse|fhirClient:FHIRError response = fhirConnector->search(
        "ClaimResponse",
        searchParameters = searchParams
    );

    if response is fhirClient:FHIRError {
        return error(string `Failed to search ClaimResponses: ${response.message()}`);
    }

    return extractResourcesFromBundle(<json>response.'resource);
}

# Add organization extension to ClaimResponse for filtering
#
# + payload - ClaimResponse JSON  
# + organizationId - Organization NPI  
# + patientMemberId - Patient member identifier
# + return - ClaimResponse JSON with organization extension
isolated function addOrganizationExtension(json payload, string organizationId, string patientMemberId) returns json|error {
    map<json> payloadMap = check payload.cloneWithType();

    // Add meta profile if not present
    if !payloadMap.hasKey("meta") {
        payloadMap["meta"] = {};
    }

    // Add extension for organization tracking (useful for subscription filtering)
    json[] extensions = [];
    if payloadMap.hasKey("extension") {
        json existingExt = payloadMap.get("extension");
        if existingExt is json[] {
            extensions = existingExt;
        }
    }

    extensions.push({
        "url": "http://example.org/fhir/StructureDefinition/organization-identifier",
        "valueString": organizationId
    });
    extensions.push({
        "url": "http://example.org/fhir/StructureDefinition/patient-member-id",
        "valueString": patientMemberId
    });

    payloadMap["extension"] = extensions;

    return payloadMap.toJson();
}

# Extract organization ID from ClaimResponse extension
#
# + fhirResource - FHIR resource
# + return - Organization ID
isolated function extractOrganizationIdFromResource(json fhirResource) returns string|error {
    json|error extensions = fhirResource.extension;
    if extensions is json[] {
        foreach json ext in extensions {
            json|error url = ext.url;
            if url is string && url == "http://example.org/fhir/StructureDefinition/organization-identifier" {
                json|error value = ext.valueString;
                if value is string {
                    return value;
                }
            }
        }
    }

    // Fallback: try to get from requestor reference identifier (the provider)
    json|error requestor = fhirResource.requestor;
    if requestor is json {
        json|error identifier = requestor.identifier;
        if identifier is json {
            json|error value = identifier.value;
            if value is string {
                return value;
            }
        }
    }

    return "";
}

# Convert FHIR resource to internal ClaimRecord format
#
# + fhirResource - FHIR resource
# + return - ClaimRecord
isolated function toClaimRecord(json fhirResource) returns ClaimRecord|error {
    string claimResponseId = check fhirResource.id.ensureType();
    string organizationId = check extractOrganizationIdFromResource(fhirResource);

    // Extract claim reference
    string claimId = "";
    json|error request = fhirResource.request;
    if request is json {
        json|error reference = request.reference;
        if reference is string {
            // Parse "Claim/xxx" format
            string[] parts = re `/`.split(reference);
            if parts.length() > 1 {
                claimId = parts[1];
            }
        }
    }

    // Extract patient member ID from extension
    string patientMemberId = "";
    json|error extensions = fhirResource.extension;
    if extensions is json[] {
        foreach json ext in extensions {
            json|error url = ext.url;
            if url is string && url == "http://example.org/fhir/StructureDefinition/patient-member-id" {
                json|error value = ext.valueString;
                if value is string {
                    patientMemberId = value;
                }
            }
        }
    }

    // Extract status/outcome
    string status = "";
    json|error outcome = fhirResource.outcome;
    if outcome is string {
        status = outcome;
    }

    return {
        claim_id: claimId,
        claimresponse_id: claimResponseId,
        organization_id: organizationId,
        patient_member_id: patientMemberId,
        status: status,
        payload: fhirResource,
        created_at: [0, 0],
        updated_at: [0, 0]
    };
}

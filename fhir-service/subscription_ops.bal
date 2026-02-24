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
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.parser;

# Create subscription in Azure FHIR Server
#
# + fhirConnector - Azure FHIR Connector instance
# + subscription - PASSubscription resource to create
# + return - Created subscription ID or error
public isolated function createSubscription(fhirClient:FHIRConnector fhirConnector, international401:Subscription subscription)
        returns string|error {

    // Convert to JSON for FHIR connector
    json fhirSubscription = subscription.toJson();

    fhirClient:FHIRResponse|fhirClient:FHIRError response = fhirConnector->create(
        fhirSubscription
    );

    if response is fhirClient:FHIRError {
        log:printError(string `Failed to create subscription ${subscription.id ?: "unknown"}: ${response.message()}`);
        return error(string `Failed to create subscription: ${response.message()}`);
    }

    if response.'resource is json {
        json|error idResult = (<json>response.'resource).resourceId;
        if idResult is string {
            log:printInfo(string `Created subscription ${idResult} in Azure FHIR`);
            return idResult;
        }
    }

    return subscription.id ?: "";
}

# Get subscription by ID from Azure FHIR Server
#
# + fhirConnector - Azure FHIR Connector instance
# + id - Subscription ID
# + return - PASSubscription resource or error
public isolated function getSubscription(fhirClient:FHIRConnector fhirConnector, string id)
        returns international401:Subscription|error {

    fhirClient:FHIRResponse|fhirClient:FHIRError response = fhirConnector->getById("Subscription", id);

    if response is fhirClient:FHIRError {
        return error(string `Subscription ${id} not found: ${response.message()}`);
    }

    return trap parser:parse((<json>response.'resource).toJson(), international401:Subscription).ensureType(international401:Subscription);
}

# Get active subscriptions by organization ID from Azure FHIR Server
#
# + fhirConnector - Azure FHIR Connector instance
# + organizationId - Organization NPI
# + return - Array of PASSubscription resources or error
public isolated function getActiveSubscriptionsByOrg(fhirClient:FHIRConnector fhirConnector, string organizationId)
        returns international401:Subscription[]|error {

    // Search for active subscriptions with organization filter via constructed ID
    map<string[]> searchParams = {
        "_id": [string `PasSubscription-${organizationId}`]
    };

    fhirClient:FHIRResponse|fhirClient:FHIRError response = fhirConnector->search(
        "Subscription",
        searchParameters = searchParams
    );

    if response is fhirClient:FHIRError {
        log:printError(string `Failed to search subscriptions: ${response.message()}`);
        return error(string `Failed to search subscriptions: ${response.message()}`);
    }

    return extractSubscriptionsFromBundle(<json>response.'resource, organizationId);
}

# Update subscription status in Azure FHIR Server
#
# + fhirConnector - Azure FHIR Connector instance
# + id - Subscription ID
# + status - New status
# + return - Error if operation fails
public isolated function updateSubscriptionStatus(fhirClient:FHIRConnector fhirConnector, string id, string status) returns error? {
    // Get existing subscription
    fhirClient:FHIRResponse|fhirClient:FHIRError getResponse = fhirConnector->getById("Subscription", id);

    if getResponse is fhirClient:FHIRError {
        return error(string `Subscription ${id} not found: ${getResponse.message()}`);
    }

    json|xml|error 'resource = getResponse.'resource;
    if 'resource is error {
        return error(string `Failed to get subscription resource: ${'resource.message()}`);
    }

    // Update status field
    map<json> subscriptionMap = check 'resource.cloneWithType();
    subscriptionMap["status"] = status;

    // Update in Azure FHIR
    fhirClient:FHIRResponse|fhirClient:FHIRError updateResponse = fhirConnector->update(subscriptionMap.toJson(), returnPreference = "representation");

    if updateResponse is fhirClient:FHIRError {
        log:printError(string `Failed to update subscription ${id}: ${updateResponse.message()}`);
        return error(string `Failed to update subscription: ${updateResponse.message()}`);
    }

    log:printInfo(string `Updated subscription ${id} to status ${status} in Azure FHIR`);
}

# Check if subscription exists for organization
#
# + fhirConnector - Azure FHIR Connector instance
# + organizationId - Organization NPI
# + endpoint - Endpoint URL
# + return - True if exists
public isolated function subscriptionExists(fhirClient:FHIRConnector fhirConnector, string organizationId, string endpoint)
        returns boolean|error {

    // Search for existing subscription with same org and endpoint
    map<string[]> searchParams = {
        "status": ["active", "requested"],
        "url": [endpoint]
    };

    fhirClient:FHIRResponse|fhirClient:FHIRError response = fhirConnector->search(
        "Subscription",
        searchParameters = searchParams
    );

    if response is fhirClient:FHIRError {
        // If search fails, assume no duplicate exists
        return false;
    }

    json bundle = <json>response.'resource;

    // Check if any results match the organization
    json|error total = bundle.total;
    if total is int && total > 0 {
        json|error entries = bundle.entry;
        if entries is json[] {
            foreach json entry in entries {
                json|error 'resource = entry.'resource;
                if 'resource is json {
                    string|error orgId = extractOrganizationIdFromSubscription('resource);
                    if orgId is string && orgId == organizationId {
                        return true;
                    }
                }
            }
        }
    }
    return false;
}

# Extract organization ID from Subscription resource
#
# + fhirResource - FHIR resource
# + return - Organization ID
public isolated function extractOrganizationIdFromSubscription(json fhirResource) returns string|error {
    // First check extension
    json|error extensions = fhirResource.extension;
    if extensions is json[] {
        foreach json ext in extensions {
            json|error url = ext.url;
            if url is string && url.endsWith("organization-identifier") {
                json|error value = ext.valueString;
                if value is string {
                    return value;
                }
            }
        }
    }

    // Fallback: try to parse from _criteria extension
    json|error criteriaExt = fhirResource._criteria;
    if criteriaExt is json[] {
        foreach json ext in criteriaExt {
            json|error url = ext.url;
            if url is string && url.endsWith("backport-filter-criteria") {
                json|error criteria = ext.valueString;
                if criteria is string {
                    // Parse "org-identifier=<orgId>"
                    int? eqIndex = criteria.indexOf("=");
                    if eqIndex is int {
                        return criteria.substring(eqIndex + 1);
                    }
                }
            }
        }
    }

    // Fallback: Check base criteria element
    json|error criteriaStr = fhirResource.criteria;
    if criteriaStr is string {
        int? eqIndex = criteriaStr.indexOf("=");
        if eqIndex is int {
            return criteriaStr.substring(eqIndex + 1);
        }
    }

    // Fallback: Check if ID has the expected prefix
    json|error id = fhirResource.id;
    if id is string {
        if id.startsWith("PasSubscription-") {
            return id.substring(16);
        }
    }

    return "";
}

# Extract subscriptions from FHIR Bundle with organization filter
#
# + bundle - FHIR Bundle
# + organizationId - Organization ID
# + return - Array of Subscription resources
isolated function extractSubscriptionsFromBundle(json bundle, string organizationId)
        returns international401:Subscription[]|error {

    // TODO: Migrate to Davinci PAS Subscription profile. Currently using base profile due to a issue with the Davinci PAS lib.
    international401:Subscription[] subscriptions = [];
    json|error entries = bundle.entry;

    if entries is json[] {
        foreach json entry in entries {
            json|error 'resource = entry.'resource;
            if 'resource is json {
                // Extract organization and filter
                string|error orgId = extractOrganizationIdFromSubscription('resource);
                if orgId is string && orgId == organizationId {
                    international401:Subscription|error sub = trap parser:parse('resource.toJson(), international401:Subscription).ensureType(international401:Subscription);
                    if sub is international401:Subscription {
                        subscriptions.push(sub);
                    } else {
                        log:printError(string `Failed to parse Subscription resource: ${sub.message()}`);
                    }
                }
            }
        }
    }

    return subscriptions;
}

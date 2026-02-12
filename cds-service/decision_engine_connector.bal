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
import ballerinax/health.fhir.cds;
import ballerinax/health.fhir.r4;

# ====================================== Please do your implementations to the below methods ===========================
#
# Consider the below steps while do your implementations.
#
# 1. Map the received CdsRequest/ Feedback request to the custom payload format, if needed (Optional).
# 2. Implement the connectivity with your external decision support systems.
# 3. Send the CdsRequest/ Feedback request to appropriate external systems.
# 4. Get the response.
# 5. Map the received response to the CdsCards and Cds actions.
# 6. Return the CdsResponse to the client.
#
# ======================================================================================================================

configurable string rule_engine_url = ?;
isolated http:Client httpClient = check new (rule_engine_url);

# Handle decision service connectivity.
#
# + cdsRequest - CdsRequest to sent to the backend.
# + hookId - ID of the hook being invoked.
# + return - return CdsResponse or CdsError
isolated function connectDecisionSystemForCrdMriSpineOrderSign(cds:CdsRequest cdsRequest, string hookId) returns cds:CdsResponse|cds:CdsError {
    lock {
        r4:Bundle bundle = {'type: "collection"};
        r4:BundleEntry[] entries = [];
        map<r4:DomainResource>? prefetch = cdsRequest.clone().prefetch;
        if prefetch is map<r4:DomainResource> {
            foreach var item in prefetch.keys() {
                r4:BundleEntry entry = {
                    'resource: prefetch.get(item)
                };
                entries.push(entry);
            }
        }

        cds:Context context = cdsRequest.clone().context;
        r4:Bundle? draftOrders = context?.draftOrders;
        if draftOrders is r4:Bundle {
            r4:BundleEntry[]? entriesArray = draftOrders.entry;
            if entriesArray is r4:BundleEntry[] {
                foreach var item in entriesArray {
                    entries.push(item);
                }
            }
        }

        bundle.entry = entries;

        http:Response|http:ClientError response = httpClient->post(string `/${hookId}`, bundle.clone().toJson());
        if response is error {
            return cds:createCdsError(response.message(), 500, cause = response);
        }

        json|http:ClientError jsonPayload = response.getJsonPayload();
        if jsonPayload is error {
            return cds:createCdsError(jsonPayload.message(), 500, cause = jsonPayload);
        }

        PriorAuthDecision|error priorAuthDecision = jsonPayload.cloneWithType(PriorAuthDecision);
        if priorAuthDecision is error {
            return cds:createCdsError(priorAuthDecision.message(), 500, cause = priorAuthDecision);
        }

        cds:CdsResponse res = {cards: []};

        cds:Card card = {
            summary: priorAuthDecision.summary,
            detail: priorAuthDecision.reasons[0],
            indicator: "critical",
            'source: {label: "WSO2 Healthcare Rule Engine"}
        };

        PriorAuthLink[]? links = priorAuthDecision.links;

        cds:Link[] cdsLinks = [];
        if links is PriorAuthLink[] {
            foreach PriorAuthLink item in links {
                cds:Link link = {label: item.label, 'type: cds:ABSOLUTE, url: item.url};
                cdsLinks.push(link);
            }
            card.links = cdsLinks;
        }

        res.cards.push(card);
        return res.clone();
    }
}

# Handle feedback service connectivity.
#
# + feedback - Feedback record to be processed.
# + hookId - ID of the hook being invoked.
# + return - return CdsError, if any.
isolated function connectFeedbackSystemForCrdMriSpineOrderSign(cds:Feedbacks feedback, string hookId) returns cds:CdsError? {
    return cds:createCdsError(string `Rule repository backend not implemented/ connected yet for ${hookId}`, 501);
}

public type PriorAuthDecision record {|
    boolean priorAuthRequired;
    // High-level summary of why we decided this way.
    string summary;
    // Detailed reasons / rule hits.
    string[] reasons;
    // Medical necessity status derived from clinical data in the bundle.
    MedicalNecessityStatus medicalNecessity;
    // Missing documentation / data points to complete the check.
    string[] missingDocumentation;

    // Links to payer resources (coverage policy, docs checklist, DTR launch, PA portal, etc.)
    PriorAuthLink[] links?;
|};

public type PriorAuthLink record {|
    string label; // e.g., "Coverage policy", "Docs checklist", "Launch DTR"
    string url; // absolute URL
    string 'type?; // optional: "absolute" | "smart" | "web" | "api" (your convention)
    string description?; // optional short help text
|};

public type MedicalNecessityStatus "MET"|"NOT_MET"|"INSUFFICIENT_DATA";

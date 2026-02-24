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
import ballerina/log;

type ClaimStatus record {|
    string status = "entered-in-error";
    string outcome = "queued";
    string patientName = "";
    string providerName = "";
    string medicationRef = "";
    string date = "";
|};

// In-memory store
map<ClaimStatus> claimStatuses = {};

@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"]
    }
}
service / on new http:Listener(9099) {

    // Webhook endpoint
    resource function post .(@http:Payload json payload) returns http:Response {
        log:printInfo("Received webhook notification");

        json|error entries = payload.entry;
        if entries is json[] {
            foreach json entry in entries {
                json|error resourceObj = entry.'resource;
                if resourceObj is json {
                    json|error resType = resourceObj.resourceType;
                    if resType is string && resType == "Bundle" {
                        json|error subEntries = resourceObj.entry;
                        if subEntries is json[] {
                            foreach json subEntry in subEntries {
                                json|error subResource = subEntry.'resource;
                                if subResource is json {
                                    json|error subResType = subResource.resourceType;
                                    if subResType is string && subResType == "ClaimResponse" {
                                        json|error req = subResource.request;
                                        if req is json {
                                            json|error reference = req.reference;
                                            json|error outcome = subResource.outcome;
                                            json|error status = subResource.status;

                                            if reference is string && outcome is string && status is string {
                                                // Extract Claim ID
                                                string claimId = reference;
                                                if reference.startsWith("Claim/") {
                                                    claimId = reference.substring(6);
                                                }
                                                
                                                log:printInfo("Extracted ClaimResponse status update for Claim ID: " + claimId + ", outcome: " + outcome);
                                                
                                                if claimStatuses.hasKey(claimId) {
                                                    ClaimStatus existing = claimStatuses.get(claimId);
                                                    existing.outcome = outcome;
                                                    existing.status = status;
                                                    claimStatuses[claimId] = existing;
                                                } else {
                                                    claimStatuses[claimId] = {outcome: outcome, status: status};
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

        http:Response res = new;
        res.statusCode = 200;
        return res;
    }

    // Endpoint to register a new claim for tracking
    resource function post claim(@http:Payload json payload) returns http:Response {
        log:printInfo("Registering new claim for tracking");
        
        json|error id = payload.id;
        json|error patientName = payload.patientName;
        json|error providerName = payload.providerName;
        json|error medicationRef = payload.medicationRef;
        json|error dateStr = payload.date;
        json|error outcome = payload.outcome;
        json|error status = payload.status;

        if id is string {
            ClaimStatus newStatus = {
                outcome: "queued",
                status: "active",
                patientName: (patientName is string) ? patientName : "Unknown Patient",
                providerName: (providerName is string) ? providerName : "Unknown Provider",
                medicationRef: (medicationRef is string) ? medicationRef : "Unknown Medication",
                date: (dateStr is string) ? dateStr : ""
            };
            
            // Allow outcome and status overrides
            if outcome is string {
                newStatus.outcome = outcome;
            }
            if status is string {
                newStatus.status = status;
            }
            
            claimStatuses[id] = newStatus;
            log:printInfo("Registered Claim ID: " + id);
            
            http:Response res = new;
            res.statusCode = 201;
            return res;
        }

        http:Response badRes = new;
        badRes.statusCode = 400;
        badRes.setPayload({message: "Missing Claim ID"});
        return badRes;
    }

    // Endpoint to retrieve all tracked claim states
    resource function get claims() returns json[] {
        json[] claimsList = [];
        foreach [string, ClaimStatus] [id, claimStatus] in claimStatuses.entries() {
            json claimEntry = claimStatus.toJson();
            json|error merged = claimEntry.mergeJson({"id": id});
            if merged is json {
                claimsList.push(merged);
            }
        }
        return claimsList;
    }

    // Polling endpoint
    resource function get claim\-status/[string id]() returns json|http:Response {
        if claimStatuses.hasKey(id) {
            return claimStatuses.get(id).toJson();
        } else {
            http:Response res = new;
            res.statusCode = 404;
            res.setPayload({message: "ClaimResponse ID not found"});
            return res;
        }
    }
}

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

import ballerina/file;
import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/time;
import ballerinax/health.fhir.r4.international401;

# Create R4:Parameters resource for $member-match operation.
#
# + request - PayerDataExchangeRequest with member details
# + fhirClient - HTTP client for local FHIR server
# + return - R4:Parameters resource
public isolated function createMemberMatchParams(PayerDataExchangeRequest request, http:Client fhirClient) returns international401:Parameters|error {

    international401:ParametersParameter[] paramsArr = [];

    // MemberPatient
    // Fetch from local FHIR server
    json|error patientResult = fhirClient->get("/Patient/" + request.memberId);

    international401:Patient memberPatient = {
        resourceType: "Patient",
        id: request.memberId
    };

    if patientResult is json {
        // Map required fields: identifier, name, address, telecom, gender, birthdate
        map<json> patientMap = check patientResult.ensureType();

        if patientMap.hasKey("identifier") {
            memberPatient.identifier = check patientMap.get("identifier").cloneWithType();
        }
        if patientMap.hasKey("name") {
            memberPatient.name = check patientMap.get("name").cloneWithType();
        }
        if patientMap.hasKey("address") {
            memberPatient.address = check patientMap.get("address").cloneWithType();
        }
        if patientMap.hasKey("telecom") {
            memberPatient.telecom = check patientMap.get("telecom").cloneWithType();
        }
        if patientMap.hasKey("gender") {
            memberPatient.gender = check patientMap.get("gender").cloneWithType();
        }
        if patientMap.hasKey("birthDate") {
            memberPatient.birthDate = check patientMap.get("birthDate").cloneWithType();
        }
    } else {
        log:printError("Error fetching patient details: ", patientResult);
        // Continue with minimal patient or return error? 
        // Requirements said "include...". I'll log and proceed with minimal if fetch fails, or return error?
        // Let's proceed with minimal to be safe, but logging error.
    }

    paramsArr.push({name: "MemberPatient", 'resource: memberPatient});

    // OldCoverage
    if request.oldCoverageId != () {
        international401:Coverage oldCoverage = {
            resourceType: "Coverage",
            id: request.oldCoverageId ?: "",
            status: "active",
            subscriberId: request.memberId,
            beneficiary: {reference: "Patient/" + request.memberId},
            payor: [{display: request.oldPayerName}]
        };
        paramsArr.push({name: "CoverageToMatch", 'resource: oldCoverage});
    }

    // NewCoverage 
    international401:Coverage newCoverage = {
        resourceType: "Coverage",
        status: "active",
        subscriberId: request.memberId,
        beneficiary: {reference: "Patient/" + request.memberId},
        payor: [{display: "New Payer"}]
    };
    paramsArr.push({name: "CoverageToLink", 'resource: newCoverage});

    // Consent - HRex Profile
    if request.consent != () {
        international401:Consent consent = {
            resourceType: "Consent",
            status: "active",
            scope: {
                coding: [
                    {
                        system: "http://terminology.hl7.org/CodeSystem/consentscope",
                        code: "patient-privacy"
                    }
                ]
            },
            category: [
                {
                    coding: [
                        {
                            system: "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                            code: "IDSCL"
                        }
                    ]
                }
            ],
            patient: {reference: "Patient/" + request.memberId},
            performer: [
                {reference: "Patient/" + request.memberId}
            ],
            sourceReference: {
                reference: "http://example.org/DocumentReference/someconsent"
            },
            policy: [
                {
                    uri: "http://hl7.org/fhir/us/davinci-hrex/StructureDefinition-hrex-consent.html#regular"
                }
            ],
            provision: {
                'type: "permit",
                period: {
                    'start: request.coverageStartDate,
                    end: request.coverageEndDate
                },
                actor: [
                    {
                        role: {
                            coding: [
                                {
                                    system: "http://terminology.hl7.org/CodeSystem/provenance-participant-type",
                                    code: "performer"
                                }
                            ]
                        },
                        reference: {
                            identifier: {
                                system: "http://hl7.org/fhir/sid/us-npi",
                                value: request.payerId
                            },
                            display: request.oldPayerName
                        }
                    },
                    {
                        role: {
                            coding: [
                                {
                                    system: "http://terminology.hl7.org/CodeSystem/v3-ParticipationType",
                                    code: "IRCP"
                                }
                            ]
                        },
                        reference: {
                            identifier: {
                                system: "http://hl7.org/fhir/sid/us-npi",
                                value: clientServiceConfig.newPayerNpi
                            },
                            display: "New Health Plan"
                        }
                    }
                ],
                action: [
                    {
                        coding: [
                            {
                                system: "http://terminology.hl7.org/CodeSystem/consentaction",
                                code: "disclose"
                            }
                        ]
                    }
                ]
            }
        };
        paramsArr.push({name: "Consent", 'resource: consent});
    }

    return {'parameter: paramsArr};
}

# Extract MatchedPatient from $member-match response.
#
# + responsePayload - JSON payload of the response
# + systemUrl - The system URL of the old payer
# + return - MatchedPatient or error
public isolated function extractMatchedPatient(json responsePayload, string systemUrl) returns MatchedPatient|error {
    // Response should be a Parameters resource containing a "MemberPatient" parameter with a unique identifier.

    // Check if it is a Parameters resource
    if responsePayload !is map<json> {
        return error("Invalid response payload structure");
    }
    map<json> payloadMap = responsePayload;

    string resourceType = "";
    json resourceTypeJson = payloadMap["resourceType"];
    if resourceTypeJson is string {
        resourceType = resourceTypeJson;
    } else {
        return error("Invalid resourceType");
    }

    if resourceType != "Parameters" {
        return error("Expected Parameters resource, got " + resourceType);
    }

    json parameterJson = payloadMap["parameter"];
    if parameterJson !is json[] {
        return error("Expected json array for parameter");
    }
    json[] parameters = parameterJson;

    foreach json param in parameters {
        if param !is map<json> {
            continue;
        }
        map<json> paramMap = param;

        json nameJson = paramMap["name"];
        if nameJson !is string {
            continue;
        }
        string name = nameJson;

        // Check for "MemberIdentifier" as per Da Vinci HRex / User sample
        if name == "MemberIdentifier" {
            json valueIdentifierJson = paramMap["valueIdentifier"];
            if valueIdentifierJson !is map<json> {
                return error("Invalid valueIdentifier in MemberIdentifier parameter");
            }
            map<json> valueIdentifierMap = valueIdentifierJson;
            // Extract value
            json idJson = valueIdentifierMap["value"];
            if idJson !is string {
                return error("Invalid value in MemberIdentifier");
            }
            string id = idJson;

            // Construct MatchedPatient
            return {
                id: id,
                systemId: systemUrl
            };
        }
    }

    return error("MemberIdentifier not found in response");
}

# Sync data to FHIR server.
#
# + exportId - The export ID
# + exportSummary - The export summary JSON
# + context - Context map with payer details
# + return - Error if failed
public isolated function syncDataToFhirServer(string exportId, json exportSummary, map<string> context) returns error? {

    // Parse export summary
    ExportSummary summary = check exportSummary.cloneWithType(ExportSummary);

    foreach OutputFile item in summary.output {
        log:printInfo("Syncing file: " + item.url);

        // Download file stream
        http:Client fileClient = check new (item.url);
        http:Response response = check fileClient->get("");

        if response.statusCode != 200 {
            log:printError("Failed to download file: " + item.url);
            continue;
        }

        // Read NDJSON line by line
        stream<byte[], io:Error?> byteStream = check response.getByteStream();

        // Helper to process stream
        check processNdjsonStream(byteStream, clientFhirClient, context);
    }

    return null;
}

isolated function processNdjsonStream(stream<byte[], io:Error?> byteStream, http:Client fhirClient, map<string> context) returns error? {
    string tempFile = check file:createTemp(suffix = ".ndjson");
    check io:fileWriteBlocksFromStream(tempFile, byteStream);

    stream<string, io:Error?> lineStream = check io:fileReadLinesAsStream(tempFile);

    check from string line in lineStream
        do {
            json|error resourceJson = line.fromJsonString();
            if resourceJson is json {
                check processAndInsertResource(resourceJson, fhirClient, context);
            }
        };

    return null;
}

isolated function processAndInsertResource(json resourceJson, http:Client fhirClient, map<string> context) returns error? {
    map<json> resourceMap = check resourceJson.ensureType();
    string resourceType = check resourceMap.get("resourceType").ensureType(string);

    // Skip Patient updates if needed or just sync
    if resourceType == "Patient" {
        return null;
    }

    // Modify ID
    string id = check resourceMap.get("id").ensureType(string);
    // Prefix logic: we need the prefix.
    string prefix = "PAYER_DATA_";
    if context.hasKey("payerId") {
        prefix += context.get("payerId") + "_";
    }
    string newId = prefix + id;

    resourceMap["id"] = newId;

    // Flagging: "only the new data coming from old payer should be there with some kind of flagging"
    // Add a Tag to meta.
    map<json> meta = {};
    if resourceMap.hasKey("meta") {
        meta = check resourceMap.get("meta").cloneWithType();
    }

    json[] tag = [];
    if meta.hasKey("tag") {
        tag = check meta.get("tag").cloneWithType();
    }

    tag.push({
        system: "http://wso2.com/fhir/pdex-source",
        code: "old-payer-data",
        display: "Data from old payer"
    });

    meta["tag"] = tag;
    resourceMap["meta"] = meta;

    // Insert (POST for new resource creation)
    http:Response|http:ClientError resp = fhirClient->post("/" + resourceType, resourceMap, headers = {"Content-Type": "application/fhir+json"});
    if resp is http:ClientError {
        log:printError("Error syncing resource " + resourceType + "/" + newId, resp);
    } else {
        // Create Provenance resource
        check createProvenance(resourceType, newId, context, fhirClient);
    }

    return null;
}

isolated function createProvenance(string resourceType, string resourceId, map<string> context, http:Client fhirClient) returns error? {

    string oldPayerName = "Unknown Payer";
    if context.hasKey("oldPayerName") {
        oldPayerName = context.get("oldPayerName");
    }

    international401:Provenance provenance = {
        resourceType: "Provenance",
        target: [
            {
                reference: resourceType + "/" + resourceId
            }
        ],
        recorded: time:utcToString(time:utcNow()),
        reason: [
            {
                coding: [
                    {
                        system: "http://terminology.hl7.org/CodeSystem/v3-ActReason",
                        code: "HCOMPL",
                        display: "health compliance"
                    }
                ]
            }
        ],
        agent: [
            {
                'type: {
                    coding: [
                        {
                            system: "http://terminology.hl7.org/CodeSystem/provenance-participant-type",
                            code: "author",
                            display: "Author"
                        }
                    ]
                },
                who: {
                    display: oldPayerName
                }
            }
        ]
    };

    http:Response|http:ClientError resp = fhirClient->post("/Provenance", provenance, headers = {"Content-Type": "application/fhir+json"});
    if resp is http:ClientError {
        log:printError("Error creating Provenance for " + resourceType + "/" + resourceId, resp);
    }
}

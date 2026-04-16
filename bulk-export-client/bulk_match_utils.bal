// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
// Licensed under the Apache License, Version 2.0.

import ballerina/http;
import ballerina/log;

# Build Parameters JSON for POST /Group/$bulk-member-match.
# Fetches each member's Patient from the local FHIR server and wraps it in a MemberBundle.
#
# + requests   - List of PDex exchange requests to include in the batch
# + fhirClient - HTTP client pointed at the LOCAL FHIR server (to fetch Patient resources)
# + return     - BulkMatchParamsResult or error
public isolated function buildBulkMemberMatchParams(
    PayerDataExchangeRequest[] requests,
    http:Client fhirClient
) returns BulkMatchParamsResult|error {

    json[] memberBundles = [];
    map<string> memberIdToRequestIdMap = {};

    foreach PayerDataExchangeRequest request in requests {
        string memberId = request.memberId;
        string requestId = request.requestId ?: "";

        // 1. Fetch Patient from local FHIR server
        json|error patientResult = fhirClient->get("/Patient/" + memberId);
        if patientResult is error {
            log:printError("Failed to fetch patient for bulk match", patientResult, memberId = memberId);
            return error("Failed to fetch patient details for member: " + memberId);
        }
        map<json> patientMap = check patientResult.ensureType();

        // 2. Build MemberPatient JSON — keep only required demographic fields
        map<json> memberPatient = {
            "resourceType": "Patient",
            "id": memberId
        };
        foreach string 'field in ["identifier", "name", "address", "telecom", "gender", "birthDate"] {
            if patientMap.hasKey('field) {
                memberPatient['field] = patientMap.get('field);
            }
        }

        // 3. Build part[] array for the MemberBundle
        json[] parts = [
            {"name": "MemberPatient", "resource": memberPatient}
        ];

        // 4. CoverageToMatch (only if oldCoverageId is provided)
        if request.oldCoverageId != () {
            json coverageToMatch = {
                "resourceType": "Coverage",
                "id": request.oldCoverageId ?: "",
                "status": "active",
                "subscriberId": memberId,
                "beneficiary": {"reference": "Patient/" + memberId},
                "payor": [{"display": request.oldPayerName}]
            };
            parts.push({"name": "CoverageToMatch", "resource": coverageToMatch});
        }

        // 5. CoverageToLink (always present — links to new payer)
        json coverageToLink = {
            "resourceType": "Coverage",
            "status": "active",
            "subscriberId": memberId,
            "beneficiary": {"reference": "Patient/" + memberId},
            "payor": [{"display": clientServiceConfig.newPayerName}]
        };
        parts.push({"name": "CoverageToLink", "resource": coverageToLink});

        // 6. Consent (if consent field is set on the request)
        if request.consent != () {
            json consent = {
                "resourceType": "Consent",
                "status": "active",
                "scope": {
                    "coding": [{"system": "http://terminology.hl7.org/CodeSystem/consentscope", "code": "patient-privacy"}]
                },
                "category": [
                    {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/v3-ActCode", "code": "IDSCL"}]}
                ],
                "patient": {"reference": "Patient/" + memberId},
                "performer": [{"reference": "Patient/" + memberId}],
                "sourceReference": {"reference": "http://example.org/DocumentReference/someconsent"},
                "policy": [{"uri": "http://hl7.org/fhir/us/davinci-hrex/StructureDefinition-hrex-consent.html#regular"}],
                "provision": {
                    "type": "permit",
                    "period": {
                        "start": request.coverageStartDate,
                        "end": request.coverageEndDate
                    },
                    "actor": [
                        {
                            "role": {
                                "coding": [{"system": "http://terminology.hl7.org/CodeSystem/provenance-participant-type", "code": "performer"}]
                            },
                            "reference": {
                                "identifier": {"system": "http://hl7.org/fhir/sid/us-npi", "value": request.payerId},
                                "display": request.oldPayerName
                            }
                        },
                        {
                            "role": {
                                "coding": [{"system": "http://terminology.hl7.org/CodeSystem/v3-ParticipationType", "code": "IRCP"}]
                            },
                            "reference": {
                                "identifier": {"system": "http://hl7.org/fhir/sid/us-npi", "value": clientServiceConfig.newPayerNpi},
                                "display": clientServiceConfig.newPayerName
                            }
                        }
                    ],
                    "action": [
                        {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/consentaction", "code": "disclose"}]}
                    ]
                }
            };
            parts.push({"name": "Consent", "resource": consent});
        }

        // 7. Wrap in MemberBundle
        memberBundles.push({"name": "MemberBundle", "part": parts});

        // 8. Track correlation — index by memberId AND by every patient identifier value.
        //    The old payer echoes back our submitted identifier values on the contained patients
        //    in the response Group, so we need those values as lookup keys too.
        memberIdToRequestIdMap[memberId] = requestId;
        json patientIdentifiers = patientMap["identifier"];
        if patientIdentifiers is json[] {
            foreach json idEntry in patientIdentifiers {
                if idEntry is map<json> {
                    json idValue = idEntry["value"];
                    if idValue is string && idValue != "" {
                        memberIdToRequestIdMap[idValue] = requestId;
                    }
                }
            }
        }
    }

    json params = {
        "resourceType": "Parameters",
        "parameter": memberBundles
    };

    return {params, memberIdToRequestIdMap};
}

# Parse the 200 response from $bulk-member-match polling.
# Extracts the MatchedMembers Group ID and correlates members back to requestIds.
#
# + responsePayload        - JSON body of the 200 polling response
# + memberIdToRequestIdMap - memberId -> requestId built during param construction
# + return                 - BulkMatchResponseResult or error
public isolated function extractBulkMatchResult(
    json responsePayload,
    map<string> memberIdToRequestIdMap
) returns BulkMatchResponseResult|error {

    map<json> payloadMap = check responsePayload.ensureType();
    json resourceTypeVal = payloadMap["resourceType"];
    if resourceTypeVal !is string || resourceTypeVal != "Parameters" {
        return error("Expected Parameters resource in bulk match response");
    }

    json parameterVal = payloadMap["parameter"];
    if parameterVal !is json[] {
        return error("Expected parameter array in bulk match response");
    }

    string matchedGroupId = "";
    string[] matchedRequestIds = [];
    string[] nonMatchedRequestIds = [];
    string[] consentConstrainedRequestIds = [];

    foreach json param in <json[]>parameterVal {
        map<json> paramMap = check param.ensureType();
        json nameVal = paramMap["name"];
        if nameVal !is string {
            continue;
        }
        string paramName = nameVal;

        if paramName == "MatchedMembers" || paramName == "NonMatchedMembers" || paramName == "ConsentConstrainedMembers" {
            json resourceVal = paramMap["resource"];
            if resourceVal !is map<json> {
                continue;
            }
            map<json> groupMap = check resourceVal.ensureType();

            // Extract Group id (only for MatchedMembers)
            if paramName == "MatchedMembers" {
                json groupId = groupMap["id"];
                if groupId is string {
                    matchedGroupId = groupId;
                }
            }

            // Extract contained patients to correlate back to requestIds
            json[] contained = [];
            json containedVal = groupMap["contained"];
            if containedVal is json[] {
                contained = containedVal;
            }

            // Build a lookup: contained patient id -> identifier values
            map<string[]> containedIdToIdentifiers = {};
            foreach json containedResource in contained {
                map<json> containedMap = check containedResource.ensureType();
                json containedId = containedMap["id"];
                if containedId !is string {
                    continue;
                }
                json[] identifiers = [];
                json identifierVal = containedMap["identifier"];
                if identifierVal is json[] {
                    identifiers = identifierVal;
                }
                string[] values = [];
                foreach json identifier in identifiers {
                    map<json> identifierMap = check identifier.ensureType();
                    json idValue = identifierMap["value"];
                    if idValue is string {
                        values.push(idValue);
                    }
                }
                containedIdToIdentifiers[containedId] = values;
            }

            // Walk member[] entries and correlate via contained patient identifiers
            json memberVal = groupMap["member"];
            if memberVal !is json[] {
                continue;
            }

            foreach json member in <json[]>memberVal {
                map<json> memberMap = check member.ensureType();

                // The match-parameters extension is on member[].entity.extension, not member[].extension
                string containedRef = "";
                json entityVal = memberMap["entity"];
                if entityVal is map<json> {
                    map<json> entityMap = check entityVal.ensureType();
                    json extensionVal = entityMap["extension"];
                    if extensionVal is json[] {
                        foreach json ext in extensionVal {
                            map<json> extMap = check ext.ensureType();
                            json urlVal = extMap["url"];
                            if urlVal is string && urlVal.includes("match-parameters") {
                                json valueRefVal = extMap["valueReference"];
                                if valueRefVal is map<json> {
                                    map<json> valueRefMap = check valueRefVal.ensureType();
                                    json refVal = valueRefMap["reference"];
                                    if refVal is string {
                                        // reference is "#containedId" e.g. "#1"
                                        containedRef = refVal.startsWith("#") ? refVal.substring(1) : refVal;
                                    }
                                }
                            }
                        }
                    }
                }

                // Find requestId by matching identifier values of the contained patient
                string[] identifierValues = containedIdToIdentifiers[containedRef] ?: [];
                string requestId = "";
                foreach string idValue in identifierValues {
                    if memberIdToRequestIdMap.hasKey(idValue) {
                        requestId = memberIdToRequestIdMap.get(idValue);
                        break;
                    }
                }

                if requestId == "" {
                    log:printWarn("Could not correlate bulk match member to a requestId",
                        containedRef = containedRef);
                    continue;
                }

                if paramName == "MatchedMembers" {
                    matchedRequestIds.push(requestId);
                } else if paramName == "NonMatchedMembers" {
                    nonMatchedRequestIds.push(requestId);
                } else {
                    consentConstrainedRequestIds.push(requestId);
                }
            }
        }
    }

    return {
        matchedGroupId,
        matchedRequestIds,
        nonMatchedRequestIds,
        consentConstrainedRequestIds
    };
}

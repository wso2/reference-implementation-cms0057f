// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
// Licensed under the Apache License, Version 2.0.

import ballerina/http;
import ballerina/log;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincihrex100 as hrex100;
import ballerinax/health.fhir.r4.davincipdex220;
import ballerinax/health.fhir.r4.international401;

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

    davincipdex220:PDexMultiMemberMatchRequestParametersParameter[] memberBundles = [];
    map<string> memberIdToRequestIdMap = {};

    foreach PayerDataExchangeRequest request in requests {
        string memberId = request.memberId;
        string requestId = request.requestId ?: "";

        // 1. Fetch Patient from local FHIR server and parse into typed record
        json|error patientResult = fhirClient->get("/Patient/" + memberId);
        if patientResult is error {
            log:printError("Failed to fetch patient for bulk match", patientResult, memberId = memberId);
            return error("Failed to fetch patient details for member: " + memberId);
        }
        hrex100:HRexPatientDemographics fullPatient = check patientResult.cloneWithType(hrex100:HRexPatientDemographics);

        // 2. Build MemberPatient — demographic fields defined by HRex patient-demographics profile
        hrex100:HRexPatientDemographics memberPatient = {
            id: memberId,
            identifier: fullPatient.identifier,
            name: fullPatient.name,
            address: fullPatient.address,
            telecom: fullPatient.telecom,
            gender: fullPatient.gender,
            birthDate: fullPatient.birthDate
        };

        // 3. Build part[] array for the MemberBundle
        international401:ParametersParameter[] parts = [
            {name: "MemberPatient", 'resource: memberPatient}
        ];

        // 4. CoverageToMatch (only if oldCoverageId is provided)
        if request.oldCoverageId != () {
            hrex100:HRexCoverage coverageToMatch = {
                id: request.oldCoverageId ?: "",
                status: "active",
                subscriberId: memberId,
                beneficiary: {reference: "Patient/" + memberId},
                payor: [{display: request.oldPayerName}]
            };
            parts.push({name: "CoverageToMatch", 'resource: coverageToMatch});
        }

        // 5. CoverageToLink (always present — links to new payer)
        hrex100:HRexCoverage coverageToLink = {
            status: "active",
            subscriberId: memberId,
            beneficiary: {reference: "Patient/" + memberId},
            payor: [{display: clientServiceConfig.newPayerName}]
        };
        parts.push({name: "CoverageToLink", 'resource: coverageToLink});

        // 6. Consent (if consent field is set on the request)
        if request.consent != () {
            hrex100:HRexConsent consent = {
                status: "active",
                patient: {reference: "Patient/" + memberId},
                performer: [{reference: "Patient/" + memberId}],
                scope: {coding: [{system: "http://terminology.hl7.org/CodeSystem/consentscope", code: "patient-privacy"}]},
                category: [{
                    coding: [{
                        system: "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                        code: "IDSCL"
                    }]
                }],
                sourceReference: {reference: "http://example.org/DocumentReference/someconsent"},
                policy: [{uri: "http://hl7.org/fhir/us/davinci-hrex/StructureDefinition-hrex-consent.html#regular"}],
                provision: {
                    'type: "permit",
                    period: {
                        'start: request.coverageStartDate,
                        'end: request.coverageEndDate
                    },
                    actor: [
                        {
                            role: {coding: [{
                                system: "http://terminology.hl7.org/CodeSystem/provenance-participant-type",
                                code: "performer"
                            }]},
                            reference: {
                                identifier: {system: "http://hl7.org/fhir/sid/us-npi", value: request.payerId},
                                display: request.oldPayerName
                            }
                        },
                        {
                            role: {coding: [{
                                system: "http://terminology.hl7.org/CodeSystem/v3-ParticipationType",
                                code: "IRCP"
                            }]},
                            reference: {
                                identifier: {system: "http://hl7.org/fhir/sid/us-npi", value: clientServiceConfig.newPayerNpi},
                                display: clientServiceConfig.newPayerName
                            }
                        }
                    ],
                    action: [{coding: [{system: "http://terminology.hl7.org/CodeSystem/consentaction", code: "disclose"}]}]
                }
            };
            parts.push({name: "Consent", 'resource: consent});
        }

        // 7. Wrap in MemberBundle
        memberBundles.push({name: "MemberBundle", part: parts});

        // 8. Track correlation — index by memberId AND by every patient identifier value.
        //    The old payer echoes back our submitted identifier values on the contained patients
        //    in the response Group, so we need those values as lookup keys too.
        memberIdToRequestIdMap[memberId] = requestId;
        foreach r4:Identifier identifier in (fullPatient.identifier ?: []) {
            string? idValue = identifier.value;
            if idValue is string && idValue != "" {
                memberIdToRequestIdMap[idValue] = requestId;
            }
        }
    }

    davincipdex220:PDexMultiMemberMatchRequestParameters params = {
        'parameter: memberBundles
    };

    return {params: params.toJson(), memberIdToRequestIdMap};
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

    davincipdex220:PDexMultiMemberMatchResponseParameters response =
        check responsePayload.cloneWithType(davincipdex220:PDexMultiMemberMatchResponseParameters);

    string matchedGroupId = "";
    string[] matchedRequestIds = [];
    string[] nonMatchedRequestIds = [];
    string[] consentConstrainedRequestIds = [];

    foreach davincipdex220:PDexMultiMemberMatchResponseParametersParameter param in response.'parameter {
        r4:Resource? groupResource = param.'resource;
        if groupResource is () {
            continue;
        }

        international401:Group|error groupResult = groupResource.cloneWithType(international401:Group);
        if groupResult is error {
            log:printWarn("Failed to parse Group in bulk match response", groupResult, paramName = param.name);
            continue;
        }
        international401:Group grp = groupResult;

        if param.name == "MatchedMembers" {
            matchedGroupId = grp.id ?: "";
        }

        // Build a lookup: contained patient id -> identifier values
        map<string[]> containedIdToIdentifiers = {};
        foreach r4:Resource containedResource in (grp.contained ?: []) {
            international401:Patient|error ptResult = containedResource.cloneWithType(international401:Patient);
            if ptResult is error {
                continue;
            }
            string containedId = ptResult.id ?: "";
            if containedId == "" {
                continue;
            }
            string[] values = [];
            foreach r4:Identifier identifier in (ptResult.identifier ?: []) {
                string? idValue = identifier.value;
                if idValue is string && idValue != "" {
                    values.push(idValue);
                }
            }
            containedIdToIdentifiers[containedId] = values;
        }

        // Walk member[] entries and correlate via contained patient identifiers
        foreach international401:GroupMember member in (grp.member ?: []) {
            // The match-parameters extension is on member.entity.extension
            string containedRef = "";
            foreach r4:Extension ext in (member.entity.extension ?: []) {
                if ext is r4:ReferenceExtension {
                    if ext.url.includes("match-parameters") {
                        string? refVal = ext.valueReference.reference;
                        if refVal is string {
                            containedRef = refVal.startsWith("#") ? refVal.substring(1) : refVal;
                        }
                        break;
                    }
                }
            }

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

            if param.name == "MatchedMembers" {
                matchedRequestIds.push(requestId);
            } else if param.name == "NonMatchedMembers" {
                nonMatchedRequestIds.push(requestId);
            } else {
                consentConstrainedRequestIds.push(requestId);
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

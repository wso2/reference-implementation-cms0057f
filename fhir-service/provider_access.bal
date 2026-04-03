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
import ballerina/time;
import ballerina/uuid;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;

configurable int providerMatchTreatmentRecencyMonths = 18;
configurable int providerMatchGroupTtlDays = 30;
configurable int providerMatchSynchronousThreshold = 20;

isolated map<ProviderMemberMatchJob> providerMemberMatchJobStore = {};
const decimal PROVIDER_MEMBER_MATCH_JOB_TTL_SECONDS = 3600.0d;

// ============================================================================
// Async Job Management
// ============================================================================

# Evict terminal async provider-member-match jobs that exceeded the in-memory TTL.
isolated function evictExpiredProviderMemberMatchJobs() {
    time:Utc now = time:utcNow();
    lock {
        string[] toRemove = [];
        foreach string key in providerMemberMatchJobStore.keys() {
            ProviderMemberMatchJob job = providerMemberMatchJobStore.get(key);
            if job.status == PROVIDER_MEMBER_MATCH_PENDING || job.status == PROVIDER_MEMBER_MATCH_PROCESSING {
                continue;
            }
            time:Utc anchor = job.completedAt ?: job.createdAt;
            if time:utcDiffSeconds(now, anchor) > PROVIDER_MEMBER_MATCH_JOB_TTL_SECONDS {
                toRemove.push(key);
            }
        }
        foreach string key in toRemove {
            _ = providerMemberMatchJobStore.remove(key);
        }
    }
}

# Get an async provider-member-match job by ID.
#
# + jobId - Async job identifier
# + providerIdentifier - Requesting provider identifier (must match job ownership)
# + return - Stored job copy, or () if not found
isolated function getProviderMemberMatchJob(string jobId, string providerIdentifier) returns ProviderMemberMatchJob? {
    lock {
        if providerMemberMatchJobStore.hasKey(jobId) {
            ProviderMemberMatchJob job = providerMemberMatchJobStore.get(jobId);
            if job.providerIdentifier == providerIdentifier {
                return job.clone();
            }
        }
    }
    return ();
}

# Check whether an async provider-member-match job exists by ID.
#
# + jobId - Async job identifier
# + return - True if the job exists
isolated function hasProviderMemberMatchJob(string jobId) returns boolean {
    lock {
        return providerMemberMatchJobStore.hasKey(jobId);
    }
}

# Run provider-member-match in background and persist result in the async job store.
#
# + jobId - Async job identifier
# + providerIdentifier - Requesting provider identifier context
# + memberPatientIds - Member patient IDs to evaluate
isolated function processAndStoreProviderMemberMatch(string jobId, string providerIdentifier, readonly & string[] memberPatientIds) {
    lock {
        if providerMemberMatchJobStore.hasKey(jobId) {
            ProviderMemberMatchJob current = providerMemberMatchJobStore.get(jobId);
            providerMemberMatchJobStore[jobId] = {
                jobId: current.jobId,
                providerIdentifier: current.providerIdentifier,
                status: PROVIDER_MEMBER_MATCH_PROCESSING,
                createdAt: current.createdAt,
                completedAt: (),
                result: (),
                errorMessage: ()
            };
        }
    }

    map<json>|r4:FHIRError|error result = trap processProviderMemberMatch(providerIdentifier, memberPatientIds.clone());
    lock {
        if providerMemberMatchJobStore.hasKey(jobId) {
            ProviderMemberMatchJob current = providerMemberMatchJobStore.get(jobId);
            if result is map<json> {
                providerMemberMatchJobStore[jobId] = {
                    jobId: current.jobId,
                    providerIdentifier: current.providerIdentifier,
                    status: PROVIDER_MEMBER_MATCH_COMPLETED,
                    createdAt: current.createdAt,
                    completedAt: time:utcNow(),
                    result: result.cloneReadOnly(),
                    errorMessage: ()
                };
            } else {
                string errMsg = result is r4:FHIRError ? result.message() : result.message();
                log:printError("Provider member match job " + jobId + " failed: " + errMsg);
                providerMemberMatchJobStore[jobId] = {
                    jobId: current.jobId,
                    providerIdentifier: current.providerIdentifier,
                    status: PROVIDER_MEMBER_MATCH_FAILED,
                    createdAt: current.createdAt,
                    completedAt: time:utcNow(),
                    result: (),
                    errorMessage: errMsg
                };
            }
        }
    }
}

// ============================================================================
// Core Provider-Member-Match Processing
// ============================================================================

# Process a provider-member-match request.
# For each member: classifies as matched / no-match / consent-constrained.
# Creates:
#   - One Member-Provider TRL Group per matched member (member-keyed, provider as member entry)
#   - Short-lived Matched Member Group (contains all matched Patient refs)
#   - Short-lived No-Match Group (contains all unmatched patients with per-member reason)
#   - Updates the single persistent Member Opt-Out Group with constrained members
# + providerIdentifier - Requesting provider identifier context
# + memberPatientIds - Member patient IDs from operation input
# + return - Summary payload with group refs/counts or FHIRError
isolated function processProviderMemberMatch(string providerIdentifier, string[] memberPatientIds) returns map<json>|r4:FHIRError {
    ProviderMatchDecision[] matched = [];
    ProviderMatchDecision[] noMatched = [];
    ProviderMatchDecision[] constrained = [];

    foreach string memberPatientId in memberPatientIds {
        ProviderMatchDecision decision = classifyProviderMember(providerIdentifier, memberPatientId);
        if decision.outcome == PROVIDER_MATCHED {
            matched.push(decision);
        } else if decision.outcome == PROVIDER_NO_MATCH {
            noMatched.push(decision);
        } else {
            constrained.push(decision);
        }
    }

    // Create one TRL Group per matched member (v2: member-keyed, inverted model)
    string[] trlGroupRefs = [];
    foreach ProviderMatchDecision decision in matched {
        string|r4:FHIRError trlRef = persistTrlGroup(decision.memberPatientId, providerIdentifier);
        if trlRef is r4:FHIRError {
            return trlRef;
        }
        trlGroupRefs.push(trlRef);
    }

    // Create short-lived Matched Member Group
    string|r4:FHIRError matchedGroupRef = persistMatchedMemberGroup(providerIdentifier, matched);
    if matchedGroupRef is r4:FHIRError {
        return matchedGroupRef;
    }

    // Create short-lived No-Match Group (per-member reason extensions)
    string|r4:FHIRError noMatchGroupRef = persistNoMatchGroup(providerIdentifier, noMatched);
    if noMatchGroupRef is r4:FHIRError {
        return noMatchGroupRef;
    }

    // Update persistent system-wide Member Opt-Out Group with constrained members
    string|r4:FHIRError optOutGroupRef = updateOptOutGroup(constrained);
    if optOutGroupRef is r4:FHIRError {
        return optOutGroupRef;
    }

    time:Utc expiresAt = time:utcAddSeconds(time:utcNow(), <decimal>(providerMatchGroupTtlDays * 86400));
    map<json> summary = {
        outcome: "provider-member-match",
        providerIdentifier: providerIdentifier,
        treatmentRecencyMonths: providerMatchTreatmentRecencyMonths,
        groups: {
            treatmentRelationshipGroups: trlGroupRefs,
            matchedMemberGroup: matchedGroupRef,
            noMatchGroup: noMatchGroupRef,
            optOutGroup: optOutGroupRef
        },
        counts: {
            matched: matched.length(),
            noMatch: noMatched.length(),
            consentConstrained: constrained.length()
        },
        matchedGroupExpiresAt: time:utcToString(expiresAt),
        matchedGroupTtlDays: providerMatchGroupTtlDays
    };
    return summary;
}

// ============================================================================
// Treatment Relationship Classification
// ============================================================================

# Classify a single member for a given provider using claims-based evidence.
# Applies recency window (providerMatchTreatmentRecencyMonths) and provider NPI matching.
# + providerIdentifier - Requesting provider identifier
# + memberPatientId - Member patient ID to classify
# + return - Classified provider-member decision
isolated function classifyProviderMember(string providerIdentifier, string memberPatientId) returns ProviderMatchDecision {
    // Verify the patient exists
    r4:DomainResource|r4:FHIRError patient = getById(fhirConnector, PATIENT, memberPatientId);
    if patient is r4:FHIRError {
        return {
            memberPatientId: memberPatientId,
            providerIdentifier: providerIdentifier,
            outcome: PROVIDER_NO_MATCH,
            reason: "patient-not-found",
            memberRef: ()
        };
    }

    // Check opt-out BEFORE treatment relationship (§pdex-247: opt-out takes precedence)
    if isMemberOptedOut(memberPatientId, providerIdentifier) {
        return {
            memberPatientId: memberPatientId,
            providerIdentifier: providerIdentifier,
            outcome: PROVIDER_CONSENT_CONSTRAINED,
            reason: "member-opted-out",
            memberRef: ()
        };
    }

    // Claims-based treatment relationship detection with recency window.
    // service-date is not a supported search parameter on this server, so we fetch all claims
    // for the patient and apply the recency cutoff in-memory by inspecting item[].servicedDate/Period.
    string cutoffDate = getRecencyCutoffDate(providerMatchTreatmentRecencyMonths);
    // HAPI requires the type-qualified reference "Patient/{id}" — bare id returns all claims
    map<string[]> claimParams = {
        "patient": ["Patient/" + memberPatientId]
    };
    r4:Bundle|r4:FHIRError claims = search(fhirConnector, CLAIM, claimParams);
    if claims is r4:FHIRError {
        return {
            memberPatientId: memberPatientId,
            providerIdentifier: providerIdentifier,
            outcome: PROVIDER_NO_MATCH,
            reason: "claim-search-failed",
            memberRef: ()
        };
    }

    r4:BundleEntry[] claimEntries = claims.entry ?: [];
    if claimEntries.length() == 0 {
        return {
            memberPatientId: memberPatientId,
            providerIdentifier: providerIdentifier,
            outcome: PROVIDER_NO_MATCH,
            reason: "no-treatment-relationship",
            memberRef: ()
        };
    }

    // Verify that at least one claim (within the recency window) has the requesting provider as rendering provider
    // (Claim.careTeam[role=rendering].provider NPI must match providerIdentifier)
    boolean npiMatched = claimHasRenderingProvider(claimEntries, providerIdentifier, cutoffDate);
    if !npiMatched {
        return {
            memberPatientId: memberPatientId,
            providerIdentifier: providerIdentifier,
            outcome: PROVIDER_NO_MATCH,
            reason: "no-treatment-relationship-with-provider",
            memberRef: ()
        };
    }

    return {
        memberPatientId: memberPatientId,
        providerIdentifier: providerIdentifier,
        outcome: PROVIDER_MATCHED,
        reason: "matched",
        memberRef: {reference: "Patient/" + memberPatientId}
    };
}

# Compute the ISO-8601 date string for the recency cutoff (N months ago).
# + months - Number of months to subtract from current UTC time
# + return - Cutoff date string in YYYY-MM-DD format
isolated function getRecencyCutoffDate(int months) returns string {
    time:Utc now = time:utcNow();
    // Approximate months as 30 days each for simplicity
    decimal secondsBack = <decimal>(months * 30 * 86400);
    time:Utc cutoff = time:utcAddSeconds(now, -secondsBack);
    // utcToString returns RFC 3339; truncate to date part (first 10 chars)
    string fullTs = time:utcToString(cutoff);
    if fullTs.length() >= 10 {
        return fullTs.substring(0, 10);
    }
    return fullTs;
}

# Check whether any claim entry has the given NPI as the rendering care-team provider,
# filtering in-memory to only claims with a service date >= cutoffDate.
# Parses `Claim.careTeam[].role.coding[].code == "rendering"` and
# `Claim.careTeam[].provider.identifier.value == providerIdentifier`.
# Also checks `Claim.item[].servicedDate` or `Claim.item[].servicedPeriod.start` against cutoffDate.
# + claimEntries - Claim bundle entries to evaluate
# + providerNpi - Provider identifier (NPI) to match
# + cutoffDate - ISO-8601 date string (YYYY-MM-DD); claims must have at least one item on/after this date
# + return - True if a rendering care-team provider match exists within the recency window
isolated function claimHasRenderingProvider(r4:BundleEntry[] claimEntries, string providerNpi, string cutoffDate) returns boolean {
    foreach r4:BundleEntry entry in claimEntries {
        json|error entryJson = entry.toJson();
        if entryJson is error {
            continue;
        }
        map<json> entryMap = <map<json>>entryJson;
        json? resourceJson = entryMap["resource"];
        if resourceJson is () {
            continue;
        }
        international401:Claim|error claim = resourceJson.cloneWithType(international401:Claim);
        if claim is error {
            continue;
        }

        // In-memory recency check: at least one item must have servicedDate >= cutoffDate
        boolean withinWindow = false;
        international401:ClaimItem[] items = claim.item ?: [];
        foreach international401:ClaimItem item in items {
            string? servicedDate = item.servicedDate;
            if servicedDate is string && servicedDate >= cutoffDate {
                withinWindow = true;
                break;
            }
            // Also check servicedPeriod.start
            r4:Period? servicedPeriod = item.servicedPeriod;
            if servicedPeriod is r4:Period {
                string? periodStart = servicedPeriod.'start;
                if periodStart is string && periodStart.length() >= 10
                        && periodStart.substring(0, 10) >= cutoffDate {
                    withinWindow = true;
                    break;
                }
            }
        }
        // If claim has no items, fall back to claim.created as a proxy for service date
        if !withinWindow && items.length() == 0 {
            string? created = claim.created;
            if created is string && created.length() >= 10 && created.substring(0, 10) >= cutoffDate {
                withinWindow = true;
            }
        }
        if !withinWindow {
            continue;
        }

        international401:ClaimCareTeam[] careTeamEntries = claim.careTeam ?: [];
        foreach international401:ClaimCareTeam ctEntry in careTeamEntries {
            r4:CodeableConcept? role = ctEntry.role;
            if role is () {
                continue;
            }
            r4:Coding[] roleCodings = role.coding ?: [];
            boolean isRendering = false;
            foreach r4:Coding coding in roleCodings {
                if coding.code is string && coding.code == "rendering" {
                    isRendering = true;
                }
            }
            if !isRendering {
                continue;
            }

            r4:Reference? provider = ctEntry.provider;
            if provider is () {
                continue;
            }

            // Try provider.identifier.value first
            r4:Identifier? providerIdentifier = provider.identifier;
            if providerIdentifier is r4:Identifier
                && providerIdentifier.value is string
                && providerIdentifier.value == providerNpi {
                return true;
            }

            // Fallback: provider.reference may contain the NPI.
            string? providerRef = provider.reference;
            if providerRef is string && (providerRef.endsWith(providerNpi) || providerRef.includes(providerNpi)) {
                return true;
            }
        }
    }
    return false;
}

// ============================================================================
// Opt-Out Checking
// ============================================================================

# Check whether a member has opted out for the given provider (any applicable scope).
# Prefers a targeted server search: `GET /Group?member=Patient/{id}&code=consentconstraint`
# (PDex `PdexMultiMemberMatchResultCS#consentconstraint`), which returns opt-out Groups that list
# that member. Opt-out scope is read from `Group.characteristic[]` only (`valueCodeableConcept` /
# opt-out-scope CodeSystem; for `provider-specific`, optional `characteristic.extension` with
# `opt-out-scope-detail`). If search fails, falls back to an in-memory scan of Group resources.
# + memberPatientId - Member patient ID
# + providerIdentifier - Requesting provider identifier
# + return - True if the member is opted out for this provider context
isolated function isMemberOptedOut(string memberPatientId, string providerIdentifier) returns boolean {
    string patientRef = "Patient/" + memberPatientId;
    map<string[]> targetedParams = {
        "member": [patientRef],
        "code": [PDEX_CONSENT_CONSTRAINT_CODE],
        "_count": ["100"]
    };
    r4:Bundle|r4:FHIRError targeted = search(fhirConnector, GROUP, targetedParams);
    r4:BundleEntry[] entries = [];
    if targeted is r4:Bundle {
        r4:BundleEntry[]? te = targeted.entry;
        if te is r4:BundleEntry[] {
            entries = te;
        }
    } else {
        return isMemberOptedOutFullScan(memberPatientId, providerIdentifier);
    }

    // Some servers only resolve Group.code when given a token parameter system|code (FHIR R4).
    if entries.length() == 0 {
        targetedParams = {
            "member": [patientRef],
            "code": [PDEX_MULTI_MEMBER_MATCH_RESULT_CS + "|" + PDEX_CONSENT_CONSTRAINT_CODE],
            "_count": ["100"]
        };
        r4:Bundle|r4:FHIRError targeted2 = search(fhirConnector, GROUP, targetedParams);
        if targeted2 is r4:Bundle {
            r4:BundleEntry[]? te2 = targeted2.entry;
            if te2 is r4:BundleEntry[] {
                entries = te2;
            }
        }
    }

    foreach r4:BundleEntry entry in entries {
        json|error entryJson = entry.toJson();
        if entryJson is error {
            continue;
        }
        map<json> entryJsonMap = <map<json>>entryJson;
        json? resourceJson = entryJsonMap["resource"];
        if resourceJson !is map<json> {
            continue;
        }
        international401:Group|error typedGroup = (<map<json>>resourceJson).cloneWithType(international401:Group);
        if typedGroup is error {
            continue;
        }
        if memberOptedOutInGroup(typedGroup, memberPatientId, providerIdentifier) {
            return true;
        }
    }

    if entries.length() == 0 {
        return isMemberOptedOutFullScan(memberPatientId, providerIdentifier);
    }
    return false;
}

# Evaluate opt-out for one Group: IG Member Opt-Out profile or `Group.code` with
# PdexMultiMemberMatchResultCS `consentconstraint`; member must appear in `member`.
# Opt-out **scope**: prefer `extension` **`opt-out-scope`** `valueCode` on the **matched member** row
# (`member.extension` / `member.entity.extension`) so `global` vs `provider-specific` can differ per member
# when the group only has a default in `characteristic.valueCodeableConcept` (often `provider-specific`).
# If the member has no scope extension, fall back to `Group.characteristic[].valueCodeableConcept`.
# **Provider-specific** NPI: `opt-out-scope-detail` on `characteristic.extension` first, else on the member row.
# + grp - Group resource
# + memberPatientId - Member patient logical id
# + providerIdentifier - Requesting provider identifier (e.g. US NPI)
# + return - True if this group opts the member out for this provider context
isolated function memberOptedOutInGroup(international401:Group grp, string memberPatientId, string providerIdentifier) returns boolean {
    if !isMemberOptOutOrConsentConstraintGroup(grp) {
        return false;
    }

    international401:GroupMember[]? membersVal = grp.member;
    if membersVal is () {
        return false;
    }
    international401:GroupMember? matchedMember = ();
    foreach international401:GroupMember memberEntry in membersVal {
        r4:Reference entity = memberEntry.entity;
        string? ref = entity.reference;
        if ref is string && patientReferenceMatchesMember(ref, memberPatientId) {
            matchedMember = memberEntry;
            break;
        }
    }
    if matchedMember is () {
        return false;
    }
    international401:GroupMember memberForDetail = matchedMember;

    string? memberScope = extractOptOutScopeCodeFromGroupMember(memberForDetail);
    string? groupScope = extractOptOutScopeFromGroupCharacteristics(grp);
    string? optOutScope = memberScope is string ? memberScope : groupScope;
    if optOutScope is () {
        return false;
    }

    if optOutScope == OPT_OUT_SCOPE_GLOBAL {
        return true;
    }
    if optOutScope == OPT_OUT_SCOPE_PROVIDER_SPECIFIC {
        string? scopeDetailRef = extractOptOutScopeDetailRefFromGroupCharacteristics(grp);
        if scopeDetailRef is () || scopeDetailRef == "" {
            scopeDetailRef = extractOptOutScopeDetailRefFromGroupMember(memberForDetail);
        }
        if scopeDetailRef is () {
            return false;
        }
        string detail = scopeDetailRef;
        if detail == "" {
            return false;
        }
        return detail.endsWith(providerIdentifier) || detail.includes(providerIdentifier);
    }
    if optOutScope == OPT_OUT_SCOPE_PURPOSE_SPECIFIC
            || optOutScope == OPT_OUT_SCOPE_PAYER_SPECIFIC
            || optOutScope == OPT_OUT_SCOPE_PROVIDER_CATEGORY {
        return true;
    }
    return false;
}

# Fallback when `Group?member=&code=` search is unsupported or returns no Bundle entries incorrectly.
# + memberPatientId - Member patient ID
# + providerIdentifier - Requesting provider identifier
# + return - True if opted out for this provider context
isolated function isMemberOptedOutFullScan(string memberPatientId, string providerIdentifier) returns boolean {
    r4:Bundle|r4:FHIRError groups = search(fhirConnector, GROUP, {"_count": ["500"]});
    if groups is r4:FHIRError {
        return false;
    }
    r4:BundleEntry[] entries = groups.entry ?: [];
    foreach r4:BundleEntry entry in entries {
        json|error entryJson = entry.toJson();
        if entryJson is error {
            continue;
        }
        map<json> entryJsonMap = <map<json>>entryJson;
        json? resourceJson = entryJsonMap["resource"];
        if resourceJson !is map<json> {
            continue;
        }
        international401:Group|error typedGroup = (<map<json>>resourceJson).cloneWithType(international401:Group);
        if typedGroup is error {
            continue;
        }
        if memberOptedOutInGroup(typedGroup, memberPatientId, providerIdentifier) {
            return true;
        }
    }
    return false;
}

# True if meta.profile declares Member Opt-Out Group (either canonical name).
# + grp - Group resource
# + return - True if this is an opt-out group profile
isolated function isMemberOptOutGroupProfile(international401:Group grp) returns boolean {
    return groupResourceHasProfile(grp, PROVIDER_ACCESS_OPT_OUT_GROUP_PROFILE)
        || groupResourceHasProfile(grp, PROVIDER_ACCESS_OPT_OUT_GROUP_PROFILE_PDEX);
}

# True if Member Opt-Out profile **or** `Group.code` marks a consent-constrained (opt-out) group (PDex CS).
# + grp - Group resource
# + return - True if this group is an opt-out / consent-constraint group by profile or code
isolated function isMemberOptOutOrConsentConstraintGroup(international401:Group grp) returns boolean {
    if isMemberOptOutGroupProfile(grp) {
        return true;
    }
    r4:CodeableConcept? codeVal = grp.code;
    if codeVal is () {
        return false;
    }
    r4:Coding[]? codingArr = codeVal.coding;
    if codingArr is () {
        return false;
    }
    foreach r4:Coding c in codingArr {
        string? sys = c.system;
        string? code = c.code;
        if sys is string && code is string
                && sys == PDEX_MULTI_MEMBER_MATCH_RESULT_CS && code == PDEX_CONSENT_CONSTRAINT_CODE {
            return true;
        }
    }
    return false;
}

# Match Patient reference to logical member id (supports `Patient/{id}` or `{id}`).
# + reference - FHIR Reference string
# + memberPatientId - Expected patient logical id
# + return - True if reference identifies this patient
isolated function patientReferenceMatchesMember(string reference, string memberPatientId) returns boolean {
    if reference == "Patient/" + memberPatientId {
        return true;
    }
    if !reference.includes("/") && reference == memberPatientId {
        return true;
    }
    return false;
}

# Read opt-out scope from `Group.characteristic[].valueCodeableConcept.coding` (IG: CodeSystem opt-out-scope).
# Each characteristic also carries `characteristic.code` (= consentconstraint); scope is in **valueCodeableConcept**, not `Group.code`.
# Accepts missing or variant `system` when `code` is a known opt-out-scope token (some stores omit system).
# + grp - Group resource
# + return - Scope code if found, else ()
isolated function extractOptOutScopeFromGroupCharacteristics(international401:Group grp) returns string? {
    international401:GroupCharacteristic[]? chars = grp.characteristic;
    if chars is () {
        return ();
    }
    foreach international401:GroupCharacteristic ch in chars {
        r4:CodeableConcept? vcc = ch.valueCodeableConcept;
        if vcc is () {
            continue;
        }
        r4:Coding[]? codingArr = vcc.coding;
        if codingArr is () {
            continue;
        }
        foreach r4:Coding coding in codingArr {
            string? code = coding.code;
            if code is () {
                continue;
            }
            string scopeCode = code;
            if scopeCode == OPT_OUT_SCOPE_GLOBAL || scopeCode == OPT_OUT_SCOPE_PROVIDER_SPECIFIC
                    || scopeCode == OPT_OUT_SCOPE_PURPOSE_SPECIFIC || scopeCode == OPT_OUT_SCOPE_PAYER_SPECIFIC
                    || scopeCode == OPT_OUT_SCOPE_PROVIDER_CATEGORY {
                string? sys = coding.system;
                if sys is string {
                    if sys == OPT_OUT_SCOPE_CODE_SYSTEM || sys.includes("opt-out-scope") {
                        return scopeCode;
                    }
                }
                // Known scope token without usable system (persisted JSON from some clients)
                return scopeCode;
            }
        }
    }
    return ();
}

# Optional practitioner (or other) reference on `Group.characteristic[].extension` for provider-specific opt-outs.
# + grp - Group resource
# + return - Reference string if an `opt-out-scope-detail` extension is present, else ()
isolated function extractOptOutScopeDetailRefFromGroupCharacteristics(international401:Group grp) returns string? {
    international401:GroupCharacteristic[]? chars = grp.characteristic;
    if chars is () {
        return ();
    }
    foreach international401:GroupCharacteristic ch in chars {
        r4:Extension[]? extArr = ch.extension;
        if extArr is () {
            continue;
        }
        foreach r4:Extension ext in extArr {
            if ext.url == PROVIDER_ACCESS_EXT_OPT_OUT_SCOPE_DETAIL && ext is r4:ReferenceExtension {
                r4:Reference? valRef = ext.valueReference;
                if valRef is r4:Reference {
                    return valRef.reference;
                }
            }
        }
    }
    return ();
}

# `opt-out-scope` as `valueCode` on the matched member row (`member.extension` / `member.entity.extension`).
# + memberEntry - Group.member entry
# + return - Scope code (e.g. global, provider-specific) if present
isolated function extractOptOutScopeCodeFromGroupMember(international401:GroupMember memberEntry) returns string? {
    r4:Extension[] combinedExt = [];
    r4:Extension[]? memberExt = memberEntry.extension;
    if memberExt is r4:Extension[] {
        foreach r4:Extension x in memberExt {
            combinedExt.push(x);
        }
    }
    r4:Extension[]? entityExt = memberEntry.entity.extension;
    if entityExt is r4:Extension[] {
        foreach r4:Extension x in entityExt {
            combinedExt.push(x);
        }
    }
    foreach r4:Extension ext in combinedExt {
        if ext.url == PROVIDER_ACCESS_EXT_OPT_OUT_SCOPE && ext is r4:CodeExtension {
            r4:code? val = ext.valueCode;
            if val is string {
                return val;
            }
        }
    }
    return ();
}

# `opt-out-scope-detail` on the matched member row (payloads often put this on `member` / `member.entity`, not on characteristic).
# + memberEntry - Group.member entry
# + return - Inner reference string if present
isolated function extractOptOutScopeDetailRefFromGroupMember(international401:GroupMember memberEntry) returns string? {
    r4:Extension[] combinedExt = [];
    r4:Extension[]? memberExt = memberEntry.extension;
    if memberExt is r4:Extension[] {
        foreach r4:Extension x in memberExt {
            combinedExt.push(x);
        }
    }
    r4:Extension[]? entityExt = memberEntry.entity.extension;
    if entityExt is r4:Extension[] {
        foreach r4:Extension x in entityExt {
            combinedExt.push(x);
        }
    }
    foreach r4:Extension ext in combinedExt {
        if ext.url == PROVIDER_ACCESS_EXT_OPT_OUT_SCOPE_DETAIL && ext is r4:ReferenceExtension {
            r4:Reference? valRef = ext.valueReference;
            if valRef is r4:Reference {
                return valRef.reference;
            }
        }
    }
    return ();
}

# Helper — check if a Group has a given profile URL in meta.profile.
# + grp - Group resource
# + profileUrl - Canonical profile URL to check
# + return - True if profile is present in meta.profile
isolated function groupResourceHasProfile(international401:Group grp, string profileUrl) returns boolean {
    r4:Meta? meta = grp.meta;
    if meta is () {
        return false;
    }
    r4:canonical[]? profileVal = meta.profile;
    if profileVal is () {
        return false;
    }
    foreach r4:canonical p in profileVal {
        if p == profileUrl {
            return true;
        }
    }
    return false;
}

// ============================================================================
// Group Persistence Helpers
// ============================================================================

# Persist a Member-Provider Treatment Relationship Group for one member (v2 inverted model).
# Structure: type=practitioner, characteristic=member (Patient), members=providers (Practitioner).
# §pdex v2: one TRL group per member listing all their treatment providers.
# + memberPatientId - Member patient ID represented by the TRL group
# + providerIdentifier - Provider identifier to include as a group member
# + return - Created Group reference (`Group/<id>`) or FHIRError
isolated function persistTrlGroup(string memberPatientId, string providerIdentifier) returns string|r4:FHIRError {
    // Resolve providerIdentifier (NPI) to an actual Practitioner resource ID via search; never
    // synthesize Practitioner/{npi} — if unresolved, carry NPI on Reference.identifier (US NPI system).
    r4:Reference practitionerEntity = {
        identifier: {
            system: "http://hl7.org/fhir/sid/us-npi",
            value: providerIdentifier
        }
    };
    r4:Bundle|r4:FHIRError practSearchResult = search(fhirConnector, PRACTITIONER, {"identifier": [providerIdentifier]});
    if practSearchResult is r4:Bundle {
        r4:BundleEntry[] practEntries = practSearchResult.entry ?: [];
        if practEntries.length() > 0 {
            json|error practEntryJson = practEntries[0].toJson();
            if practEntryJson is json {
                json|error practIdJson = practEntryJson.'resource.id;
                if practIdJson is string {
                    practitionerEntity = {reference: "Practitioner/" + practIdJson};
                }
            }
        }
    }

    // Build TRL group: member (Patient) is the characteristic key; provider is a group member entry
    r4:Extension[] memberEntryExtensions = [
        {url: PROVIDER_ACCESS_EXT_RELATIONSHIP_TYPE, valueCode: "rendering-provider"},
        {url: PROVIDER_ACCESS_EXT_ATTESTATION_DATE, valueDateTime: time:utcToString(time:utcNow())},
        {url: PROVIDER_ACCESS_EXT_TREATMENT_PERIOD_START, valueDate: getRecencyCutoffDate(0)}
    ];

    international401:GroupMember practitionerMember = {
        entity: practitionerEntity,
        extension: memberEntryExtensions
    };

    international401:Group trlGroup = {
        'type: "practitioner",
        actual: true,
        meta: {profile: [PROVIDER_ACCESS_TRL_GROUP_PROFILE]},
        extension: [
            {
                url: PROVIDER_ACCESS_EXT_ATR_LIST_STATUS,
                valueCode: "open"
            }
        ],
        characteristic: [
            {
                code: {coding: [{code: "member", display: "Member (Patient)"}]},
                valueReference: {reference: "Patient/" + memberPatientId},
                exclude: false,
                period: {
                    'start: getRecencyCutoffDate(0)
                }
            }
        ],
        member: [practitionerMember]
    };

    return createGroupResource(trlGroup);
}

# Create the short-lived Matched Member Group.
# Contains all successfully matched Patient references. Expiry set via valueDateTime extension.
# + providerIdentifier - Requesting provider identifier
# + matched - Matched member decisions
# + return - Created Group reference (`Group/<id>`) or FHIRError
isolated function persistMatchedMemberGroup(string providerIdentifier, ProviderMatchDecision[] matched) returns string|r4:FHIRError {
    international401:GroupMember[] members = [];
    foreach ProviderMatchDecision decision in matched {
        members.push({entity: {reference: "Patient/" + decision.memberPatientId}});
    }

    // Calculate expiry as a proper dateTime (RFC 3339 / ISO 8601)
    time:Utc expiresAt = time:utcAddSeconds(time:utcNow(), <decimal>(providerMatchGroupTtlDays * 86400));
    string expiryDateTime = time:utcToString(expiresAt);

    international401:Group matchedGroup = {
        'type: "person",
        actual: true,
        meta: {profile: [PROVIDER_ACCESS_MATCHED_GROUP_PROFILE]},
        extension: [
            {
                url: PROVIDER_ACCESS_EXT_PROVIDER_ID,
                valueString: providerIdentifier
            },
            {
                // matchedGroupExpiry — use valueDateTime per plan §6.3
                url: PROVIDER_ACCESS_EXT_EXPIRES_AT,
                valueDateTime: expiryDateTime
            },
            {
                url: PROVIDER_ACCESS_EXT_ATR_LIST_STATUS,
                valueCode: "open"
            }
        ],
        member: members
    };

    return createGroupResource(matchedGroup);
}

# Create the short-lived PDex Member No-Match Group.
# Each failed member gets a per-member `noMatchReason` extension on their entry (§6.4).
# + providerIdentifier - Requesting provider identifier
# + noMatched - No-match member decisions
# + return - Created Group reference (`Group/<id>`) or FHIRError
isolated function persistNoMatchGroup(string providerIdentifier, ProviderMatchDecision[] noMatched) returns string|r4:FHIRError {
    international401:GroupMember[] members = [];
    foreach ProviderMatchDecision decision in noMatched {
        // Per-member extension: noMatchReason on each member entry
        international401:GroupMember memberEntry = {
            entity: {reference: "Patient/" + decision.memberPatientId},
            extension: [
                {
                    url: PROVIDER_ACCESS_EXT_NO_MATCH_REASON,
                    valueCode: decision.reason
                }
            ]
        };
        members.push(memberEntry);
    }

    international401:Group noMatchGroup = {
        'type: "person",
        actual: true,
        meta: {profile: [PROVIDER_ACCESS_NO_MATCH_GROUP_PROFILE]},
        extension: [
            {
                url: PROVIDER_ACCESS_EXT_PROVIDER_ID,
                valueString: providerIdentifier
            }
        ],
        member: members
    };

    return createGroupResource(noMatchGroup);
}

# Update the single persistent system-wide Member Opt-Out Group.
# Looks up an existing opt-out group; if none exists, creates one.
# Adds constrained member entries with per-member opt-out scope extensions (§6.2).
# Returns the Group reference (Group/<id>).
# + constrained - Consent-constrained member decisions
# + return - Updated Group reference (`Group/<id>`) or FHIRError
isolated function updateOptOutGroup(ProviderMatchDecision[] constrained) returns string|r4:FHIRError {
    if constrained.length() == 0 {
        // No opted-out members in this batch; find-or-create the group and return its ref
        return findOrCreateSystemOptOutGroup();
    }

    // Look up existing persistent opt-out group
    string|r4:FHIRError existingRef = findOrCreateSystemOptOutGroup();
    if existingRef is r4:FHIRError {
        return existingRef;
    }

    // Extract group ID from "Group/<id>"
    string groupId = existingRef.substring(6); // strip "Group/"

    // Fetch the current group
    r4:DomainResource|r4:FHIRError grpResource = getById(fhirConnector, GROUP, groupId);
    if grpResource is r4:FHIRError {
        return grpResource;
    }
    international401:Group|error currentGroup = grpResource.cloneWithType(international401:Group);
    if currentGroup is error {
        return r4:createFHIRError(currentGroup.message(), r4:ERROR, r4:PROCESSING,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }

    // Build a set of member IDs already in the group to avoid duplicates
    international401:GroupMember[] existingMembers = currentGroup.member ?: [];
    map<boolean> alreadyPresent = {};
    foreach international401:GroupMember em in existingMembers {
        string? ref = em.entity.reference;
        if ref is string {
            alreadyPresent[ref] = true;
        }
    }

    // Append new constrained members with per-member scope extensions
    international401:GroupMember[] updatedMembers = existingMembers.clone();
    foreach ProviderMatchDecision decision in constrained {
        string memberRef = "Patient/" + decision.memberPatientId;
        if alreadyPresent.hasKey(memberRef) {
            continue; // already opted out — don't duplicate
        }
        updatedMembers.push({
            entity: {reference: memberRef},
            extension: [
                {
                    url: PROVIDER_ACCESS_EXT_OPT_OUT_SCOPE,
                    valueCode: OPT_OUT_SCOPE_PROVIDER_SPECIFIC
                },
                {
                    url: PROVIDER_ACCESS_EXT_OPT_OUT_REASON,
                    valueCode: decision.reason
                },
                {
                    url: PROVIDER_ACCESS_EXT_OPT_OUT_DATE,
                    valueDateTime: time:utcToString(time:utcNow())
                }
            ]
        });
    }

    // Write updated group back
    international401:Group updatedGroup = {
        id: currentGroup.id,
        'type: "person",
        actual: true,
        meta: {profile: [PROVIDER_ACCESS_OPT_OUT_GROUP_PROFILE]},
        member: updatedMembers
    };
    r4:DomainResource|r4:FHIRError updateResult = update(fhirConnector, GROUP, groupId, updatedGroup.toJson());
    if updateResult is r4:FHIRError {
        return updateResult;
    }
    return existingRef;
}

# Find the single persistent system-wide Member Opt-Out Group,
# creating it if it does not exist yet.
# + return - Existing or newly created Group reference (`Group/<id>`) or FHIRError
isolated function findOrCreateSystemOptOutGroup() returns string|r4:FHIRError {
    // Search for existing opt-out group — large _count to avoid pagination misses
    r4:Bundle|r4:FHIRError groups = search(fhirConnector, GROUP, {"_count": ["500"]});
    if groups !is r4:FHIRError {
        r4:BundleEntry[] entries = groups.entry ?: [];
        foreach r4:BundleEntry entry in entries {
            json|error entryJson = entry.toJson();
            if entryJson is error {
                continue;
            }
            map<json> entryMap = <map<json>>entryJson;
            json? resourceJson = entryMap["resource"];
            if resourceJson !is map<json> {
                continue;
            }
            international401:Group|error typedGroup = (<map<json>>resourceJson).cloneWithType(international401:Group);
            if typedGroup is error {
                continue;
            }
            if isMemberOptOutOrConsentConstraintGroup(typedGroup) {
                string? gid = typedGroup.id;
                if gid is string {
                    return "Group/" + gid;
                }
            }
        }
    }

    // Create the persistent opt-out group (initially empty)
    international401:Group optOutGroup = {
        'type: "person",
        actual: true,
        meta: {profile: [PROVIDER_ACCESS_OPT_OUT_GROUP_PROFILE]},
        member: []
    };
    return createGroupResource(optOutGroup);
}

# Create a Group resource via the FHIR connector and return its reference ("Group/<id>").
# + grp - Group resource to create
# + return - Created Group reference (`Group/<id>`) or FHIRError
isolated function createGroupResource(international401:Group grp) returns string|r4:FHIRError {
    // Assign a UUID id if not already set — required when the server has server-generated IDs disabled
    if grp.id is () {
        grp.id = uuid:createType4AsString();
    }
    r4:DomainResource|r4:FHIRError created = create(fhirConnector, GROUP, grp.toJson());
    if created is r4:FHIRError {
        return created;
    }
    international401:Group|error createdGroup = created.cloneWithType(international401:Group);
    if createdGroup is error {
        return r4:createFHIRError(createdGroup.message(), r4:ERROR, r4:PROCESSING,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }
    string? createdId = createdGroup.id;
    if createdId is () {
        return r4:createFHIRError("Created provider access group is missing id", r4:ERROR, r4:PROCESSING,
                httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
    }
    return "Group/" + createdId;
}

# Extract provider-member-match inputs from header and Parameters body.
#
# + fhirContext - Request context used to resolve provider identity headers
# + parameters - Operation input Parameters resource
# + return - Tuple [providerIdentifier, memberPatientIds] or FHIRError
isolated function extractProviderMemberMatchInputs(r4:FHIRContext fhirContext, international401:Parameters parameters)
        returns [string, string[]]|r4:FHIRError {
    string providerIdentifier = "";
    r4:HTTPRequest? req = fhirContext.getHTTPRequest();
    if req !is () {
        // Header names may arrive in original or lowercase — check case-insensitively
        foreach string headerName in req.headers.keys() {
            if headerName.toLowerAscii() == "x-provider-identifier" {
                string[]? vals = req.headers[headerName];
                if vals is string[] && vals.length() > 0 {
                    providerIdentifier = vals[0].trim();
                    break;
                }
            }
        }
    }
    // Also accept providerIdentifier as a body parameter (fallback / alternative transport)
    if providerIdentifier == "" {
        json parametersJsonForProvider = parameters.toJson();
        json[]|error rawParamsForProvider = (parametersJsonForProvider).'parameter.ensureType();
        json[] paramListForProvider = rawParamsForProvider is json[] ? rawParamsForProvider : [];
        foreach json p in paramListForProvider {
            json|error nameVal = p.name;
            if nameVal is string && nameVal == "providerIdentifier" {
                json|error strVal = p.valueString;
                if strVal is string && strVal.trim() != "" {
                    providerIdentifier = strVal.trim();
                    break;
                }
            }
        }
    }
    if providerIdentifier == "" {
        return r4:createFHIRError(PROVIDER_MEMBER_MATCH_MISSING_PROVIDER, r4:ERROR, r4:INVALID,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    string[] memberPatientIds = [];
    // parameters.'parameter may arrive as json[] at runtime — use JSON traversal to avoid TypeCastError
    json parametersJson = parameters.toJson();
    json[]|error rawParams = (parametersJson).'parameter.ensureType();
    json[] paramList = rawParams is json[] ? rawParams : [];
    foreach json p in paramList {
        json|error nameVal = p.name;
        if nameVal is string && nameVal == "member" {
            // Try valueReference.reference first
            json|error refVal = p.valueReference.reference;
            if refVal is string && refVal.trim() != "" {
                string ref = refVal.trim();
                if ref.startsWith("Patient/") {
                    memberPatientIds.push(ref.substring(8));
                } else {
                    memberPatientIds.push(ref);
                }
            } else {
                // Fall back to valueString
                json|error strVal = p.valueString;
                if strVal is string && strVal.trim() != "" {
                    string val = strVal.trim();
                    if val.startsWith("Patient/") {
                        memberPatientIds.push(val.substring(8));
                    } else {
                        memberPatientIds.push(val);
                    }
                }
            }
        }
    }
    if memberPatientIds.length() == 0 {
        return r4:createFHIRError(PROVIDER_MEMBER_MATCH_NO_MEMBERS, r4:ERROR, r4:INVALID,
                httpStatusCode = http:STATUS_BAD_REQUEST);
    }
    return [providerIdentifier, memberPatientIds];
}

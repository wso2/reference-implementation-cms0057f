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

import ballerina/lang.regexp;
import ballerina/time;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;

// -----------------------------------------------------------------------------
// Models
// -----------------------------------------------------------------------------

public type Indicator "info"|"warning"|"critical";

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

// -----------------------------------------------------------------------------
// Entry point
// -----------------------------------------------------------------------------

# Evaluates whether prior authorization is required for a Spine MRI order and
# returns a structured decision.
#
# The input bundle is expected to include (at minimum):
# - ServiceRequest (draft order)
# - Patient
# Optionally:
# - Encounter
# - Condition(s)
# - Observation(s)
# - DiagnosticReport(s) for prior imaging
# - MedicationRequest(s), Procedure(s), DocumentReference(s)
#
# + bundle - Input FHIR bundle containing relevant resources  
# + hookId - Hook Id
# + return - PriorAuthDecision or error if mandatory data is missing/invalid
public isolated function decidePriorAuth(r4:Bundle bundle, string hookId) returns PriorAuthDecision|error {
    // 1) Extract key resources
    international401:ServiceRequest|error sr = getFirstServiceRequest(bundle);
    if sr is error {
        return sr;
    }

    international401:Encounter? enc = check getEncounterFromBundle(bundle, sr);
    international401:Condition[] conditions = check getAllConditions(bundle);
    international401:Observation[] observations = check getAllObservations(bundle);
    international401:DiagnosticReport[] diagnosticReports = check getAllDiagnosticReports(bundle);

    // 2) Only apply these rules to Spine MRI orders.
    boolean isSpineMri = isSpineMriOrder(sr);
    if !isSpineMri {
        return {
            priorAuthRequired: false,
            summary: "Not applicable: order is not MRI Spine.",
            reasons: ["ServiceRequest is not a recognized MRI Spine order (CPT 72148/72149/72158)."],
            medicalNecessity: "INSUFFICIENT_DATA",
            missingDocumentation: []
        };
    }

    // 3) Check exemption conditions (Emergency / red flags).
    string[] reasons = [];
    string[] missingDocs = [];

    if isEmergencyEncounter(enc) {
        reasons.push("Emergency encounter → prior auth not required.");
        return {
            priorAuthRequired: false,
            summary: "Prior auth not required due to emergency encounter.",
            reasons: reasons,
            medicalNecessity: "INSUFFICIENT_DATA",
            missingDocumentation: []
        };
    }

    if hasRedFlagClinicalIndicators(conditions, observations) {
        reasons.push("Red-flag clinical indicators present (e.g., progressive neuro deficit / cauda equina / malignancy / infection suspicion).");
        return {
            priorAuthRequired: false,
            summary: "Prior auth not required due to red-flag clinical indicators.",
            reasons: reasons,
            medicalNecessity: "INSUFFICIENT_DATA",
            missingDocumentation: []
        };
    }

    // 4) Frequency / repeat imaging rule (example).
    if isRepeatImagingWithinMonths(diagnosticReports, 6) {
        reasons.push("Repeat MRI spine within last 6 months → prior auth required.");
        // Still compute medical necessity & missing docs to help payer submission.
        MedicalNecessityStatus mns = evaluateMedicalNecessity(sr, conditions, observations, bundle, missingDocs);
        return {
            priorAuthRequired: true,
            summary: "Prior auth required (repeat MRI within frequency limit).",
            reasons: reasons,
            medicalNecessity: mns,
            missingDocumentation: missingDocs
        };
    }

    // 5) Default policy: outpatient MRI spine typically requires prior auth.
    reasons.push("Outpatient MRI spine is prior-auth-managed by default policy.");

    MedicalNecessityStatus medicalNecessity = evaluateMedicalNecessity(sr, conditions, observations, bundle, missingDocs);

    return {
        priorAuthRequired: true,
        summary: "Prior auth required for MRI spine.",
        reasons: reasons,
        medicalNecessity: medicalNecessity,
        missingDocumentation: missingDocs,
        links: prepareTheLinks(hookId)
    };
}

# Evaluates whether prior authorization is required for a Medication Request.
#
# + bundle - Input FHIR bundle containing relevant resources
# + return - PriorAuthDecision or error
public isolated function decidePrescriptionPriorAuth(r4:Bundle bundle) returns PriorAuthDecision|error {
    // 1) Extract MedicationRequest
    boolean hasMedicationRequest = false;
    r4:BundleEntry[]? entries = bundle.entry;
    if entries is r4:BundleEntry[] {
        foreach r4:BundleEntry entry in entries {
            anydata res = entry?.'resource;
            if res is map<json> {
                if res["resourceType"] == "MedicationRequest" {
                    hasMedicationRequest = true;
                }
            } else {
                r4:DomainResource|error domainRes = res.cloneWithType(r4:DomainResource);
                if domainRes is r4:DomainResource && domainRes.resourceType == "MedicationRequest" {
                    hasMedicationRequest = true;
                }
            }
        }
    }

    if !hasMedicationRequest {
        return {
            priorAuthRequired: false,
            summary: "No MedicationRequest found.",
            reasons: [],
            medicalNecessity: "INSUFFICIENT_DATA",
            missingDocumentation: []
        };
    }

    // 2) Always require PA for this demo flow
    return {
        priorAuthRequired: true,
        summary: "Prior Authorization Required",
        reasons: ["This medication (Aimovig) requires prior authorization from UnitedCare Health Insurance. Please complete the required documentation."],
        medicalNecessity: "INSUFFICIENT_DATA", // Not evaluating medical necessity for meds in this demo
        missingDocumentation: []
    };
}

isolated function prepareTheLinks(string hookId) returns PriorAuthLink[]? {

    if hook_id_questionnaire_id_map.hasKey(hookId) {
        string questionnaireResourceId = hook_id_questionnaire_id_map.get(hookId);
        string questionnaireResourceUrl = string `https://${fhir_server_url}/Questionnaire/${questionnaireResourceId}`;

        return [
            {
                label: "Questionnaire url",
                url: questionnaireResourceUrl
            }
        ];
    } else {
        return ();
    }

}

// -----------------------------------------------------------------------------
// Medical necessity logic (example heuristics)
// -----------------------------------------------------------------------------

# Evaluates medical necessity using simple guideline-style checks.
# This does NOT approve/deny; it indicates MET/NOT_MET/INSUFFICIENT_DATA and
# collects missing documentation items.
#
# + sr - ServiceRequest
# + conditions - conditions from bundle
# + observations - observations from bundle
# + bundle - full bundle (optional to inspect meds/procedures/docs)
# + missingDocs - (in/out) list that gets appended with missing documentation
# + return - medical necessity status
isolated function evaluateMedicalNecessity(
        international401:ServiceRequest sr,
        international401:Condition[] conditions,
        international401:Observation[] observations,
        r4:Bundle bundle,
        string[] missingDocs
) returns MedicalNecessityStatus {

    // 1) Need a reason/diagnosis
    if !hasAnyDiagnosis(sr, conditions) {
        missingDocs.push("Diagnosis / reason for MRI (e.g., radiculopathy, neuro deficit, trauma, malignancy suspicion).");
        // keep checking other items but likely insufficient
    }

    // 2) Check for objective neuro findings
    boolean hasObjectiveNeuro = hasObjectiveNeuroFindings(observations);
    if !hasObjectiveNeuro {
        missingDocs.push("Objective neurological findings (motor weakness, sensory loss, reflex changes, positive SLR, etc.).");
    }

    // 3) Conservative management documentation (PT/NSAIDs etc.)
    boolean hasConservativeCare = hasConservativeManagementEvidence(bundle);
    if !hasConservativeCare {
        missingDocs.push("Conservative management evidence (PT dates, medications, home exercise, response) typically ~6 weeks unless red flags.");
    }

    // 4) Duration of symptoms (use Condition.onsetDateTime if available)
    int? symptomDays = estimateSymptomDurationDays(conditions);
    if symptomDays is () {
        missingDocs.push("Symptom duration (onset date or documented duration).");
    }

    // Rule-of-thumb decision:
    // - MET: objective neuro + conservative care + duration >= 42 days OR strong diagnosis that warrants imaging
    // - NOT_MET: duration < 42 days and no red flags and no objective neuro and no conservative care
    // - INSUFFICIENT_DATA: missing key details
    boolean hasEnoughForDecision = (symptomDays is int) || hasConservativeCare || hasObjectiveNeuro;

    if !hasEnoughForDecision {
        return "INSUFFICIENT_DATA";
    }

    if (symptomDays is int) && symptomDays < 42 && !hasObjectiveNeuro && !hasConservativeCare {
        return "NOT_MET";
    }

    if hasObjectiveNeuro && hasConservativeCare {
        if (symptomDays is int) {
            if symptomDays >= 42 {
                return "MET";
            }
            // Even if < 42, objective neuro + attempted care can be considered close;
            // keep as insufficient to avoid false "MET".
            return "INSUFFICIENT_DATA";
        }
        return "INSUFFICIENT_DATA";
    }

    // If we got some data but not enough to confidently say MET
    return "INSUFFICIENT_DATA";
}

// -----------------------------------------------------------------------------
// Order classification
// -----------------------------------------------------------------------------

// Recognize MRI Spine by CPT codes (examples).
// 72148 MRI lumbar spine w/o contrast
// 72149 MRI lumbar spine w/ contrast
// 72158 MRI lumbar spine w/ & w/o contrast
isolated function isSpineMriOrder(international401:ServiceRequest sr) returns boolean {
    string[] mriSpineCpt = ["72148", "72149", "72158"];

    // sr.code.coding may have many codings; match by system + code
    r4:CodeableConcept? cc = sr.code;
    if cc is () {
        return false;
    }
    r4:Coding[]? codings = cc.coding;
    if codings is () {
        return false;
    }

    foreach r4:Coding c in codings {
        string? code = c.code;
        if code is string && contains(mriSpineCpt, code) {
            return true;
        }
    }

    // Fallback: match text contains "MRI" and "spine"
    string? text = cc.text;
    if text is string {
        string t = text.toLowerAscii();
        if t.includes("mri") && t.includes("spine") {
            return true;
        }
        if t.includes("mri") && t.includes("lumbar") {
            return true;
        }
        if t.includes("mri") && t.includes("cervical") {
            return true;
        }
        if t.includes("mri") && t.includes("thoracic") {
            return true;
        }
    }
    return false;
}

isolated function contains(string[] list, string v) returns boolean {
    foreach string s in list {
        if s == v {
            return true;
        }
    }
    return false;
}

// -----------------------------------------------------------------------------
// Exemptions / red flags
// -----------------------------------------------------------------------------

isolated function isEmergencyEncounter(international401:Encounter? enc) returns boolean {
    if enc is () {
        return false;
    }
    // Example: enc.class.code == "EMER" or enc.priority indicates emergency
    r4:Coding? cls = (<international401:Encounter>enc).'class;
    if cls is r4:Coding {
        string? code = cls.code;
        if code is string && code == "EMER" {
            return true;
        }
    }
    return false;
}

isolated function hasRedFlagClinicalIndicators(international401:Condition[] conditions, international401:Observation[] observations) returns boolean {
    // Very simplified “red flags” example:
    // - suspected malignancy
    // - infection
    // - cauda equina symptoms
    // - progressive neuro deficit (if explicitly noted)
    if hasConditionCode(conditions, ["C80.1", "C79.51", "C79.9"]) { // malignant neoplasm / bone metastasis examples
        return true;
    }
    if hasConditionCode(conditions, ["M46.2", "M46.4", "M86.9"]) { // osteomyelitis / discitis examples
        return true;
    }

    // Look for cauda equina keywords in Observation notes (simple text check)
    foreach international401:Observation o in observations {
        if hasNoteKeyword(o, ["cauda", "bowel", "bladder", "saddle anesthesia", "progressive weakness"]) {
            return true;
        }
    }
    return false;
}

isolated function hasConditionCode(international401:Condition[] conditions, string[] icd10Codes) returns boolean {
    foreach international401:Condition c in conditions {
        r4:CodeableConcept? cc = c.code;
        if cc is () {
            continue;
        }
        r4:Coding[]? codings = cc.coding;
        if codings is () {
            continue;
        }
        foreach r4:Coding coding in codings {
            string? code = coding.code;
            if code is string && contains(icd10Codes, code) {
                return true;
            }
        }
    }
    return false;
}

isolated function hasNoteKeyword(international401:Observation o, string[] keywords) returns boolean {
    r4:Annotation[]? notes = o.note;
    if notes is () {
        return false;
    }
    foreach r4:Annotation a in notes {
        string? t = a.text;
        if t is string {
            string lt = t.toLowerAscii();
            foreach string k in keywords {
                if lt.includes(k.toLowerAscii()) {
                    return true;
                }
            }
        }
    }
    return false;
}

// -----------------------------------------------------------------------------
// Repeat imaging rule (based on DiagnosticReport dates)
// -----------------------------------------------------------------------------

isolated function isRepeatImagingWithinMonths(international401:DiagnosticReport[] reports, int months) returns boolean {
    // If any imaging DiagnosticReport with MRI spine keywords exists within the last N months → true
    time:Utc now = time:utcNow();
    int cutoffDays = months * 30;

    foreach international401:DiagnosticReport r in reports {
        if !isLikelySpineMriReport(r) {
            continue;
        }

        r4:instant? dt = getDiagnosticReportDate(r);
        if dt is () {
            continue;
        }

        int|error days = approxDaysBetween(dt, time:utcToString(now));
        if days is error {
            return false;
        }
        if days >= 0 && days <= cutoffDays {
            return true;
        }
    }
    return false;
}

isolated function isLikelySpineMriReport(international401:DiagnosticReport r) returns boolean {
    // Heuristic: based on code.text or coding.display
    r4:CodeableConcept? cc = r.code;
    if cc is () {
        return false;
    }
    string? text = cc.text;
    if text is string {
        string t = text.toLowerAscii();
        if t.includes("mri") && (t.includes("spine") || t.includes("lumbar") || t.includes("cervical") || t.includes("thoracic")) {
            return true;
        }
    }
    r4:Coding[]? codings = cc.coding;
    if codings is r4:Coding[] {
        foreach r4:Coding c in codings {
            string? disp = c.display;
            if disp is string {
                string d = disp.toLowerAscii();
                if d.includes("mri") && (d.includes("spine") || d.includes("lumbar") || d.includes("cervical") || d.includes("thoracic")) {
                    return true;
                }
            }
        }
    }
    return false;
}

isolated function getDiagnosticReportDate(international401:DiagnosticReport r) returns r4:instant? {
    // Prefer issued, otherwise effective[x]
    if r.issued is r4:instant {
        return r.issued;
    }
    // effective can be dateTime/Period in FHIR; keeping minimal here.
    // If your generated types include effectiveDateTime:
    if r.effectiveDateTime is r4:dateTime {
        return r.effectiveDateTime;
    }
    return ();
}

# Returns the approximate number of days between two FHIR instants.
#
# + from - FHIR instant (earlier time)
# + to - FHIR instant (later time)
# + return - Number of days between the two instants, or error if parsing fails
public isolated function approxDaysBetween(r4:instant 'from, r4:instant to) returns int|error {
    // Parse FHIR instant (RFC3339) to time:Utc
    time:Utc fromUtc = check time:utcFromString('from);
    time:Utc toUtc = check time:utcFromString(to);

    // Difference in seconds
    time:Seconds diffSeconds = time:utcDiffSeconds(toUtc, fromUtc);

    // Convert seconds to days (approximate)
    decimal decimalResult = diffSeconds / (60 * 60 * 24);
    return <int>decimalResult.floor();
}

// -----------------------------------------------------------------------------
// Medical necessity helpers
// -----------------------------------------------------------------------------

isolated function hasAnyDiagnosis(international401:ServiceRequest sr, international401:Condition[] conditions) returns boolean {
    // ServiceRequest.reasonCode / reasonReference OR any Condition present
    if sr.reasonCode is r4:CodeableConcept[] && (<r4:CodeableConcept[]>sr.reasonCode).length() > 0 {
        return true;
    }
    if sr.reasonReference is r4:Reference[] && (<r4:Reference[]>sr.reasonReference).length() > 0 {
        return true;
    }
    return conditions.length() > 0;
}

isolated function hasObjectiveNeuroFindings(international401:Observation[] observations) returns boolean {
    // Simple heuristic: look for neuro exam note keywords
    foreach international401:Observation o in observations {
        if hasNoteKeyword(o, ["motor", "weakness", "reflex", "sensation", "straight leg raise", "slr", "dermatome"]) {
            return true;
        }
    }
    return false;
}

isolated function hasConservativeManagementEvidence(r4:Bundle bundle) returns boolean {
    // Very simplified: if bundle contains any MedicationRequest or Procedure/ServiceRequest that looks like PT
    foreach r4:BundleEntry e in (bundle.entry ?: []) {
        anydata r = e?.'resource;
        if r is international401:MedicationRequest {
            // Any active medication can be treated as "some conservative care" (example).
            return true;
        }
        if r is international401:Procedure {
            if looksLikePhysicalTherapy(r) {
                return true;
            }
        }
        if r is international401:ServiceRequest {
            // PT order in supporting info could exist as a ServiceRequest too
            if looksLikePhysicalTherapyOrder(r) {
                return true;
            }
        }
        if r is international401:DocumentReference {
            // If clinical notes mention PT/NSAIDs etc.
            if documentMentionsConservativeCare(r) {
                return true;
            }
        }
    }
    return false;
}

isolated function looksLikePhysicalTherapy(international401:Procedure p) returns boolean {
    r4:CodeableConcept? cc = p.code;
    if cc is () {
        return false;
    }
    string? t = cc.text;
    if t is string && t.toLowerAscii().includes("physical therapy") {
        return true;
    }
    return false;
}

isolated function looksLikePhysicalTherapyOrder(international401:ServiceRequest sr) returns boolean {
    r4:CodeableConcept? cc = sr.code;
    if cc is () {
        return false;
    }
    string? t = cc.text;
    if t is string && (t.toLowerAscii().includes("physical therapy") || t.toLowerAscii().includes("physiotherapy")) {
        return true;
    }
    return false;
}

isolated function documentMentionsConservativeCare(international401:DocumentReference dr) returns boolean {
    // Minimal placeholder: check description/title if available
    string? desc = dr.description;
    if desc is string {
        string d = desc.toLowerAscii();
        if d.includes("pt") || d.includes("physical therapy") || d.includes("nsaid") || d.includes("ibuprofen") {
            return true;
        }
    }
    return false;
}

isolated function estimateSymptomDurationDays(international401:Condition[] conditions) returns int? {
    // Use first Condition.onsetDateTime if available
    time:Utc now = time:utcNow();

    foreach international401:Condition c in conditions {
        if c.onsetRange is r4:Range {
            r4:Range onset = <r4:Range>c.onsetRange;
            decimal? unionResult = onset?.low?.value;
            int|error days = unionResult is decimal ? <int>(unionResult.floor()) : 0;
            if days is error {
                return 0;
            }
            if days >= 0 {
                return days;
            }
        }
        // If your generated model uses onsetDateTime:
        if c.onsetDateTime is r4:dateTime {
            r4:dateTime onset2 = <r4:dateTime>c.onsetDateTime;
            int|error days2 = approxDaysBetween(onset2, time:utcToString(now));
            if days2 is error {
                return 0;
            }
            if days2 >= 0 {
                return days2;
            }
        }
    }
    return ();
}

// -----------------------------------------------------------------------------
// Bundle extraction helpers
// -----------------------------------------------------------------------------

isolated function getFirstServiceRequest(r4:Bundle bundle) returns international401:ServiceRequest|error {

    r4:BundleEntry[]? entries = bundle.entry;
    if entries is r4:BundleEntry[] {
        foreach r4:BundleEntry entry in entries {
            anydata res = entry?.'resource;
            r4:DomainResource domainRes = check res.cloneWithType();
            if domainRes.resourceType == "ServiceRequest" {
                return res.cloneWithType(international401:ServiceRequest);
            }
        }
    }

    return error("No ServiceRequest found in the input bundle.");
}

isolated function getEncounterFromBundle(r4:Bundle bundle, international401:ServiceRequest sr) returns international401:Encounter|error? {
    // Prefer Encounter referenced by ServiceRequest.encounter if present
    r4:Reference? ref = sr.encounter;
    string? encId = getIdFromReference(ref);

    if encId is string {
        international401:Encounter? found = check getEncounterById(bundle, encId);
        if found is international401:Encounter {
            return found;
        }
    }

    // Otherwise use the first Encounter in the bundle if present
    r4:BundleEntry[]? entries = bundle.entry;
    if entries is r4:BundleEntry[] {
        foreach r4:BundleEntry entry in entries {
            anydata res = entry?.'resource;
            r4:DomainResource domainRes = check res.cloneWithType(r4:DomainResource);
            if domainRes.resourceType == "Encounter" {
                return res.cloneWithType(international401:Encounter);
            }
        }
    }
    return ();
}

isolated function getEncounterById(r4:Bundle bundle, string encRef) returns international401:Encounter?|error {
    // encRef can be "Encounter/enc-1001" or just "enc-1001"
    string targetId = encRef;
    if encRef.includes("/") {
        string[] parts = regexp:split(re `/`, encRef);
        if parts.length() >= 2 {
            targetId = parts[1];
        }
    }

    r4:BundleEntry[]? entries = bundle.entry;
    if entries is r4:BundleEntry[] {
        foreach r4:BundleEntry entry in entries {
            anydata res = entry?.'resource;
            r4:DomainResource domainRes = check res.cloneWithType();
            if domainRes.resourceType == "Encounter" {
                if (domainRes.id ?: "") == targetId {
                    return res.cloneWithType(international401:Encounter);
                }
            }
        }
    }

    return ();
}

isolated function getIdFromReference(r4:Reference? ref) returns string? {
    if ref is () {
        return ();
    }
    string? reference = ref.reference;
    if reference is () {
        return ();
    }
    return reference;
}

isolated function getAllConditions(r4:Bundle bundle) returns international401:Condition[]|error {
    international401:Condition[] out = [];

    r4:BundleEntry[]? entries = bundle.entry;
    if entries is r4:BundleEntry[] {
        foreach r4:BundleEntry entry in entries {
            anydata res = entry?.'resource;
            r4:DomainResource domainRes = check res.cloneWithType(r4:DomainResource);
            if domainRes.resourceType == "Condition" {
                out.push(check res.cloneWithType(international401:Condition));
            }
        }
    }

    return out;
}

isolated function getAllObservations(r4:Bundle bundle) returns international401:Observation[]|error {
    international401:Observation[] out = [];

    r4:BundleEntry[]? entries = bundle.entry;
    if entries is r4:BundleEntry[] {
        foreach r4:BundleEntry entry in entries {
            anydata res = entry?.'resource;
            r4:DomainResource domainRes = check res.cloneWithType(r4:DomainResource);
            if domainRes.resourceType == "Observation" {
                out.push(check res.cloneWithType(international401:Observation));
            }
        }
    }

    return out;
}

isolated function getAllDiagnosticReports(r4:Bundle bundle) returns international401:DiagnosticReport[]|error {
    international401:DiagnosticReport[] out = [];

    r4:BundleEntry[]? entries = bundle.entry;
    if entries is r4:BundleEntry[] {
        foreach r4:BundleEntry e in entries {
            anydata res = e?.'resource;
            r4:DomainResource domainRes = check res.cloneWithType(r4:DomainResource);
            if domainRes.resourceType == "DiagnosticReport" {
                out.push(check res.cloneWithType(international401:DiagnosticReport));
            }
        }
    }

    return out;
}

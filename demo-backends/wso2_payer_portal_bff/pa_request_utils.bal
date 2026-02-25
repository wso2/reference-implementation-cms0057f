// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).

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
import ballerina/http;
import ballerina/time;
import ballerina/url;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.ips;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.davincipas;
import ballerinax/health.fhir.r4.international401;

// ============================================
// Prior Authorization Request Utility Functions
// ============================================

const string CLAIM_RESPONSE = "/ClaimResponse";

# Query PA requests from FHIR Claim and ClaimResponse resources
#
# + page - Page number (1-indexed)
# + pageSize - Number of items per page
# + search - Search by patient ID or request ID
# + urgency - Filter by urgency levels
# + status - Filter by processing status
# + return - Tuple containing PA requests array and total count, or error
function queryPARequests(
    int page,
    int pageSize,
    string? search,
    PARequestUrgency[]? urgency,
    PARequestProcessingStatus[]? status
) returns [PARequestListItem[], int]|error {

    // Construct outcome parameter based on status filter
    string outcomeParam = "";
    if status is PARequestProcessingStatus[] {
        string[] outcomeValues = [];
        foreach PARequestProcessingStatus s in status {
            if s == "Pending" {
                // outcomeValues.push("queued"); TODO: Add later after the support is added in the FHIR server
                outcomeValues.push("partial");
            } else if s == "Completed" {
                outcomeValues.push("complete");
            } else if s == "Error" {
                outcomeValues.push("error");
            }
        }
        if (outcomeValues.length() > 0) {
            outcomeParam = "outcome=" + string:'join(",", ...outcomeValues);
        }
    }

    // Build query parameters list to avoid malformed URLs
    string[] queryParams = [];
    
    // Add outcome parameter if present
    if outcomeParam.length() > 0 {
        queryParams.push(outcomeParam);
    }
    
    // Add pagination parameters
    queryParams.push(string `_count=${pageSize.toString()}`);
    queryParams.push(string `page=${page.toString()}`);
    
    // Add patient search parameter if present (URL-encoded)
    if search is string && search.trim().length() > 0 {
        string encodedSearch = check url:encode(search, "UTF-8");
        queryParams.push(string `patient=${encodedSearch}`);
    }
    
    // Construct the final URL with properly formatted query string
    string claimResponseSearchPath = CLAIM_RESPONSE + "?" + string:'join("&", ...queryParams);

    r4:Bundle claimResponseBundle = check fhirHttpClient->get(claimResponseSearchPath);

    // Extract total count from bundle
    int totalCount = 0;
    json|error totalJson = claimResponseBundle.total;
    if totalJson is int {
        totalCount = totalJson;
    }

    // Process each of the ClaimResponse entries to get the corresponding Claim and build PARequestListItem
    PARequestListItem[] paRequests = [];

    // Process entries from the bundle
    r4:BundleEntry[]? entries = claimResponseBundle.entry;
    if entries is r4:BundleEntry[] {
        foreach r4:BundleEntry entry in entries {
            json resourceJson = <json>entry?.'resource;
            // Extract the request reference from ClaimResponse
            json|error requestRef = resourceJson.request;
            json|error responseIdJson = resourceJson.id;
            string responseId = responseIdJson is error ? "unknown" : <string>responseIdJson;
            if requestRef is json {
                json|error refString = requestRef.reference;
                if refString is string {
                    // Fetch the actual Claim resource
                    json|http:ClientError claimResource = fhirHttpClient->get("/" + refString);
                    if claimResource is json {
                        // Parse Claim to PARequestListItem
                        PARequestListItem|error paRequest = parseClaimToPARequestListItem(claimResource, responseId);
                        if paRequest is PARequestListItem {
                            // Apply urgency filter if provided
                            boolean includeItem = true;
                            if urgency is PARequestUrgency[] {
                                includeItem = false;
                                foreach PARequestUrgency urg in urgency {
                                    if paRequest.urgency == urg {
                                        includeItem = true;
                                        break;
                                    }
                                }
                            }
                            if includeItem {
                                paRequests.push(paRequest);
                            }
                        } else {
                            log:printWarn("Failed to parse Claim to PARequestListItem: " + paRequest.message());
                        }
                    } else {
                        log:printWarn("Failed to fetch Claim resource: " + claimResource.message());
                    }
                }
            }
        }
    }
    
    return [paRequests, totalCount];
}

# Parse FHIR Claim resource to PARequestListItem
#
# + claimResource - FHIR Claim resource as JSON
# + responseId - FHIR Claim response ID
# + return - PARequestListItem or error
function parseClaimToPARequestListItem(json claimResource, string responseId) returns PARequestListItem|error {
    // Extract Claim ID
    string requestId = let var idVal = claimResource.id in idVal is string ? idVal : "";
    
    // Extract and map priority to urgency
    string priorityStr = let var prioVal = claimResource.priority in prioVal is json ? 
                         (let var coding = prioVal.coding in coding is json[] && coding.length() > 0 ?
                          (let var code = coding[0].code in code is string ? code : "normal") : "normal") : "normal";
    
    PARequestUrgency urgency = mapPriorityToUrgency(priorityStr);
    
    // Extract patient reference
    string patientId = "";
    json|error patientJson = claimResource.patient;
    if patientJson is json {
        json|error refJson = patientJson.reference;
        if refJson is string {
            // Extract ID from reference like "Patient/123"
            string:RegExp regex = re `/`;
            string[] parts = regex.split(refJson);
            if parts.length() > 1 {
                patientId = parts[parts.length() - 1];
            }
        }
    }
    
    // Extract practitioner from careTeam
    string? practitionerId = ();
    json|error careTeamJson = claimResource.careTeam;
    if careTeamJson is json[] {
        foreach json member in careTeamJson {
            json|error providerJson = member.provider;
            if providerJson is json {
                json|error refJson = providerJson.reference;
                if refJson is string && refJson.includes("Practitioner") {
                    string:RegExp regex = re `/`;
                    string[] parts = regex.split(refJson);
                    if parts.length() > 1 {
                        practitionerId = parts[parts.length() - 1];
                    }
                    break;
                }
            }
        }
    }
    
    // Extract provider name from provider or insurer reference
    string provider = "Unknown Provider";
    json|error providerJson = claimResource.provider;
    if providerJson is json {
        json|error displayJson = providerJson.display;
        if (displayJson is string) {
            provider = displayJson;
        }
    } else {
        // Try insurer if provider not found
        json|error insurerJson = claimResource.insurer;
        if insurerJson is json {
            json|error displayJson = insurerJson.display;
            if (displayJson is string) {
                provider = displayJson;
            }
        }
    }
    
    // Extract created date
    string dateSubmitted = let var createdVal = claimResource.created in createdVal is string ? createdVal : "";
    
    return {
        requestId: requestId,
        responseId: responseId,
        urgency: urgency,
        patientId: patientId,
        practitionerId: practitionerId,
        provider: provider,
        dateSubmitted: dateSubmitted
    };
}

# Map FHIR priority code to PARequestUrgency
#
# + priorityCode - FHIR priority code (stat, normal, deferred)
# + return - PARequestUrgency
function mapPriorityToUrgency(string priorityCode) returns PARequestUrgency {
    match priorityCode.toLowerAscii() {
        "stat" => {
            return "Urgent";
        }
        "deferred" => {
            return "Deferred";
        }
        _ => {
            return "Standard"; // Default to Standard for "normal" or unknown
        }
    }
}

# Map FHIR ClaimResponse outcome to PARequestProcessingStatus
#
# + outcome - FHIR ClaimResponse outcome (queued, complete, error, partial)
# + return - PARequestProcessingStatus
function mapOutcomeToStatus(string outcome) returns PARequestProcessingStatus {
    match outcome.toLowerAscii() {
        "queued" => {
            return "Pending";
        }
        "complete" => {
            // Note: In real scenario, would need to check disposition to determine Approved vs Denied
            // For now, defaulting to Completed for complete
            return "Completed";
        }
        "error" => {
            return "Error";
        }
        "partial" => {
            return "Pending";
        }
        _ => {
            return "Pending";
        }
    }
}

# Get PA request analytics from PostgreSQL database
#
# + return - PARequestAnalytics or error
function getPARequestAnalytics() returns PARequestAnalytics|error {
    // Query analytics counts from the pa_request_analytics table
    PARequestAnalytics analytics = {
        urgentCount: 0,
        standardCount: 0,
        reAuthorizationCount: 0,
        appealCount: 0
    };
    
    // Query for urgent count
    record {| int count; |}|error urgentResult = dbClient->queryRow(
        `SELECT count FROM pa_request_analytics WHERE urgency_type = 'Urgent'`
    );
    if urgentResult is record {| int count; |} {
        analytics.urgentCount = urgentResult.count;
    }
    
    // Query for standard count
    record {| int count; |}|error standardResult = dbClient->queryRow(
        `SELECT count FROM pa_request_analytics WHERE urgency_type = 'Standard'`
    );
    if standardResult is record {| int count; |} {
        analytics.standardCount = standardResult.count;
    }
    
    // Query for re-authorization count
    record {| int count; |}|error reAuthResult = dbClient->queryRow(
        `SELECT count FROM pa_request_analytics WHERE urgency_type = 'Re-authorization'`
    );
    if reAuthResult is record {| int count; |} {
        analytics.reAuthorizationCount = reAuthResult.count;
    }
    
    // Query for appeal count
    record {| int count; |}|error appealResult = dbClient->queryRow(
        `SELECT count FROM pa_request_analytics WHERE urgency_type = 'Appeal'`
    );
    if appealResult is record {| int count; |} {
        analytics.appealCount = appealResult.count;
    }
    
    return analytics;
}

# Increment PA request analytics count
#
# + urgencyType - The urgency type to increment (Urgent, Standard, Deferred, Re-authorization, Appeal)
# + return - Error if operation fails
function incrementPARequestCount(string urgencyType) returns error? {
    _ = check dbClient->execute(
        `UPDATE pa_request_analytics SET count = count + 1 WHERE urgency_type = ${urgencyType}`
    );
}

# Decrement PA request analytics count
#
# + urgencyType - The urgency type to decrement (Urgent, Standard, Deferred, Re-authorization, Appeal)
# + return - Error if operation fails
function decrementPARequestCount(string urgencyType) returns error? {
    _ = check dbClient->execute(
        `UPDATE pa_request_analytics SET count = GREATEST(count - 1, 0) WHERE urgency_type = ${urgencyType}`
    );
}

// ============================================
// PA Request Detail Functions
// ============================================

# Get complete PA request detail by ID
#
# + responseId - The ClaimResponse ID (if available) to get processing status and notes
# + return - PARequestDetail or error
public function getPARequestDetail(string responseId) returns PARequestDetail|error {
    // 1. Get the ClaimResponse if it exists - DONE
    international401:ClaimResponse claimResponse = check getClaimResponse(responseId, limited = false);

    // 2. Get the PAS Claim - DONE
    r4:Reference? requestRef = claimResponse.request;
    if requestRef is () {
        return error("ClaimResponse does not have a request reference");
    }
    json claim = check fhirHttpClient->get("/"+<string>requestRef.reference);
    davincipas:PASClaim pasClaim = <davincipas:PASClaim> check parser:parse(claim);
    
    // 3. Extract patient ID from claim - DONE
    string patientId = "";
    string patientRef = <string>pasClaim.patient.reference;
    string:RegExp regex = re `/`;
    string[] parts = regex.split(patientRef);
    patientId = parts[parts.length() - 1];
    
    // 4. Get IPS summary for patient - DONE
    PatientInformation patientInfo = check getPatientIPSSummary(patientId);
    
    // 5. Extract practitioner/provider info - DONE
    ProviderInformation providerInfo = check getProviderInformation(pasClaim.provider);
    
    // 6. Parse claim items - DONE
    ClaimItem[] items = check parseClaimItems(pasClaim.item);

    // 7. Get the supporting information - DONE
    [string?, string?, string?, json[]?, json[]?] supportingInfo = check extractSupportingInformation(pasClaim.supportingInfo);
    string? admissionDate = supportingInfo[0];
    string? dischargeDate = supportingInfo[1];
    string? clinicalJustification = supportingInfo[2];
    json[]? questionnairesJson = supportingInfo[3];
    json[]? attachmentsJson = supportingInfo[4];

    QuestionnaireResponseItem [] questionnaireItems = [];
    // 8. Add AI analysis to questionnaires - TODO
    if questionnairesJson != () {
        foreach json questionnaire in questionnairesJson {
            QuestionnaireResponseItem item = {
                questionnaire: questionnaire,
                analysis: generateAIAnalysis(questionnaire)
            };
            questionnaireItems.push(item);
        }
    }
    
    // 9. Build PARequestDetail - DONE
    string claimId = <string>pasClaim.id;
    string status = claimResponse.outcome;
    string created = pasClaim.created;
    string use = "preauthorization";
    
    // Extract priority - DONE
    string priorityCode = <string>(<r4:Coding[]>(pasClaim.priority.coding))[0].code;
    string? targetDate = ();
    PARequestUrgency priority = "Standard";
    if priorityCode == "stat" {
        priority = "Urgent";
        // Have to do in 3 days
        targetDate = check AddDurationToDate(created, "3");
    } else if priorityCode == "deferred" {
        priority = "Deferred";
        // Have to do in 30 days
        targetDate = check AddDurationToDate(created, "30");
    } else {
        targetDate = check AddDurationToDate(created, "7"); // Default to 7 days for standard
    }
    
    // Build summary - DONE
    RequestSummary summary = {
        serviceType: extractServiceType(items), // TODO
        clinicalJustification: clinicalJustification,
        submittedDate: created,
        targetDate: targetDate
    };
    
    // Extract coverage information - DONE
    CoverageInformation[]? coverage = extractCoverageInfo(pasClaim.insurance);
    
    // Calculate totals - DONE
    ClaimTotals|error total = calculateClaimTotals(items, claimResponse);
    if total is error {
        log:printError("Failed to calculate claim totals: " + total.message());
        return total;
    }
    
    // Extract process notes - DONE
    ProcessNote[]? processNotes = extractProcessNotes(claimResponse);
    
    PARequestDetail detail = {
        id: claimId,
        responseId: responseId,
        status: status,
        use: use,
        created: created,
        targetDate: targetDate,
        admissionDate: admissionDate,
        dischargeDate: dischargeDate,
        questionnaires: questionnaireItems,
        attachments: attachmentsJson,
        priority: priority,
        summary: summary,
        patient: patientInfo,
        provider: providerInfo,
        items: items,
        coverage: coverage,
        total: total,
        processNotes: processNotes
    };
    
    return detail;
}

# Get ClaimResponse for a given Claim ID
#
# + claimResId - The ClaimResponse resource ID
# + limited - Whether to fetch a limited set of elements
# + return - ClaimResponse JSON or null if not found
function getClaimResponse(string claimResId, boolean limited=true) returns international401:ClaimResponse|error{
    string claimResponsePath = CLAIM_RESPONSE + "/" + claimResId;
    if limited {
        claimResponsePath += "?_elements=outcome,disposition,processNote";
    }
    
    json|http:ClientError response = fhirHttpClient->get(claimResponsePath);
    if response is http:ClientError {
        log:printError("ClaimResponse not found for ClaimResponse ID " + claimResId);
        return response; // Return error to indicate not found, caller will handle as null
    }
    international401:ClaimResponse pasClaimResponse = <international401:ClaimResponse> check parser:parse(response);
    return pasClaimResponse;
}

# Get Patient IPS Summary
#
# + patientId - Patient ID
# + return - PatientInformation or error
function getPatientIPSSummary(string patientId) returns PatientInformation|error {
    // Get patient summary using IPS $summary operation
    json|error ipsSummary = fhirHttpClient->get("/Patient/" + patientId + "/$summary");
    if ipsSummary is error{
        log:printError("Failed to fetch IPS summary for patient " + patientId + ": " + ipsSummary.message());
        return ipsSummary;
    }
    
    // Parse JSON to strongly-typed IPS Bundle
    r4:Bundle ipsData = check ipsSummary.cloneWithType(r4:Bundle);
    
    // Parse IPS Bundle using strongly-typed data
    PatientInformation patientInfo = check parseIPSBundle(ipsData, patientId);
    
    return patientInfo;
}

# Parse IPS Patient resource to PatientInformation
#
# + patient - IPS Patient resource
# + return - PatientInformation or error
function parsePatientResource(ips:PatientUvIps patient) returns PatientInformation|error {
    string patientId = patient.id ?: "unknown";
    
    // Extract name - work with anydata
    string fullName = "Unknown";
    ips:PatientUvIpsName[] nameData = patient.name;
    if nameData.length() > 0 {
        ips:PatientUvIpsName firstNameData = nameData[0];
        string[]? givenData = firstNameData.given;
        string? familyData = firstNameData.family;
        string? family = familyData is string ? familyData : ();
        string? given = ();
        if givenData is string[] {
            string[] givenArray = <string[]> givenData;
            if (givenArray.length() > 0) {
                given = givenArray[0];
            }
        }
        if given is string && family is string {
            fullName = given + " " + family;
        } else if family is string {
            fullName = family;
        } else if given is string {
            fullName = given;
        }
    }
    
    // Extract birth date
    r4:date birthDate = patient.birthDate;
    
    // Extract gender
    ips:PatientUvIpsGender gender = patient.gender ?: "unknown";
    
    PatientDemographics demographics = {
        name: fullName,
        dateOfBirth: birthDate,
        age: calculateAge(birthDate),
        gender: gender,
        mrn: patientId
    };
    
    PatientInformation patientInfo = {
        id: patientId,
        demographics: demographics,
        allergies: [],
        medications: []
    };
    
    return patientInfo;
}

# Parse IPS Bundle to PatientInformation
#
# + ipsBundle - Strongly-typed IPS Bundle data
# + patientId - Patient ID
# + return - PatientInformation or error
function parseIPSBundle(r4:Bundle ipsBundle, string patientId) returns PatientInformation|error {

    ips:PatientUvIps? patientResource = ();
    ips:AllergyIntoleranceUvIps[] allergyResources = [];
    ips:MedicationStatementIPS[] medicationResources = [];

    foreach r4:BundleEntry entry in <r4:BundleEntry[]>ipsBundle.entry{
        if (<string>(<r4:uri>entry.fullUrl)).includes("Patient"){
            patientResource = check (entry?.'resource).cloneWithType(ips:PatientUvIps);
        } else if (<string>(<r4:uri>entry.fullUrl)).includes("AllergyIntolerance"){
            ips:AllergyIntoleranceUvIps allergyResource = check (entry?.'resource).cloneWithType(ips:AllergyIntoleranceUvIps);
            allergyResources.push(allergyResource);
        } else if (<string>(<r4:uri>entry.fullUrl)).includes("MedicationStatement"){
            ips:MedicationStatementIPS medicationResource = check (entry?.'resource).cloneWithType(ips:MedicationStatementIPS);
            medicationResources.push(medicationResource);
        }
    }

    // Parse patient demographics from the patient field
    PatientInformation patientInfo = check parsePatientResource(<ips:PatientUvIps>patientResource);
    
    // Extract allergies from allergyIntolerance array
    AllergyIntolerance[] allergies = [];
    foreach ips:AllergyIntoleranceUvIps allergyResource in allergyResources {
        AllergyIntolerance? allergy = parseAllergy(allergyResource);
        if allergy is AllergyIntolerance {
            allergies.push(allergy);
        }
    }
    
    // Extract medications from medicationStatement array
    MedicationStatement[] medications = [];
    foreach ips:MedicationStatementIPS medResource in medicationResources {
        MedicationStatement? med = parseMedicationStatement(medResource);
        if med is MedicationStatement {
            medications.push(med);
        }
    }
    
    patientInfo.allergies = allergies;
    patientInfo.medications = medications;
    return patientInfo;
}

# Parse AllergyIntolerance resource
#
# + allergyResource - IPS AllergyIntolerance resource
# + return - AllergyIntolerance or null
function parseAllergy(ips:AllergyIntoleranceUvIps allergyResource) returns AllergyIntolerance? {
    ips:CodeableConceptUvIps? code = allergyResource.code;
    string substance = "Unknown";
    if code is ips:CodeableConceptUvIps{
        substance = code.text ?: "Unknown";
    }
    string? severity = allergyResource.criticality;
    return {
        substance: substance,
        severity: severity
    };
}

# Parse MedicationStatement resource
#
# + medResource - IPS MedicationStatement resource
# + return - MedicationStatement or null
function parseMedicationStatement(ips:MedicationStatementIPS medResource) returns MedicationStatement? {
    if medResource.status != "active" {
        return ();
    }
    string medication = "";
    ips:CodeableConceptUvIps? medCodeData = medResource.medicationCodeableConcept;
    if medCodeData is ips:CodeableConceptUvIps {
        medication = medCodeData.text ?: "Unknown";
    }
    return {
        medication: medication,
        status: medResource.status
    };
}

# Calculate age from birth date
#
# + birthDate - Birth date in YYYY-MM-DD format
# + return - Age in years or null
function calculateAge(string birthDate) returns int? {
    time:Utc currentTimeUtc = time:utcNow();
    time:Civil civilTime = time:utcToCivil(currentTimeUtc);
    int year = civilTime.year;
    if birthDate.length() >= 4 {
        int|error birthYear = int:fromString(birthDate.substring(0, 4));
        if birthYear is int {
            return year - birthYear; 
        }
    }
    return ();
}

# Get Provider Information from Claim
#
# + providerRef - Reference to provider from Claim resource
# + return - ProviderInformation or error
function getProviderInformation(r4:Reference providerRef) returns ProviderInformation|error {
    // Extract provider from careTeam
    string? practitionerId = providerRef.reference;
    // If PractitionerRole is in reference, fetch practitioner info or organization info based on reference type
    if practitionerId == () {
        log:printError("Practitioner or Organization information is not found in the bundle");
        return error("Practitioner or Organization information is not found in the bundle");
    }

    string:RegExp regex = re `/`;
    string[] parts = regex.split(practitionerId);
    string resourceType = parts[0];
    practitionerId = parts[parts.length() - 1];

    if resourceType == "Organization" {
        return getOrganizationInfo(<string>practitionerId);
    } else if resourceType == "PractitionerRole" {
        return getPractitionerInfo(<string>practitionerId);
    } else {
        log:printError("Unknown provider reference type: " + resourceType);
        return error("Unknown provider reference type: " + resourceType);
    }
}

# Get Practitioner Information
#
# + practitionerId - Practitioner ID
# + return - ProviderInformation or error
function getPractitionerInfo(string practitionerId) returns ProviderInformation|error {
    json practitionerRoleRes = check fhirHttpClient->get("/PractitionerRole/" + practitionerId);
    davincipas:PASPractitionerRole practitionerRole = <davincipas:PASPractitionerRole> check parser:parse(practitionerRoleRes);

    json practitionerRes = check fhirHttpClient->get("/" + <string>practitionerRole.practitioner.reference);
    davincipas:PASPractitioner practitioner = <davincipas:PASPractitioner> check parser:parse(practitionerRes);

    string fullName = "Unknown Practitioner";
    string? initials = ();
    r4:HumanName[] nameData = <r4:HumanName[]>practitioner.name;
    if nameData.length() > 0 {
        r4:HumanName firstNameData = nameData[0];
        string[]? givenData = firstNameData.given;
        string? familyData = firstNameData.family;
        string? family = familyData is string ? familyData : ();
        string? given = ();
        if givenData is string[] {
            string[] givenArray = <string[]> givenData;
            if givenArray.length() > 0 {
                given = givenArray[0];
            }
        }
        if given is string && family is string {
            fullName = "Dr. " + given + " " + family;
            initials = (given[0].toUpperAscii() + family[0].toUpperAscii());
        } else if family is string {
            fullName = "Dr. " + family;
            initials = family[0].toUpperAscii();
        } else if given is string {
            fullName = "Dr. " + given;
            initials = given[0].toUpperAscii();
        }
    }

    string speciality = "";

    if practitionerRole.specialty is r4:CodeableConcept[] {
        foreach r4:CodeableConcept item in <r4:CodeableConcept[]>practitionerRole.specialty {
            speciality += <string>item.text + " ";
        }
    } else {
        speciality = "General";
    }

    ProviderContact? contact = ();

    if practitioner.telecom is r4:ContactPoint[] {
        r4:ContactPoint[] telecoms = <r4:ContactPoint[]>practitioner.telecom;
        
        string? phone = ();
        string? email = ();
        
        // Extract phone and email from contact points
        foreach r4:ContactPoint telecom in telecoms {
            if telecom.system == "phone" && phone is () {
                phone = telecom.value;
            } else if telecom.system == "email" && email is () {
                email = telecom.value;
            }
            
            // Break if we found both
            if phone is string && email is string {
                break;
            }
        }
        
        // Create contact if we have at least one
        if phone is string || email is string {
            contact = {
                phone: phone,
                email: email
            };
        }
    }
    
    // Extract organization/facility information from PractitionerRole
    Facility? facility = ();
    if practitionerRole.organization is r4:Reference {
        r4:Reference orgRef = <r4:Reference>practitionerRole.organization;
        if orgRef.reference is string {
            string:RegExp regex = re `/`;
            string[] parts = regex.split(<string>orgRef.reference);
            string orgId = parts[parts.length() - 1];
            facility = check extractFacilityInfo(orgId);
        }
    }
    
    return {
        id: practitionerId,
        name: fullName,
        specialty: speciality,
        initials: initials,
        contact: contact,
        facility: facility
    };
}

# Extract Facility information from Organization
#
# + organizationId - Organization ID
# + return - Facility or error
function extractFacilityInfo(string organizationId) returns Facility|error {
    json organizationJson = check fhirHttpClient->get("/Organization/" + organizationId);
    davincipas:PASOrganization org = check organizationJson.cloneWithType(davincipas:PASOrganization);

    // Extract organization name
    string orgName = org.name;
    
    // Extract address from the organization
    Address? address = ();
    if org.address is r4:Address[] {
        r4:Address[] addresses = <r4:Address[]>org.address;
        if addresses.length() > 0 {
            r4:Address firstAddress = addresses[0];
            string[] line = [];
            if (firstAddress.line is string[]) {
                string[] addressLines = <string[]>firstAddress.line;
                line = addressLines;
            }
            address = {
                line: line,
                city: firstAddress.city,
                state: firstAddress.state,
                postalCode: firstAddress.postalCode
            };
        }
    }
    
    return {
        name: orgName,
        address: address
    };
}

# Get Organization Information
#
# + organizationId - Organization ID
# + return - ProviderInformation or error
function getOrganizationInfo(string organizationId) returns ProviderInformation|error {
    json organizationJson = check fhirHttpClient->get("/Organization/" + organizationId);
    davincipas:PASOrganization org = check organizationJson.cloneWithType(davincipas:PASOrganization);
    
    // Extract organization name
    string orgName = org.name;
    
    // Extract contact information (phone and email)
    ProviderContact? contact = ();
    if org.telecom is r4:ContactPoint[] {
        r4:ContactPoint[] telecoms = <r4:ContactPoint[]>org.telecom;
        
        string? phone = ();
        string? email = ();
        
        foreach r4:ContactPoint telecom in telecoms {
            if telecom.system == "phone" && phone is () {
                phone = telecom.value;
            } else if telecom.system == "email" && email is () {
                email = telecom.value;
            }
            
            if phone is string && email is string {
                break;
            }
        }
        
        if phone is string || email is string {
            contact = {
                phone: phone,
                email: email
            };
        }
    }
    // Extract facility information
    Facility? facility = check extractFacilityInfo(organizationId);

    return {
        id: organizationId,
        name: orgName,
        specialty: (),
        initials: (),
        contact: contact,
        facility: facility
    };
}

# Extract supporting information from PAS Claim
#
# + supportingInfo - Array of PASClaimSupportingInfo from PAS Claim resource
# + return - Tuple containing [admissionDate, dischargeDate, clinicalJustification, questionnaires, attachments] or error
function extractSupportingInformation(davincipas:PASClaimSupportingInfo[]? supportingInfo) returns [string?, string?, string?, json[]?, json[]?]|error {
    string? admissionDate = ();
    string? dischargeDate = ();
    string? clinicalJustification = ();
    json[] questionnaires = [];
    json[] attachments = [];
    
    if supportingInfo is () {
        return [admissionDate, dischargeDate, (), (), ()];
    }
    
    foreach davincipas:PASClaimSupportingInfo info in supportingInfo {
        // Check category code
        r4:CodeableConcept category = info.category;
        r4:Coding[]? codings = category.coding;
        
        if codings is r4:Coding[] && codings.length() > 0 {
            string? code = codings[0].code;
            
            if code == "admissionDates" {
                // Extract admission date from timingPeriod
                if info.timingPeriod is r4:Period {
                    r4:Period period = <r4:Period>info.timingPeriod;
                    admissionDate = period.'start;
                }
            } else if code == "dischargeDates" {
                // Extract discharge date from timingPeriod
                if info.timingPeriod is r4:Period {
                    r4:Period period = <r4:Period>info.timingPeriod;
                    dischargeDate = period.end;
                }
            } else if code == "additionalInformation" {
                // Extract additional information - can be Attachment or Reference
                if info.valueAttachment is r4:Attachment {
                    // Handle attachment
                    r4:Attachment attachment = <r4:Attachment>info.valueAttachment;
                    json attachmentJson = attachment.toJson();
                    attachments.push(attachmentJson);
                } else if info.valueReference is r4:Reference {
                    // Handle reference - could be DocumentReference or QuestionnaireResponse
                    r4:Reference ref = <r4:Reference>info.valueReference;
                    string? reference = ref.reference;
                    
                    if reference is string {
                        // Fetch the referenced resource
                        json|http:ClientError resourceJson = fhirHttpClient->get("/" + reference);
                        if resourceJson is http:ClientError {
                            log:printWarn("Failed to fetch referenced resource " + reference + ": " + resourceJson.message());
                            continue;
                        }
                        string:RegExp regex = re `/`;
                        string[] parts = regex.split(reference);
                        string resourceType = parts[0];
                        if resourceType == "DocumentReference" {
                            // Add to attachments
                            attachments.push(resourceJson);
                        } else if resourceType == "QuestionnaireResponse" || resourceType == "Bundle" {
                            // Add to questionnaires
                            questionnaires.push(resourceJson);
                        } else {
                            // Unknown type, add to attachments as fallback
                            attachments.push(resourceJson);
                        }
                    }
                }
            } else if code == "freeFormMessage"{
                clinicalJustification = info.valueString is string ? <string>info.valueString : "";
            }
        }
    }
    
    return [admissionDate, dischargeDate, clinicalJustification, questionnaires, attachments];
}

# Parse Claim items
#
# + pasClaimItems - Array of PASClaimItem from PAS Claim resource
# + return - Array of ClaimItems or error
function parseClaimItems(davincipas:PASClaimItem[] pasClaimItems) returns ClaimItem[]|error {
    ClaimItem[] items = [];
    
    foreach davincipas:PASClaimItem pasItem in pasClaimItems {
        // Extract description from productOrService
        string? description = pasItem.productOrService.text;
        if description is () && pasItem.productOrService.coding is r4:Coding[] {
            r4:Coding[] codings = <r4:Coding[]>pasItem.productOrService.coding;
            if codings.length() > 0 {
                description = codings[0].display;
            }
        }
        
        // Convert strongly-typed fields to json for backwards compatibility
        json productOrServiceJson = pasItem.productOrService.toJson();
        json? quantityJson = pasItem.quantity is r4:Quantity ? pasItem.quantity.toJson() : ();
        json? unitPriceJson = pasItem.unitPrice is r4:Money ? pasItem.unitPrice.toJson() : ();
        json? netJson = pasItem.net is r4:Money ? pasItem.net.toJson() : ();
        json? servicedPeriodJson = pasItem.servicedPeriod is r4:Period ? pasItem.servicedPeriod.toJson() : ();
        
        ClaimItem item = {
            sequence: pasItem.sequence,
            productOrService: productOrServiceJson,
            description: description,
            quantity: quantityJson,
            unitPrice: unitPriceJson,
            net: netJson,
            servicedDate: pasItem.servicedDate,
            servicedPeriod: servicedPeriodJson,
            adjudication: (),
            noteNumbers: (),
            reviewNote: ()
        };
        
        items.push(item);
    }
    
    return items;
}

# Extract service type from items
#
# + items - Array of claim items
# + return - Service type string
function extractServiceType(ClaimItem[] items) returns string {
    if items.length() > 0 {
        return items[0].description ?: "Medical Service";
    }
    return "Medical Service";
}

# Extract coverage information from PAS Claim insurance array
#
# + insuranceArray - Array of PASClaimInsurance from PAS Claim resource
# + return - Array of CoverageInformation or null
function extractCoverageInfo(davincipas:PASClaimInsurance[]? insuranceArray) returns CoverageInformation[]? {
    if insuranceArray is () || insuranceArray.length() == 0 {
        return ();
    }
    
    CoverageInformation[] coverageList = [];
    
    foreach davincipas:PASClaimInsurance insurance in insuranceArray {
        string coverageRef = insurance.coverage.reference ?: "";
        
        string serviceItemRequestType = "";
        string certificationType = "";
        if insurance.extension is r4:Extension[] {
            r4:Extension[] extensions = <r4:Extension[]> insurance.extension;

            // Get the serviceItemRequestType from extensions
            if extensions.length() > 0 {
                r4:CodeableConceptExtension? codeableConceptExt = <r4:CodeableConceptExtension> extensions[0];
                if codeableConceptExt is r4:CodeableConceptExtension {
                    serviceItemRequestType = codeableConceptExt.valueCodeableConcept.text ?: "";
                }
            }

            // Get CertificationType from extensions
            if extensions.length() > 1 {
                r4:CodeableConceptExtension? certTypeExt = <r4:CodeableConceptExtension> extensions[1];
                if certTypeExt is r4:CodeableConceptExtension {
                    certificationType = certTypeExt.valueCodeableConcept.text ?: "";
                }
            }
        }
        
        CoverageInformation coverageInfo = {
            sequence: insurance.sequence,
            focal: insurance.focal,
            coverageReference: coverageRef,
            serviceItemRequestType: serviceItemRequestType,
            certificationType: certificationType
        };
        
        coverageList.push(coverageInfo);
    }
    
    return coverageList.length() > 0 ? coverageList : ();
}

# Calculate claim totals
#
# + items - Claim items
# + claimResponse - ClaimResponse or null
# + return - ClaimTotals
function calculateClaimTotals(ClaimItem[] items, international401:ClaimResponse? claimResponse) returns ClaimTotals|error {
    json? submitted = ();
    json? benefit = ();
    
    // Calculate submitted total from items
    decimal totalSubmitted = 0.0d;
    string currency = "USD";
    foreach ClaimItem item in items {
        if (item.net is ()){
            continue;
        }
        r4:Money net = check item.net.cloneWithType(r4:Money);
        totalSubmitted += net.value ?: 0.0d;
        currency = net.currency ?: "USD";
        
    }
        
    if totalSubmitted > 0.0d {
        submitted = {value: totalSubmitted, currency: currency};
    }
    
    // Extract benefit from ClaimResponse
    if claimResponse is international401:ClaimResponse {
        international401:ClaimResponseTotal[]? totals = claimResponse.total;
        if totals is international401:ClaimResponseTotal[] {
            foreach international401:ClaimResponseTotal tot in totals {
                r4:CodeableConcept category = tot.category;
                if category.coding is r4:Coding[] {
                    r4:Coding[] codings = <r4:Coding[]>category.coding;
                    if codings.length() > 0 && codings[0].code == "benefit" {
                        benefit = tot.amount.toJson();
                        break;
                    }
                }
            }
        }
    }
    
    return {
        submitted: submitted,
        benefit: benefit
    };
}

# Extract process notes from ClaimResponse
#
# + claimResponse - ClaimResponse or null
# + return - Array of process notes or null
function extractProcessNotes(international401:ClaimResponse? claimResponse) returns ProcessNote[]? {
    if claimResponse is () {
        return ();
    }
    
    ProcessNote[] notes = [];
    international401:ClaimResponseProcessNote[]? processNotes = claimResponse.processNote;
    if processNotes is international401:ClaimResponseProcessNote[] {
        foreach international401:ClaimResponseProcessNote noteItem in processNotes {
            ProcessNote note = {
                number: noteItem.number,
                text: noteItem.text,
                'type: noteItem.'type
            };
            notes.push(note);
        }
    }
    
    return notes.length() > 0 ? notes : ();
}

# Generate dummy AI analysis for a claim item
#
# + questionnaire - questionnaire JSON to analyze
# + return - AIAnalysis
public function generateAIAnalysis(json questionnaire) returns AIAnalysis {
    // Dummy implementation - returns random/sample data
    string[] recommendations = ["approved", "denied", "approved", "approved"];
    int[] confidenceScores = [87, 65, 92, 78];
    string[] summaries = [
        "Request aligns with medical necessity criteria based on clinical documentation.",
        "Insufficient documentation to support medical necessity for this service.",
        "All clinical criteria met. Strong supporting evidence from recent diagnostic tests.",
        "Request meets standard coverage criteria with documented prior treatments."
    ];
    
    int randomIndex = 3;
    
    CriteriaMatch[] criteriaMatches = [
        {criteria: "Documented clinical symptoms", met: true, details: "Chronic symptoms documented over 6 months"},
        {criteria: "Prior conservative treatments", met: true, details: "Previous therapies attempted without success"},
        {criteria: "Specialist recommendation", met: true, details: "Referred by board-certified specialist"}
    ];
    
    return {
        recommendation: recommendations[randomIndex],
        confidenceScore: confidenceScores[randomIndex],
        summary: summaries[randomIndex],
        criteriaMatches: criteriaMatches,
        riskLevel: confidenceScores[randomIndex] > 80 ? "Low" : "Medium",
        policyReference: "MED-2024-" + (randomIndex + 1).toString()
    };
}

// ============================================
// Adjudication Submission Functions
// ============================================

# Submit PA request adjudication
#
# + responseId - PA response (ClaimResponse) ID to submit adjudication for
# + adjudication - Adjudication submission data
# + return - AdjudicationResponse or error
public function submitPARequestAdjudication(string responseId, AdjudicationSubmission adjudication) returns AdjudicationResponse|error {
    
    // 1. Fetch Existing ClaimResponse 
    international401:ClaimResponse claimResponse = check getClaimResponse(responseId, limited = false);

    davincipas:PASClaimResponse pasClaimResponse = check claimResponse.cloneWithType(davincipas:PASClaimResponse);

    // 2. Modify the claimResponse with adjudication data
    
    // Update outcome based on decision
    pasClaimResponse.outcome = check adjudication.decision.cloneWithType(davincipas:PASClaimResponseOutcome);
    pasClaimResponse.disposition = adjudication.decision;
    
    // Build item adjudications
    davincipas:PASClaimResponseItem[] items = [];
    foreach ItemAdjudicationSubmission itemAdj in adjudication.itemAdjudications {
        
        // Create adjudication array for this item
        davincipas:PASClaimResponseItemAdjudication[] adjudicationArray = [];
        
        // Add the main adjudication category
        davincipas:PASClaimResponseItemAdjudication mainAdj = {
            category: {
                coding: [
                    {
                        system: "http://terminology.hl7.org/CodeSystem/adjudication",
                        code: itemAdj.adjudicationCode,
                        display: itemAdj.adjudicationCode
                    }
                ]
            }
        };
        adjudicationArray.push(mainAdj);
        
        // Add benefit amount if approved
        if itemAdj.approvedAmount is decimal {
            davincipas:PASClaimResponseItemAdjudication benefitAdj = {
                category: {
                    coding: [
                        {
                            system: "http://terminology.hl7.org/CodeSystem/adjudication",
                            code: "benefit",
                            display: "Benefit Amount"
                        }
                    ]
                },
                amount: {
                    value: <decimal>itemAdj.approvedAmount,
                    currency: "USD"
                }
            };
            adjudicationArray.push(benefitAdj);
        }
        
        // Create the item response
        davincipas:PASClaimResponseItem item = {
            itemSequence: itemAdj.sequence,
            adjudication: adjudicationArray
        };
        
        items.push(item);
    }
    
    pasClaimResponse.item = items;
    
    // Build process notes
    davincipas:PASClaimResponseProcessNote[] processNotes = [];
    int noteNumber = 1;
    
    // Add reviewer notes
    if adjudication.reviewerNotes is string {
        davincipas:PASClaimResponseProcessNote reviewerNote = {
            number: noteNumber,
            'type: "display",
            text: <string>adjudication.reviewerNotes
        };
        processNotes.push(reviewerNote);
        noteNumber += 1;
    }
    
    // Add item-specific notes and link them to corresponding items
    foreach ItemAdjudicationSubmission itemAdj in adjudication.itemAdjudications {
        if itemAdj.itemNotes is string {
            davincipas:PASClaimResponseProcessNote itemNote = {
                number: noteNumber,
                'type: "display",
                text: <string>itemAdj.itemNotes
            };
            processNotes.push(itemNote);
            
            // Find the corresponding item and assign the note reference
            foreach davincipas:PASClaimResponseItem item in items {
                if item.itemSequence == itemAdj.sequence {
                    item.noteNumber = [noteNumber];
                    break;
                }
            }
            
            noteNumber += 1;
        }
    }
    
    if processNotes.length() > 0 {
        pasClaimResponse.processNote = processNotes;
    }

    // 3. Post the updated ClaimResponse back to the FHIR server
    // json claimResponseJson = pasClaimResponse.toJson();
    json|http:ClientError updateResponse = fhirHttpClient->put(string`${CLAIM_RESPONSE}/${responseId}`, pasClaimResponse, 
                                            headers = {"Content-Type": "application/fhir+json"}
                                        );
    
    if updateResponse is http:ClientError {
        log:printError("Failed to update ClaimResponse: " + updateResponse.message());
        return error("Failed to update ClaimResponse: " + updateResponse.message());
    }
    
    return {
        id: <string>pasClaimResponse.id,
        status: adjudication.decision,
        message: "Adjudication submitted successfully"
    };
}

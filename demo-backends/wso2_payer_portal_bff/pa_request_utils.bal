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
import ballerina/sql;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.davincipas;
import ballerina/uuid;

// ============================================
// Prior Authorization Request Utility Functions
// ============================================

const string ORGANIZATION = "/Organization";
const string CLAIM = "/Claim";
const string CLAIM_RESPONSE = "/ClaimResponse";

# Query PA requests from the pa_requests database table
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

    sql:ParameterizedQuery whereClause = ` WHERE 1=1`;

    if search is string && search.trim().length() > 0 {
        string escaped = re`\\`.replaceAll(search, "\\\\");
        escaped = re`%`.replaceAll(escaped, "\\%");
        escaped = re`_`.replaceAll(escaped, "\\_");
        string searchPattern = "%" + escaped + "%";
        whereClause = sql:queryConcat(whereClause, ` AND (patient_id LIKE ${searchPattern} ESCAPE '\\' OR request_id LIKE ${searchPattern} ESCAPE '\\')`);
    }

    PARequestUrgency[] effectiveUrgency = (urgency is PARequestUrgency[] && urgency.length() > 0)
        ? urgency
        : ["Urgent", "Standard", "Deferred"];
    sql:ParameterizedQuery urgencyInClause = ` AND priority IN (`;
    foreach int i in 0 ..< effectiveUrgency.length() {
        if i > 0 {
            urgencyInClause = sql:queryConcat(urgencyInClause, `, `);
        }
        urgencyInClause = sql:queryConcat(urgencyInClause, `${effectiveUrgency[i]}`);
    }
    urgencyInClause = sql:queryConcat(urgencyInClause, `)`);
    whereClause = sql:queryConcat(whereClause, urgencyInClause);

    if status is PARequestProcessingStatus[] && status.length() > 0 {
        string[] dbStatuses = [];
        foreach PARequestProcessingStatus s in status {
            if s == "Pending" {
                dbStatuses.push("PENDING_ON_PROVIDER");
                dbStatuses.push("PENDING_ON_PAYER");
                dbStatuses.push("QUEUED");
            } else if s == "Completed" {
                dbStatuses.push("COMPLETED");
            } else if s == "Error" {
                dbStatuses.push("ERROR");
            }
        }
        if dbStatuses.length() > 0 {
            sql:ParameterizedQuery statusInClause = ` AND status IN (`;
            foreach int i in 0 ..< dbStatuses.length() {
                if i > 0 {
                    statusInClause = sql:queryConcat(statusInClause, `, `);
                }
                statusInClause = sql:queryConcat(statusInClause, `${dbStatuses[i]}`);
            }
            statusInClause = sql:queryConcat(statusInClause, `)`);
            whereClause = sql:queryConcat(whereClause, statusInClause);
        }
    }

    record {| int count; |} countResult = check dbClient->queryRow(
        sql:queryConcat(`SELECT COUNT(*) AS count FROM pa_requests`, whereClause)
    );

    sql:ParameterizedQuery dataQuery = sql:queryConcat(
        `SELECT request_id, response_id, priority, patient_id, practitioner_id, provider_name, date_submitted FROM pa_requests`,
        whereClause,
        ` ORDER BY date_submitted DESC LIMIT ${pageSize} OFFSET ${(page - 1) * pageSize}`
    );

    stream<PARequestDBRow, sql:Error?> dataStream = dbClient->query(dataQuery, PARequestDBRow);
    PARequestDBRow[] rows = check from PARequestDBRow row in dataStream select row;

    PARequestListItem[] paRequests = [];
    foreach PARequestDBRow row in rows {
        paRequests.push({
            requestId: row.request_id,
            responseId: row.response_id ?: "",
            urgency: <PARequestUrgency>row.priority,
            patientId: row.patient_id,
            practitionerId: row.practitioner_id,
            provider: row.provider_name ?: "Unknown Provider",
            dateSubmitted: row.date_submitted ?: ""
        });
    }

    return [paRequests, countResult.count];
}

# Get PA request analytics from the pa_requests database table
#
# + return - PARequestAnalytics or error
function getPARequestAnalytics() returns PARequestAnalytics|error {
    record {| int urgentCount; int standardCount; int reAuthorizationCount; int appealCount; |} result = check dbClient->queryRow(
        `SELECT
            COUNT(IF(priority = 'Urgent', 1, NULL)) AS urgentCount,
            COUNT(IF(priority = 'Standard', 1, NULL)) AS standardCount,
            COUNT(IF(priority = 'Deferred', 1, NULL)) AS reAuthorizationCount,
            COUNT(IF(is_appeal = TRUE, 1, NULL)) AS appealCount
        FROM pa_requests`
    );
    return {
        urgentCount: result.urgentCount,
        standardCount: result.standardCount,
        reAuthorizationCount: result.reAuthorizationCount,
        appealCount: result.appealCount
    };
}

// ============================================
// PA Request Detail Functions
// ============================================

# Get complete PA request detail by ID
#
# + responseId - The ClaimResponse ID (if available) to get processing status and notes
# + return - PARequestDetail or error
public function getPARequestDetail(string responseId) returns PARequestDetail|error {
    // 1. Fetch pre-computed fields from DB using response_id
    PARequestDBRow dbRow = check dbClient->queryRow(
        `SELECT request_id, response_id, priority, patient_id, practitioner_id, provider_name, date_submitted
        FROM pa_requests WHERE response_id = ${responseId}`,
        PARequestDBRow
    );
    string requestId = dbRow.request_id;
    PARequestUrgency priority = <PARequestUrgency>dbRow.priority;
    string patientId = dbRow.patient_id;
    string created = dbRow.date_submitted ?: "";

    // 2. Fetch ClaimResponse (needed for adjudication, process notes, totals, and outcome status)
    international401:ClaimResponse claimResponse = check getClaimResponse(responseId, limited = false);

    // 3. Fetch Claim directly using request_id from DB (no need to parse ClaimResponse.request)
    json claim = check fhirHttpClient->get(string `${CLAIM}/${requestId}`);
    international401:Claim pasClaim = <international401:Claim> check parser:parse(claim, international401:Claim);

    // 4. Get IPS summary using patient_id from DB (no need to parse Claim.patient.reference)
    PatientInformation patientInfo = check getPatientIPSSummary(patientId);

    // 5. Extract provider information from Claim
    ProviderInformation providerInfo = check getProviderInformation(pasClaim.provider);

    // 6. Parse claim items with adjudication data from ClaimResponse
    ClaimItem[] items = check parseClaimItems(<international401:ClaimItem[]>pasClaim.item, claimResponse);

    // 7. Get the supporting information
    [string?, string?, string?, json[]?, json[]?] supportingInfo = check extractSupportingInformation(pasClaim.supportingInfo);
    string? admissionDate = supportingInfo[0];
    string? dischargeDate = supportingInfo[1];
    string? clinicalJustification = supportingInfo[2];
    json[]? questionnairesJson = supportingInfo[3];
    json[]? attachmentsJson = supportingInfo[4];

    QuestionnaireResponseItem[] questionnaireItems = [];
    if questionnairesJson != () {
        foreach json questionnaire in questionnairesJson {
            QuestionnaireResponseItem item = {
                questionnaire: questionnaire,
                analysis: generateAIAnalysis(questionnaire)
            };
            questionnaireItems.push(item);
        }
    }

    // 8. Build PARequestDetail using priority and dates from DB
    string status = claimResponse.outcome;
    string? targetDate = ();
    if priority == "Urgent" {
        targetDate = check AddDurationToDate(created, "3");
    } else if priority == "Deferred" {
        targetDate = check AddDurationToDate(created, "30");
    } else {
        targetDate = check AddDurationToDate(created, "7");
    }

    RequestSummary summary = {
        serviceType: extractServiceType(items), // TODO
        clinicalJustification: clinicalJustification,
        submittedDate: created,
        targetDate: targetDate
    };

    CoverageInformation[]? coverage = extractCoverageInfo(pasClaim.insurance);

    ClaimTotals|error total = calculateClaimTotals(items, claimResponse);
    if total is error {
        log:printError("Failed to calculate claim totals: " + total.message());
        return total;
    }

    ProcessNote[]? processNotes = extractProcessNotes(claimResponse);

    // 9. Fetch linked CommunicationRequests from ClaimResponse references
    CommunicationRequestItem[] communicationRequests = [];
    if claimResponse.communicationRequest is r4:Reference[] {
        foreach r4:Reference commRef in <r4:Reference[]>claimResponse.communicationRequest {
            string? refStr = commRef.reference;
            if refStr is string {
                json|http:ClientError commReqJson = fhirHttpClient->get(string `/${refStr}`);
                if commReqJson is json {
                    CommunicationRequestItem|error commReqItem = parseCommunicationRequest(commReqJson);
                    if commReqItem is CommunicationRequestItem {
                        communicationRequests.push(commReqItem);
                    } else {
                        log:printWarn("Failed to parse CommunicationRequest " + refStr + ": " + commReqItem.message());
                    }
                } else {
                    log:printWarn("Failed to fetch CommunicationRequest " + refStr + ": " + commReqJson.message());
                }
            }
        }
    }

    return {
        id: requestId,
        responseId: responseId,
        status: status,
        use: "preauthorization",
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
        processNotes: processNotes,
        communicationRequests: communicationRequests.length() > 0 ? communicationRequests : ()
    };
}

# Look up the display name for a code in a given FHIR ValueSet via $validate-code
#
# + code - The code to look up
# + valueSetUrl - Canonical URL of the ValueSet to validate against
# + valuesetID - The ID of the ValueSet (used in the API path)
# + return - Display string from the ValueSet, or () if not found / lookup fails
function lookupValueSetDisplay(string code, string valueSetUrl, string valuesetID) returns string? {
    string path = string `/ValueSet/${valuesetID}/$validate-code?url=${valueSetUrl}&code=${code}&system=http://loinc.org`;
    json|http:ClientError result = fhirHttpClient->get(path);
    if result is map<json> {
        json params = result["parameter"];
        if params is json[] {
            foreach json param in params {
                if param is map<json> {
                    json nameJson = param["name"];
                    if nameJson is string && nameJson == "display" {
                        json display = param["valueString"];
                        if display is string {
                            return display;
                        }
                    }
                }
            }
        }
    }
    return ();
}

# Parse a FHIR CommunicationRequest JSON into a CommunicationRequestItem.
# Uses international401:CommunicationRequest for type safety and enriches each
# payload code via the PAS LOINC attachment ValueSet and the reason code
# via the v3-ActReason ValueSet.
#
# + commReqJson - FHIR CommunicationRequest resource as JSON
# + return - CommunicationRequestItem or error
function parseCommunicationRequest(json commReqJson) returns CommunicationRequestItem|error {
    international401:CommunicationRequest commReq = <international401:CommunicationRequest> check parser:parse(commReqJson);

    string id = commReq.id ?: "";

    string statusStr = <string>commReq.status;
    CommunicationRequestStatus status = statusStr is CommunicationRequestStatus ? statusStr : "unknown";

    string priorityStr = commReq.priority is international401:CommunicationRequestPriority
        ? <string>commReq.priority : "routine";
    PARequestPriority priority = priorityStr is PARequestPriority ? priorityStr : "routine";

    // Build AdditionalInfoItem list — each payload contentString is a LOINC attachment code
    AdditionalInfoItem[] requestedItems = [];
    if commReq.payload is international401:CommunicationRequestPayload[] {
        foreach international401:CommunicationRequestPayload payloadItem in
                <international401:CommunicationRequestPayload[]>commReq.payload {
            string? code = payloadItem.contentString;
            if code is string {
                requestedItems.push({
                    code: code,
                    display: lookupValueSetDisplay(code, PAS_ATTACHMENT_CODES_VALUESET_URL, PAS_ATTACHMENT_CODE_ID)
                });
            }
        }
    }

    // Resolve reasonCode display from v3-ActReason ValueSet; fall back to .text then raw code
    string? reasonCode = ();
    if commReq.reasonCode is r4:CodeableConcept[] {
        r4:CodeableConcept[] reasons = <r4:CodeableConcept[]>commReq.reasonCode;
        if reasons.length() > 0 {
            r4:CodeableConcept first = reasons[0];
            if first.coding is r4:Coding[] {
                r4:Coding[] codings = <r4:Coding[]>first.coding;
                if codings.length() > 0 && codings[0].code is string {
                    string actCode = <string>codings[0].code;
                    reasonCode = lookupValueSetDisplay(actCode, PAS_ACT_REASON_VALUESET_URL, PAS_ACT_REASON_CODE_ID)
                        ?: first.text
                        ?: actCode;
                }
            } else {
                reasonCode = first.text;
            }
        }
    }

    return {
        id: id,
        status: status,
        priority: priority,
        requestedItems: requestedItems,
        reasonCode: reasonCode,
        requestedDate: commReq.occurrenceDateTime
    };
}

# Get ClaimResponse for a given Claim ID
#
# + claimResId - The ClaimResponse resource ID
# + limited - Whether to fetch a limited set of elements
# + return - ClaimResponse JSON or null if not found
function getClaimResponse(string claimResId, boolean limited=true) returns international401:ClaimResponse|error{
    string claimResponsePath = string `${CLAIM_RESPONSE}/${claimResId}`;
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
    json|error ipsSummary = fhirHttpClient->get(string `/Patient/${patientId}/$summary`);
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

# Parse Patient resource to PatientInformation
#
# + patient - Patient resource
# + return - PatientInformation or error
function parsePatientResource(international401:Patient patient) returns PatientInformation|error {
    string patientId = patient.id ?: "unknown";

    // Extract name - work with anydata
    string fullName = "Unknown";
    r4:HumanName[] nameData = patient.name ?: [];
    if nameData.length() > 0 {
        r4:HumanName firstNameData = nameData[0];
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
    r4:date? birthDate = patient.birthDate;

    // Extract gender
    international401:PatientGender gender = patient.gender ?: "unknown";

    PatientDemographics demographics = {
        name: fullName,
        dateOfBirth: birthDate ?: "unknown",
        age: birthDate is r4:date ? calculateAge(birthDate) : (),
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

    international401:Patient? patientResource = ();
    international401:AllergyIntolerance[] allergyResources = [];
    international401:MedicationStatement[] medicationResources = [];

    foreach r4:BundleEntry entry in <r4:BundleEntry[]>ipsBundle.entry{
        if (<string>(<r4:uri>entry.fullUrl)).includes("Patient"){
            patientResource = check (entry?.'resource).cloneWithType(international401:Patient);
        } else if (<string>(<r4:uri>entry.fullUrl)).includes("AllergyIntolerance"){
            international401:AllergyIntolerance allergyResource = check (entry?.'resource).cloneWithType(international401:AllergyIntolerance);
            allergyResources.push(allergyResource);
        } else if (<string>(<r4:uri>entry.fullUrl)).includes("MedicationStatement"){
            international401:MedicationStatement medicationResource = check (entry?.'resource).cloneWithType(international401:MedicationStatement);
            medicationResources.push(medicationResource);
        }
    }

    // Parse patient demographics from the patient field
    PatientInformation patientInfo = check parsePatientResource(<international401:Patient>patientResource);

    // Extract allergies from allergyIntolerance array
    AllergyIntolerance[] allergies = [];
    foreach international401:AllergyIntolerance allergyResource in allergyResources {
        AllergyIntolerance? allergy = parseAllergy(allergyResource);
        if allergy is AllergyIntolerance {
            allergies.push(allergy);
        }
    }

    // Extract medications from medicationStatement array
    MedicationStatement[] medications = [];
    foreach international401:MedicationStatement medResource in medicationResources {
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
# + allergyResource - AllergyIntolerance resource
# + return - AllergyIntolerance or null
function parseAllergy(international401:AllergyIntolerance allergyResource) returns AllergyIntolerance? {
    r4:CodeableConcept? code = allergyResource.code;
    string substance = "Unknown";
    if code is r4:CodeableConcept {
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
# + medResource - MedicationStatement resource
# + return - MedicationStatement or null
function parseMedicationStatement(international401:MedicationStatement medResource) returns MedicationStatement? {
    if medResource.status != "active" {
        return ();
    }
    string medication = "";
    r4:CodeableConcept? medCodeData = medResource.medicationCodeableConcept;
    if medCodeData is r4:CodeableConcept {
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
    json practitionerRoleRes = check fhirHttpClient->get(string `/PractitionerRole/${practitionerId}`);
    international401:PractitionerRole practitionerRole = <international401:PractitionerRole> check parser:parse(practitionerRoleRes);

    json practitionerRes = check fhirHttpClient->get(string `/${<string>practitionerRole.practitioner?.reference}`);
    international401:Practitioner practitioner = <international401:Practitioner> check parser:parse(practitionerRes);

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
    json organizationJson = check fhirHttpClient->get(string `${ORGANIZATION}/${organizationId}`);
    international401:Organization org = check organizationJson.cloneWithType(international401:Organization);

    // Extract organization name
    string orgName = org.name ?: "Unknown Facility";
    
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
    json organizationJson = check fhirHttpClient->get(string `${ORGANIZATION}/${organizationId}`);
    international401:Organization org = check organizationJson.cloneWithType(international401:Organization);
    
    // Extract organization name
    string orgName = org.name ?: "Unknown Organization";
    
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
function extractSupportingInformation(international401:ClaimSupportingInfo[]? supportingInfo) returns [string?, string?, string?, json[]?, json[]?]|error {
    string? admissionDate = ();
    string? dischargeDate = ();
    string? clinicalJustification = ();
    json[] questionnaires = [];
    json[] attachments = [];
    
    if supportingInfo is () {
        return [admissionDate, dischargeDate, (), (), ()];
    }
    
    foreach international401:ClaimSupportingInfo info in supportingInfo {
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
# + claimResponse - ClaimResponse resource (optional) to extract adjudication data
# + return - Array of ClaimItems or error
function parseClaimItems(international401:ClaimItem[] pasClaimItems, international401:ClaimResponse? claimResponse = ()) returns ClaimItem[]|error {
    ClaimItem[] items = [];
    
    foreach international401:ClaimItem pasItem in pasClaimItems {
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
        
        // Extract adjudication data from ClaimResponse if available
        json[]? adjudication = ();
        int[]? noteNumbers = ();
        string? reviewNote = ();
        
        if claimResponse is international401:ClaimResponse {
            international401:ClaimResponseItem[]? responseItems = claimResponse.item;
            if responseItems is international401:ClaimResponseItem[] {
                // Find matching item by sequence
                foreach international401:ClaimResponseItem responseItem in responseItems {
                    if responseItem.itemSequence == pasItem.sequence {
                        // Extract adjudication array
                        international401:ClaimResponseItemAdjudication[] adjArray = <international401:ClaimResponseItemAdjudication[]>responseItem.adjudication;
                        json[] adjJsonArray = [];
                        foreach international401:ClaimResponseItemAdjudication adj in adjArray {
                            adjJsonArray.push(adj.toJson());
                        }
                        adjudication = adjJsonArray;  
                        
                        // Extract note numbers
                        if responseItem.noteNumber is int[] {
                            noteNumbers = <int[]>responseItem.noteNumber;
                            
                            // Extract review note text from processNote
                            if claimResponse.processNote is international401:ClaimResponseProcessNote[] {
                                international401:ClaimResponseProcessNote[] processNotes = <international401:ClaimResponseProcessNote[]>claimResponse.processNote;
                                foreach int noteNum in <int[]>noteNumbers {
                                    foreach international401:ClaimResponseProcessNote note in processNotes {
                                        if note.number == noteNum {
                                            reviewNote = note.text;
                                            break;
                                        }
                                    }
                                    if reviewNote is string {
                                        break;
                                    }
                                }
                            }
                        }
                        break;
                    }
                }
            }
        }
        
        ClaimItem item = {
            sequence: pasItem.sequence,
            productOrService: productOrServiceJson,
            description: description,
            quantity: quantityJson,
            unitPrice: unitPriceJson,
            net: netJson,
            servicedDate: pasItem.servicedDate,
            servicedPeriod: servicedPeriodJson,
            adjudication: adjudication,
            noteNumbers: noteNumbers,
            reviewNote: reviewNote
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
function extractCoverageInfo(international401:ClaimInsurance[]? insuranceArray) returns CoverageInformation[]? {
    if insuranceArray is () || insuranceArray.length() == 0 {
        return ();
    }
    
    CoverageInformation[] coverageList = [];
    
    foreach international401:ClaimInsurance insurance in insuranceArray {
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

    international401:ClaimResponse pasClaimResponse = check claimResponse.cloneWithType(international401:ClaimResponse);

    // 2. Modify the claimResponse with adjudication data
    
    // Update outcome based on decision
    pasClaimResponse.outcome = check adjudication.decision.cloneWithType(international401:ClaimResponseOutcome);
    pasClaimResponse.disposition = adjudication.decision;
    
    // Build item adjudications
    international401:ClaimResponseItem[] items = [];
    foreach ItemAdjudicationSubmission itemAdj in adjudication.itemAdjudications {
        
        // Create adjudication array for this item
        international401:ClaimResponseItemAdjudication[] adjudicationArray = [];
        
        // Add the main adjudication category
        international401:ClaimResponseItemAdjudication mainAdj = {
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
            international401:ClaimResponseItemAdjudication benefitAdj = {
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
        international401:ClaimResponseItem item = {
            itemSequence: itemAdj.sequence,
            adjudication: adjudicationArray
        };
        
        items.push(item);
    }
    
    pasClaimResponse.item = items;
    
    // Build process notes
    international401:ClaimResponseProcessNote[] processNotes = [];
    int noteNumber = 1;
    
    // Add reviewer notes
    if adjudication.reviewerNotes is string {
        international401:ClaimResponseProcessNote reviewerNote = {
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
            international401:ClaimResponseProcessNote itemNote = {
                number: noteNumber,
                'type: "display",
                text: <string>itemAdj.itemNotes
            };
            processNotes.push(itemNote);
            
            // Find the corresponding item and assign the note reference
            foreach international401:ClaimResponseItem item in items {
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
        sql:ParameterizedQuery errorStatusQuery = `UPDATE pa_requests SET status = 'ERROR' WHERE response_id = ${responseId}`;
        sql:ExecutionResult|sql:Error errorDbResult = dbClient->execute(errorStatusQuery);
        if errorDbResult is sql:Error {
            log:printError("Failed to update pa_requests status to ERROR: " + errorDbResult.message());
        }
        return error("Failed to update ClaimResponse: " + updateResponse.message());
    }

    sql:ParameterizedQuery completedStatusQuery = `UPDATE pa_requests SET status = 'COMPLETED' WHERE response_id = ${responseId}`;
    sql:ExecutionResult|sql:Error completedDbResult = dbClient->execute(completedStatusQuery);
    if completedDbResult is sql:Error {
        log:printError("Failed to update pa_requests status to COMPLETED: " + completedDbResult.message());
    }

    return {
        id: <string>pasClaimResponse.id,
        status: adjudication.decision,
        message: "Adjudication submitted successfully"
    };
}

// ============================================
// Request Additional Information Submission Functions
// ============================================

# Submit PA request additional information request
#
# + responseId - PA response (ClaimResponse) ID to submit additional information for
# + additionalInformation - Additional information submission data
# + return - AdditionalInfoResponse or error
public function submitPARequestAdditionalInfo(string responseId, AdditionalInformation additionalInformation) 
    returns AdditionalInfoResponse|error {
    // Fetch existing ClaimResponse
    international401:ClaimResponse claimResponse = check getClaimResponse(responseId, limited = false);
    
    // create communication request for additional information using the data from additionalInformation and 
    // link it to the claim response
    davincipas:PASCommunicationRequestPayload[] payload = [];
    foreach string code in additionalInformation.informationCodes {
        davincipas:PASCommunicationRequestPayload payloadItem = {
            contentString: code
        };
        payload.push(payloadItem);
    }

    r4:Reference? subjectJson = claimResponse.patient;

    r4:Reference? requestRef = claimResponse.request;
    r4:Reference[] about = requestRef != () ? [requestRef] : [];
    r4:CodeableConcept[] reasonCode = [];
    if additionalInformation.reasonCode is r4:CodeableConcept[] {
        reasonCode = <r4:CodeableConcept[]>additionalInformation.reasonCode;
    } else {
        reasonCode = [{
            coding: [{
                system: "http://terminology.hl7.org/CodeSystem/v3-ActReason",
                code: "priorAuthorization"
            }]
        }];
    }

    davincipas:PASCommunicationRequest communicationRequest = {
        resourceType: "CommunicationRequest",
        id: uuid:createType1AsString(),
        meta: {
            profile: ["http://hl7.org/fhir/us/davinci-pas/StructureDefinition/profile-communicationrequest"]
        },
        status: "active",
        category: [
            {
                coding: [
                    {
                        "system": "http://terminology.hl7.org/CodeSystem/communication-category",
                        "code": "instruction"
                    }
                ]
            }
        ],
        priority: additionalInformation.priority,
        occurrenceDateTime: time:utcToString(time:utcNow()),
        subject: subjectJson,
        about: about,
        reasonCode: reasonCode,
        payload: payload
    };

    json|http:ClientError communicationResponse = fhirHttpClient->post("/CommunicationRequest", communicationRequest, 
        headers = {"Content-Type": "application/fhir+json"});
    if communicationResponse is http:ClientError {
        log:printError("Failed to create CommunicationRequest: " + communicationResponse.message());
        return error("Failed to create CommunicationRequest: " + communicationResponse.message());
    }

    string commId = "";
    json|error commIdJson = communicationResponse.id;
    if commIdJson is string {
        commId = commIdJson;
    }

    if commId.length() == 0 {
        return error("CommunicationRequest ID not found in response");
    }

    log:printDebug(string `Communication request created with id: ${commId}`);
    
    r4:Reference[] commRefs = [];
    if claimResponse.communicationRequest is r4:Reference[] {
        commRefs = <r4:Reference[]>claimResponse.communicationRequest;
    }
    commRefs.push({ reference: "CommunicationRequest/" + commId });
    claimResponse.communicationRequest = commRefs;

    json claimResponseJson = claimResponse.toJson();
    json|http:ClientError updateResponse = fhirHttpClient->put(CLAIM_RESPONSE + "/" + responseId, claimResponseJson, headers = {"Content-Type": "application/fhir+json"});
    if updateResponse is http:ClientError {
        log:printError("Failed to update ClaimResponse with CommunicationRequest: " + updateResponse.message());
        return error("Failed to update ClaimResponse with CommunicationRequest: " + updateResponse.message());
    }
    log:printDebug("ClaimResponse updated with CommunicationRequest reference: " + commId);
    sql:ParameterizedQuery pendingProviderQuery = `UPDATE pa_requests SET status = 'PENDING_ON_PROVIDER' WHERE response_id = ${responseId}`;
    sql:ExecutionResult|sql:Error pendingDbResult = dbClient->execute(pendingProviderQuery);
    if pendingDbResult is sql:Error {
        log:printError("Failed to update pa_requests status to PENDING_ON_PROVIDER: " + pendingDbResult.message());
    }
    return {
        id: commId,
        status: "active",
        message: "Additional information request submitted successfully"
    };
}

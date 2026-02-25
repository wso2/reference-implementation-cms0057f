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

import ballerina/constraint;
import ballerinax/health.fhir.r4;

# Database configuration.
#
# + host - Database host
# + port - Database port
# + user - Database user
# + password - Database password
# + database - Database name
public type DatabaseConfig record {|
    string host;
    int port;
    string user;
    string password;
    string database;
|};

# Input for creating or updating a payer
public type PayerFormData record {
    # Payer organization name
    @constraint:String {maxLength: 255, minLength: 1}
    string name;
    # Contact email
    string email;
    # Mailing address
    string? address;
    # State of operation
    string state?;
    # FHIR server base URL
    string fhir_server_url;
    # OAuth client ID for FHIR server
    string app_client_id;
    # OAuth client secret for FHIR server
    string app_client_secret;
    # SMART on FHIR configuration URL
    string smart_config_url;
    # Optional scopes for OAuth token request
    string? scopes;
};

# Payer resource with system-generated fields
public type Payer record {
    *PayerFormData;
    # Creation timestamp
    string createdAt?;
    # Last update timestamp
    string updatedAt?;
};

public type PayerListResponse record {
    Payer[] data;
    PaginationMeta pagination;
};

public type PaginationMeta record {
    # Current page number
    int page;
    # Items per page
    int 'limit;
    # Total number of items
    int totalCount;
    # Total number of pages
    int totalPages;
};

// Questionnaire-related types

# Publication status of the questionnaire
public type QuestionnaireStatus "draft"|"active"|"retired"|"unknown";

public type QuestionnaireListItem record {
    # Questionnaire ID
    string id;
    # Questionnaire title
    string title;
    # Questionnaire description
    string description?;
    # Publication status of the questionnaire
    QuestionnaireStatus status;
    string createdAt?;
    string updatedAt?;
};

public type QuestionnaireListResponse record {
    QuestionnaireListItem[] data;
    PaginationMeta pagination;
};

# Type of PA request
public type PARequestProcessingStatus "Pending" | "Completed" | "Error"; // This will be mapped from the PAS Claim Response outcome: pending (queued), complete (approved/denied), error (error)

# Urgency of PA request
public type PARequestUrgency "Urgent"|"Standard"|"Deferred";

# This is a filtered response of the FHIR PAS Claim and FHIR PAS Claim Response resources
#
# + requestId - PA request unique identifier  
# + responseId - PA response unique identifier
# + patientId - ID of the patient associated with the PA request
# + practitionerId - ID of the practitioner who submitted the PA request
# + provider - Name of the provider associated with the PA request
# + dateSubmitted - Date when the PA request was submitted
public type PARequestListItem record {
    string requestId; // PAS Claim.id
    string responseId; // PAS ClaimResponse.id
    # Type of PA request
    PARequestUrgency urgency; // map with priority - stat (urgent), normal (standard), deferred (later anytime)
    string patientId; // PAS Claim.patient
    string practitionerId?; // PAS Claim.requestor (This can be either practitioner or organization, but we'll assume practitioner for this context)
    string provider; // This can be derived from the practitioner or organization details, but we'll keep it simple here
    string dateSubmitted; // PAS Claim.created
};


# This is the analytics data related to PAS Claims from postgresql database
#
# + urgentCount - field description  
# + standardCount - field description  
# + reAuthorizationCount - field description  
# + appealCount - field description
public type PARequestAnalytics record {
    int urgentCount;
    int standardCount;
    int reAuthorizationCount;
    int appealCount;
};

public type PARequestListResponse record {
    PARequestListItem[] data;
    PaginationMeta pagination;
    PARequestAnalytics analytics;
};

type QuestionnaireResponseItem record {
    json questionnaire;
    AIAnalysis analysis;
};

# PA Request Detail - Complete information for a specific PA request
#
# + id - field description  
# + responseId - field description
# + status - field description  
# + use - field description  
# + created - field description  
# + targetDate - field description  
# + admissionDate - field description
# + dischargeDate - field description
# + questionnaires - field description
# + attachments - field description
# + priority - field description  
# + summary - field description  
# + patient - field description  
# + provider - field description  
# + items - field description  
# + coverage - field description  
# + total - field description  
# + processNotes - field description
public type PARequestDetail record {
    string id;
    string responseId;
    string status;
    string use?;
    string created;
    string? targetDate;
    string? admissionDate;
    string? dischargeDate;
    QuestionnaireResponseItem[]? questionnaires;
    json[]? attachments;
    PARequestUrgency priority;
    RequestSummary summary;
    PatientInformation patient;
    ProviderInformation provider;
    ClaimItem[] items;
    CoverageInformation[]? coverage;
    ClaimTotals total;
    ProcessNote[]? processNotes;
};

# Request Summary
#
# + serviceType - field description  
# + clinicalJustification - field description  
# + submittedDate - field description  
# + targetDate - field description
public type RequestSummary record {
    string serviceType;
    string? clinicalJustification;
    string submittedDate;
    string? targetDate;
};

# Patient Information (IPS-based)
#
# + id - field description  
# + demographics - field description  
# + allergies - field description  
# + medications - field description
public type PatientInformation record {
    string id;
    PatientDemographics demographics;
    AllergyIntolerance[]? allergies;
    MedicationStatement[]? medications;
};

# Patient Demographics
#
# + name - field description  
# + dateOfBirth - field description  
# + age - field description  
# + gender - field description  
# + mrn - field description  
public type PatientDemographics record {
    string name;
    string dateOfBirth;
    int? age;
    string gender;
    string? mrn;
};

# Allergy Intolerance
#
# + substance - field description  
# + severity - field description  
public type AllergyIntolerance record {
    string substance;
    string? severity;
};

# Medication Statement
#
# + medication - field description  
# + status - field description
public type MedicationStatement record {
    string medication;
    string? status;
};

# Provider Information
#
# + id - field description  
# + name - field description  
# + specialty - field description  
# + initials - field description  
# + contact - field description  
# + facility - field description
public type ProviderInformation record {
    string id;
    string name;
    string? specialty;
    string? initials;
    ProviderContact? contact;
    Facility? facility;
};

# Provider Contact
#
# + phone - field description  
# + email - field description
public type ProviderContact record {
    string? phone;
    string? email;
};

# Facility
#
# + name - field description  
# + address - field description
public type Facility record {
    string name;
    Address? address;
};

# Address
#
# + line - field description  
# + city - field description  
# + state - field description  
# + postalCode - field description
public type Address record {
    string[] line;
    string? city;
    string? state;
    string? postalCode;
};

# Coverage Information
#
# + sequence - Insurance sequence number
# + focal - Whether this is the primary insurance
# + coverageReference - Reference to the Coverage resource
# + serviceItemRequestType - Service item request type (reserved for future use)
# + certificationType - Certification type (reserved for future use)
public type CoverageInformation record {
    int sequence;
    boolean focal;
    string coverageReference;
    string? serviceItemRequestType;
    string? certificationType;
};

# Claim Item
#
# + sequence - field description  
# + productOrService - field description  
# + description - field description  
# + quantity - field description  
# + unitPrice - field description  
# + net - field description  
# + servicedDate - field description  
# + servicedPeriod - field description  
# + adjudication - field description  
# + noteNumbers - field description  
# + reviewNote - field description
public type ClaimItem record {
    int sequence;
    json productOrService; // FHIR CodeableConcept
    string? description;
    json? quantity; // FHIR Quantity
    json? unitPrice; // FHIR Money
    json? net; // FHIR Money
    string? servicedDate;
    json? servicedPeriod;
    json[]? adjudication;
    int[]? noteNumbers;
    string? reviewNote;
};

# Patient Event Dates
#
# + eventStartDate - field description  
# + eventEndDate - field description  
# + admissionDate - field description  
# + dischargeDate - field description  
# + expectedDischargeDate - field description
public type PatientEventDates record {
    string? eventStartDate;
    string? eventEndDate;
    string? admissionDate;
    string? dischargeDate;
    string? expectedDischargeDate;
};

# Linked FHIR Resources
#
# + observations - field description  
# + medicationRequests - field description  
# + documentReferences - field description  
# + otherReferences - field description
public type LinkedFHIRResources record {
    json[]? observations;
    json[]? medicationRequests;
    json[]? documentReferences;
    json[]? otherReferences;
};

# AI Analysis
#
# + recommendation - field description  
# + confidenceScore - field description  
# + summary - field description  
# + criteriaMatches - field description  
# + riskLevel - field description  
# + policyReference - field description
public type AIAnalysis record {
    string recommendation;
    int confidenceScore;
    string summary;
    CriteriaMatch[]? criteriaMatches;
    string? riskLevel;
    string? policyReference;
};

# Criteria Match
#
# + criteria - field description  
# + met - field description  
# + details - field description
public type CriteriaMatch record {
    string criteria;
    boolean met;
    string? details;
};

# Claim Totals
#
# + submitted - field description  
# + benefit - field description
public type ClaimTotals record {
    json? submitted; // FHIR Money
    json? benefit; // FHIR Money
};

# Process Note
#
# + number - field description  
# + text - field description  
# + 'type - field description
public type ProcessNote record {
    int? number;
    string text;
    string? 'type;
};

# Adjudication Submission Request
#
# + decision - field description  
# + itemAdjudications - field description  
# + reviewerNotes - field description
public type AdjudicationSubmission record {
    string decision; // "complete", "error", "queued"
    ItemAdjudicationSubmission[] itemAdjudications;
    string? reviewerNotes;
};

# Item Adjudication Submission
#
# + sequence - field description  
# + adjudicationCode - field description  
# + approvedAmount - field description  
# + itemNotes - field description
public type ItemAdjudicationSubmission record {
    int sequence;
    string adjudicationCode; // "approved", "denied", etc.
    decimal? approvedAmount;
    string? itemNotes;
};

# Adjudication Response
#
# + id - field description  
# + status - field description  
# + message - field description
public type AdjudicationResponse record {
    string id;
    string status;
    string message;
};

type ResourceEntry record {
    string resourceType;
    string id;
    r4:Meta meta;
    r4:Reference request;
};

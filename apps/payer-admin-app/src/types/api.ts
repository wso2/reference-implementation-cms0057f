// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

/**
 * API Type Definitions for PA Request Detail
 * Maps to backend PARequestDetail record type
 */

import type { AIAnalysis } from './claimItem';

/**
 * PA Request Urgency
 */
export type PARequestUrgency = 'Urgent' | 'Standard' | 'Deferred';

/**
 * Questionnaire Response Item with AI Analysis
 */
export interface QuestionnaireResponseItem {
  questionnaire: unknown; // JSON object containing FHIR QuestionnaireResponse
  analysis: AIAnalysis;
}

/**
 * Request Summary
 */
export interface RequestSummary {
  serviceType: string;
  clinicalJustification?: string;
  submittedDate: string;
  targetDate?: string;
}

/**
 * Patient Demographics
 */
export interface PatientDemographics {
  name: string;
  dateOfBirth: string;
  age?: number;
  gender: string;
  mrn?: string;
}

/**
 * Allergy Intolerance
 */
export interface AllergyIntolerance {
  substance: string;
  severity?: string;
}

/**
 * Medication Statement
 */
export interface MedicationStatement {
  medication: string;
  status?: string;
}

/**
 * Patient Information (IPS-based)
 */
export interface PatientInformation {
  id: string;
  demographics: PatientDemographics;
  allergies?: AllergyIntolerance[];
  medications?: MedicationStatement[];
}

/**
 * Address
 */
export interface Address {
  line: string[];
  city?: string;
  state?: string;
  postalCode?: string;
}

/**
 * Facility
 */
export interface Facility {
  name: string;
  address?: Address;
}

/**
 * Provider Contact
 */
export interface ProviderContact {
  phone?: string;
  email?: string;
}

/**
 * Provider Information
 */
export interface ProviderInformation {
  id: string;
  name: string;
  specialty?: string;
  initials?: string;
  contact?: ProviderContact;
  facility?: Facility;
}

/**
 * Coverage Information
 */
export interface CoverageInformation {
  sequence: number;
  focal: boolean;
  coverageReference: string;
  serviceItemRequestType?: string;
  certificationType?: string;
}

/**
 * FHIR CodeableConcept structure
 */
export interface CodeableConcept {
  coding?: Array<{
    system?: string;
    code?: string;
    display?: string;
  }>;
  text?: string;
}

/**
 * FHIR Period structure
 */
export interface Period {
  start?: string;
  end?: string;
}

/**
 * FHIR Quantity structure
 */
export interface FHIRQuantity {
  value?: number;
  unit?: string;
}

/**
 * FHIR Money structure
 */
export interface FHIRMoney {
  value?: number;
  currency?: string;
}

/**
 * Claim Item (simplified for adjudication)
 */
export interface ClaimItem {
  sequence: number;
  productOrService: CodeableConcept;
  description?: string;
  quantity?: FHIRQuantity;
  unitPrice?: FHIRMoney;
  net?: FHIRMoney;
  servicedDate?: string;
  servicedPeriod?: Period;
  adjudication?: unknown[];
  noteNumbers?: number[];
  reviewNote?: string;
}

/**
 * Claim Item with adjudication state for UI
 */
export interface ClaimItemWithAdjudication extends ClaimItem {
  selectedAdjudicationCode?: string;
  adjudicationAmount?: number;
  adjudicationPercent?: number;
  itemReviewNote?: string;
  isReviewed?: boolean;
}

/**
 * Claim Totals
 */
export interface ClaimTotals {
  submitted?: unknown; // FHIR Money
  benefit?: unknown; // FHIR Money
}

/**
 * Process Note
 */
export interface ProcessNote {
  number?: number;
  text: string;
  type?: string;
}

export type CommunicationRequestStatus = "draft" | "active" | "on-hold" | "revoked" | "completed" | "entered-in-error" | 
    "unknown";

export type PARequestPriority = "routine" | "urgent" | "asap" | "stat";

export type AdditionalInfoItem = {
    code: string;
    display?: string;
};


export interface CommunicationRequestItem {
    id: string;
    status: CommunicationRequestStatus;
    priority: PARequestPriority;
    requestedItems: AdditionalInfoItem[];
    reasonCode?: string;
    requestedDate?: string;
};

/**
 * PA Request Detail - Complete information for a specific PA request
 */
export interface PARequestDetail {
  id: string;
  responseId: string;
  status: string;
  use?: string;
  created: string;
  targetDate?: string;
  admissionDate?: string;
  dischargeDate?: string;
  questionnaires?: QuestionnaireResponseItem[];
  attachments?: unknown[]; // JSON array
  priority: PARequestUrgency;
  summary: RequestSummary;
  patient: PatientInformation;
  provider: ProviderInformation;
  items: ClaimItem[];
  coverage?: CoverageInformation[];
  total: ClaimTotals;
  processNotes?: ProcessNote[];
  communicationRequests?: CommunicationRequestItem[];
}

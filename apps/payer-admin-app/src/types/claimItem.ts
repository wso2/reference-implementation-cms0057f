/**
 * FHIR R4 Claim Item and ClaimResponse Type Definitions
 * Based on HL7 FHIR ClaimResponse Resource
 * https://hl7.org/fhir/R4/claimresponse.html
 */

import type { Coding, Attachment } from './questionnaire';

/**
 * Adjudication category codes from FHIR ValueSet
 * http://hl7.org/fhir/ValueSet/adjudication
 */
export type AdjudicationCode =
  | 'submitted'      // The total submitted amount for the claim or group or line item
  | 'copay'          // Patient Co-Payment
  | 'eligible'       // Amount of the change which is considered for adjudication
  | 'deductible'     // Amount deducted from the eligible amount prior to adjudication
  | 'unallocdeduct'  // The amount of deductible which could not allocated to other line items
  | 'eligpercent'    // Eligible Percentage
  | 'tax'            // The amount of tax
  | 'benefit';       // Amount payable under the coverage

/**
 * Display names for adjudication codes
 */
export const AdjudicationCodeDisplay: Record<AdjudicationCode, string> = {
  submitted: 'Submitted Amount',
  copay: 'CoPay',
  eligible: 'Eligible Amount',
  deductible: 'Deductible',
  unallocdeduct: 'Unallocated Deductible',
  eligpercent: 'Eligible %',
  tax: 'Tax',
  benefit: 'Benefit Amount',
};

/**
 * Descriptions for adjudication codes
 */
export const AdjudicationCodeDescription: Record<AdjudicationCode, string> = {
  submitted: 'The total submitted amount for the claim or group or line item.',
  copay: 'Patient Co-Payment amount.',
  eligible: 'Amount of the charge which is considered for adjudication.',
  deductible: 'Amount deducted from the eligible amount prior to adjudication.',
  unallocdeduct: 'The amount of deductible which could not be allocated to other line items.',
  eligpercent: 'Eligible Percentage for the service.',
  tax: 'The amount of tax applicable.',
  benefit: 'Amount payable under the coverage.',
};

/**
 * Document Reference (for attachments like PDF, DICOM, PNG)
 */
export interface DocumentReference {
  id: string;
  /** Type of document */
  type?: Coding;
  /** Human readable description */
  description?: string;
  /** When the document was created */
  date?: string;
  /** Content details */
  content: Array<{
    attachment: Attachment;
    format?: Coding;
  }>;
}

/**
 * AI Analysis result for items with questionnaire responses
 */
export interface AIAnalysis {
  /** Recommended action */
  recommendation: 'approve' | 'deny' | 'review';
  /** Confidence score (0-100) */
  confidenceScore: number;
  /** Summary of the clinical analysis */
  summary: string;
  /** Detailed criteria matches */
  criteriaMatches?: Array<{
    criteria: string;
    met: boolean;
    details?: string;
  }>;
  /** Risk assessment */
  riskLevel?: 'low' | 'medium' | 'high';
  /** Policy reference if applicable */
  policyReference?: string;
}

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
 * FHIR R4 Questionnaire Type Definitions
 * Based on HL7 FHIR Da Vinci DTR Implementation Guide
 * http://hl7.org/fhir/us/davinci-dtr/StructureDefinition/dtr-std-questionnaire
 */

/**
 * Publication status of the questionnaire
 */
export type QuestionnaireStatus = 'draft' | 'active' | 'retired' | 'unknown';

/**
 * Supported answer types based on FHIR Questionnaire item types
 */
export type QuestionnaireItemType =
  | 'group'      // Container for nested items
  | 'display'    // Display text only, no answer
  | 'boolean'    // true/false answer
  | 'decimal'    // Decimal number
  | 'integer'    // Whole number
  | 'date'       // Date without time
  | 'dateTime'   // Date with time
  | 'time'       // Time of day
  | 'string'     // Short text answer
  | 'text'       // Long text answer
  | 'choice'     // Coded answer from answerOption or answerValueSet
  | 'open-choice'// Choice with option for free text
  | 'url'        // URL answer
  | 'quantity'   // Number with unit
  | 'reference'  // Reference to external resource
  | 'attachment'; // Attachment/file upload

/**
 * Operators for enableWhen conditional logic
 */
export type EnableWhenOperator =
  | 'exists'     // Question has any answer
  | '='          // Equal to
  | '!='         // Not equal to
  | '>'          // Greater than
  | '<'          // Less than
  | '>='         // Greater than or equal
  | '<=';        // Less than or equal

/**
 * How multiple enableWhen conditions are combined
 */
export type EnableBehavior = 'all' | 'any';

/**
 * FHIR Coding type
 */
export interface Coding {
  system?: string;
  code: string;
  display?: string;
}

/**
 * FHIR Quantity type
 */
export interface Quantity {
  value?: number;
  unit?: string;
  system?: string;
  code?: string;
}

/**
 * FHIR Reference type
 */
export interface Reference {
  reference?: string;
  display?: string;
  identifier?: {
    system?: string;
    value?: string;
  };
}

/**
 * FHIR Attachment type
 */
export interface Attachment {
  contentType?: string;
  data?: string;
  url?: string;
  size?: number;
  title?: string;
}

/**
 * Conditional logic for when to enable/display a question
 * Follows FHIR enableWhen structure
 */
export interface QuestionnaireEnableWhen {
  /** Link ID of the question that controls this condition */
  question: string;
  /** The operator to apply */
  operator: EnableWhenOperator;
  /** The answer value to compare against (answer[x]) */
  answerBoolean?: boolean;
  answerDecimal?: number;
  answerInteger?: number;
  answerDate?: string;
  answerDateTime?: string;
  answerTime?: string;
  answerString?: string;
  answerCoding?: Coding;
  answerQuantity?: Quantity;
  answerReference?: Reference;
}

/**
 * Answer option for choice/open-choice type questions
 * Follows FHIR answerOption structure
 */
export interface QuestionnaireAnswerOption {
  /** Value for this option (value[x]) - using valueCoding for coded answers */
  valueCoding?: Coding;
  valueInteger?: number;
  valueDate?: string;
  valueTime?: string;
  valueString?: string;
  valueReference?: Reference;
  /** Whether this option is initially selected */
  initialSelected?: boolean;
}

/**
 * Initial value for a question
 * Follows FHIR initial structure
 */
export interface QuestionnaireInitial {
  valueBoolean?: boolean;
  valueDecimal?: number;
  valueInteger?: number;
  valueDate?: string;
  valueDateTime?: string;
  valueTime?: string;
  valueString?: string;
  valueUri?: string;
  valueCoding?: Coding;
  valueQuantity?: Quantity;
  valueReference?: Reference;
  valueAttachment?: Attachment;
}

/**
 * Expression structure for FHIR expressions (e.g., CQL)
 */
export interface Expression {
  language: string;
  expression: string;
}

/**
 * Extension structure for FHIR extensions
 */
export interface Extension {
  url: string;
  valueString?: string;
  valueCanonical?: string;
  valueCode?: string;
  valueBoolean?: boolean;
  valueInteger?: number;
  valueDecimal?: number;
  valueCoding?: Coding;
  valueQuantity?: Quantity;
  valueReference?: Reference;
  valueExpression?: Expression;
}

/**
 * A single question or group in the questionnaire
 * Follows FHIR Questionnaire.item structure
 */
export interface QuestionnaireItem {
  /** Unique identifier for this item within the questionnaire (max 255 chars) */
  linkId: string;

  /** Optional prefix (e.g., "1(a)", "2.5.3") */
  prefix?: string;

  /** The question text or group label */
  text: string;

  /** Type of answer expected */
  type: QuestionnaireItemType;

  /** Whether this question is required */
  required?: boolean;

  /** Whether this question can have multiple answers */
  repeats?: boolean;

  /** Whether this item is read-only */
  readOnly?: boolean;

  /** Maximum length for string/text answers */
  maxLength?: number;

  /** Conditional logic for when to show this item */
  enableWhen?: QuestionnaireEnableWhen[];

  /** How to combine multiple enableWhen conditions ('all' or 'any') */
  enableBehavior?: EnableBehavior;

  /** Answer options for 'choice' and 'open-choice' type questions */
  answerOption?: QuestionnaireAnswerOption[];

  /** Reference to a value set containing answer options */
  answerValueSet?: string;

  /** Initial value(s) for the question */
  initial?: QuestionnaireInitial[];

  /** Nested items (for 'group' type or sub-questions) */
  item?: QuestionnaireItem[];

  /** Extensions for additional metadata */
  extension?: Extension[];

  // ----- Helper fields for UI (not part of FHIR spec) -----
  /** Help text or additional instructions (maps to itemControl extension) */
  _helpText?: string;
}

/**
 * The complete FHIR Questionnaire resource structure
 */
export interface Questionnaire {
  /** Resource type - always "Questionnaire" */
  resourceType: 'Questionnaire';

  /** Logical id of this artifact */
  id?: string;

  /** Metadata about the resource */
  meta?: {
    versionId?: string;
    lastUpdated?: string;
    profile?: string[];
  };

  /** Canonical identifier for this questionnaire (globally unique URI) */
  url?: string;

  /** Business version of the questionnaire */
  version?: string;

  /** Name for this questionnaire (computer friendly, PascalCase) */
  name?: string;

  /** Name for this questionnaire (human friendly) */
  title: string;

  /** Publication status: draft | active | retired | unknown */
  status: QuestionnaireStatus;

  /** Resource that can be subject of QuestionnaireResponse */
  subjectType?: string[];

  /** Date last changed */
  date?: string;

  /** Name of the publisher */
  publisher?: string;

  /** Natural language description */
  description?: string;

  /** When the questionnaire is expected to be used */
  effectivePeriod?: {
    start?: string;
    end?: string;
  };

  /** Root-level items */
  item: QuestionnaireItem[];

  /** Extensions */
  extension?: Extension[];
}

/**
 * Helper function to generate a unique link ID (max 255 chars per FHIR spec)
 */
export function generateLinkId(prefix = 'item'): string {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substring(2, 9);
  return `${prefix}-${timestamp}-${random}`.substring(0, 255);
}

/**
 * Helper function to generate a UUID v4
 */
export function generateUUID(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

/**
 * Helper function to create a new questionnaire item
 */
export function createQuestionnaireItem(
  type: QuestionnaireItemType = 'string',
  text = ''
): QuestionnaireItem {
  const item: QuestionnaireItem = {
    linkId: generateLinkId(),
    text,
    type,
  };

  if (type === 'group') {
    item.item = [];
  }

  if (type === 'choice' || type === 'open-choice') {
    item.answerOption = [];
  }

  return item;
}

/**
 * Helper function to get answer value from enableWhen
 */
export function getEnableWhenAnswerValue(enableWhen: QuestionnaireEnableWhen): unknown {
  if (enableWhen.answerBoolean !== undefined) return enableWhen.answerBoolean;
  if (enableWhen.answerDecimal !== undefined) return enableWhen.answerDecimal;
  if (enableWhen.answerInteger !== undefined) return enableWhen.answerInteger;
  if (enableWhen.answerDate !== undefined) return enableWhen.answerDate;
  if (enableWhen.answerDateTime !== undefined) return enableWhen.answerDateTime;
  if (enableWhen.answerTime !== undefined) return enableWhen.answerTime;
  if (enableWhen.answerString !== undefined) return enableWhen.answerString;
  if (enableWhen.answerCoding !== undefined) return enableWhen.answerCoding;
  if (enableWhen.answerQuantity !== undefined) return enableWhen.answerQuantity;
  if (enableWhen.answerReference !== undefined) return enableWhen.answerReference;
  return undefined;
}

/**
 * Helper function to validate questionnaire structure
 */
export function validateQuestionnaire(questionnaire: Questionnaire): string[] {
  const errors: string[] = [];
  const linkIds = new Set<string>();

  function validateItem(item: QuestionnaireItem, path: string) {
    // Check for duplicate linkIds
    if (linkIds.has(item.linkId)) {
      errors.push(`${path}: Duplicate linkId "${item.linkId}"`);
    }
    linkIds.add(item.linkId);

    // Check linkId length (FHIR constraint que-15)
    if (item.linkId.length > 255) {
      errors.push(`${path}: linkId exceeds 255 characters`);
    }

    // Check required fields
    if (!item.text?.trim()) {
      errors.push(`${path}: Question text is required`);
    }

    // Type-specific validation
    if (item.type === 'group') {
      if (!item.item || item.item.length === 0) {
        errors.push(`${path}: Group must have at least one nested item`);
      }
    }

    // Display items cannot have nested items (que-1c)
    if (item.type === 'display' && item.item && item.item.length > 0) {
      errors.push(`${path}: Display items cannot have nested items`);
    }

    // Display items cannot have required or repeats (que-6)
    if (item.type === 'display' && (item.required || item.repeats)) {
      errors.push(`${path}: Display items cannot have required or repeats`);
    }

    // Choice items should have answerOption or answerValueSet (dtrq-2)
    if ((item.type === 'choice' || item.type === 'open-choice') && 
        (!item.answerOption || item.answerOption.length === 0) && 
        !item.answerValueSet) {
      errors.push(`${path}: Choice type questions must have answerOption or answerValueSet`);
    }

    // Cannot have both answerOption and answerValueSet (que-4)
    if (item.answerOption && item.answerOption.length > 0 && item.answerValueSet) {
      errors.push(`${path}: Cannot have both answerOption and answerValueSet`);
    }

    // Validate enableWhen
    if (item.enableWhen && item.enableWhen.length > 0) {
      item.enableWhen.forEach((ew, idx) => {
        if (!ew.question) {
          errors.push(`${path}.enableWhen[${idx}]: Question reference is required`);
        }
        // exists operator must have boolean answer (que-7)
        if (ew.operator === 'exists' && ew.answerBoolean === undefined) {
          errors.push(`${path}.enableWhen[${idx}]: 'exists' operator requires a boolean answer`);
        }
      });

      // Multiple enableWhen requires enableBehavior (que-12)
      if (item.enableWhen.length > 1 && !item.enableBehavior) {
        errors.push(`${path}: enableBehavior is required when multiple enableWhen conditions exist`);
      }
    }

    // maxLength only for certain types (que-10)
    if (item.maxLength !== undefined) {
      const allowedTypes: QuestionnaireItemType[] = ['boolean', 'decimal', 'integer', 'string', 'text', 'url', 'open-choice'];
      if (!allowedTypes.includes(item.type)) {
        errors.push(`${path}: maxLength is not allowed for type "${item.type}"`);
      }
    }

    // readOnly not for display items (que-9)
    if (item.type === 'display' && item.readOnly !== undefined) {
      errors.push(`${path}: readOnly cannot be specified for display items`);
    }

    // Validate nested items
    if (item.item) {
      item.item.forEach((child, idx) => {
        validateItem(child, `${path}.item[${idx}]`);
      });
    }
  }

  // Validate root level
  if (!questionnaire.title?.trim()) {
    errors.push('Questionnaire title is required');
  }

  if (!questionnaire.status) {
    errors.push('Questionnaire status is required');
  }

  if (!questionnaire.item || questionnaire.item.length === 0) {
    errors.push('Questionnaire must have at least one item');
  }

  // Validate name format (cnl-0, que-0)
  if (questionnaire.name && !/^[A-Z]([A-Za-z0-9_]){0,254}$/.test(questionnaire.name)) {
    errors.push('Questionnaire name should be PascalCase and usable as an identifier');
  }

  questionnaire.item?.forEach((item, idx) => {
    validateItem(item, `item[${idx}]`);
  });

  return errors;
}

/**
 * Helper function to parse and validate an imported FHIR Questionnaire
 */
export function parseQuestionnaireResource(json: unknown): { questionnaire: Questionnaire | null; errors: string[] } {
  const errors: string[] = [];

  if (!json || typeof json !== 'object') {
    errors.push('Invalid JSON: expected an object');
    return { questionnaire: null, errors };
  }

  const resource = json as Record<string, unknown>;

  // Check resourceType
  if (resource.resourceType !== 'Questionnaire') {
    errors.push(`Invalid resourceType: expected "Questionnaire", got "${resource.resourceType}"`);
    return { questionnaire: null, errors };
  }

  // Validate required fields
  if (!resource.status) {
    errors.push('Missing required field: status');
  }

  if (!resource.item || !Array.isArray(resource.item)) {
    errors.push('Missing or invalid required field: item');
  }

  // If basic validation passes, cast to Questionnaire
  if (errors.length === 0) {
    const questionnaire = resource as unknown as Questionnaire;
    
    // Ensure title exists
    if (!questionnaire.title) {
      questionnaire.title = questionnaire.name || 'Imported Questionnaire';
    }

    return { questionnaire, errors: validateQuestionnaire(questionnaire) };
  }

  return { questionnaire: null, errors };
}

// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
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

export enum CDSIndicator {
  WARNING = "warning",
  INFO = "info",
  CRITICAL = "critical",
}

export enum CDSSelectorBehavior {
  Single = "at-most-one",
  Multi = "any",
}

export enum CDSActionType {
  CREATE = "create",
  UPDATE = "update",
  DELETE = "delete",
}

interface CDSLink {
  label: string;
  url: string;
  type: string;
  appContext?: string;
}

interface CDSActions {
  type: CDSActionType;
  description: string;
  resource?: unknown;
  resourceId?: string;
}

interface CDSSuggesstion {
  label: string;
  uuid?: string;
  isRecommended?: boolean;
  actions?: CDSActions[];
}

interface CDSCoding {
  code: string;
  system: string;
  display?: string;
}

interface CDSSource {
  label: string;
  url?: string;
  icon?: string;
  topic?: CDSCoding;
}

export interface SystemActionExtension {
  extension: Extension[];
}

interface Extension {
  url: string;
  valueReference?: {
    reference: string;
  };
  valueCode?: string;
  valueCoding?: {
    system: string;
    code: string;
  };
  valueCodeableConcept?: {
    coding: CDSCoding[];
    text: string;
  };
}

export interface CoverageCardProps {
  source: CDSSource;
  summary: string;
  indicator: CDSIndicator;
  detail?: string;
  suggestions?: CDSSuggesstion[];
  selectorBehavior?: CDSSelectorBehavior;
  links?: CDSLink[];
  isPreview: boolean;
}

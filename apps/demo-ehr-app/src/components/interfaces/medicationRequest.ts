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

interface Coding {
  system?: string;
  code?: string;
  display?: string;
}

interface Note {
  text: string;
}

interface Code {
  coding: Coding[];
}

interface Contained {
  resourceType: string;
  id: string;
  code: Code;
}

interface DoseAndRate {
  type: Code;
  doseQuantity: {
    value: number;
    unit: string;
    system: string;
    code: string;
  };
}

interface DosageInstruction {
  sequence?: number;
  text?: string;
  additionalInstruction?: Code[];
  timing?: {
    repeat: {
      frequency: number;
      period: number;
      periodUnit: string;
    };
  };
  route?: Code;
  method?: Code;
  doseAndRate?: DoseAndRate[];
}

export interface MedicationRequest {
  resourceType: string;
  id: string;
  text?: {
    status: string;
    div: string;
  };
  contained?: Contained[];
  status?: string;
  intent?: string;
  medicationReference?: {
    reference: string;
  };
  subject?: {
    reference: string;
  };
  encounter?: {
    reference: string;
  };
  authoredOn?: string;
  requester?: {
    reference: string;
  };
  reasonCode?: Code[];
  note?: Note[];
  dosageInstruction?: DosageInstruction[];
  dispenseRequest?: {
    validityPeriod?: {
      start: string;
      end: string;
    };
    numberOfRepeatsAllowed?: number;
    quantity?: {
      value: number;
      unit: string;
      system: string;
      code: string;
    };
    expectedSupplyDuration?: {
      value: number;
      unit: string;
      system: string;
      code: string;
    };
  };
}

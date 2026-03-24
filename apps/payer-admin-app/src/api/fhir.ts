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

// Backend API for interacting with FHIR server to fetch patient information
const API_BASE_URL = window.config?.BFF_URL || 'http://localhost:6091/v1';

export interface FhirPatient {
  resourceType: 'Patient';
  id: string;
  name?: Array<{
    use?: string;
    family?: string;
    given?: string[];
    text?: string;
  }>;
  birthDate?: string;
  identifier?: Array<{
    system?: string;
    value?: string;
  }>;
  telecom?: Array<{
    system?: 'phone' | 'email' | 'fax' | 'pager' | 'url' | 'sms' | 'other';
    value?: string;
    use?: string;
  }>;
}

export interface PatientInfo {
  id: string;
  name: string;
  dateOfBirth: string;
  memberId: string;
  email: string;
  phone: string;
}

/**
 * Map FHIR Patient resource to simplified PatientInfo
 */
function mapFhirPatientToInfo(fhirPatient: FhirPatient): PatientInfo {
  // Extract name (prefer official, fallback to first available)
  const officialName = fhirPatient.name?.find(n => n.use === 'official');
  const anyName = fhirPatient.name?.[0];
  const nameObj = officialName || anyName;
  const name = nameObj?.text || 
    `${nameObj?.given?.join(' ') || ''} ${nameObj?.family || ''}`.trim() || 
    'Unknown';

  // Extract member ID (first identifier)
  const memberId = fhirPatient.identifier?.[0]?.value || fhirPatient.id;

  // Extract email
  const emailContact = fhirPatient.telecom?.find(t => t.system === 'email');
  const email = emailContact?.value || 'N/A';

  // Extract phone
  const phoneContact = fhirPatient.telecom?.find(t => t.system === 'phone');
  const phone = phoneContact?.value || 'N/A';

  return {
    id: fhirPatient.id,
    name,
    dateOfBirth: fhirPatient.birthDate || 'N/A',
    memberId,
    email,
    phone,
  };
}

/**
 * Fetch patient information from FHIR server
 */
export async function getPatient(patientId: string): Promise<PatientInfo> {
  const response = await fetch(`${API_BASE_URL}/patients/${patientId}`);

  if (!response.ok) {
    throw new Error(`Failed to fetch patient: ${response.statusText}`);
  }

  const fhirPatient: FhirPatient = await response.json();
  return mapFhirPatientToInfo(fhirPatient);
}

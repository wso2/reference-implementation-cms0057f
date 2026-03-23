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

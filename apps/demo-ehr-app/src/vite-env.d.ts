/// <reference types="vite/client" />

interface Window {
  Config: {
    asgardeoBaseUrl: string;
    asgardeoClientId: string;
    asgardeoClientSecret: string;
    smartAppUrl: string;
    smartLaunchServiceUrl: string;
    baseUrl: string;
    demoBaseUrl: string;
    demoHospitalUrl: string;
    cdsRequestUrl: string;
    fhirServerUrl: string;
    dtrAppUrl: string;
    webhookServerUrl: string;
    medication_request: string;
    prescribe_medication: string;
    questionnaire_package: string;
    questionnaire_response: string;
    claim_submit: string;
    practitioner_new: string;
    patient: string;
    claim: string;
    bulkExportFetch: string;
    bulkExportKickoffUrl: string;
    bulkExportStatusUrl: string;
    radiology_order: string;
    book_imaging_center: string;
    practitioner: string;
    slot: string;
    location: string;
    appointment: string;
    organization: string;
    group: string;
    npi: string;
    payers: { id: string; name: string }[];
    scope: string[];
  };
}

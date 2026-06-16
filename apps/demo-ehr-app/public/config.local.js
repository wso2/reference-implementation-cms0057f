// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).
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

// ---------------------------------------------------------------------------
// LOCAL configuration template — Provider Access + Prior Authorization
// (demo-ehr-app)
//
// Usage: copy this file over config.js to run against a local stack:
//     cp public/config.local.js public/config.js
//
// The URLs below point DIRECTLY at the locally running services (no APIM),
// which is the simplest way to develop locally:
//     fhir-service        : /fhirapi
//     cds-service         : /cdsapi
//     fhir-repository      : /fhirapi
//     bulk-export-client  : /bulkapi , file server :8100/file
//     ehr-webhook-service : /webhookapi
//
// To route through the APIM gateway instead, replace each host:port with the
// gateway base + API context, e.g. https://localhost:8243/fhirapi/fhir/r4 and
// https://localhost:8243/cdsapi/cds-services. NOTE: cds-service uses 9096 and
// rule-engine 9097 to avoid clashing with the SMART-on-FHIR consent (9092) and
// IAM (9093) extension services that ship with the WSO2 Healthcare Accelerator.
//
// dtrAppUrl must match wherever you run the demo-dtr-app (assign it a distinct
// Vite port if both apps run at once, e.g. npm run dev -- --port 5174).
// ---------------------------------------------------------------------------

window.Config = {
  baseUrl: "/fhirapi",
  demoBaseUrl: "https://unitedcare.com",
  demoHospitalUrl: "https://grace-hospital.com",
  cdsRequestUrl: "/cdsapi",
  fhirServerUrl: "http://localhost:8080/fhir/r4",
  dtrAppUrl: "http://localhost:5174",
  webhookServerUrl: "/webhookapi",

  medication_request: "/fhirapi/MedicationRequest",
  service_request: "/fhirapi/ServiceRequest",
  prescribe_medication: "/cdsapi/prescribe-medication",
  crd_mri_spine: "/cdsapi/crd-mri-spine-order-sign",
  questionnaire_package: "/fhirapi/Questionnaire/questionnaire-package",
  questionnaire_response: "/fhirapi/QuestionnaireResponse",
  claim_submit: "/fhirapi/Claim/$submit",
  practitioner_new: "/fhirapi/Practitioner",
  patient: "/fhirapi/Patient",
  coverage: "/fhirapi/Coverage",
  claim: "/fhirapi/Claim",

  bulkExportFetch: "/fileapi/fetch",
  bulkExportKickoffUrl: "/bulkapi/export",
  bulkExportStatusUrl: "/bulkapi/status",

  npi: "5432109876",
  payers: [{ id: "united-health", name: "United Health" }],
  organization: "/fhirapi/Organization",
  group: "/fhirapi/Group",
  practitioner: "/fhirapi/Practitioner",
  slot: "/fhirapi/Slot",
  location: "/fhirapi/Location",
  appointment: "/fhirapi/Appointment",
  book_imaging_center: "/cdsapi/book-imaging-center",
};

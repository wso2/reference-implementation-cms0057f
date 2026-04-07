// Copyright (c) 2024 - 2025, WSO2 LLC. (http://www.wso2.com).
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

window.Config = {
  baseUrl:
    "https://c32618cf-389d-44f1-93ee-b67a3468aae3-dev.e1-us-east-azure.choreoapis.dev/cms-paas/fhir-service-fm/v1.0",
  demoBaseUrl: "https://unitedcare.com",
  demoHospitalUrl: "https://grace-hospital.com",
  cdsRequestUrl: "https://c32618cf-389d-44f1-93ee-b67a3468aae3-dev.e1-us-east-azure.choreoapis.dev/cms-paas/cds-service/v1.0/cds-services",
  fhirServerUrl: "http://fhir-server-1853775667:9090/fhir/r4",
  dtrAppUrl: "https://localhost:10001",
  webhookServerUrl: "/choreo-apis/cms-provider/pa-notification-service/v1",

  medication_request:
    "/choreo-apis/cms-paas/fhir-service-fm/v1/MedicationRequest",
  service_request:
    "/choreo-apis/cms-paas/fhir-service-fm/v1/ServiceRequest",
  prescribe_medication:
    "/choreo-apis/cms-paas/cds-service/v1/cds-services/prescribe-medication",
  crd_mri_spine:
    "/choreo-apis/cms-paas/cds-service/v1/cds-services/crd-mri-spine-order-sign",
  questionnaire_package:
    "/choreo-apis/cms-paas/fhir-service-fm/v1/Questionnaire/questionnaire-package",
  questionnaire_response:
    "/choreo-apis/cms-paas/fhir-service-fm/v1/QuestionnaireResponse",
  claim_submit:
    "/choreo-apis/cms-paas/fhir-service-fm/v1/Claim/$submit",
  practitioner_new:
    "/choreo-apis/cms-paas/fhir-service-fm/v1/Practitioner",
  patient:
    "/choreo-apis/cms-paas/fhir-service-fm/v1/Patient",
  coverage:
    "/choreo-apis/cms-paas/fhir-service-fm/v1/Coverage",
  claim:
    "/choreo-apis/cms-paas/fhir-service-fm/v1/Claim",
  bulkExportFetch:
    "/choreo-apis/cms-0057-f/bulk-export-client/file-service/v1.0/fetch",
  bulkExportKickoffUrl:
    "/choreo-apis/cms-0057-f/bulk-export-client/v1.0/export",
  bulkExportStatusUrl: "/choreo-apis/cms-0057-f/bulk-export-client/v1.0/status",

  // old urls
  radiology_order:
    "/choreo-apis/cms-paas/cds-service/v1/cds-services/radiology-order",
  book_imaging_center:
    "/choreo-apis/cms-paas/cds-service/v1/cds-services/book-imaging-center",
  practitioner: "/choreo-apis/cms-paas/fhir-service/v1/Practitioner",
  slot: "/choreo-apis/cms-paas/fhir-service-fm/v1/Slot",
  location:
    "/choreo-apis/cms-paas/fhir-service-fm/v1/Location",
  appointment:
    "/choreo-apis/cms-paas/fhir-service-fm/v1/Appointment",
  organization:
    "/choreo-apis/cms-paas/fhir-service-fm/v1/Organization",
  group:
    "/choreo-apis/cms-paas/fhir-service-fm/v1/Group",
  npi: "5432109876",
  payers: [
    { id: "united-health", name: "United Health" }
  ],
};

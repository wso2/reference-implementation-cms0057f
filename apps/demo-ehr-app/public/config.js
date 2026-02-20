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
    "https://c32618cf-389d-44f1-93ee-b67a3468aae3-dev.e1-us-east-azure.choreoapis.dev/cms-0057f---unitedhealth/fhir-service/v1.0",
  demoBaseUrl: "https://unitedcare.com",
  demoHospitalUrl: "https://grace-hospital.com",
  dtrAppUrl: "http://localhost:9000/launch-dtr",
  fhirServerUrl: "http://localhost:9090/fhir/r4",

  medication_request:
    "/choreo-apis/cms-0057f---unitedhealth/fhir-service/v1/fhir/r4/MedicationRequest",
  prescribe_medication:
    "/choreo-apis/cms-0057f---unitedhealth/cds-service/v1/prescribe-medication",
  questionnaire_package:
    "/choreo-apis/cms-0057f---unitedhealth/fhir-service/v1/fhir/r4/Questionnaire/questionnaire-package",
  questionnaire_response:
    "/choreo-apis/cms-0057f---unitedhealth/fhir-service/v1/fhir/r4/QuestionnaireResponse",
  claim_submit:
    "/choreo-apis/cms-0057f---unitedhealth/fhir-service/v1/Claim/$submit",
  practitioner_new:
    "/choreo-apis/cms-0057f---unitedhealth/fhir-service/v1/fhir/r4/Practitioner",
  patient:
    "/choreo-apis/cms-0057f---unitedhealth/fhir-service/v1/fhir/r4/Patient",
  bulkExportFetch:
    "/choreo-apis/cms-0057-f/bulk-export-client/file-service/v1.0/fetch",
  bulkExportKickoffUrl:
    "/choreo-apis/cms-0057-f/bulk-export-client/v1.0/export",
  bulkExportStatusUrl: "/choreo-apis/cms-0057-f/bulk-export-client/v1.0/status",

  // old urls
  radiology_order:
    "/cmsdemosetups/cds-server/v1.0/cds-services/radiology-order",
  book_imaging_center:
    "/cmsdemosetups/cds-server/v1.0/cds-services/book-imaging-center",
  practitioner: "/cmsdemosetups/medconnect-service/v1.0/fhir/r4/Practitioner",
  slot: "/cmsdemosetups/medconnect-service/cerner-fhir-slot-api-745/v1.0/fhir/r4/Slot",
  location:
    "/cmsdemosetups/medconnect-service/cerner-fhir-location-api-cbc/v1.0/fhir/r4/Location",
  appointment:
    "/cmsdemosetups/medconnect-service/cerner-fhir-appointment-api-2ae/v1.0/fhir/r4/Appointment",
};

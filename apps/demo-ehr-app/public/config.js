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
    "https://abdf12cf-bd27-4827-82a6-c661dc00af8e.e1-us-east-azure.choreoapps.dev",
  demoBaseUrl: "https://unitedcare.com",
  demoHospitalUrl: "https://grace-hospital.com",

  medication_request:
    "/choreo-apis/cms-0057-f/prior-authorization-fhir/fhir-medication-request-api/v1",
  prescribe_medication:
    "/choreo-apis/cms-0057-f/prior-authorization-cds-s/v1/prescribe-medication",
  questionnaire_package:
    "/choreo-apis/cms-0057-f/prior-authorization-fhir/international401-parameters-api/v1",
  questionnaire_response:
    "/choreo-apis/cms-0057-f/prior-authorization-fhir/questionnaire-response-api/v1",
  claim_submit:
    "/choreo-apis/cms-0057-f/prior-authorization-fhir/fhir-claim-api/v1/$submit",
  practitioner_new:
    "/choreo-apis/cms-0057-f/prior-authorization-fhir/fhir-practitioner-api/v1",
  patient: "/choreo-apis/cms-0057-f/prior-authorization-fhir/v1",
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

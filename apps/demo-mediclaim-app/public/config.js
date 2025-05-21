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

// 1. Connect to a standard FHIR server

window.Config = {
  baseUrl: "",
  consumerKey: "",
  consumerSecret: "",
  wellKnownEndpoint: "/.well-known/smart-configuration",
  audienceEndpoint: "",

  patientEndpoint: "/Patient",
  explanationOfBenefitsEndpoint: "/ExplanationOfBenefit",
  coverageEndpoint: "/Coverage",
  claimResponseEndpoint: "/ClaimResponse",
  diagnosticReportEndpoint: "/DiagnosticReport",
};

// 2. Connect to launch.smarthealthit.org FHIR server

// window.Config = {
//   baseUrl:
//     "https://launch.smarthealthit.org/v/r4/sim/WzMsIiIsIiIsIkFVVE8iLDAsMCwwLCIiLCIiLCIiLCIiLCIiLCIiLCIiLDEsMCwiIl0/fhir",
//   consumerKey: "anything",
//   consumerSecret: "anything",
//   wellKnownEndpoint: "/.well-known/smart-configuration",
//   audienceEndpoint: "",

//   patientEndpoint: "/Patient",
//   explanationOfBenefitsEndpoint: "/ExplanationOfBenefit",
//   coverageEndpoint: "/Coverage",
//   claimResponseEndpoint: "/ClaimResponse",
//   diagnosticReportEndpoint: "/DiagnosticReport",
// };

// 3. Connect to WSO2 Choreo hosted FHIR server

// window.Config = {
//   baseUrl: "https://mediclaim.cms-wso2.publicvm.com",
//   consumerKey: "tB8I1tBZFYi5UxKfR_fc9kZmUqIa",
//   consumerSecret: "",
//   wellKnownEndpoint: "/fhir/r4/.well-known/smart-configuration",
//   audienceEndpoint: "/fhir/r4",

//   patientEndpoint: "/patient-service/fhir/r4/Patient",
//   explanationOfBenefitsEndpoint: "/eob-service/fhir/r4/ExplanationOfBenefit",
//   coverageEndpoint: "/coverage-service/fhir/r4/Coverage",
//   claimResponseEndpoint: "/claimresponse-service/fhir/r4/ClaimResponse",
//   diagnosticReportEndpoint: "/diag-report-service/fhir/r4/DiagnosticReport",
// };

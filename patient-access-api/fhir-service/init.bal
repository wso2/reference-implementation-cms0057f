// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).

// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/os;

# Enable when you run locally.
// configurable string serviceURL = "https://google.com";
// configurable string consumerKey = "";
// configurable string consumerSecret = "";
// configurable string tokenURL = "";
// configurable string choreoApiKey = "";

# Configurations for the claim repository service.
configurable string serviceURL = os:getEnv("CHOREO_PATIENT_ACCESS_API_CLAIM_REPO_SERVICEURL");
configurable string consumerKey = os:getEnv("CHOREO_PATIENT_ACCESS_API_CLAIM_REPO_CONSUMERKEY");
configurable string consumerSecret = os:getEnv("CHOREO_PATIENT_ACCESS_API_CLAIM_REPO_CONSUMERSECRET");
configurable string tokenURL = os:getEnv("CHOREO_PATIENT_ACCESS_API_CLAIM_REPO_TOKENURL");
configurable string choreoApiKey = os:getEnv("CHOREO_PATIENT_ACCESS_API_CLAIM_REPO_CHOREOAPIKEY");

function init() returns error? {
    check loadPatientData();
    check loadCoverageData();
    check loadEobData();
    check loadMedicationRequestData();
    check loadOrganizationData();
    check loadPractitionerData();
    check loadAllergyIntoleranceData();
    check loadObservationData();
    check loadDiagnosticReportData();
}

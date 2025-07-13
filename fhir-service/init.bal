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
import ballerinax/health.fhir.r4;
// import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore501;

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
    check loadAllergyIntoleranceData();
    check loadCoverageData();
    check loadDiagnosticReportData();
    check loadEncounterData();
    check loadEobData();
    check loadMedicationRequestData();
    check loadObservationData();
    check loadOrganizationData();
    check loadPatientData();
    check loadPractitionerData();
    check loadQuestionnaireData();
    check loadQuestionnairePackageData();
    check loadQuestionnaireResponseData();
}

function loadData() returns error? {
    foreach var patientJson in patientJsons {
        lock {
            uscore501:USCorePatientProfile patient = check parser:parse(patientJson.clone(), uscore501:USCorePatientProfile).ensureType();
            r4:Resource[] patientArr = repositoryMap.get(PATIENT);
            patientArr.push(patient);
            repositoryMap[PATIENT] = patientArr;
        }
    }

    foreach var allergyIntoleranceJson in allergyIntoleranceJsons {
        lock {
            AllergyIntolerance allergyIntolerance = check parser:parse(allergyIntoleranceJson.clone(), AllergyIntolerance).ensureType();
            r4:Resource[] allergyIntoleranceArr = repositoryMap.get(ALLERGY_INTOLERENCE);
            allergyIntoleranceArr.push(allergyIntolerance);
            repositoryMap[ALLERGY_INTOLERENCE] = allergyIntoleranceArr;
        }
    }

    foreach var claimJson in claimJsons {
        lock {
            Claim claim = check parser:parse(claimJson.clone(), Claim).ensureType();
            r4:Resource[] claimArr = repositoryMap.get(CLAIM);
            claimArr.push(claim);
            repositoryMap[CLAIM] = claimArr;
        }
    }

    foreach var claimResponseJson in claimResponseJsons {
        lock {
            ClaimResponse claimResponse = check parser:parse(claimResponseJson.clone(), ClaimResponse).ensureType();
            r4:Resource[] claimResponseArr = repositoryMap.get(CLAIM_RESPONSE);
            claimResponseArr.push(claimResponse);
            repositoryMap[CLAIM_RESPONSE] = claimResponseArr;
        }
    }

    foreach var coverageJson in coverageJsons {
        lock {
            Coverage coverage = check parser:parse(coverageJson.clone(), Coverage).ensureType();
            r4:Resource[] coverageArr = repositoryMap.get(COVERAGE);
            coverageArr.push(coverage);
            repositoryMap[COVERAGE] = coverageArr;
        }
    }

    foreach var diagnosticReportJson in diagnosticReportJsons {
        lock {
            DiagnosticReport diagnosticReport = check parser:parse(diagnosticReportJson.clone(), DiagnosticReport).ensureType();
            r4:Resource[] diagnosticReportArr = repositoryMap.get(DIAGNOSTIC_REPORT);
            diagnosticReportArr.push(diagnosticReport);
            repositoryMap[DIAGNOSTIC_REPORT] = diagnosticReportArr;
        }
    }

    foreach var encounterJson in encounterJsons {
        lock {
            Encounter encounter = check parser:parse(encounterJson.clone(), Encounter).ensureType();
            r4:Resource[] encounterArr = repositoryMap.get(ENCOUNTER);
            encounterArr.push(encounter);
            repositoryMap[ENCOUNTER] = encounterArr;
        }
    }

    foreach var medicationRequestJson in medicationRequestJsons {
        lock {
            MedicationRequest medicationRequest = check parser:parse(medicationRequestJson.clone(), MedicationRequest).ensureType();
            r4:Resource[] medicationRequestArr = repositoryMap.get(MEDICATION_REQUEST);
            medicationRequestArr.push(medicationRequest);
            repositoryMap[MEDICATION_REQUEST] = medicationRequestArr;
        }
    }

    foreach var observationJson in observationJsons {
        lock {
            Observation observation = check parser:parse(observationJson.clone(), Observation).ensureType();
            r4:Resource[] observationArr = repositoryMap.get(OBSERVATION);
            observationArr.push(observation);
            repositoryMap[OBSERVATION] = observationArr;
        }
    }

    foreach var organizationJson in organizationJsons {
        lock {
            Organization organization = check parser:parse(organizationJson.clone(), Organization).ensureType();
            r4:Resource[] organizationArr = repositoryMap.get(ORGANIZATION);
            organizationArr.push(organization);
            repositoryMap[ORGANIZATION] = organizationArr;
        }
    }

    foreach var practitionerJson in practitionerJsons {
        lock {
            Practitioner practitioner = check parser:parse(practitionerJson.clone(), Practitioner).ensureType();
            r4:Resource[] practitionerArr = repositoryMap.get(PRACTITIONER);
            practitionerArr.push(practitioner);
            repositoryMap[PRACTITIONER] = practitionerArr;
        }
    }

    foreach var questionnaireJson in questionnaireJsons {
        lock {
            Questionnaire questionnaire = check parser:parse(questionnaireJson.clone(), Questionnaire).ensureType();
            r4:Resource[] questionnaireArr = repositoryMap.get(QUESTIONNAIRE);
            questionnaireArr.push(questionnaire);
            repositoryMap[QUESTIONNAIRE] = questionnaireArr;
        }
    }

    foreach var questionnaireresponseJson in questionnaireResponseJsons {
        lock {
            QuestionnaireResponse questionnaireresponse = check parser:parse(questionnaireresponseJson.clone(), QuestionnaireResponse).ensureType();
            r4:Resource[] questionnaireresponseArr = repositoryMap.get(QUESTIONNAIRE_RESPONSE);
            questionnaireresponseArr.push(questionnaireresponse);
            repositoryMap[QUESTIONNAIRE_RESPONSE] = questionnaireresponseArr;
        }
    }
}

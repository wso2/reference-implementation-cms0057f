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

import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore501;

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
    check loadClaimData();
}

function loadData() returns error? {
    foreach var patientJson in patientJsons {
        lock {
            uscore501:USCorePatientProfile patient = check parser:parse(patientJson.clone(), uscore501:USCorePatientProfile).ensureType();
            r4:DomainResource[] patientArr = repositoryMap.get(PATIENT);
            patientArr.push(patient);
            repositoryMap[PATIENT] = patientArr;
        }
    }

    foreach var allergyIntoleranceJson in allergyIntoleranceJsons {
        lock {
            AllergyIntolerance allergyIntolerance = check parser:parse(allergyIntoleranceJson.clone(), AllergyIntolerance).ensureType();
            r4:DomainResource[] allergyIntoleranceArr = repositoryMap.get(ALLERGY_INTOLERENCE);
            allergyIntoleranceArr.push(allergyIntolerance);
            repositoryMap[ALLERGY_INTOLERENCE] = allergyIntoleranceArr;
        }
    }

    foreach var claimJson in claimJsons {
        lock {
            Claim claim = check parser:parse(claimJson.clone(), Claim).ensureType();
            r4:DomainResource[] claimArr = repositoryMap.get(CLAIM);
            claimArr.push(claim);
            repositoryMap[CLAIM] = claimArr;
        }
    }

    foreach var claimResponseJson in claimResponseJsons {
        lock {
            ClaimResponse claimResponse = check parser:parse(claimResponseJson.clone(), ClaimResponse).ensureType();
            r4:DomainResource[] claimResponseArr = repositoryMap.get(CLAIM_RESPONSE);
            claimResponseArr.push(claimResponse);
            repositoryMap[CLAIM_RESPONSE] = claimResponseArr;
        }
    }

    foreach var coverageJson in coverageJsons {
        lock {
            Coverage coverage = check parser:parse(coverageJson.clone(), Coverage).ensureType();
            r4:DomainResource[] coverageArr = repositoryMap.get(COVERAGE);
            coverageArr.push(coverage);
            repositoryMap[COVERAGE] = coverageArr;
        }
    }

    foreach var diagnosticReportJson in diagnosticReportJsons {
        lock {
            DiagnosticReport diagnosticReport = check parser:parse(diagnosticReportJson.clone(), DiagnosticReport).ensureType();
            r4:DomainResource[] diagnosticReportArr = repositoryMap.get(DIAGNOSTIC_REPORT);
            diagnosticReportArr.push(diagnosticReport);
            repositoryMap[DIAGNOSTIC_REPORT] = diagnosticReportArr;
        }
    }

    foreach var encounterJson in encounterJsons {
        lock {
            Encounter encounter = check parser:parse(encounterJson.clone(), Encounter).ensureType();
            r4:DomainResource[] encounterArr = repositoryMap.get(ENCOUNTER);
            encounterArr.push(encounter);
            repositoryMap[ENCOUNTER] = encounterArr;
        }
    }

    foreach var medicationRequestJson in medicationRequestJsons {
        lock {
            MedicationRequest medicationRequest = check parser:parse(medicationRequestJson.clone(), MedicationRequest).ensureType();
            r4:DomainResource[] medicationRequestArr = repositoryMap.get(MEDICATION_REQUEST);
            medicationRequestArr.push(medicationRequest);
            repositoryMap[MEDICATION_REQUEST] = medicationRequestArr;
        }
    }

    foreach var observationJson in observationJsons {
        lock {
            Observation observation = check parser:parse(observationJson.clone(), Observation).ensureType();
            r4:DomainResource[] observationArr = repositoryMap.get(OBSERVATION);
            observationArr.push(observation);
            repositoryMap[OBSERVATION] = observationArr;
        }
    }

    foreach var organizationJson in organizationJsons {
        lock {
            Organization organization = check parser:parse(organizationJson.clone(), Organization).ensureType();
            r4:DomainResource[] organizationArr = repositoryMap.get(ORGANIZATION);
            organizationArr.push(organization);
            repositoryMap[ORGANIZATION] = organizationArr;
        }
    }

    foreach var practitionerJson in practitionerJsons {
        lock {
            Practitioner practitioner = check parser:parse(practitionerJson.clone(), Practitioner).ensureType();
            r4:DomainResource[] practitionerArr = repositoryMap.get(PRACTITIONER);
            practitionerArr.push(practitioner);
            repositoryMap[PRACTITIONER] = practitionerArr;
        }
    }

    foreach var questionnaireJson in questionnaireJsons {
        lock {
            Questionnaire questionnaire = check parser:parse(questionnaireJson.clone(), Questionnaire).ensureType();
            r4:DomainResource[] questionnaireArr = repositoryMap.get(QUESTIONNAIRE);
            questionnaireArr.push(questionnaire);
            repositoryMap[QUESTIONNAIRE] = questionnaireArr;
        }
    }

    foreach var questionnaireresponseJson in questionnaireResponseJsons {
        lock {
            QuestionnaireResponse questionnaireresponse = check parser:parse(questionnaireresponseJson.clone(), QuestionnaireResponse).ensureType();
            r4:DomainResource[] questionnaireresponseArr = repositoryMap.get(QUESTIONNAIRE_RESPONSE);
            questionnaireresponseArr.push(questionnaireresponse);
            repositoryMap[QUESTIONNAIRE_RESPONSE] = questionnaireresponseArr;
        }
    }
}

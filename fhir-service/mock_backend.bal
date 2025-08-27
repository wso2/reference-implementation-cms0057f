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

import ballerina/http;
import ballerina/log;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.parser;

// This implementation is a mock FHIR backend which acts as a FHIR repository which has data in FHIR format.
// In actual production scenario we will use the connectors to connect to the actual backend systems of records
// such as EHRs, Databases, HL7 servers, X12 servers, FHIR repositories etc.

function init() returns error? {
    check loadData();
    log:printInfo("Mock FHIR repository backend started.");
}

function loadData() returns error? {
    http:Client dataClient = check new (sampleDataGithubUrl);
    json dataSet = check dataClient->get("");

    if dataSet is map<json> {
        json[] patientData = check dataSet[PATIENT].cloneWithType();
        json[] allergyIntoleranceData = check dataSet[ALLERGY_INTOLERENCE].cloneWithType();
        json[] claimData = check dataSet[CLAIM].cloneWithType();
        json[] claimResponseData = check dataSet[CLAIM_RESPONSE].cloneWithType();
        json[] coverageData = check dataSet[COVERAGE].cloneWithType();
        json[] diagnosticReportData = check dataSet[DIAGNOSTIC_REPORT].cloneWithType();
        json[] encounterData = check dataSet[ENCOUNTER].cloneWithType();
        json[] medicationRequestData = check dataSet[MEDICATION_REQUEST].cloneWithType();
        json[] observationData = check dataSet[OBSERVATION].cloneWithType();
        json[] organizationData = check dataSet[ORGANIZATION].cloneWithType();
        json[] practitionerData = check dataSet[PRACTITIONER].cloneWithType();
        json[] questionnaireData = check dataSet[QUESTIONNAIRE].cloneWithType();
        json[] questionnaireResponseData = check dataSet[QUESTIONNAIRE_RESPONSE].cloneWithType();
        json[] explanationOfBenefitData = check dataSet[EXPLANATION_OF_BENEFIT].cloneWithType();
        json[] questionnairePackageData = check dataSet[QUESTIONNAIRE_PACKAGE].cloneWithType();

        foreach var patientJson in patientData {
            lock {
                Patient patient = check parser:parse(patientJson.clone()).ensureType();
                r4:DomainResource[] patientArr = repositoryMap.get(PATIENT);
                patientArr.push(patient);
                repositoryMap[PATIENT] = patientArr;
            }
        }

        foreach var allergyIntoleranceJson in allergyIntoleranceData {
            lock {
                AllergyIntolerance allergyIntolerance = check parser:parse(allergyIntoleranceJson.clone()).ensureType();
                r4:DomainResource[] allergyIntoleranceArr = repositoryMap.get(ALLERGY_INTOLERENCE);
                allergyIntoleranceArr.push(allergyIntolerance);
                repositoryMap[ALLERGY_INTOLERENCE] = allergyIntoleranceArr;
            }
        }

        foreach var claimJson in claimData {
            lock {
                Claim claim = check parser:parse(claimJson.clone()).ensureType();
                r4:DomainResource[] claimArr = repositoryMap.get(CLAIM);
                claimArr.push(claim);
                repositoryMap[CLAIM] = claimArr;
            }
        }

        foreach var claimResponseJson in claimResponseData {
            lock {
                ClaimResponse claimResponse = check parser:parse(claimResponseJson.clone()).ensureType();
                r4:DomainResource[] claimResponseArr = repositoryMap.get(CLAIM_RESPONSE);
                claimResponseArr.push(claimResponse);
                repositoryMap[CLAIM_RESPONSE] = claimResponseArr;
            }
        }

        foreach var coverageJson in coverageData {
            lock {
                Coverage coverage = check parser:parse(coverageJson.clone()).ensureType();
                r4:DomainResource[] coverageArr = repositoryMap.get(COVERAGE);
                coverageArr.push(coverage);
                repositoryMap[COVERAGE] = coverageArr;
            }
        }

        foreach var diagnosticReportJson in diagnosticReportData {
            lock {
                DiagnosticReport diagnosticReport = check parser:parse(diagnosticReportJson.clone()).ensureType();
                r4:DomainResource[] diagnosticReportArr = repositoryMap.get(DIAGNOSTIC_REPORT);
                diagnosticReportArr.push(diagnosticReport);
                repositoryMap[DIAGNOSTIC_REPORT] = diagnosticReportArr;
            }
        }

        foreach var encounterJson in encounterData {
            lock {
                Encounter encounter = check parser:parse(encounterJson.clone()).ensureType();
                r4:DomainResource[] encounterArr = repositoryMap.get(ENCOUNTER);
                encounterArr.push(encounter);
                repositoryMap[ENCOUNTER] = encounterArr;
            }
        }

        foreach var medicationRequestJson in medicationRequestData {
            lock {
                MedicationRequest medicationRequest = check parser:parse(medicationRequestJson.clone()).ensureType();
                r4:DomainResource[] medicationRequestArr = repositoryMap.get(MEDICATION_REQUEST);
                medicationRequestArr.push(medicationRequest);
                repositoryMap[MEDICATION_REQUEST] = medicationRequestArr;
            }
        }

        foreach var observationJson in observationData {
            lock {
                Observation observation = check parser:parse(observationJson.clone()).ensureType();
                r4:DomainResource[] observationArr = repositoryMap.get(OBSERVATION);
                observationArr.push(observation);
                repositoryMap[OBSERVATION] = observationArr;
            }
        }

        foreach var organizationJson in organizationData {
            lock {
                Organization organization = check parser:parse(organizationJson.clone()).ensureType();
                r4:DomainResource[] organizationArr = repositoryMap.get(ORGANIZATION);
                organizationArr.push(organization);
                repositoryMap[ORGANIZATION] = organizationArr;
            }
        }

        foreach var practitionerJson in practitionerData {
            lock {
                Practitioner practitioner = check parser:parse(practitionerJson.clone()).ensureType();
                r4:DomainResource[] practitionerArr = repositoryMap.get(PRACTITIONER);
                practitionerArr.push(practitioner);
                repositoryMap[PRACTITIONER] = practitionerArr;
            }
        }

        foreach var questionnaireJson in questionnaireData {
            lock {
                Questionnaire questionnaire = check parser:parse(questionnaireJson.clone()).ensureType();
                r4:DomainResource[] questionnaireArr = repositoryMap.get(QUESTIONNAIRE);
                questionnaireArr.push(questionnaire);
                repositoryMap[QUESTIONNAIRE] = questionnaireArr;
            }
        }

        foreach var questionnaireresponseJson in questionnaireResponseData {
            lock {
                QuestionnaireResponse questionnaireresponse = check parser:parse(questionnaireresponseJson.clone()).ensureType();
                r4:DomainResource[] questionnaireresponseArr = repositoryMap.get(QUESTIONNAIRE_RESPONSE);
                questionnaireresponseArr.push(questionnaireresponse);
                repositoryMap[QUESTIONNAIRE_RESPONSE] = questionnaireresponseArr;
            }
        }

        foreach var explanationOfBenefitJson in explanationOfBenefitData {
            lock {
                ExplanationOfBenefit explanationOfBenefit = check parser:parse(explanationOfBenefitJson.clone()).ensureType();
                r4:DomainResource[] explanationOfBenefitArr = repositoryMap.get(EXPLANATION_OF_BENEFIT);
                explanationOfBenefitArr.push(explanationOfBenefit);
                repositoryMap[EXPLANATION_OF_BENEFIT] = explanationOfBenefitArr;
            }
        }

        foreach var questionnairePackageJson in questionnairePackageData {
            lock {
                international401:Parameters questionnairePackage = check parser:parse(questionnairePackageJson.clone()).ensureType();
                r4:DomainResource[] questionnairePackageArr = repositoryMap.get(QUESTIONNAIRE_PACKAGE);
                questionnairePackageArr.push(questionnairePackage);
                repositoryMap[QUESTIONNAIRE_PACKAGE] = questionnairePackageArr;
            }
        }
    }
}

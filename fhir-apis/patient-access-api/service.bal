// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.
// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein is strictly forbidden, unless permitted by WSO2 in accordance with
// the WSO2 Software License available at: https://wso2.com/licenses/eula/3.2
// For specific language governing the permissions and limitations under
// this license, please see the license as well as any agreement you’ve
// entered into with WSO2 governing the purchase of this software and any
// associated services.
//
//
// AUTO-GENERATED FILE.
//
// This file is auto-generated by Ballerina.
// Developers are allowed to modify this file as per the requirement.

import ballerina/http;
import ballerina/log;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhirr4;
import ballerinax/health.fhir.r4.carinbb200;
import ballerinax/health.fhir.r4.davincipas;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore501;

// ######################################################################################################################
// # Patient API                                                                                                        #
// ###################################################################################################################### 

public type Patient uscore501:USCorePatientProfile|international401:Patient;

service /fhir/r4/Patient on new fhirr4:Listener(9090, patientApiConfig) {

    // Implementation of the $match operation
    isolated resource function post \$match(r4:FHIRContext fhirContext, international401:Parameters parameters) returns r4:FHIRError|r4:Bundle|error {

        // This is a dummy logic to test the connections. Todo: add relavant matching logic
        uscore501:USCorePatientProfile matchedPatient = {
            identifier: [
                {
                    use: "usual",
                    system: "",
                    value: "",
                    'type: {
                        coding: [
                            {system: "", code: ""}
                        ]
                    }
                }
            ],
            gender: "male",
            name: [
                {
                    family: "Doe",
                    given: [
                        "John",
                        "Hamilton"
                    ]
                }
            ]
        };
        r4:BundleEntry matchEntry = {
            'resource: matchedPatient,
            fullUrl: ""
        };
        r4:Bundle matchBundle = {

            'type: "searchset",
            entry: [matchEntry]
        };
        return matchBundle;
    }

    // Read the current state of single resource based on its id.
    isolated resource function get [string id](r4:FHIRContext fhirContext) returns r4:FHIRError|uscore501:USCorePatientProfile|error {
        uscore501:USCorePatientProfile response = check getByIdPatient(id);
        return response;
    }

    // Read the state of a specific version of a resource based on its id.
    isolated resource function get [string id]/_history/[string vid](r4:FHIRContext fhirContext) returns Patient|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Search for resources based on a set of criteria.
    isolated resource function get .(r4:FHIRContext fhirContext) returns r4:FHIRError|error|r4:Bundle {
        r4:Bundle searchResult = check searchPatient("Patient", getQueryParamsMap(fhirContext.getRequestSearchParameters()));
        return searchResult;
    }

    // Create a new resource.
    isolated resource function post .(r4:FHIRContext fhirContext, Patient patient) returns Patient|error {
        uscore501:USCorePatientProfile uSCorePatientProfile = check createPatient(patient.toJson());

        return uSCorePatientProfile;
    }

    // Update the current state of a resource completely.
    isolated resource function put [string id](r4:FHIRContext fhirContext, Patient patient) returns Patient|r4:OperationOutcome|r4:FHIRError {
        fhir:FHIRResponse response = check updatePatient(patient.toJson());

        do {
            return <uscore501:USCorePatientProfile>check parser:parse(response.'resource, uscore501:USCorePatientProfile);
        } on fail error parseError {
            log:printError(string `Error occurred while parsing : ${parseError.message()}`, parseError);
            return r4:createFHIRError(parseError.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
    }

    // Update the current state of a resource partially.
    isolated resource function patch [string id](r4:FHIRContext fhirContext, json patch) returns Patient|r4:OperationOutcome|r4:FHIRError {
        fhir:FHIRResponse response = check patchResourcePatient("Patient", id, patch);

        do {
            return <uscore501:USCorePatientProfile>check parser:parse(response.'resource, uscore501:USCorePatientProfile);
        } on fail error parseError {
            log:printError(string `Error occurred while parsing : ${parseError.message()}`, parseError);
            return r4:createFHIRError(parseError.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
    }

    // Delete a resource.
    isolated resource function delete [string id](r4:FHIRContext fhirContext) returns r4:OperationOutcome?|r4:FHIRError? {
        _ = check deletePatient("Patient", id);
    }

    // Retrieve the update history for a particular resource.
    isolated resource function get [string id]/_history(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Retrieve the update history for all resources.
    isolated resource function get _history(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }
}

// ######################################################################################################################
// # Claim API                                                                                                          #
// ###################################################################################################################### 

public type Claim davincipas:PASClaim;

public type Parameters international401:Parameters;

# initialize source system endpoint here

# A service representing a network-accessible API
# bound to port `9090`.
service /fhir/r4/Claim on new fhirr4:Listener(9091, ClaimApiConfig) {

    isolated resource function post \$submit(r4:FHIRContext fhirContext, Parameters parameters) returns error|http:Response {
        international401:Parameters submitResult = check claimSubmit(parameters);
        http:Response response = new;
        response.setJsonPayload(submitResult.toJson());
        return response;
    }

    // Read the current state of single resource based on its id.
    isolated resource function get [string id](r4:FHIRContext fhirContext) returns error|http:Response {
        davincipas:PASClaim claim = check getByIdClaim(id);
        http:Response response = new;
        response.setJsonPayload(claim.toJson());
        return response;
    }

    // Read the state of a specific version of a resource based on its id.
    isolated resource function get [string id]/_history/[string vid](r4:FHIRContext fhirContext) returns Claim|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Search for resources based on a set of criteria.
    isolated resource function get .(r4:FHIRContext fhirContext) returns error|http:Response {
        map<string[]> queryParamsMap = getQueryParamsMap(fhirContext.getRequestSearchParameters());
        r4:Bundle bundle = check searchClaim(queryParamsMap);

        http:Response response = new;
        response.setJsonPayload(bundle.toJson());
        return response;
    }

    // Create a new resource.
    isolated resource function post .(r4:FHIRContext fhirContext, Claim procedure) returns error|http:Response {
        davincipas:PASClaim createResult = check createClaim(procedure);
        http:Response response = new;
        response.setJsonPayload(createResult.toJson());
        return response;
    }

    // Update the current state of a resource completely.
    isolated resource function put [string id](r4:FHIRContext fhirContext, Claim claim) returns Claim|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Update the current state of a resource partially.
    isolated resource function patch [string id](r4:FHIRContext fhirContext, json patch) returns Claim|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Delete a resource.
    isolated resource function delete [string id](r4:FHIRContext fhirContext) returns r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Retrieve the update history for a particular resource.
    isolated resource function get [string id]/_history(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Retrieve the update history for all resources.
    isolated resource function get _history(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }
}

// ######################################################################################################################
// # ClaimResponse API                                                                                                  #
// ###################################################################################################################### 

public type ClaimResponse davincipas:PASClaimResponse;

service /fhir/r4/ClaimResponse on new fhirr4:Listener(9092, claimResponseApiConfig) {

    // Read the current state of single resource based on its id.
    isolated resource function get [string id](r4:FHIRContext fhirContext) returns http:Response|r4:OperationOutcome|r4:FHIRError|error {
        ClaimResponse claimResponse = check getByIdClaimResponse(id);
        http:Response response = new;
        response.setJsonPayload(claimResponse.toJson());
        response.statusCode = http:STATUS_OK;
        return response;
    }

    // Read the state of a specific version of a resource based on its id.
    isolated resource function get [string id]/_history/[string vid](r4:FHIRContext fhirContext) returns ClaimResponse|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Search for resources based on a set of criteria.
    isolated resource function get .(r4:FHIRContext fhirContext) returns http:Response|r4:OperationOutcome|r4:FHIRError|error {
        map<string[]> queryParamsMap = getQueryParamsMap(fhirContext.getRequestSearchParameters());

        http:Response response = new;
        r4:Bundle bundle = check searchClaimResponse(queryParamsMap);
        response.setJsonPayload(bundle.toJson());
        response.statusCode = http:STATUS_OK;
        return response;
    }

    // Create a new resource.
    isolated resource function post .(r4:FHIRContext fhirContext, ClaimResponse procedure) returns error|http:Response {
        http:Response response = new;
        ClaimResponse result = check createClaimResponse(procedure);
        response.setJsonPayload(result.toJson());
        response.statusCode = http:STATUS_CREATED;
        return response;
    }

    // Update the current state of a resource completely.
    isolated resource function put [string id](r4:FHIRContext fhirContext, ClaimResponse claimresponse) returns ClaimResponse|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Update the current state of a resource partially.
    isolated resource function patch [string id](r4:FHIRContext fhirContext, json patch) returns ClaimResponse|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Delete a resource.
    isolated resource function delete [string id](r4:FHIRContext fhirContext) returns r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Retrieve the update history for a particular resource.
    isolated resource function get [string id]/_history(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Retrieve the update history for all resources.
    isolated resource function get _history(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }
}

// ######################################################################################################################
// # Coverage API                                                                                                       #
// ######################################################################################################################

public type Coverage international401:Coverage;

# initialize source system endpoint here

# A service representing a network-accessible API
# bound to port `9090`.
service /fhir/r4/Coverage on new fhirr4:Listener(9093, coverageApiConfig) {

    // Read the current state of single resource based on its id.
    isolated resource function get [string id](r4:FHIRContext fhirContext) returns Coverage|r4:OperationOutcome|r4:FHIRError {
        return getByIdCoverage(id);
    }

    // Read the state of a specific version of a resource based on its id.
    isolated resource function get [string id]/_history/[string vid](r4:FHIRContext fhirContext) returns Coverage|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Search for resources based on a set of criteria.
    isolated resource function get .(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        map<string[]> queryParamsMap = getQueryParamsMap(fhirContext.getRequestSearchParameters());
        return searchCoverage(queryParamsMap);
    }

    // Create a new resource.
    isolated resource function post .(r4:FHIRContext fhirContext, Coverage coverage) returns Coverage|r4:OperationOutcome|r4:FHIRError {
        return createCoverage(coverage);
    }

    // Update the current state of a resource completely.
    isolated resource function put [string id](r4:FHIRContext fhirContext, Coverage coverage) returns Coverage|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Update the current state of a resource partially.
    isolated resource function patch [string id](r4:FHIRContext fhirContext, json patch) returns Coverage|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Delete a resource.
    isolated resource function delete [string id](r4:FHIRContext fhirContext) returns r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Retrieve the update history for a particular resource.
    isolated resource function get [string id]/_history(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Retrieve the update history for all resources.
    isolated resource function get _history(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }
}

// ######################################################################################################################
// # EoB API                                                                                                            #
// ######################################################################################################################

public type ExplanationOfBenefit carinbb200:C4BBExplanationOfBenefitOutpatientInstitutional|carinbb200:C4BBExplanationOfBenefitInpatientInstitutional|carinbb200:C4BBExplanationOfBenefitPharmacy|carinbb200:C4BBExplanationOfBenefitOral|carinbb200:C4BBExplanationOfBenefitProfessionalNonClinician;

# initialize source system endpoint here

# A service representing a network-accessible API
# bound to port `9090`.
service / on new fhirr4:Listener(9094, eobApiConfig) {

    // Read the current state of single resource based on its id.
    isolated resource function get fhir/r4/ExplanationOfBenefit/[string id](r4:FHIRContext fhirContext) returns ExplanationOfBenefit|r4:OperationOutcome|r4:FHIRError {
        return getByIdEob(id);
    }

    // Read the state of a specific version of a resource based on its id.
    isolated resource function get fhir/r4/ExplanationOfBenefit/[string id]/_history/[string vid](r4:FHIRContext fhirContext) returns ExplanationOfBenefit|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Search for resources based on a set of criteria.
    isolated resource function get fhir/r4/ExplanationOfBenefit(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        r4:Bundle searchResult = check searchEob(getQueryParamsMap(fhirContext.getRequestSearchParameters()));
        return searchResult;
    }

    // Create a new resource.
    isolated resource function post fhir/r4/ExplanationOfBenefit(r4:FHIRContext fhirContext, ExplanationOfBenefit procedure) returns ExplanationOfBenefit|r4:OperationOutcome|r4:FHIRError {
        ExplanationOfBenefit eob = check createEob(procedure.toJson());

        return eob;
    }

    // Update the current state of a resource completely.
    isolated resource function put fhir/r4/ExplanationOfBenefit/[string id](r4:FHIRContext fhirContext, ExplanationOfBenefit explanationofbenefit) returns ExplanationOfBenefit|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Update the current state of a resource partially.
    isolated resource function patch fhir/r4/ExplanationOfBenefit/[string id](r4:FHIRContext fhirContext, json patch) returns ExplanationOfBenefit|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Delete a resource.
    isolated resource function delete fhir/r4/ExplanationOfBenefit/[string id](r4:FHIRContext fhirContext) returns r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Retrieve the update history for a particular resource.
    isolated resource function get fhir/r4/ExplanationOfBenefit/[string id]/_history(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Retrieve the update history for all resources.
    isolated resource function get fhir/r4/ExplanationOfBenefit/_history(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }
}

// ######################################################################################################################
// # MedicationRequest API                                                                                              #
// ######################################################################################################################

public type MedicationRequest uscore501:USCoreMedicationRequestProfile;

# initialize source system endpoint here

# A service representing a network-accessible API
# bound to port `9090`.
service /fhir/r4/MedicationRequest on new fhirr4:Listener(9095, medicationRequestApiConfig) {

    // Read the current state of single resource based on its id.
    isolated resource function get [string id](r4:FHIRContext fhirContext) returns MedicationRequest|r4:OperationOutcome|r4:FHIRError {
        return getByIdMedicationRequest(id);
    }

    // Read the state of a specific version of a resource based on its id.
    isolated resource function get [string id]/_history/[string vid](r4:FHIRContext fhirContext) returns MedicationRequest|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Search for resources based on a set of criteria.
    isolated resource function get .(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        map<string[]> queryParamsMap = getQueryParamsMap(fhirContext.getRequestSearchParameters());
        return searchMedicationRequest(queryParamsMap);
    }

    // Create a new resource.
    isolated resource function post .(r4:FHIRContext fhirContext, MedicationRequest medicationRequest) returns error|http:Response {
        uscore501:USCoreMedicationRequestProfile createResult = check createMedicationRequest(medicationRequest);
        http:Response response = new;
        response.setJsonPayload(createResult.toJson());
        return response;
    }

    // Update the current state of a resource completely.
    isolated resource function put [string id](r4:FHIRContext fhirContext, MedicationRequest medicationrequest) returns MedicationRequest|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Update the current state of a resource partially.
    isolated resource function patch [string id](r4:FHIRContext fhirContext, json patch) returns MedicationRequest|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Delete a resource.
    isolated resource function delete [string id](r4:FHIRContext fhirContext) returns r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Retrieve the update history for a particular resource.
    isolated resource function get [string id]/_history(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Retrieve the update history for all resources.
    isolated resource function get _history(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }
}

// ######################################################################################################################
// # Organization API                                                                                                   #
// ######################################################################################################################

public type Organization uscore501:USCoreOrganizationProfile;

# initialize source system endpoint here

# A service representing a network-accessible API
# bound to port `9090`.
service /fhir/r4/Organization on new fhirr4:Listener(9096, organizationApiConfig) {

    // Read the current state of single resource based on its id.
    isolated resource function get [string id](r4:FHIRContext fhirContext) returns Organization|r4:OperationOutcome|r4:FHIRError {
        return getByIdOrganization(id);
    }

    // Read the state of a specific version of a resource based on its id.
    isolated resource function get [string id]/_history/[string vid](r4:FHIRContext fhirContext) returns Organization|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Search for resources based on a set of criteria.
    isolated resource function get .(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        map<string[]> queryParamsMap = getQueryParamsMap(fhirContext.getRequestSearchParameters());
        return searchOrganization(queryParamsMap);
    }

    // Create a new resource.
    isolated resource function post .(r4:FHIRContext fhirContext, Organization organization) returns Organization|r4:OperationOutcome|r4:FHIRError {
        return createOrganization(organization);
    }

    // Update the current state of a resource completely.
    isolated resource function put [string id](r4:FHIRContext fhirContext, Organization organization) returns Organization|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Update the current state of a resource partially.
    isolated resource function patch [string id](r4:FHIRContext fhirContext, json patch) returns Organization|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Delete a resource.
    isolated resource function delete [string id](r4:FHIRContext fhirContext) returns r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Retrieve the update history for a particular resource.
    isolated resource function get [string id]/_history(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Retrieve the update history for all resources.
    isolated resource function get _history(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }
}

// ######################################################################################################################
// # Practitioner API                                                                                                   #
// ######################################################################################################################

public type Practitioner uscore501:USCorePractitionerProfile;

# initialize source system endpoint here

# A service representing a network-accessible API
# bound to port `9090`.
service /fhir/r4/Practitioner on new fhirr4:Listener(9097, practitionerApiConfig) {

    // Read the current state of single resource based on its id.
    isolated resource function get [string id](r4:FHIRContext fhirContext) returns Practitioner|r4:OperationOutcome|r4:FHIRError {
        return getByIdPractitioner(id);
    }

    // Read the state of a specific version of a resource based on its id.
    isolated resource function get [string id]/_history/[string vid](r4:FHIRContext fhirContext) returns Practitioner|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Search for resources based on a set of criteria.
    isolated resource function get .(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        map<string[]> queryParamsMap = getQueryParamsMap(fhirContext.getRequestSearchParameters());
        return searchPractitioner(queryParamsMap);
    }

    // Create a new resource.
    isolated resource function post .(r4:FHIRContext fhirContext, Practitioner practitioner) returns Practitioner|r4:OperationOutcome|r4:FHIRError {
        return createPractitioner(practitioner);
    }

    // Update the current state of a resource completely.
    isolated resource function put [string id](r4:FHIRContext fhirContext, Practitioner practitioner) returns Practitioner|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Update the current state of a resource partially.
    isolated resource function patch [string id](r4:FHIRContext fhirContext, json patch) returns Practitioner|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Delete a resource.
    isolated resource function delete fhir/r4/Practitioner/[string id](r4:FHIRContext fhirContext) returns r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Retrieve the update history for a particular resource.
    isolated resource function get fhir/r4/Practitioner/[string id]/_history(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Retrieve the update history for all resources.
    isolated resource function get fhir/r4/Practitioner/_history(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }
}

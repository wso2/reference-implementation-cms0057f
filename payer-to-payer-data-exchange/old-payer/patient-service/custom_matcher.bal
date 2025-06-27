import ballerina/http;
import ballerina/log;
// import ballerina/os;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincihrex100 as hrex100;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.uscore501;

configurable string coverageServiceUrl =?;
configurable string fhirRepositoryUrl =?;

// Error indicating an internal server error occurred during the member matching process
final r4:FHIRError & readonly INTERNAL_ERROR = r4:createFHIRError("Internal server error", r4:ERROR,
        r4:PROCESSING, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);

public isolated class DemoFHIRMemberMatcher {
    *hrex100:MemberMatcher;
    // FHIR repository clients. These will be used internally (within the project)
    // private final fhir:FHIRConnector fhirPatientClient;
    // private final fhir:FHIRConnector fhirCoverageClient;
    private final http:Client fhirPatientClient;
    private final http:Client fhirCoverageClient;

    public function init() returns error? {
        // self.fhirPatientClient = check new (fhirPatientClientConfig);
        // self.fhirCoverageClient = check new (fhirCoverageClientConfig);
        self.fhirPatientClient = check new (fhirRepositoryUrl);
        self.fhirCoverageClient = check new (coverageServiceUrl);

    }

    public isolated function matchMember(anydata memberMatchResources) returns hrex100:MemberIdentifier|r4:FHIRError {

        if memberMatchResources !is hrex100:MemberMatchResources {
            log:printError("Invalid type for \"memberMatchResources\". Expected type: MemberMatchResources.");
            return r4:createFHIRError("Internal server error", r4:ERROR, r4:PROCESSING, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
        log:printDebug("Custom matcher engaged");

        // Member match resources
        uscore501:USCorePatientProfile memberPatient = memberMatchResources.memberPatient;
        hrex100:HRexConsent? consent = memberMatchResources.consent;
        hrex100:HRexCoverage coverageToMatch = memberMatchResources.coverageToMatch;
        hrex100:HRexCoverage? coverageToLink = memberMatchResources.coverageToLink;

        // Get patient resource from OLD payor
        // Search Patient from given name
        uscore501:USCorePatientProfileName[] name = memberPatient.name;

        international401:Patient[] nameMatchedPatients = check self.getNameMatchedPatients(name);

        international401:Patient oldPatient = {};
        if nameMatchedPatients.length() == 0 {
            return INTERNAL_ERROR;
        } else if nameMatchedPatients.length() == 1 {
            oldPatient = nameMatchedPatients[0];
        } else {
            oldPatient = self.filterPatientsByDemographics(nameMatchedPatients.clone(), memberPatient.clone());
        }

        string patientId = <string>oldPatient.id;

        // Get coverage from id

        string coverageId = <string>coverageToMatch.id;
        r4:Reference incomingCoverageBeneficiary = coverageToMatch.beneficiary;
        fhir:FHIRResponse|fhir:FHIRError readRes = self.getById("Coverage", coverageId, ());
        if readRes is fhir:FHIRError {
            log:printError("FHIR search error", readRes);
            return INTERNAL_ERROR;
        }
        international401:Coverage|error oldCoverage = readRes.'resource.cloneWithType();
        if oldCoverage is error {
            log:printError("FHIR read response is not a valid FHIR Resource", oldCoverage);
            return INTERNAL_ERROR;
        }
        string oldBeneficiaryRef = <string>oldCoverage.beneficiary.reference;

        if oldBeneficiaryRef != incomingCoverageBeneficiary.reference {
            log:printError(string `Beneficiaries Mismatch. Old reference:${oldBeneficiaryRef}  Patient ID:${patientId}`);
            //verify with incoming beneficiary reference
            return INTERNAL_ERROR;
        }

        log:printDebug(oldBeneficiaryRef.substring(8));

        log:printDebug(patientId);

        // If both beneficiaryRef and oldPatient.id are same, we can derive it as a match
        if oldBeneficiaryRef.substring(8) == patientId {
            //match found
            return <hrex100:MemberIdentifier>patientId;
        }

        return r4:createFHIRError("No match found", r4:ERROR, r4:PROCESSING_NOT_FOUND, httpStatusCode = http:STATUS_UNPROCESSABLE_ENTITY);
    }

    private isolated function filterPatientsByDemographics(international401:Patient[] nameMatchedPatients, uscore501:USCorePatientProfile memberPatient)
    returns international401:Patient {
        international401:Patient filteredPatient = {};
        uscore501:USCorePatientProfileGender incomingPatientGender = memberPatient.gender;
        r4:date? birthDate = memberPatient.birthDate;

        log:printDebug(string `Demographic values from the request: Gender = ${incomingPatientGender} , DoB = ${birthDate.toBalString()}`);

        foreach international401:Patient patient in nameMatchedPatients {
            // Additional filter logic can be added here.
        }
        // Selecting the first element as the matched patient for the reference Impl
        filteredPatient = nameMatchedPatients[0];

        return filteredPatient;
    }

    private isolated function getNameMatchedPatients(uscore501:USCorePatientProfileName[] name) returns international401:Patient[]|r4:FHIRError & readonly {

        international401:Patient[] nameMatchedPatients = [];
        string[] givenNames = [];

        foreach uscore501:USCorePatientProfileName patientName in name {
            if patientName.given is string[] {
                if (<string[]>patientName.given).length() > 0 {
                    foreach string givenName in <string[]>patientName.given {
                        givenNames[givenNames.length()] = givenName;
                    }
                }

            }
        }

        foreach string givenName in givenNames {
            map<string[]> searchParams = {};
            searchParams["given"] = [givenName];
            // fhir:FHIRResponse|fhir:FHIRError searchRes = self.search("Patient", searchParams, ());
            // if searchRes is fhir:FHIRError {
            //     log:printError("FHIR search error", searchRes);
            //     return INTERNAL_ERROR;
            // }
            // r4:Bundle|error searchBundle = searchRes.'resource.cloneWithType();
            r4:FHIRError|r4:Bundle searchBundle = search("Patient",searchParams);
            if searchBundle is error {
                log:printError("FHIR search response is not a valid FHIR Bundle", searchBundle);
                return INTERNAL_ERROR;
            }
            r4:BundleEntry[]? patientBundleEntries = searchBundle.entry;
            if patientBundleEntries == () || patientBundleEntries.length() == 0 { // No matches
                continue;
            }

            foreach r4:BundleEntry bundleEntry in patientBundleEntries {
                international401:Patient|error matchedPatient = bundleEntry?.'resource.cloneWithType();
                if matchedPatient is international401:Patient {
                    nameMatchedPatients.push(matchedPatient);
                } else {
                    log:printError("Matched patient resource is not a valid US Core patient resource", matchedPatient);
                }
            }
        }

        return nameMatchedPatients;

    }

    // private isolated function search(string 'type, map<string[]>? searchParameters = (), fhir:MimeType? returnMimeType = ())
    // returns fhir:FHIRResponse|fhir:FHIRError {
    //     string requestUrl = SLASH + 'type + QUESTION_MARK + setSearchParams(searchParameters);
    //     map<string> headerMap = {[ACCEPT_HEADER]: "application/fhir+json"};
    //     // lock {
    //     //     headerMap["Choreo-API-Key"] = patientChoreoapikey.cloneReadOnly();
    //     // }

    //     do {
    //         http:Response response = check self.fhirPatientClient->get(requestUrl, headerMap);
    //         fhir:FHIRResponse result = check getBundleResponse(response);
    //         return result;
    //     } on fail error e {
    //         if e is fhir:FHIRError {
    //             return e;
    //         }
    //         return error(string `FHIR_CONNECTOR_ERROR: ${e.message()}`, errorDetails = e);
    //     }
    // }

    private isolated function getById(string 'type, string id, fhir:MimeType? returnMimeType = ()) returns fhir:FHIRResponse|fhir:FHIRError {
        map<string> headerMap = {[ACCEPT_HEADER]: "application/fhir+json"};
        string requestURL = SLASH + 'type + SLASH + id;
        // lock {
        //     headerMap["Choreo-API-Key"] = coverageChoreoapikey.cloneReadOnly();
        // }
        do {
            http:Response response = check self.fhirCoverageClient->get(requestURL, headerMap);
            fhir:FHIRResponse result = check getFhirResourceResponse(response);

            return result;
        } on fail error e {
            if e is fhir:FHIRError {
                return e;
            }
            return error(string `FHIR_CONNECTOR_ERROR: ${e.message()}`, errorDetails = e);
        }
    }
}

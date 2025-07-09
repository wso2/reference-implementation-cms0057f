import ballerina/http;
import ballerina/log;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincihrex100 as hrex100;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.fhir.r4.uscore501;

// Error indicating an internal server error occurred during the member matching process
final r4:FHIRError & readonly INTERNAL_ERROR = r4:createFHIRError("Internal server error", r4:ERROR,
        r4:PROCESSING, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);

public isolated class DemoFHIRMemberMatcher {
    *hrex100:MemberMatcher;

    public isolated function matchMember(anydata memberMatchResources) returns hrex100:MemberIdentifier|r4:FHIRError {

        if memberMatchResources !is hrex100:MemberMatchResources {
            log:printError("Invalid type for \"memberMatchResources\". Expected type: MemberMatchResources.");
            return r4:createFHIRError("Internal server error", r4:ERROR, r4:PROCESSING, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
        log:printDebug("Custom matcher engaged");

        // Member match resources
        uscore501:USCorePatientProfile memberPatient = memberMatchResources.memberPatient;
        hrex100:HRexConsent? _ = memberMatchResources.consent;
        hrex100:HRexCoverage coverageToMatch = memberMatchResources.coverageToMatch;
        hrex100:HRexCoverage? _ = memberMatchResources.coverageToLink;

        // Get patient resource from OLD payor
        // Search Patient from given name
        uscore501:USCorePatientProfileName[] name = memberPatient.name;

        string[] given = name[0].given ?: [];
        r4:Bundle nameMatchedPatients = check searchPatient("Patient", {"given": [given[0]]});

        r4:BundleEntry[]? entry = nameMatchedPatients.entry;

        if entry is r4:BundleEntry[] {
            r4:BundleEntry firstEntry = entry[0];

            anydata 'resource = firstEntry?.'resource;

            international401:Patient|error cloneWithType = 'resource.cloneWithType(international401:Patient);
            international401:Patient oldPatient = {};
            if cloneWithType is international401:Patient {
                oldPatient = self.filterPatientsByDemographics([cloneWithType], memberPatient.clone());
            }
            string patientId = <string>oldPatient.id;

            // Get coverage from id
            string coverageId = <string>coverageToMatch.id;
            r4:Reference incomingCoverageBeneficiary = coverageToMatch.beneficiary;
            international401:Coverage|r4:FHIRError oldCoverage = check getByIdCoverge(coverageId);

            if oldCoverage is r4:FHIRError {
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
        return r4:createFHIRError("No match found", r4:ERROR, r4:PROCESSING_NOT_FOUND, httpStatusCode = http:STATUS_UNPROCESSABLE_ENTITY);
    }

    private isolated function filterPatientsByDemographics(international401:Patient[] nameMatchedPatients, uscore501:USCorePatientProfile memberPatient)
    returns international401:Patient {
        international401:Patient filteredPatient = {};
        uscore501:USCorePatientProfileGender incomingPatientGender = memberPatient.gender;
        r4:date? birthDate = memberPatient.birthDate;

        log:printDebug(string `Demographic values from the request: Gender = ${incomingPatientGender} , DoB = ${birthDate.toBalString()}`);

        // Additional filter logic can be added here.
        // foreach international401:Patient patient in nameMatchedPatients {

        // }

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
            r4:FHIRError|r4:Bundle searchBundle = searchPatient("Patient", searchParams);
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
}

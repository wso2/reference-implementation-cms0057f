// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.

// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein is strictly forbidden, unless permitted by WSO2 in accordance with
// the WSO2 Software License available at: https://wso2.com/licenses/eula/3.2
// For specific language governing the permissions and limitations under
// this license, please see the license as well as any agreement you’ve
// entered into with WSO2 governing the purchase of this software and any
// associated services.

import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.uscore311;

isolated function transform(LegacyPatient legacyPatientRecord) returns uscore311:USCorePatientProfile|error => {
    resourceType: "Patient",
    id: legacyPatientRecord.legacyPatientId,
    meta: {
        profile: [
            "http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient"
        ]
    },
    identifier: [
        {
            use: uscore311:CODE_USE_USUAL,
            'type: {
                coding: [
                    {
                        code: "MR",
                        display: "Medical record number",
                        system: "http://terminology.hl7.org/CodeSystem/v2-0203"
                    }
                ]
            },
            value: <string>legacyPatientRecord.medicalRecordNumber,
            system: "http://terminology.hl7.org/CodeSystem/v2-0203"
        }
    ],
    active: legacyPatientRecord.recordActive == "Y" ? true : false,
    name: getNames(legacyPatientRecord),
    address: getAddresses(legacyPatientRecord),
    birthDate: legacyPatientRecord.dob,
    gender: legacyPatientRecord.sex == "F" ? "female" : "male",
    telecom: getTelecom(legacyPatientRecord),
    extension: check getExtensions(legacyPatientRecord),
    communication: [
        {
            language: {
                coding: [
                    {
                        code: legacyPatientRecord.language === "English" ? "en-US" : legacyPatientRecord.language,
                        display: "English (United States)",
                        system: "urn:ietf:bcp:47"
                    }
                ]
            }

        }
    ]
};

isolated function getExtensions(LegacyPatient legacyPatientRecord) returns r4:Extension[]|error {
    r4:Extension[] extensions = [];
    int i = 0;
    r4:ExtensionExtension? raceExtensions = getRaceExtensions(legacyPatientRecord.raceCode, 
        legacyPatientRecord.raceDetail, legacyPatientRecord.raceText ?: "");
    r4:ExtensionExtension? ethnicityExtensions = getEthnicityExtensions(legacyPatientRecord.ethnicityCode, 
        legacyPatientRecord.ethnicityDetail, legacyPatientRecord.ethnicityText ?: "");
    r4:CodeExtension? birthSexExtension = check getBirthSexExtension(legacyPatientRecord.sex);
    if raceExtensions is r4:ExtensionExtension {
        extensions[i] = raceExtensions;
        i += 1;
    }
    if ethnicityExtensions is r4:ExtensionExtension {
        extensions[i] = ethnicityExtensions;
        i += 1;
    }
    if birthSexExtension is r4:CodeExtension {
        extensions[i] = birthSexExtension;
        i += 1;
    }
    return extensions;
}

isolated function getRaceExtensions(string[]? raceCodes, string[]? raceDetails, string raceText) returns ()|r4:ExtensionExtension {
    r4:ExtensionExtension raceExtension = {
        url: "http://hl7.org/fhir/us/core/StructureDefinition/us-core-race",
        extension: [
        ]
    };
    int i = 0;
    if raceCodes is string[] && raceCodes.length() > 0 {
        foreach string code in raceCodes {
            raceExtension.extension[i] = {
                url: "ombCategory",
                valueCoding: {
                    code: code,
                    system: getCodeInfo(code)[0],
                    display: getCodeInfo(code)[1]
                }
            };
            i += 1;
        }
    }
    if raceDetails is string[] && raceDetails.length() > 0 {
        foreach string code in raceDetails {
            raceExtension.extension[i] = {
                url: "detailed",
                valueCoding: {
                    code: code,
                    system: getCodeInfo(code)[0],
                    display: getCodeInfo(code)[1]
                }
            };
            i += 1;
        }
    }
    raceExtension.extension[i] = {
        url: "text",
        valueString: raceText
    };
    return i > 0 ? raceExtension : ();
}

isolated function getEthnicityExtensions(string[]? ethnicityCodes, string[]? ethnicityDetails, string ethnicityText) 
    returns ()|r4:ExtensionExtension {
    r4:ExtensionExtension ethnicityExtension = {
        url: "http://hl7.org/fhir/us/core/StructureDefinition/us-core-ethnicity",
        extension: [
        ]
    };
    int i = 0;
    if ethnicityCodes is string[] && ethnicityCodes.length() > 0 {
        foreach string code in ethnicityCodes {
            ethnicityExtension.extension[i] = {
                url: "ombCategory",
                valueCoding: {
                    code: code,
                    system: getCodeInfo(code)[0],
                    display: getCodeInfo(code)[1]
                }
            };
            i += 1;
        }
    }
    if ethnicityDetails is string[] && ethnicityDetails.length() > 0 {
        foreach string code in ethnicityDetails {
            ethnicityExtension.extension[i] = {
                url: "detailed",
                valueCoding: {
                    code: code,
                    system: getCodeInfo(code)[0],
                    display: getCodeInfo(code)[1]
                }
            };
            i += 1;
        }
    }
    ethnicityExtension.extension[i] = {
        url: "text",
        valueString: ethnicityText
    };
    return i > 0 ? ethnicityExtension : ();
}

isolated function getCodeInfo(string code) returns [string, string] {
    if (code == "2135-2") {
        return ["urn:oid:2.16.840.1.113883.6.238", "Hispanic or Latino"];
    } else if (code == "2184-0") {
        return ["urn:oid:2.16.840.1.113883.6.238", "Dominican"];
    } else if (code == "2148-5") {
        return ["urn:oid:2.16.840.1.113883.6.238", "Mexican"];
    } else if (code == "2106-3") {
        return ["urn:oid:2.16.840.1.113883.6.238", "White"];
    } else if (code == "1002-5") {
        return ["urn:oid:2.16.840.1.113883.6.238", "American Indian or Alaska Native"];
    } else if (code == "2028-9") {
        return ["urn:oid:2.16.840.1.113883.6.238", "Asian"];
    } else if (code == "1586-7") {
        return ["urn:oid:2.16.840.1.113883.6.238", "Shoshone"];
    } else if (code == "2036-2") {
        return ["urn:oid:2.16.840.1.113883.6.238", "Filipino"];
    } else if (code == "2054-5") {
        return ["urn:oid:2.16.840.1.113883.6.238", "Black or African American"];
    } else if (code == "1117-1") {
        return ["urn:oid:2.16.840.1.113883.6.238", "Haitian"];
    } else if (code == "2149-3") {
        return ["urn:oid:2.16.840.1.113883.6.238", "Puerto Rican"];
    } else {
        return ["", ""];
    }
}

isolated function getBirthSexExtension(string birthSex) returns r4:CodeExtension|error {
    return {
        url: "http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex",
        valueCode: check birthSex.ensureType()

    };
}

isolated function getNames(LegacyPatient legacyPatientRecord) returns uscore311:USCorePatientProfileName[] {
    uscore311:USCorePatientProfileName[] names = [];
    uscore311:USCorePatientProfileName nameResource = {
        family: legacyPatientRecord.name.lastName,
        given: [
            legacyPatientRecord.name.firstName
        ]
    };
    if (legacyPatientRecord.name.period?.startDate != ()) {
        nameResource.period = {
            'start: legacyPatientRecord.name.period?.startDate,
            end: legacyPatientRecord.name.period?.endDate
        };
    }
    if (legacyPatientRecord.name.middleName != "") {
        nameResource.given[1] = legacyPatientRecord.name.middleName ?: "";
    }
    names.push(nameResource);

    Name[] legacyNames = legacyPatientRecord.previousNames ?: [];
    foreach Name name in legacyNames {
        uscore311:USCorePatientProfileName previousName = {
            family: name.lastName,
            given: [
                name.firstName
            ]
        };
        if (name.period?.startDate != ()) {
            previousName.period = {
                'start: name.period?.startDate,
                end: name.period?.endDate
            };
        }
        if (name.middleName != "") {
            previousName.given[1] = name.middleName ?: "";
        }
        names.push(previousName);
    }
    return names;
}

isolated function getTelecom(LegacyPatient legacyPatientRecord) returns uscore311:USCorePatientProfileTelecom[] {
    uscore311:USCorePatientProfileTelecom[] telecoms = [];
    if (legacyPatientRecord.homePhone != "") {
        telecoms.push({
            system: "phone",
            value: legacyPatientRecord.homePhone ?: "",
            use: "home"
        });
    }
    if (legacyPatientRecord.emailAddress != "") {
        telecoms.push({
            system: "email",
            value: legacyPatientRecord.emailAddress ?: ""
        });
    }
    return telecoms;
}

isolated function getAddresses(LegacyPatient legacyPatientRecord) returns uscore311:USCoreOrganizationProfileAddress[] {
    uscore311:USCorePatientProfileAddress[] addresses = [];
    uscore311:USCorePatientProfileAddress currentAddress = {
        line: [legacyPatientRecord.address.line1],
        city: legacyPatientRecord.address.city,
        state: legacyPatientRecord.address.state,
        postalCode: legacyPatientRecord.address.zip,
        country: legacyPatientRecord.address.country
    };
    if (legacyPatientRecord.address.period?.startDate != ()) {
        currentAddress.period = {
            'start: legacyPatientRecord.address.period?.startDate,
            end: legacyPatientRecord.address.period?.endDate
        };
    }
    addresses.push(currentAddress);
    Address[] legacyAddr = legacyPatientRecord.previousAddresses ?: [];
    foreach Address address in legacyAddr {
        uscore311:USCorePatientProfileAddress prevAddress = {
            line: [address.line1],
            city: address.city,
            state: address.state,
            postalCode: address.zip,
            country: address.country
        };
        if (address.period?.startDate != ()) {
            prevAddress.period = {
                'start: address.period?.startDate,
                end: address.period?.endDate
            };
        }
        addresses.push(prevAddress);
    }
    return addresses;
}

type Period record {|
    string startDate?;
    string endDate?;
|};

type Address record {
    string line1;
    string city;
    string state;
    string zip;
    string country;
    Period period?;
};

type Name record {
    string firstName;
    string middleName?;
    string lastName;
    Period period?;
};

type LegacyPatient record {
    string legacyPatientId;
    Name name;
    Name[] previousNames?;
    string dob;
    string sex;
    string homePhone?;
    string emailAddress?;
    Address address;
    Address[] previousAddresses?;
    string medicalRecordNumber?;
    string recordActive?;
    string language?;
    string[] raceCode?;
    string[] raceDetail?;
    string raceText?;
    string[] ethnicityCode?;
    string[] ethnicityDetail?;
    string ethnicityText?;
    string maritalStatus?;
    string height?;
    string weight?;
    string preferredName?;
    string insuranceId?;
    string primaryCareProvider?;
    string emergencyContactName?;
    string emergencyContactPhone?;
    string[] allergies?;
    string notes?;
    string workEmail?;
    string hospitalPatientId?;
};

type LegacyPatients record {
    LegacyPatient[] patients;
};

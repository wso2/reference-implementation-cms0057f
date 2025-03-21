import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated uscore700:USCoreImmunizationProfile[] immunizations = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|uscore700:USCoreImmunizationProfile {
    uscore700:USCoreImmunizationProfile|error immunization = parser:parse(payload, uscore700:USCoreImmunizationProfile).ensureType();

    if immunization is error {
        return r4:createFHIRError(immunization.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            immunization.id = (createOperationNextId).toBalString();
        }

        lock {
            immunizations.push(immunization.clone());
        }

        return immunization;
    }
}

# Description.
#
# + id - parameter description
# + return - return value description
public isolated function getById(string id) returns r4:FHIRError|uscore700:USCoreImmunizationProfile {
    lock {
        foreach var item in immunizations {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a immunization resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    uscore700:USCoreImmunizationProfile byId = check getById(searchParameters.get('key)[0]);
                    bundle.entry = [
                        {
                            'resource: byId
                        }
                    ];
                    return bundle;
                }
                _ => {
                    return r4:createFHIRError(string `Not supported search parameter: ${'key}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
                }
            }
        }
    }

    lock {
        r4:BundleEntry[] bundleEntries = [];
        foreach var item in immunizations {
            r4:BundleEntry bundleEntry = {
                'resource: item
            };
            bundleEntries.push(bundleEntry);
        }
        r4:Bundle cloneBundle = bundle.clone();
        cloneBundle.entry = bundleEntries;
        return cloneBundle.clone();
    }
}

function init() returns error? {
    lock {
        json immunizationJson = {
            "resourceType": "Immunization",
            "id": "12344",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-immunization|7.0.0"]
            },
            "text": {
                "status": "generated",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p><b>Generated Narrative: Immunization</b><a name=\"imm-1\"> </a><a name=\"hcimm-1\"> </a></p><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Resource Immunization &quot;imm-1&quot; </p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-us-core-immunization.html\">US Core Immunization Profile (version 7.0.0)</a></p></div><p><b>status</b>: completed</p><p><b>vaccineCode</b>: influenza, high-dose, quadrivalent <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"http://terminology.hl7.org/5.3.0/CodeSystem-CVX.html\">Vaccine Administered Code Set (CVX)</a>#197; <a href=\"http://terminology.hl7.org/5.3.0/CodeSystem-v3-ndc.html\">National drug codes</a>#49281012165 &quot;FLUZONE High-Dose Quadrivalent Northern Hemisphere, 10 SYRINGE, GLASS in 1 PACKAGE (49281-121-65) &gt; .7 mL in 1 SYRINGE, GLASS (49281-121-88) (package)&quot;)</span></p><p><b>patient</b>: <a href=\"Patient-example.html\">Patient/example: Amy Shaw</a> &quot; SHAW&quot;</p><p><b>encounter</b>: <a href=\"Encounter-example-1.html\">Encounter/example-1: Office Visit</a></p><p><b>occurrence</b>: 2020-11-19 12:46:57-0800</p><p><b>primarySource</b>: false</p><p><b>location</b>: <a href=\"Location-hospital.html\">Location/hospital: Holy Family Hospital</a> &quot;Holy Family Hospital&quot;</p></div>"
            },
            "status": "completed",
            "vaccineCode": {
                "coding": [
                    {
                        "system": "http://hl7.org/fhir/sid/cvx",
                        "code": "197",
                        "display": "influenza, high-dose, quadrivalent"
                    },
                    {
                        "system": "http://hl7.org/fhir/sid/ndc",
                        "code": "49281012165",
                        "display": "FLUZONE High-Dose Quadrivalent Northern Hemisphere, 10 SYRINGE, GLASS in 1 PACKAGE (49281-121-65) > .7 mL in 1 SYRINGE, GLASS (49281-121-88) (package)"
                    }
                ],
                "text": "influenza, high-dose, quadrivalent"
            },
            "patient": {
                "reference": "Patient/example",
                "display": "Amy Shaw"
            },
            "encounter": {
                "reference": "Encounter/example-1",
                "display": "Office Visit"
            },
            "occurrenceDateTime": "2020-11-19T12:46:57-08:00",
            "occurrenceString": "2020-11-19 12:46:57-0800",
            "primarySource": false,
            "location": {
                "reference": "Location/hospital",
                "display": "Holy Family Hospital"
            }
        };
        uscore700:USCoreImmunizationProfile immunization = check parser:parse(immunizationJson, uscore700:USCoreImmunizationProfile).ensureType();
        immunizations.push(immunization.clone());
    }
}

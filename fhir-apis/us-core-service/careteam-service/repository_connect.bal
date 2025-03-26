import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated uscore700:USCoreCareTeam[] careTeams = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|uscore700:USCoreCareTeam {
    uscore700:USCoreCareTeam|error careTeam = parser:parse(payload, uscore700:USCoreCareTeam).ensureType();

    if careTeam is error {
        return r4:createFHIRError(careTeam.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            careTeam.id = (createOperationNextId).toBalString();
        }

        lock {
            careTeams.push(careTeam.clone());
        }

        return careTeam;
    }
}

# Description.
#
# + id - parameter description
# + return - return value description
public isolated function getById(string id) returns r4:FHIRError|uscore700:USCoreCareTeam {
    lock {
        foreach var item in careTeams {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a careTeam resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    uscore700:USCoreCareTeam byId = check getById(searchParameters.get('key)[0]);
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
        foreach var item in careTeams {
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
        json careTeamJson = {
            "resourceType": "CareTeam",
            "id": "12344",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-careteam|7.0.0"]
            },
            "text": {
                "status": "generated",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p><b>Generated Narrative: CareTeam</b><a name=\"example\"> </a><a name=\"hcexample\"> </a></p><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Resource CareTeam &quot;example&quot; </p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-us-core-careteam.html\">US Core CareTeam Profile (version 7.0.0)</a></p></div><p><b>status</b>: active</p><p><b>name</b>: US-Core example CareTeam</p><p><b>subject</b>: <a href=\"Patient-example.html\">Patient/example: Amy V. Shaw</a> &quot; SHAW&quot;</p><blockquote><p><b>participant</b></p><p><b>role</b>: Cardiologist <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"https://browser.ihtsdotools.org/\">SNOMED CT[US]</a>#17561000)</span></p><p><b>member</b>: <a href=\"Practitioner-practitioner-1.html\">Practitioner/practitioner-1: Ronald Bone, MD</a> &quot; BONE&quot;</p></blockquote><blockquote><p><b>participant</b></p><p><b>role</b>: Primary care provider <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"https://browser.ihtsdotools.org/\">SNOMED CT[US]</a>#453231000124104)</span></p><p><b>member</b>: <a href=\"Practitioner-practitioner-2.html\">Practitioner/practitioner-2: Kathy Fielding, MD</a> &quot; KATHY&quot;</p></blockquote><blockquote><p><b>participant</b></p><p><b>role</b>: Patient (person) <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"https://browser.ihtsdotools.org/\">SNOMED CT[US]</a>#116154003)</span></p><p><b>member</b>: <a href=\"Patient-example.html\">Patient/example: Amy V. Shaw</a> &quot; SHAW&quot;</p></blockquote><blockquote><p><b>participant</b></p><p><b>role</b>: Caregiver (person) <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> (<a href=\"https://browser.ihtsdotools.org/\">SNOMED CT[US]</a>#133932002)</span></p><p><b>member</b>: <a href=\"RelatedPerson-shaw-niece.html\">RelatedPerson/shaw-niece: Sarah van Putten</a> &quot; VAN PUTTEN&quot;</p></blockquote></div>"
            },
            "status": "active",
            "name": "US-Core example CareTeam",
            "subject": {
                "reference": "Patient/example",
                "display": "Amy V. Shaw"
            },
            "participant": [
                {
                    "role": [
                        {
                            "coding": [
                                {
                                    "system": "http://snomed.info/sct",
                                    "version": "http://snomed.info/sct/731000124108",
                                    "code": "17561000",
                                    "display": "Cardiologist"
                                }
                            ]
                        }
                    ],
                    "member": {
                        "reference": "Practitioner/practitioner-1",
                        "display": "Ronald Bone, MD"
                    }
                },
                {
                    "role": [
                        {
                            "coding": [
                                {
                                    "system": "http://snomed.info/sct",
                                    "version": "http://snomed.info/sct/731000124108",
                                    "code": "453231000124104",
                                    "display": "Primary care provider"
                                }
                            ]
                        }
                    ],
                    "member": {
                        "reference": "Practitioner/practitioner-2",
                        "display": "Kathy Fielding, MD"
                    }
                },
                {
                    "role": [
                        {
                            "coding": [
                                {
                                    "system": "http://snomed.info/sct",
                                    "version": "http://snomed.info/sct/731000124108",
                                    "code": "116154003",
                                    "display": "Patient (person)"
                                }
                            ]
                        }
                    ],
                    "member": {
                        "reference": "Patient/example",
                        "display": "Amy V. Shaw"
                    }
                },
                {
                    "role": [
                        {
                            "coding": [
                                {
                                    "system": "http://snomed.info/sct",
                                    "version": "http://snomed.info/sct/731000124108",
                                    "code": "133932002",
                                    "display": "Caregiver (person)"
                                }
                            ]
                        }
                    ],
                    "member": {
                        "reference": "RelatedPerson/shaw-niece",
                        "display": "Sarah van Putten"
                    }
                }
            ]
        };
        uscore700:USCoreCareTeam careTeam = check parser:parse(careTeamJson, uscore700:USCoreCareTeam).ensureType();
        careTeams.push(careTeam.clone());
    }
}

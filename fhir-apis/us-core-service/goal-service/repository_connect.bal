import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated uscore700:USCoreGoalProfile[] goals = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|uscore700:USCoreGoalProfile {
    uscore700:USCoreGoalProfile|error goal = parser:parse(payload, uscore700:USCoreGoalProfile).ensureType();

    if goal is error {
        return r4:createFHIRError(goal.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            goal.id = (createOperationNextId).toBalString();
        }

        lock {
            goals.push(goal.clone());
        }

        return goal;
    }
}

public isolated function getById(string id) returns r4:FHIRError|uscore700:USCoreGoalProfile {
    lock {
        foreach var item in goals {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a goal resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    uscore700:USCoreGoalProfile byId = check getById(searchParameters.get('key)[0]);
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
        foreach var item in goals {
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
        json goalJson = {
            "resourceType": "Goal",
            "id": "12344",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-goal|7.0.0"]
            },
            "text": {
                "status": "generated",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\"><p><b>Generated Narrative: Goal</b><a name=\"goal-1\"> </a><a name=\"hcgoal-1\"> </a></p><div style=\"display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%\"><p style=\"margin-bottom: 0px\">Resource Goal &quot;goal-1&quot; </p><p style=\"margin-bottom: 0px\">Profile: <a href=\"StructureDefinition-us-core-goal.html\">US Core Goal Profile (version 7.0.0)</a></p></div><p><b>lifecycleStatus</b>: active</p><p><b>description</b>: Patient is targeting a pulse oximetry of 92% and a weight of 195 lbs <span style=\"background: LightGoldenRodYellow; margin: 4px; border: 1px solid khaki\"> ()</span></p><p><b>subject</b>: <a href=\"Patient-example.html\">Patient/example: Amy Shaw</a> &quot; SHAW&quot;</p><h3>Targets</h3><table class=\"grid\"><tr><td style=\"display: none\">-</td><td><b>Due[x]</b></td></tr><tr><td style=\"display: none\">*</td><td>2016-04-05</td></tr></table></div>"
            },
            "lifecycleStatus": "active",
            "description": {
                "text": "Patient is targeting a pulse oximetry of 92% and a weight of 195 lbs"
            },
            "subject": {
                "reference": "Patient/example",
                "display": "Amy Shaw"
            },
            "target": [
                {
                    "dueDate": "2016-04-05"
                }
            ]
        };
        uscore700:USCoreGoalProfile goal = check parser:parse(goalJson, uscore700:USCoreGoalProfile).ensureType();
        goals.push(goal.clone());
    }
}

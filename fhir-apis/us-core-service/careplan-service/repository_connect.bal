import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.parser;
import ballerinax/health.fhir.r4.uscore700;

isolated uscore700:USCoreCarePlanProfile[] carePlans = [];
isolated int createOperationNextId = 12344;

public isolated function create(json payload) returns r4:FHIRError|uscore700:USCoreCarePlanProfile {
    uscore700:USCoreCarePlanProfile|error carePlan = parser:parseWithValidation(payload, uscore700:USCoreCarePlanProfile).ensureType();

    if carePlan is error {
        return r4:createFHIRError(carePlan.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            createOperationNextId += 1;
            carePlan.id = (createOperationNextId).toBalString();
        }

        lock {
            carePlans.push(carePlan.clone());
        }

        return carePlan;
    }
}

public isolated function getById(string id) returns r4:FHIRError|uscore700:USCoreCarePlanProfile {
    lock {
        foreach var item in carePlans {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a carePlan resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    uscore700:USCoreCarePlanProfile byId = check getById(searchParameters.get('key)[0]);
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
        foreach var item in carePlans {
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
        json carePlanJson = {
            "resourceType": "CarePlan",
            "id": "12344",
            "meta": {
                "profile": ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-careplan|7.0.0"]
            },
            "text": {
                "status": "additional",
                "div": "<div xmlns=\"http://www.w3.org/1999/xhtml\">\n&#9;&#9;&#9;<strong>Assessment</strong>\n&#9;&#9;&#9;<ol>\n&#9;&#9;&#9;&#9;<li>Recurrent GI bleed of unknown etiology; hypotension perhaps secondary to this but as likely secondary to polypharmacy.</li>\n&#9;&#9;&#9;&#9;<li>Acute on chronic anemia secondary to #1.</li>\n&#9;&#9;&#9;&#9;<li>Azotemia, acute renal failure with volume loss secondary to #1.</li>\n&#9;&#9;&#9;&#9;<li>Hyperkalemia secondary to #3 and on ACE and K+ supplement.</li>\n&#9;&#9;&#9;&#9;<li>Other chronic diagnoses as noted above, currently stable.</li>\n&#9;&#9;&#9;</ol>\n&#9;&#9;&#9;<table>\n&#9;&#9;&#9;&#9;<thead>\n&#9;&#9;&#9;&#9;&#9;<tr>\n&#9;&#9;&#9;&#9;&#9;&#9;<th>Planned Activity</th>\n&#9;&#9;&#9;&#9;&#9;&#9;<th>Planned Date</th>\n&#9;&#9;&#9;&#9;&#9;</tr>\n&#9;&#9;&#9;&#9;</thead>\n&#9;&#9;&#9;&#9;<tbody>\n&#9;&#9;&#9;&#9;&#9;<tr>\n&#9;&#9;&#9;&#9;&#9;&#9;<td>Colonoscopy</td>\n&#9;&#9;&#9;&#9;&#9;&#9;<td>April 21, 2000</td>\n&#9;&#9;&#9;&#9;&#9;</tr>\n&#9;&#9;&#9;&#9;</tbody>\n&#9;&#9;&#9;</table>\n&#9;&#9;</div>"
            },
            "status": "active",
            "intent": "order",
            "category": [
                {
                    "coding": [
                        {
                            "system": "http://hl7.org/fhir/us/core/CodeSystem/careplan-category",
                            "code": "assess-plan"
                        }
                    ]
                }
            ],
            "subject": {
                "reference": "Patient/example",
                "display": "Amy Shaw"
            }
        };
        uscore700:USCoreCarePlanProfile carePlan = check parser:parse(carePlanJson, uscore700:USCoreCarePlanProfile).ensureType();
        carePlans.push(carePlan.clone());
    }
}

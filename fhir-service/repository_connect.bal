import ballerina/http;
import ballerina/time;
import ballerinax/health.fhir.r4;

// key = resource type
isolated map<r4:DomainResource[]> repositoryMap = {
    Patient: [],
    AllergyIntolerance: [],
    Claim: [],
    ClaimResponse: [],
    Coverage: [],
    DiagnosticReport: [],
    Encounter: [],
    ExplanationOfBenefit: [],
    MedicationRequest: [],
    Observation: [],
    Organization: [],
    Practitioner: [],
    Questionnaire: [],
    QuestionnairPackage: [],
    QuestionnaireResponse: []
};
isolated map<int> nextIdMap = {
    Patient: 102,
    AllergyIntolerance: 20300,
    Claim: 12343,
    ClaimResponse: 12343,
    Coverage: 367,
    DiagnosticReport: 87920,
    Encounter: 12344,
    ExplanationOfBenefit: 14453,
    MedicationRequest: 111113,
    Observation: 63230,
    Organization: 50,
    Practitioner: 457,
    Questionnaire: 5,
    QuestionnairPackage: 33,
    QuestionnaireResponse: 1121
};

public isolated function create(ResourceType resourceType, r4:DomainResource payload) returns r4:DomainResource|error {
    int nextId = 0;
    lock {
        int? prevId = nextIdMap[resourceType];
        if prevId is int {
            nextId = (<int>prevId) + 1;
        }
        nextIdMap[resourceType] = nextId;

    }
    r4:DomainResource resourceClone = check payload.ensureType();
    lock {
        resourceClone.id = nextId.toBalString();

        r4:DomainResource[] resources = [];

        if repositoryMap.hasKey(resourceType) {
            r4:DomainResource[]? resourceArr = repositoryMap[resourceType].clone();
            if resourceArr is r4:DomainResource[] {
                resources = resourceArr;
            }
        }

        resources.push(payload.clone());
        repositoryMap[resourceType] = resources;
    }
    return resourceClone;
}

public isolated function getById(ResourceType resourceType, string id) returns r4:DomainResource|r4:FHIRError {
    lock {
        if repositoryMap.hasKey(resourceType) {
            r4:DomainResource[]? resources = repositoryMap[resourceType];
            if resources is r4:DomainResource[] {
                foreach r4:DomainResource resourceItem in resources {
                    if resourceItem.id == id {
                        return resourceItem.clone();
                    }
                }
            }
        }
    }
    return r4:createFHIRError(string `Resource of type ${resourceType} with id ${id} not found`, r4:ERROR, r4:PROCESSING_NOT_FOUND, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function search(ResourceType resourceType, map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:DomainResource[] results = [];
    if searchParameters is map<string[]> {
        lock {
            if repositoryMap.hasKey(resourceType) {
                results = repositoryMap[resourceType].clone() ?: [];
            }
        }

        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    // id is unique, so we can directly return the resource
                    r4:DomainResource byId = check getById(resourceType, searchParameters.get('key)[0]);
                    return r4:createFhirBundle("collection", [byId]);
                }
                "_lastUpdated" => {
                    results = check searchByDate(results, "lastUpdated", searchParameters.get('key)[0]);
                }
                "_profile" => {
                    results = searchByProfile(results, searchParameters.get('key)[0]);
                }
                "patient" => {
                    // search parameter should be patient='id' e.g., patient='123'
                    if resourceType == ALLERGY_INTOLERENCE || resourceType == CLAIM || resourceType == CLAIM_RESPONSE ||
                        resourceType == COVERAGE || resourceType == DIAGNOSTIC_REPORT || resourceType == ENCOUNTER || 
                        resourceType == EXPLANATION_OF_BENEFIT || resourceType == OBSERVATION {
                        results = searchByReference(results, "patient", string `Patient/${searchParameters.get('key)[0]}`);
                    }
                }
                "subject" => {
                    // search parameter should be subject='ResourceType/id' e.g., subject='Patient/123'
                    if resourceType == QUESTIONNAIRE_RESPONSE {
                        results = searchByReference(results, "subject", searchParameters.get('key)[0]);
                    }
                }
                "identifier" => {
                    results = searchByIdentifier(results, searchParameters.get('key)[0]);
                }
                "author" => {
                    if resourceType == QUESTIONNAIRE_RESPONSE {
                        results = searchByReference(results, "author", searchParameters.get('key)[0]);
                    }
                }
                "use" => {
                    if resourceType == CLAIM || resourceType == CLAIM_RESPONSE {
                        results = searchByAttribute(results, "use", searchParameters.get('key)[0]);
                    }
                }
                "created" => {
                    if resourceType == CLAIM || resourceType == CLAIM_RESPONSE || resourceType == EXPLANATION_OF_BENEFIT {
                        results = check searchByDate(results, "created", searchParameters.get('key)[0]);
                    }
                }
                "type" => {
                    if resourceType == ORGANIZATION {
                        results = searchByCodeableConceptCode(results, "type", searchParameters.get('key)[0]);
                    }
                }
                "name" => {
                    if resourceType == PRACTITIONER || resourceType == PATIENT {
                        results = searchByName(results, searchParameters.get('key)[0], "name");
                    }
                }
                "given" => {
                    if resourceType == PRACTITIONER || resourceType == PATIENT {
                        results = searchByName(results, searchParameters.get('key)[0], "given");
                    }
                }
                "_count" => {
                    // pagination is not used in this service
                    continue;
                }
                _ => {
                    return r4:createFHIRError(string `Not supported search parameter: ${'key}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
                }
            }
        }
    }

    return r4:createFhirBundle("collection", results);
}

isolated function searchByReference(r4:DomainResource[] resourceArr, string referenceAttributeName, string searchValue) returns r4:DomainResource[] {
    r4:DomainResource[] filteredResources = [];
    foreach r4:DomainResource resourceItem in resourceArr {
        r4:Reference|error? referenceAttribute = resourceItem[referenceAttributeName].cloneWithType();
        if referenceAttribute is r4:Reference && referenceAttribute.reference == searchValue {
            filteredResources.push(resourceItem);
        }
    }
    return filteredResources;
}

isolated function searchByAttribute(r4:DomainResource[] resourceArr, string attributeName, string searchValue) returns r4:DomainResource[] {
    r4:DomainResource[] filteredResources = [];
    foreach r4:DomainResource resourceItem in resourceArr {
        if resourceItem[attributeName] is string && resourceItem[attributeName] == searchValue {
            filteredResources.push(resourceItem);
        }
    }
    return filteredResources;
}

isolated function searchByCodeableConceptCode(r4:DomainResource[] resourceArr, string codeableConceptAttributeName, r4:code code) returns r4:DomainResource[] {
    r4:DomainResource[] filteredResources = [];
    foreach r4:DomainResource resourceItem in resourceArr {
        r4:CodeableConcept[]|error? codeableConceptAttibuteVal = resourceItem[codeableConceptAttributeName].cloneWithType();
        if codeableConceptAttibuteVal is r4:CodeableConcept[] {
            r4:CodeableConcept codeableConcept = codeableConceptAttibuteVal[0]; // for reference implementation, we take the first element
            r4:Coding[]? codings = codeableConcept.coding;
            if codings is r4:Coding[] {
                r4:Coding coding = codings[0]; // for reference implementation, we take the first coding
                if coding.code == code {
                    filteredResources.push(resourceItem);
                }
            }
        }
    }
    return filteredResources;
}

isolated function searchByProfile(r4:DomainResource[] resourceArr, string profileUri) returns r4:DomainResource[] {
    r4:DomainResource[] filteredResources = [];
    foreach r4:DomainResource resourceItem in resourceArr {
        r4:Meta? meta = resourceItem.meta;
        if meta is r4:Meta {
            r4:canonical[]? profiles = meta.profile;
            if profiles is () {
                continue; // Skip if there are no profiles
            }
            foreach r4:canonical item in profiles {
                if item == profileUri {
                    filteredResources.push(resourceItem);
                    break; // Break the inner loop if a match is found
                }
            }
        } else {
            continue; // Skip if meta is not present
        }
    }
    return filteredResources;
}

isolated function searchByIdentifier(r4:DomainResource[] resourceArr, string identifier) returns r4:DomainResource[] {
    r4:DomainResource[] filteredResources = [];
    foreach r4:DomainResource resourceItem in resourceArr {
        r4:Identifier[]|error identifiers = resourceItem["identifier"].cloneWithType();
        if identifiers is r4:Identifier[] {
            foreach r4:Identifier item in identifiers {
                if item.system == identifier {
                    filteredResources.push(resourceItem);
                    break; // Break the inner loop if a match is found
                }
            }
        }
    }
    return filteredResources;
}

isolated function searchByName(r4:DomainResource[] resourceArr, string searchValue, string nameAttributeName) returns r4:DomainResource[] {
    r4:DomainResource[] filteredResources = [];
    foreach r4:DomainResource resourceItem in resourceArr {
        var nameField = resourceItem["name"];
        if nameField is r4:HumanName[] && nameField.length() > 0 {
            r4:HumanName nameRecord = nameField[0];
            if nameAttributeName == "name" {
                string family = nameRecord.family ?: "";
                string given = (nameRecord.given is string[] && (<string[]>nameRecord.given).length() > 0) ? (<string[]>nameRecord.given)[0] : "";
                string fullName = string `${family} ${given}`;
                if fullName.toLowerAscii().includes(searchValue.toLowerAscii()) {
                    filteredResources.push(resourceItem);
                }
            } else if nameAttributeName == "given" {
                if nameRecord.given is string[] {
                    foreach string givenName in <string[]>nameRecord.given {
                        if givenName.toLowerAscii() == searchValue.toLowerAscii() {
                            filteredResources.push(resourceItem);
                            break;
                        }
                    }
                }
            } else if nameAttributeName == "family" {
                if nameRecord.family is string && (<string>nameRecord.family).toLowerAscii() == searchValue.toLowerAscii() {
                    filteredResources.push(resourceItem);
                }
            }
        }
    }
    return filteredResources;
}

isolated function searchByDate(r4:DomainResource[] resourceArr, string dateAttributeName, string searchDate) returns r4:DomainResource[]|r4:FHIRError {
    string operator = searchDate.substring(0, 2);
    r4:dateTime datetimeR4 = searchDate.substring(2);

    // convert r4:dateTime to time:Utc
    time:Utc|time:Error dateTimeUtc = time:utcFromString(datetimeR4.includes("T") ? datetimeR4 : datetimeR4 + "T00:00:00.000Z");
    if dateTimeUtc is time:Error {
        return r4:createFHIRError(string `Invalid date format: ${searchDate}, ${dateTimeUtc.message()}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    r4:DomainResource[] filteredResources = [];
    foreach r4:DomainResource resourceItem in resourceArr {
        time:Utc|time:Error? resourceDateTimeUtc = ();

        if dateAttributeName is "lastUpdated" {
            // get the lastUpdated date from the meta field
            r4:Meta? resourceMeta = resourceItem.meta;
            if resourceMeta is r4:Meta && resourceMeta.lastUpdated is r4:instant {
                resourceDateTimeUtc = time:utcFromString(resourceMeta.lastUpdated ?: "");
            }
        } else {
            if resourceItem[dateAttributeName] is r4:dateTime {
                r4:dateTime resourceDateTimeR4 = <r4:dateTime>resourceItem[dateAttributeName];
                resourceDateTimeUtc = time:utcFromString(resourceDateTimeR4.includes("T") ? resourceDateTimeR4 : resourceDateTimeR4 + "T00:00:00.000Z");
            }
        }

        if resourceDateTimeUtc is time:Error || resourceDateTimeUtc is () {
            continue; // Skip invalid date formats
        }
        match operator {
            "eq" => {
                if resourceDateTimeUtc == dateTimeUtc {
                    filteredResources.push(resourceItem.clone());
                }
            }
            "ne" => {
                if resourceDateTimeUtc != dateTimeUtc {
                    filteredResources.push(resourceItem.clone());
                }
            }
            "lt" => {
                if resourceDateTimeUtc < dateTimeUtc {
                    filteredResources.push(resourceItem.clone());
                }
            }
            "gt" => {
                if resourceDateTimeUtc > dateTimeUtc {
                    filteredResources.push(resourceItem.clone());
                }
            }
            "ge" => {
                if resourceDateTimeUtc >= dateTimeUtc {
                    filteredResources.push(resourceItem.clone());
                }
            }
            "le" => {
                if resourceDateTimeUtc <= dateTimeUtc {
                    filteredResources.push(resourceItem.clone());
                }
            }
            "sa" => {
                if resourceDateTimeUtc > dateTimeUtc {
                    filteredResources.push(resourceItem.clone());
                }
            }
            "eb" => {
                if resourceDateTimeUtc < dateTimeUtc {
                    filteredResources.push(resourceItem.clone());
                }
            }
            "ap" => {
                // Approximation: Check if the date is within 1 day of the given date

                time:Utc lowerBound = time:utcAddSeconds(dateTimeUtc, 86400);
                time:Utc upperBound = time:utcAddSeconds(dateTimeUtc, -86400);

                if resourceDateTimeUtc >= lowerBound && resourceDateTimeUtc <= upperBound {
                    filteredResources.push(resourceItem.clone());
                }
            }
            _ => {
                return r4:createFHIRError(string `Invalid operator: ${operator}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
            }
        }
    }
    return filteredResources;
}

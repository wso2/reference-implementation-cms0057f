import ballerina/http;
import ballerinax/health.fhir.r4;

// key = resource type
isolated map<r4:Resource[]> repositoryMap = {
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

public isolated function create(ResourceType resourceType, r4:Resource payload) returns r4:Resource|error {
    int nextId;
    lock {
        int? prevId = nextIdMap[resourceType];
        if prevId is int {
            nextId = (<int>prevId) + 1;
        } else {
            nextId = 12344; // default starting point
        }
        nextIdMap[resourceType] = nextId;

    }
    r4:Resource resourceClone = check payload.ensureType();
    lock {
        resourceClone.id = nextId.toBalString();

        r4:Resource[] resources = [];

        if repositoryMap.hasKey(resourceType) {
            r4:Resource[]? resourceArr = repositoryMap[resourceType].clone();
            if resourceArr is r4:Resource[] {
                resources = resourceArr;
            }
        }

        resources.push(payload.clone());
        repositoryMap[resourceType] = resources;
    }
    return resourceClone;
}

public isolated function getById(ResourceType resourceType, string id) returns r4:Resource|r4:FHIRError {
    lock {
        if repositoryMap.hasKey(resourceType) {
            r4:Resource[]? resources = repositoryMap[resourceType];
            if resources is r4:Resource[] {
                foreach r4:Resource resourceItem in resources {
                    if resourceItem.id == id {
                        return resourceItem.clone();
                    }
                }
            }
        }
    }
    return r4:createFHIRError(string `Resource of type ${resourceType} with id ${id} not found`, r4:ERROR, r4:PROCESSING_NOT_FOUND, httpStatusCode = http:STATUS_NOT_FOUND);
}


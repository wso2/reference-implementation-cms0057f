import ballerinax/health.fhir.r4;

// key = resource type
isolated map<r4:Resource[]> repositoryMap = {};
isolated map<int> nextIdMap = {};

public isolated function create(string resourceType, r4:Resource payload) returns r4:Resource|error {
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
            } else {
                resources = [];
            }
        }   

        resources.push(payload.clone());
        repositoryMap[resourceType] = resources;
    }
    return resourceClone;
}

public isolated function getById(string resourceType, string id) returns r4:Resource|error {
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
    return error(string `Resource of type ${resourceType} with id ${id} not found`);
}



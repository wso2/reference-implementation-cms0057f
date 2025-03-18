import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhirr4;
import ballerinax/health.fhir.r4.parser as fhirParser;
import ballerinax/health.fhir.r4.uscore311;

# Generic type to wrap all implemented profiles.
# Add required profile types here.
# public type Practitioner r4:Practitioner|<other_Practitioner_Profile>;
public type Practitioner uscore311:USCorePractitionerProfile;

# initialize source system endpoint here
configurable string backendBaseUrl = "http://localhost:9095/backend";
configurable string fhirBaseUrl = "localhost:9091/fhir/r4";
final http:Client fhirApiClient = check new (fhirBaseUrl);
final http:Client backendClient = check new (backendBaseUrl);

# A service representing a network-accessible API
# bound to port `9090`.
service /fhir/r4 on new fhirr4:Listener(9090, apiConfig) {

    // Read the current state of single resource based on its id.
    isolated resource function get Practitioner/[string id](r4:FHIRContext fhirContext) returns Practitioner|r4:OperationOutcome|r4:FHIRError|error {
        lock {
            json[] data = check retrieveData("Practitioner").ensureType();
            foreach json val in data {
                map<json> fhirResource = check val.ensureType();
                if (fhirResource.resourceType == "Practitioner" && fhirResource.id == id) {
                    Practitioner practitioner = check fhirParser:parse(fhirResource, uscore311:USCorePractitionerProfile).ensureType();
                    return practitioner.clone();
                }
            }
        }
        return r4:createFHIRError("Not found", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_FOUND);
    }

    // Read the state of a specific version of a resource based on its id.
    isolated resource function get Practitioner/[string id]/_history/[string vid](r4:FHIRContext fhirContext) returns Practitioner|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Search for resources based on a set of criteria.
    isolated resource function get Practitioner(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError|error {
        lock {
            return filterData(fhirContext);
        }
    }

    // Create a new resource.
    isolated resource function post Practitioner(r4:FHIRContext fhirContext, Practitioner practitioner) returns Practitioner|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Update the current state of a resource completely.
    isolated resource function put Practitioner/[string id](r4:FHIRContext fhirContext, Practitioner practitioner) returns Practitioner|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Update the current state of a resource partially.
    isolated resource function patch Practitioner/[string id](r4:FHIRContext fhirContext, json patch) returns Practitioner|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Delete a resource.
    isolated resource function delete Practitioner/[string id](r4:FHIRContext fhirContext) returns r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Retrieve the update history for a particular resource.
    isolated resource function get Practitioner/[string id]/_history(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Retrieve the update history for all resources.
    isolated resource function get Practitioner/_history(r4:FHIRContext fhirContext) returns r4:Bundle|r4:OperationOutcome|r4:FHIRError {
        return r4:createFHIRError("Not implemented", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // post search request
    isolated resource function post Practitioner/_search(r4:FHIRContext fhirContext) returns r4:FHIRError|http:Response {
        r4:Bundle|error result = filterData(fhirContext);
        if result is r4:Bundle {
            http:Response response = new;
            response.statusCode = http:STATUS_OK;
            response.setPayload(result.clone().toJson());
            return response;
        } else {
            return r4:createFHIRError("Internal Server Error", r4:ERROR, r4:INFORMATIONAL, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
    }
}

isolated function addRevInclude(string revInclude, r4:Bundle bundle, int entryCount, string apiName) returns r4:Bundle|error {

    if revInclude == "" {
        return bundle;
    }
    string[] ids = check buildSearchIds(bundle, apiName);
    if ids.length() == 0 {
        return bundle;
    }

    int count = entryCount;
    http:Response response = check fhirApiClient->/Provenance(target = string:'join(",", ...ids));
    if (response.statusCode == 200) {
        json fhirResource = check response.getJsonPayload();
        json[] entries = check fhirResource.entry.ensureType();
        foreach json entry in entries {
            map<json> entryResource = check entry.'resource.ensureType();
            string entryUrl = check entry.fullUrl.ensureType();
            r4:BundleEntry bundleEntry = {fullUrl: entryUrl, 'resource: entryResource};
            bundle.entry[count] = bundleEntry;
            count += 1;
        }
    }
    return bundle;
}

isolated function buildSearchIds(r4:Bundle bundle, string apiName) returns string[]|error {
    r4:BundleEntry[] entries = check bundle.entry.ensureType();
    string[] searchIds = [];
    foreach r4:BundleEntry entry in entries {
        var entryResource = entry?.'resource;
        if (entryResource == ()) {
            continue;
        }
        map<json> entryResourceJson = check entryResource.ensureType();
        string id = check entryResourceJson.id.ensureType();
        string resourceType = check entryResourceJson.resourceType.ensureType();
        if (resourceType == apiName) {
            searchIds.push(resourceType + "/" + id);
        }
    }
    return searchIds;
}

isolated function filterData(r4:FHIRContext fhirContext) returns r4:Bundle|error {

    boolean isSearchParamAvailable = false;
    r4:StringSearchParameter[] idParam = check fhirContext.getStringSearchParameter("_id") ?: [];
    r4:TokenSearchParameter[] identifierParam = check fhirContext.getTokenSearchParameter("identifier") ?: [];
    r4:StringSearchParameter[] nameParam = check fhirContext.getStringSearchParameter("name") ?: [];

    string[] ids = [];
    foreach r4:StringSearchParameter item in idParam {
        string id = check item.value.ensureType();
        ids.push(id);
    }
    string[] identifiers = [];
    foreach r4:TokenSearchParameter item in identifierParam {
        string identifier = check item.code.ensureType();
        identifiers.push(identifier);
    }
    string[] names = [];
    foreach r4:StringSearchParameter item in nameParam {
        string name = check item.value.ensureType();
        names.push(name);
    }

    r4:TokenSearchParameter[] revIncludeParam = check fhirContext.getTokenSearchParameter("_revinclude") ?: [];
    string revInclude = revIncludeParam != [] ? check revIncludeParam[0].code.ensureType() : "";
    lock {

        r4:Bundle bundle = {identifier: {system: ""}, 'type: "searchset", entry: []};
        r4:BundleEntry bundleEntry = {};
        int count = 0;
        // filter by id
        json[] data = check retrieveData("Practitioner").ensureType();
        json[] resultSet = data;
        if (ids.length() > 0) {
            isSearchParamAvailable = true;
            resultSet = [];
            foreach json val in data {
                map<json> fhirResource = check val.ensureType();
                if fhirResource.hasKey("id") {
                    string id = check fhirResource.id.ensureType();
                    if (ids.indexOf(id) > -1) {
                        resultSet.push(fhirResource);
                        continue;
                    }
                }
            }
        }

        // filter by name
        json[] nameFilteredData = [];
        if (names.length() > 0) {
            isSearchParamAvailable = true;
            foreach json val in resultSet {
                map<json> fhirResource = check val.ensureType();
                if fhirResource.hasKey("name") {
                    json[] nameResources = check fhirResource.name.ensureType();
                    foreach json nameResource in nameResources {
                        map<json> nameObject = check nameResource.ensureType();
                        string family = check nameObject.family.ensureType();
                        if (names.indexOf(family) > -1) {
                            nameFilteredData.push(fhirResource);
                            continue;
                        }
                        
                    }
                }
            }
            resultSet = nameFilteredData;
        }

        // filter by identifier
        json[] identifierFilteredData = [];
        if (identifiers.length() > 0) {
            isSearchParamAvailable = true;
            foreach json val in resultSet {
                map<json> fhirResource = check val.ensureType();
                if fhirResource.hasKey("identifier") {
                    json[] identifierResources = check fhirResource.identifier.ensureType();
                    foreach json identifierResource in identifierResources {
                        map<json> identifierObject = check identifierResource.ensureType();
                        string value = check identifierObject.value.ensureType();
                        if (identifiers.indexOf(value) > -1) {
                            identifierFilteredData.push(fhirResource);
                            continue;
                        }
                    }
                }
            }
            resultSet = identifierFilteredData;
        }

        resultSet = isSearchParamAvailable ? resultSet : data;
        foreach json item in resultSet {
            bundleEntry = {fullUrl: "", 'resource: item};
            bundle.entry[count] = bundleEntry;
            count += 1;
        }

        if bundle.entry != [] {
            return addRevInclude(revInclude, bundle, count, "Practitioner").clone();
        }
        return bundle.clone();
    }
}

// Retrieve data from the backend
isolated function retrieveData(string resourceType) returns json|error {
    
    http:Response response = check backendClient->get("/data/" + resourceType);
    if response.statusCode == http:STATUS_OK {
        json payload = check response.getJsonPayload();
        return payload;
    } else {
        return error("Failed to retrieve data from backend service");
    }
}

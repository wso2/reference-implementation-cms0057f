import ballerina/http;
import ballerinax/health.clients.fhir;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincipas;
import ballerinax/health.fhir.r4.parser;

isolated http:Client claimRepositoryServiceClient = check new (serviceURL,
  auth = (tokenURL == "" || consumerKey == "" || consumerSecret == "") ? () : {
    tokenUrl: tokenURL,
    clientId: consumerKey,
    clientSecret: consumerSecret
  }
);

public isolated function create(davincipas:PASClaimResponse payload) returns r4:FHIRError|davincipas:PASClaimResponse|error {
    davincipas:PASClaimResponse claimResponse = check parser:parse(payload.toJson(), davincipas:PASClaimResponse).ensureType();

    lock {
        http:Response|error response = claimRepositoryServiceClient->post("/ClaimResponse", claimResponse.clone(), {"Choreo-API-Key": choreoApiKey});

        if response is http:Response {
            if (response.statusCode == http:STATUS_CREATED) {
                davincipas:PASClaimResponse newClaimResponse = check parser:parse(check response.getJsonPayload(), davincipas:PASClaimResponse).ensureType();
                return newClaimResponse.clone();
            }

            return r4:createFHIRError("Error: Invalid request or server error.", r4:ERROR, r4:INVALID, httpStatusCode = response.statusCode);
        } else {
            return r4:createFHIRError("Error: " + response.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
    }
}

public isolated function getById(string id) returns r4:FHIRError|davincipas:PASClaimResponse|error {
    lock {
        http:Response|error response = claimRepositoryServiceClient->get("/ClaimResponse/" + id, {"Choreo-API-Key": choreoApiKey});

        if response is http:Response {
            if response.statusCode == http:STATUS_OK {
                davincipas:PASClaimResponse claimResponse = check parser:parse(check response.getJsonPayload(), davincipas:PASClaimResponse).ensureType();
                return claimResponse.clone();
            } 
            
            return r4:createFHIRError(string `Cannot find a ClaimResponse resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
        } else {
            return r4:createFHIRError("Error: " + response.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
    }
}

public isolated function update(json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented. This functionality is not yet supported.", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
}

public isolated function patchResource(string 'resource, string id, json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented. This functionality is not yet supported.", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
}

public isolated function delete(string 'resource, string id) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented. This functionality is not yet supported.", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle|error {
    r4:Bundle bundle = {
        'type: "collection",
        entry: []
    };
    
    if searchParameters is map<string[]> {
        lock {
            http:Response|error response = claimRepositoryServiceClient->post("/ClaimResponse/Search", searchParameters.clone(), {"Choreo-API-Key": choreoApiKey});

            if response is http:Response {
                if response.statusCode == http:STATUS_OK || response.statusCode == http:STATUS_CREATED {
                    r4:Bundle bundleResponse = check parser:parse(check response.getJsonPayload()).ensureType();
                    bundle = bundleResponse.clone();
                } 
            }
        }
    }

    return bundle;
}


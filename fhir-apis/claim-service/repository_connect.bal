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

public isolated function create(davincipas:PASClaim payload) returns r4:FHIRError|http:Error|davincipas:PASClaim|error {
    davincipas:PASClaim claim = check parser:parse(payload.toJson(), davincipas:PASClaim).ensureType();

    lock {
        http:Response|error response = claimRepositoryServiceClient->post("/ClaimRepo/Claim", claim.clone(), {"Choreo-API-Key": choreoApiKey});

        if response is http:Response {
            if response.statusCode == http:STATUS_CREATED {
                davincipas:PASClaim claimResponse = check parser:parse(check response.getJsonPayload(), davincipas:PASClaim).ensureType();
                return claimResponse.clone();
            }

            return r4:createFHIRError("Error occurred while creating the claim", r4:ERROR, r4:INVALID, httpStatusCode = response.statusCode);
        } else {
            return r4:createFHIRError("Error: " + response.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
    }
}

public isolated function getById(string id) returns r4:FHIRError|http:Error|davincipas:PASClaim|error {
    lock {
        http:Response|error response = claimRepositoryServiceClient->get("/ClaimRepo/Claim/" + id, {"Choreo-API-Key": choreoApiKey});

        if response is http:Response {
            if response.statusCode == http:STATUS_OK {
                davincipas:PASClaim claim = check parser:parse(check response.getJsonPayload(), davincipas:PASClaim).ensureType();
                return claim.clone();
            }

            return r4:createFHIRError(string `Not found resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = response.statusCode);
        } else {
            return r4:createFHIRError("Error: " + response.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
        }
    }
}

public isolated function update(json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function patchResource(string 'resource, string id, json payload) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);
}

public isolated function delete(string 'resource, string id) returns r4:FHIRError|fhir:FHIRResponse {
    return r4:createFHIRError("Not implemented", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_IMPLEMENTED);

}

public isolated function search(map<string[]>? searchParameters = ()) returns r4:Bundle|r4:FHIRError|http:Error|error {
    r4:Bundle bundle = {
        'type: "collection",
        entry: []
    };

    if searchParameters is map<string[]> {
        lock {
            http:Response|error response = claimRepositoryServiceClient->post("/ClaimRepo/Claim/Search", searchParameters.clone(), {"Choreo-API-Key": choreoApiKey});

            if response is http:Response {
                if response.statusCode == http:STATUS_OK || response.statusCode == http:STATUS_CREATED {
                    r4:Bundle bundleResponse = check parser:parse(check response.getJsonPayload()).ensureType();
                    bundle = bundleResponse.clone();
                } else {
                    return r4:createFHIRError("Error occurred while retrieving the claims", r4:ERROR, r4:INVALID, httpStatusCode = response.statusCode);
                }
            } else {
                return r4:createFHIRError("Error: " + response.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_INTERNAL_SERVER_ERROR);
            }
        }
    }

    return bundle;
}

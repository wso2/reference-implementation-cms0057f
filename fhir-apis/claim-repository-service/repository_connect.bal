import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincipas;
import ballerinax/health.fhir.r4.parser;

isolated davincipas:PASClaim[] claims = [];
isolated davincipas:PASClaimResponse[] claimResponses = [];

isolated int claimCreateOperationNextId = 12343;
isolated int claimResponseCreateOperationNextId = 12343;

// Claim repository service
public isolated function addNewPASClaim(davincipas:PASClaim payload) returns r4:FHIRError|davincipas:PASClaim|error {
    davincipas:PASClaim|error claim = parser:parse(payload.toJson(), davincipas:PASClaim).ensureType();

    if claim is error {
        return r4:createFHIRError(claim.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            claimCreateOperationNextId += 1;
            claim.id = (claimCreateOperationNextId).toBalString();
        }

        lock {
            claims.push(claim.clone());
        }
    }

    return claim;
}

public isolated function getPASClaimByID(string id) returns davincipas:PASClaim|r4:FHIRError? {
    lock {
        foreach davincipas:PASClaim claim in claims {
            if (claim.id == id) {
                return claim.clone();
            }
        }
    }
    return r4:createFHIRError("Claim not found", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function getAllPASClaims() returns davincipas:PASClaim[]|error? {
    lock {
        return claims.clone();
    }
}

public isolated function deletePASClaimByID(string id) returns r4:FHIRError? {
    lock {
        int count = 0;
        while (count < claims.length()) {
            if (claims[count].id == id) {
                _ = claims.remove(count);
                return;
            }
            count = count + 1;
        }
    }
    return r4:createFHIRError("Claim not found", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

// ClaimResponse repository service
public isolated function addNewPASClaimResponse(davincipas:PASClaimResponse payload) returns r4:FHIRError|davincipas:PASClaimResponse|error {
    davincipas:PASClaimResponse|error claimResponse = parser:parse(payload.toJson(), davincipas:PASClaimResponse).ensureType();

    if claimResponse is error {
        return r4:createFHIRError(claimResponse.message(), r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    } else {
        lock {
            claimResponseCreateOperationNextId += 1;
            claimResponse.id = (claimResponseCreateOperationNextId).toBalString();
        }

        lock {
            claimResponses.push(claimResponse.clone());
        }
    }

    return claimResponse;
}

public isolated function getPASClaimResponseByID(string id) returns davincipas:PASClaimResponse|r4:FHIRError? {
    lock {
        foreach davincipas:PASClaimResponse response in claimResponses {
            if (response.id == id) {
                return response.clone();
            }
        }
    }
    return r4:createFHIRError("ClaimResponse not found", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function getAllPASClaimResponses() returns davincipas:PASClaimResponse[]|error? {
    lock {
        return claimResponses.clone();
    }
}

public isolated function deletePASClaimResponseByID(string id) returns r4:FHIRError? {
    lock {
        int count = 0;
        while (count < claimResponses.length()) {
            if (claimResponses[count].id == id) {
                _ = claimResponses.remove(count);
                return;
            }
            count = count + 1;
        }
    }
    return r4:createFHIRError("ClaimResponse not found", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

import ballerina/http;
import ballerinax/health.fhir.r4;
import ballerinax/health.fhir.r4.davincipas;
import ballerinax/health.fhir.r4.parser;
import ballerina/time;

// Claim Repository
isolated davincipas:PASClaim[] claims = [];
isolated int claimCreateOperationNextId = 12343;

// Claim Response Repository
isolated davincipas:PASClaimResponse[] claimResponses = [];
isolated int claimResponseCreateOperationNextId = 12343;


// ######################################################################################################################
// # Claim Repository Functions                                                                                         #
// ######################################################################################################################

public isolated function addNewPASClaim(davincipas:PASClaim payload) returns r4:FHIRError|davincipas:PASClaim|error {
    davincipas:PASClaim|error claim = parser:parseWithValidation(payload.toJson(), davincipas:PASClaim).ensureType();

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

        return claim;
    }
}

public isolated function getPASClaimByID(string id) returns r4:FHIRError|davincipas:PASClaim {
    lock {
        foreach var item in claims {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a Patient resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
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

public isolated function searchPASClaim(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        string? id = ();
        string? patient = ();
        string? use = ();
        string? created = ();

        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    id = searchParameters.get('key)[0];
                }
                "patient" => {
                    patient = searchParameters.get('key)[0];
                }
                "use" => {
                    use = searchParameters.get('key)[0];
                }
                "created" => {
                    created = searchParameters.get('key)[0];
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

        if id is string {
            davincipas:PASClaim byId = check getPASClaimByID(id);

            bundle.entry = [
                {
                    'resource: byId
                }
            ];

            bundle.total = 1;
            return bundle;
        }

        davincipas:PASClaim[] results;
        lock {
            results = claims.clone();
        }

        if patient is string {
            results = getClaimsByPatient(patient, results);
        }
        
        if use is string {
            results = getClaimsByUse(use, results);
        }

        if created is string {
            results = check getClaimsByCreatedDate(created, results);
        }

        // reorder the results as decending order by Created date
        results = orderClaimsByCreatedDate(results);

        r4:BundleEntry[] bundleEntries = [];

        foreach davincipas:PASClaim item in results {
            r4:BundleEntry bundleEntry = {
                'resource: item
            };
            bundleEntries.push(bundleEntry);
        }
        bundle.entry = bundleEntries;
        bundle.total = results.length();
    }

    return bundle;
}

isolated function getClaimsByUse(string use, davincipas:PASClaim[] targetArr) returns davincipas:PASClaim[] {
    davincipas:PASClaim[] filteredClaims = [];
    foreach davincipas:PASClaim claim in targetArr {
        if claim.use == use {
            filteredClaims.push(claim.clone());
        }
    }
    return filteredClaims;
}

isolated function getClaimsByPatient(string patient, davincipas:PASClaim[] targetArr) returns davincipas:PASClaim[] {
    davincipas:PASClaim[] filteredClaims = [];
    foreach davincipas:PASClaim claim in targetArr {
        if claim.patient.reference == patient {
            filteredClaims.push(claim.clone());
        }
    }
    return filteredClaims;
}

isolated function orderClaimsByCreatedDate(davincipas:PASClaim[] targetArr) returns davincipas:PASClaim[] {
    return from davincipas:PASClaim item in targetArr
        order by item.created descending
        select item;
}

isolated function getClaimsByCreatedDate(string created, davincipas:PASClaim[] targetArr) returns davincipas:PASClaim[]|r4:FHIRError {
    string operator = created.substring(0, 2);
    r4:dateTime datetimeR4 = created.substring(2);

    // convert r4:dateTime to time:Utc
    time:Utc|time:Error dateTimeUtc = time:utcFromString(datetimeR4.includes("T") ? datetimeR4 : datetimeR4 + "T00:00:00.000Z");
    if dateTimeUtc is time:Error {
        return r4:createFHIRError(string `Invalid date format: ${created}, ${dateTimeUtc.message()}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    time:Utc lowerBound = time:utcAddSeconds(dateTimeUtc, 86400);
    time:Utc upperBound = time:utcAddSeconds(dateTimeUtc, -86400);

    davincipas:PASClaim[] filteredClaims = [];
    foreach davincipas:PASClaim claim in targetArr {
        r4:dateTime claimDateTimeR4 = claim.created;
        time:Utc|time:Error claimDateTimeUtc = time:utcFromString(claimDateTimeR4.includes("T") ? claimDateTimeR4 : claimDateTimeR4 + "T00:00:00.000Z");
        if claimDateTimeUtc is time:Error {
            continue; // Skip invalid date formats
        }
        match operator {
            "eq" => {
                if claimDateTimeUtc == dateTimeUtc {
                    filteredClaims.push(claim.clone());
                }
            }
            "ne" => {
                if claimDateTimeUtc != dateTimeUtc {
                    filteredClaims.push(claim.clone());
                }
            }
            "lt" => {
                if claimDateTimeUtc < dateTimeUtc {
                    filteredClaims.push(claim.clone());
                }
            }
            "gt" => {
                if claimDateTimeUtc > dateTimeUtc {
                    filteredClaims.push(claim.clone());
                }
            }
            "ge" => {
                if claimDateTimeUtc >= dateTimeUtc {
                    filteredClaims.push(claim.clone());
                }
            }
            "le" => {
                if claimDateTimeUtc <= dateTimeUtc {
                    filteredClaims.push(claim.clone());
                }
            }
            "sa" => {
                if claimDateTimeUtc > dateTimeUtc {
                    filteredClaims.push(claim.clone());
                }
            }
            "eb" => {
                if claimDateTimeUtc < dateTimeUtc {
                    filteredClaims.push(claim.clone());
                }
            }
            "ap" => {
                // Approximation: Check if the claim date is within 1 day of the given date
                if claimDateTimeUtc >= lowerBound && claimDateTimeUtc <= upperBound {
                    filteredClaims.push(claim.clone());
                }
            }
            _ => {
                return r4:createFHIRError(string `Invalid operator: ${operator}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
            }
        }
    }
    return filteredClaims;
}



// ######################################################################################################################
// # Clain Response Repository Functions                                                                                #
// ######################################################################################################################


public isolated function addNewPASClaimResponse(davincipas:PASClaimResponse payload) returns r4:FHIRError|davincipas:PASClaimResponse|error {
    davincipas:PASClaimResponse|error claimResponse = parser:parseWithValidation(payload.toJson(), davincipas:PASClaimResponse).ensureType();

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

        return claimResponse;
    }
}

public isolated function getPASClaimResponseByID(string id) returns r4:FHIRError|davincipas:PASClaimResponse {
    lock {
        foreach var item in claimResponses {
            string result = item.id ?: "";

            if result == id {
                return item.clone();
            }
        }
    }
    return r4:createFHIRError(string `Cannot find a Patient resource with id: ${id}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
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
    return r4:createFHIRError("ClaimResponseResponse not found", r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_NOT_FOUND);
}

public isolated function searchPASClaimResponse(map<string[]>? searchParameters = ()) returns r4:FHIRError|r4:Bundle {
    r4:Bundle bundle = {
        'type: "collection"
    };

    if searchParameters is map<string[]> {
        string? id = ();
        string? patient = ();
        string? use = ();
        string? created = ();

        foreach var 'key in searchParameters.keys() {
            match 'key {
                "_id" => {
                    id = searchParameters.get('key)[0];
                }
                "patient" => {
                    patient = searchParameters.get('key)[0];
                }
                "use" => {
                    use = searchParameters.get('key)[0];
                }
                "created" => {
                    created = searchParameters.get('key)[0];
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

        if id is string {
            davincipas:PASClaimResponse byId = check getPASClaimResponseByID(id);

            bundle.entry = [
                {
                    'resource: byId
                }
            ];

            bundle.total = 1;
            return bundle;
        }

        davincipas:PASClaimResponse[] results;
        lock {
            results = claimResponses.clone();
        }

        if patient is string {
            results = getClaimResponsesByPatient(patient, results);
        }
        
        if use is string {
            results = getClaimResponsesByUse(use, results);
        }

        if created is string {
            results = check getClaimResponsesByCreatedDate(created, results);
        }

        // reorder the results as decending order by Created date
        results = orderClaimResponsesByCreatedDate(results);

        r4:BundleEntry[] bundleEntries = [];

        foreach davincipas:PASClaimResponse item in results {
            r4:BundleEntry bundleEntry = {
                'resource: item
            };
            bundleEntries.push(bundleEntry);
        }
        bundle.entry = bundleEntries;
        bundle.total = results.length();
    }

    return bundle;
}

isolated function getClaimResponsesByUse(string use, davincipas:PASClaimResponse[] targetArr) returns davincipas:PASClaimResponse[] {
    davincipas:PASClaimResponse[] filteredClaimResponses = [];
    foreach davincipas:PASClaimResponse claimResponse in targetArr {
        if claimResponse.use == use {
            filteredClaimResponses.push(claimResponse.clone());
        }
    }
    return filteredClaimResponses;
}

isolated function getClaimResponsesByPatient(string patient, davincipas:PASClaimResponse[] targetArr) returns davincipas:PASClaimResponse[] {
    davincipas:PASClaimResponse[] filteredClaimResponses = [];
    foreach davincipas:PASClaimResponse claimResponse in targetArr {
        if claimResponse.patient.reference == patient {
            filteredClaimResponses.push(claimResponse.clone());
        }
    }
    return filteredClaimResponses;
}

isolated function orderClaimResponsesByCreatedDate(davincipas:PASClaimResponse[] targetArr) returns davincipas:PASClaimResponse[] {
    return from davincipas:PASClaimResponse item in targetArr
        order by item.created descending
        select item;
}

isolated function getClaimResponsesByCreatedDate(string created, davincipas:PASClaimResponse[] targetArr) returns davincipas:PASClaimResponse[]|r4:FHIRError {
    string operator = created.substring(0, 2);
    r4:dateTime datetimeR4 = created.substring(2);

    // convert r4:dateTime to time:Utc
    time:Utc|time:Error dateTimeUtc = time:utcFromString(datetimeR4.includes("T") ? datetimeR4 : datetimeR4 + "T00:00:00.000Z");
    if dateTimeUtc is time:Error {
        return r4:createFHIRError(string `Invalid date format: ${created}, ${dateTimeUtc.message()}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
    }

    time:Utc lowerBound = time:utcAddSeconds(dateTimeUtc, 86400);
    time:Utc upperBound = time:utcAddSeconds(dateTimeUtc, -86400);

    davincipas:PASClaimResponse[] filteredClaimResponses = [];
    foreach davincipas:PASClaimResponse claimResponse in targetArr {
        r4:dateTime claimResponseDateTimeR4 = claimResponse.created;
        time:Utc|time:Error claimResponseDateTimeUtc = time:utcFromString(claimResponseDateTimeR4.includes("T") ? claimResponseDateTimeR4 : claimResponseDateTimeR4 + "T00:00:00.000Z");
        if claimResponseDateTimeUtc is time:Error {
            continue; // Skip invalid date formats
        }
        match operator {
            "eq" => {
                if claimResponseDateTimeUtc == dateTimeUtc {
                    filteredClaimResponses.push(claimResponse.clone());
                }
            }
            "ne" => {
                if claimResponseDateTimeUtc != dateTimeUtc {
                    filteredClaimResponses.push(claimResponse.clone());
                }
            }
            "lt" => {
                if claimResponseDateTimeUtc < dateTimeUtc {
                    filteredClaimResponses.push(claimResponse.clone());
                }
            }
            "gt" => {
                if claimResponseDateTimeUtc > dateTimeUtc {
                    filteredClaimResponses.push(claimResponse.clone());
                }
            }
            "ge" => {
                if claimResponseDateTimeUtc >= dateTimeUtc {
                    filteredClaimResponses.push(claimResponse.clone());
                }
            }
            "le" => {
                if claimResponseDateTimeUtc <= dateTimeUtc {
                    filteredClaimResponses.push(claimResponse.clone());
                }
            }
            "sa" => {
                if claimResponseDateTimeUtc > dateTimeUtc {
                    filteredClaimResponses.push(claimResponse.clone());
                }
            }
            "eb" => {
                if claimResponseDateTimeUtc < dateTimeUtc {
                    filteredClaimResponses.push(claimResponse.clone());
                }
            }
            "ap" => {
                // Approximation: Check if the claimResponse date is within 1 day of the given date
                if claimResponseDateTimeUtc >= lowerBound && claimResponseDateTimeUtc <= upperBound {
                    filteredClaimResponses.push(claimResponse.clone());
                }
            }
            _ => {
                return r4:createFHIRError(string `Invalid operator: ${operator}`, r4:ERROR, r4:INVALID, httpStatusCode = http:STATUS_BAD_REQUEST);
            }
        }
    }
    return filteredClaimResponses;
}

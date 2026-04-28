// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).

// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/log;
import ballerina/time;
import ballerina/lang.regexp;
import ballerina/http;
import ballerina/jwt;

isolated function AddDurationToDate(string date, string durationDays) returns string|error {
    // Parse the duration days
    int days = check int:fromString(durationDays);
    
    // Parse the input date string to extract date components
    // Handle formats: YYYY, YYYY-MM, YYYY-MM-DD, or YYYY-MM-DDThh:mm:ss+zz:zz
    string dateOnly;
    boolean hasTime = date.includes("T");
    boolean hasSpace = date.includes(" ");
    
    if hasTime {
        // Extract date part before 'T'
        regexp:RegExp tPattern = re `T`;
        string[] parts = tPattern.split(date);
        dateOnly = parts[0];
    } else if hasSpace {
        // Extract date part before space
        regexp:RegExp spacePattern = re `\s`;
        string[] parts = spacePattern.split(date);
        dateOnly = parts[0];
    } else {
        dateOnly = date;
    }
    
    // Parse date components
    regexp:RegExp dashPattern = re `-`;
    string[] dateParts = dashPattern.split(dateOnly);
    int year = check int:fromString(dateParts[0]);
    int month = dateParts.length() > 1 ? check int:fromString(dateParts[1]) : 1;
    int day = dateParts.length() > 2 ? check int:fromString(dateParts[2]) : 1;
    
    // Create Civil date with UTC offset
    time:Civil baseDate = {
        year: year, 
        month: month, 
        day: day, 
        hour: 0, 
        minute: 0,
        utcOffset: {hours: 0, minutes: 0}
    };
    
    // Add the duration
    time:Duration duration = {days: days};
    time:Civil futureDate = check time:civilAddDuration(baseDate, duration);
    
    // Format the result based on input format
    string formattedDate;
    if dateParts.length() == 1 {
        // YYYY format
        formattedDate = string `${futureDate.year}`;
    } else if dateParts.length() == 2 {
        // YYYY-MM format
        formattedDate = string `${futureDate.year}-${futureDate.month < 10 ? "0" : ""}${futureDate.month}`;
    } else {
        // YYYY-MM-DD format (with or without time)
        formattedDate = string `${futureDate.year}-${futureDate.month < 10 ? "0" : ""}${futureDate.month}-${futureDate.day < 10 ? "0" : ""}${futureDate.day}`;
        
        // If original had time component, append it
        if hasTime {
            regexp:RegExp tPattern2 = re `T`;
            string[] timeParts = tPattern2.split(date);
            formattedDate = formattedDate + "T" + timeParts[1];
        }
    }
    
    return formattedDate;
}

# Decodes the payload of a JWT and extracts actor fields.
# Returns sentinel "unknown" values if the token is absent or malformed.
#
# + jwtAssertion - Raw JWT string from the X-JWT-Assertion header
# + return - Extracted actor information
isolated function extractActorFromJWT(string jwtAssertion) returns ActorInfo {
    ActorInfo unknown = {userId: "unknown", userName: "unknown", role: "unknown"};
    if jwtAssertion.length() == 0 {
        return unknown;
    }
    do {
        [jwt:Header, jwt:Payload] [_, payload] = check jwt:decode(jwtAssertion);
        return {
            userId: (payload["id"] ?: "unknown").toString(),
            userName: (payload["username"] ?: "unknown").toString(),
            role: (payload["role"] ?: "unknown").toString()
        };
    } on fail {
        log:printError("Failed to decode JWT for actor extraction.");
        return unknown;
    }
}

# Extracts the actor from the X-JWT-Assertion header of an HTTP request.
#
# + req - Incoming HTTP request
# + return - Extracted actor information
isolated function getActorFromRequest(http:Request req) returns ActorInfo {
    string|http:HeaderNotFoundError jwtHeader = req.getHeader("X-JWT-Assertion");
    if jwtHeader is http:HeaderNotFoundError {
        log:printError("X-JWT-Assertion header not found in request.");
        return {userId: "unknown", userName: "unknown", role: "unknown"};
    }
    return extractActorFromJWT(jwtHeader);
}

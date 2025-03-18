// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com). All Rights Reserved.

// This software is the property of WSO2 LLC. and its suppliers, if any.
// Dissemination of any information or reproduction of any material contained
// herein is strictly forbidden, unless permitted by WSO2 in accordance with
// the WSO2 Software License available at: https://wso2.com/licenses/eula/3.2
// For specific language governing the permissions and limitations under
// this license, please see the license as well as any agreement you’ve
// entered into with WSO2 governing the purchase of this software and any
// associated services.

import ballerina/http;
import ballerina/io;

# A service representing a network-accessible API
# bound to port `9090`.
service /backend on new http:Listener(9095) {

    # A resource for retrieving all the fhir resources
    #
    # + resourceType - fhir resource type
    # + return - json array of fhir resources
    isolated resource function get data/[string resourceType]() returns json[]|error {

        lock {
            if (!dataMap.hasKey(resourceType.toLowerAscii())) {
                return [];
            }
            json|error dataJson = io:fileReadJson(dataMap.get(resourceType.toLowerAscii()));
            if (dataJson is json) {
                json[]|error resultSet = dataJson.data.ensureType();
                if (resultSet is json[]) {
                    return resultSet;
                }
            }
            return [];
        }
    }

    # A resource for retrieving legacy format health resources
    #
    # + resourceType - fhir resource type
    # + return - json array of fhir resources
    isolated resource function get data/legacy/[string resourceType]() returns json[]|error {
        // This is a sample implementation for the legacy resource retrieval
        // Only supports patient data retrieval
        lock {
            if resourceType.toLowerAscii() != "patient" {
                return [];
            }
            json|error dataJson = io:fileReadJson("patientlegacy.json");
            if (dataJson is json) {
                json[]|error resultSet = dataJson.data.ensureType();
                if (resultSet is json[]) {
                    return resultSet;
                }
            }
            return [];
        }
    }

}

final map<string> & readonly dataMap = {
    "allergyintolerance": "allergyintolerance.json",
    "careplan": "careplan.json",
    "careteam": "careteam.json",
    "condition": "condition.json",
    "device": "device.json",
    "diagnosticreport": "diagnosticreport.json",
    "documentreference": "documentreference.json",
    "encounter": "encounter.json",
    "goal": "goal.json",
    "immunization": "immunization.json",
    "location": "location.json",
    "medicationrequest": "medicationrequest.json",
    "observation": "observation.json",
    "organization": "organization.json",
    "patient": "patient.json",
    "practitioner": "practitioner.json",
    "procedure": "procedure.json",
    "provenance": "provenance.json"
};

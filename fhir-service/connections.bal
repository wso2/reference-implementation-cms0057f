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

import ballerinax/mysql;
import ballerinax/mysql.driver as _;

# Database configuration.
#
# + host - Database host
# + port - Database port
# + user - Database user
# + password - Database password
# + database - Database name
type DatabaseConfig record {|
    string host;
    int port;
    string user;
    string password;
    string database;
|};

# PARequestDBRow represents a row in the database for a PA request. It is used to
# map the database rows to Ballerina records. The fields are:
#
# + request_id - The unique identifier for the PA request.
# + response_id - The unique identifier for the PA response, if available.
# + priority - The priority of the PA request.
# + status - The processing status of the PA request.
# + ai_summary - AI-generated summary of the PA request, if available.
# + patient_id - The unique identifier for the patient associated with the PA request.
# + practitioner_id - The unique identifier for the practitioner associated with the PA request, if available
# + provider_name - The name of the provider associated with the PA request, if available.
# + date_submitted - The date when the PA request was submitted, if available.
# + is_appeal - Whether the PA request is an appeal.
type PARequestDBRow record {|
    string request_id;
    string? response_id;
    string priority;
    string status;
    string? ai_summary;
    string patient_id;
    string? practitioner_id;
    string? provider_name;
    string? date_submitted;
    boolean is_appeal;
|};

configurable DatabaseConfig databaseConfig = ?;

final mysql:Client dbClient = check new (
    host = databaseConfig.host,
    port = databaseConfig.port,
    user = databaseConfig.user,
    password = databaseConfig.password,
    database = databaseConfig.database
);

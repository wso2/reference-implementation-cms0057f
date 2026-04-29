// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).

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

// Rotate at 10 MB, keep 5 backup files (audit.log.1 … audit.log.5)
const int LOG_MAX_BYTES = 10485760;
const int LOG_MAX_BACKUPS = 10;
const string AUDIT_LOG_PATH = "./logs/audit.log";

log:Config auditLogConfig = {
    level: log:INFO,
    format: "json",
    destinations: [{path: AUDIT_LOG_PATH}]
};

final log:Logger auditLogger = check log:fromConfig(auditLogConfig);

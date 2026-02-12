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

import ballerina/http;
import ballerinax/health.fhir.r4;

configurable string fhir_server_url = ?;
configurable map<string> & readonly hook_id_questionnaire_id_map = ?;

service http:Service / on new http:Listener(9090) {
    isolated resource function post crd\-mri\-spine\-order\-sign(@http:Payload json payload) returns PriorAuthDecision|error|error {
        // log:printInfo(payload.toJsonString());
        // return error(string `Rule repository backend not implemented/ connected yet`);

        // r4:Bundle|error parse = parser:parse(payload, r4:Bundle).ensureType();
        r4:Bundle|error parse = payload.cloneWithType();

        if parse is error {
            return parse;
        }

        return decidePriorAuth(parse, "crd-mri-spine-order-sign");
    }
}

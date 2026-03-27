// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

const AUTHORIZATION_HEADER = "authorization";

configurable string fhirServerUrl = "";
configurable string asgServerUrl = "";
configurable string orgResolverServiceUrl = "";
configurable int proxyServerPort = 9090;
configurable string[] publicEndpoints = [];
configurable string adminAppClientId = "";
configurable string adminAppClientSecret = "";
configurable string[] audience = [];
configurable string tokenEp = "";

configurable string smart_style_url = "";
configurable boolean need_patient_banner = false;
configurable string patient_id = "";

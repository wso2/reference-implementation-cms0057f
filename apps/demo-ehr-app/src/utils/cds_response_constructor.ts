// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
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

import { CDS_SERVICE_SAMPLE_RESPONSE } from "../constants/data";

export async function constructCDSResponse(
  hook: string,
  cdsRequest: any,
  showResponse: boolean = true
) {
  if (hook === "" || hook === undefined || !showResponse) {
    return {
      cards: [],
    };
  }

  if (hook === "cds-services") {
    return CDS_SERVICE_SAMPLE_RESPONSE;
  }

  // make an api call to localhost:8080/cds-services
  const response = await fetch("http://localhost:8080/cds-services/" + hook, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(cdsRequest),
  });

  const cdsResponse_from_server = await response.json();
  return cdsResponse_from_server;
}

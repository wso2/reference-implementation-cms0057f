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

import { DeviceRequest } from "../components/interfaces/deviceRequest";

export function DeviceRequestResourceConstructor(
  selectedIntent: string,
  selectedPriority: string,
  description: string,
  selectedPatientID: string,
  deviceID: string
) {
  const today = new Date();
  const year = today.getFullYear();
  const month = ("0" + (today.getMonth() + 1)).slice(-2);
  const day = ("0" + today.getDate()).slice(-2);

  const hour = ("0" + today.getHours()).slice(-2);
  const minute = ("0" + today.getMinutes()).slice(-2);
  const second = ("0" + today.getSeconds()).slice(-2);

  const todayDate = `${year}-${month}-${day}T${hour}:${minute}:${second}Z`;

  const DEVICE_REQUEST_RESOURCE: DeviceRequest = {
    resourceType: "DeviceRequest",
    id: "example",
    text: {
      status: "generated",
      div: '<div xmlns="http://www.w3.org/1999/xhtml"><p><b>Generated Narrative: DeviceRequest</b><a name="example"> </a></p><div style="display: inline-block; background-color: #d9e0e7; padding: 6px; margin: 4px; border: 1px solid #8da1b4; border-radius: 5px; line-height: 60%"><p style="margin-bottom: 0px">Resource DeviceRequest &quot;example&quot; </p></div><p><b>basedOn</b>: <a href="http://example.org/fhir/ServiceRequest/someReferral">http://example.org/fhir/ServiceRequest/someReferral</a></p><p><b>status</b>: draft</p><p><b>intent</b>: original-order</p><p><b>code</b>: <a href="Device-example.html">Device/example</a></p><p><b>subject</b>: <a href="Patient-example.html">Patient/example</a> &quot; SHAW&quot;</p><p><b>authoredOn</b>: 2016-06-10 11:01:10-0800</p><p><b>requester</b>: <a href="Practitioner-example.html">Practitioner/example</a> &quot; CAREFUL&quot;</p></div>',
    },
    basedOn: [
      {
        reference: "http://example.org/fhir/ServiceRequest/someReferral",
      },
    ],
    status: "draft",
    codeReference: {
      reference: "Device/" + deviceID,
    },
    subject: {
      reference: "Patient/" + selectedPatientID,
    },
    authoredOn: todayDate,
    requester: {
      reference: "Practitioner/1895AD3",
    },
  };

  if (selectedIntent !== "") {
    DEVICE_REQUEST_RESOURCE.intent = selectedIntent;
  }

  if (selectedPriority !== "") {
    DEVICE_REQUEST_RESOURCE.priority = selectedPriority;
  }

  if (description !== "") {
    DEVICE_REQUEST_RESOURCE.note = [
      {
        text: description,
      },
    ];
  }

  return DEVICE_REQUEST_RESOURCE;
}

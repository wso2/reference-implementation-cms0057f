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

import { v4 as uuidv4 } from "uuid";

let CDS_REQUEST = {
  hook: "",
  hookInstance: "",
  context: {},
  prefetch: {},
};

export const cds_request_constructor = (hook: string) => {
  CDS_REQUEST = {
    hook: hook,
    hookInstance: uuidv4(),
    context: {},
    prefetch: {},
  };

  if (hook === "appointment-book") {
    CDS_REQUEST.context = {
      userId: "",
      patientId: "",
      encounterId: "",
      appointments: [],
    };
    // fetch the patient resource in the prefetch
    // fetch the practitioner resource in the prefetch
    // add these to the prefetch object
  } else if (hook === "order-sign") {
    CDS_REQUEST.context = {
      userId: "",
      patientId: "",
      encounterId: "",
      draftOrders: [],
    };

    // fetch the patient resource in the prefetch
    // fetch the practitioner resource in the prefetch
    // add these to the prefetch object
  } else if (hook === "order-select") {
    CDS_REQUEST.context = {
      userId: "",
      patientId: "",
      encounterId: "",
      selections: [],
      draftOrders: [],
    };

    // fetch the patient resource in the prefetch
    // fetch the practitioner resource in the prefetch
    // add these to the prefetch object
  }

  return CDS_REQUEST;
};

export const cdsRequestForBookLabTest = () => {
  return {
    hookInstance: "d1577c69-dfbe-44ad-ba6d-3e05e953b2ea",
    fhirServer: "http://hapi.fhir.org/baseR4sd",
    hook: "order-sign",
    fhirAuthorization: {
      access_token: "some-opaque-fhir-access-token",
      token_type: "Bearer",
      expires_in: 300,
      scope: "user/Patient.read user/Observation.read",
      subject: "cds-service4",
    },
    context: {
      userId: "Practitioner/example",
      patientId: "wrong-id",
      draftOrders: {
        resourceType: "Bundle",
        id: "fb156ed3-0639-4f5e-87b7-09092b5f4d93",
        meta: {
          lastUpdated: "2024-09-10T04:31:05.409+00:00",
        },
        type: "searchset",
        link: [
          {
            relation: "self",
            url: "https://hapi.fhir.org/baseR4/ServiceRequest?_pretty=true",
          },
          {
            relation: "next",
            url: "https://hapi.fhir.org/baseR4?_getpages=fb156ed3-0639-4f5e-87b7-09092b5f4d93&_getpagesoffset=20&_count=20&_pretty=true&_bundletype=searchset",
          },
        ],
        entry: [
          {
            fullUrl: "https://hapi.fhir.org/baseR4/ServiceRequest/1523",
            resource: {
              resourceType: "ServiceRequest",
              id: "1551",
              meta: {
                versionId: "1",
                lastUpdated: "2019-09-20T13:42:13.973+00:00",
                source: "#db9103a26829c2ec",
              },
              status: "active",
              intent: "order",
              category: [
                {
                  coding: [
                    {
                      system: "http://snomed.info/sct",
                      code: "363679005",
                      display: "Imaging",
                    },
                  ],
                },
              ],
              priority: "stat",
              code: {
                coding: [
                  {
                    system: "http://loinc.org",
                    code: "24725-4",
                    display: "CT Head",
                  },
                ],
              },
              quantityQuantity: {
                value: 1,
              },
              encounter: {
                reference: "Encounter/1213",
              },
              authoredOn: "2019-09-20T15:42:13+02:00",
            },
          },
        ],
      },
    },
  };
};

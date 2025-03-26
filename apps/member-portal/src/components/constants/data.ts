export const memberMatchPayload = {
  resourceType: "Parameters",
  parameter: [
    {
      resource: {
        resourceType: "Patient",

        gender: "male",
        telecom: [
          {
            system: "phone",
            use: "home",
            value: "555-555-5555",
          },
          {
            system: "email",
            value: "amy.shaw@example.com",
          },
        ],
        id: "patient-1",
        identifier: [
          {
            system: "http://hospital.smarthealthit.org",
            use: "usual",
            type: {
              coding: [
                {
                  system: "http://terminology.hl7.org/CodeSystem/v2-0203",
                  code: "MR",
                  display: "Medical Record Number",
                },
              ],
              text: "Medical Record Number",
            },
            value: "1032702",
          },
        ],
        address: [
          {
            country: "US",
            period: {
              start: "2020-07-22",
            },
            city: "Mounds",
            line: ["183 Mountain View St"],
            postalCode: "74048",
            state: "OK",
          },
        ],
        birthDate: "1979-04-15",
        meta: {
          versionId: "1",
          lastUpdated: "2021-06-01T00:00:00Z",
          profile: [
            "http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient",
          ],
        },
        name: [
          {
            given: ["John"],
            period: {
              start: "2020-07-22",
            },
            family: "Prohaska",
            suffix: ["PharmD"],
          },
        ],
        implicitRules: "https://example.com/base",
      },
      name: "MemberPatient",
    },
    {
      resource: {
        resourceType: "Coverage",
        payor: [
          {
            identifier: {
              system: "http://hl7.org/fhir/sid/us-npi",
              value: "9876543210",
            },
            display: "Old Health Plan",
          },
        ],
        id: "367",
        class: [
          {
            type: {
              coding: [
                {
                  system:
                    "http://terminology.hl7.org/CodeSystem/coverage-class",
                  code: "group",
                },
              ],
            },
            value: "CB135",
          },
        ],
        period: {
          start: "2011-05-23",
          end: "2012-05-23",
        },
        beneficiary: {
          reference: "Patient/588675dc-e80e-4528-a78f-af10f9755f23",
        },
        meta: {
          versionId: "1",
          lastUpdated: "2021-06-01T00:00:00Z",
        },
        implicitRules: "https://example.com/base",
        status: "entered-in-error",
      },
      name: "CoverageToMatch",
    },
    {
      resource: {
        resourceType: "Coverage",
        payor: [
          {
            identifier: {
              system: "http://hl7.org/fhir/sid/us-npi",
              value: "0123456789",
            },
            display: "New Health Plan",
          },
        ],
        id: "cAA87654",
        period: {
          start: "2011-05-23",
          end: "2012-05-23",
        },
        beneficiary: {
          reference: "Patient/patient-1",
        },
        meta: {
          versionId: "1",
          lastUpdated: "2021-06-01T00:00:00Z",
        },
        implicitRules: "https://example.com/base",
        status: "active",
      },
      name: "CoverageToLink",
    },
    {
      resource: {
        resourceType: "Consent",
        status: "active",
        scope: {
          coding: [
            {
              system: "http://terminology.hl7.org/CodeSystem/consentscope",
              code: "patient-privacy",
            },
          ],
        },
        category: [
          {
            coding: [
              {
                system: "http://terminology.hl7.org/CodeSystem/v3-ActCode",
                code: "IDSCL",
              },
            ],
          },
        ],
        patient: {
          reference: "Patient/patient-1",
        },
        performer: [
          {
            reference: "http://example.org/Patient/example",
          },
        ],
        sourceReference: {
          reference: "http://example.org/DocumentReference/someconsent",
        },
        policy: [
          {
            uri: "http://hl7.org/fhir/us/davinci-hrex/StructureDefinition-hrex-consent.html#regular",
          },
        ],
        provision: {
          type: "permit",
          period: {
            start: "2022-01-01",
            end: "2022-01-31",
          },
          actor: [
            {
              role: {
                coding: [
                  {
                    system:
                      "http://terminology.hl7.org/CodeSystem/provenance-participant-type",
                    code: "performer",
                  },
                ],
              },
              reference: {
                identifier: {
                  system: "http://hl7.org/fhir/sid/us-npi",
                  value: "9876543210",
                },
                display: "Old Health Plan",
              },
            },
          ],
          action: [
            {
              coding: [
                {
                  system: "http://terminology.hl7.org/CodeSystem/consentaction",
                  code: "disclose",
                },
              ],
            },
          ],
        },
      },
      name: "Consent",
    },
  ],
  id: "member-match-in",
};

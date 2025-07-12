export const memberMatchPayload = (patient: any, coverage: any) => {
  return {
    resourceType: "Parameters",
    parameter: [
      {
        resource: patient,
        name: "MemberPatient",
      },
      {
        resource: coverage,
        name: "CoverageToMatch",
      },
      {
        resource: coverage,
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
                    system:
                      "http://terminology.hl7.org/CodeSystem/consentaction",
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
};

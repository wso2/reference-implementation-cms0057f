const Config = window.Config;

export const fhirOperationConfigs = [
  {
    id: "patient-search",
    name: "Patient Data",
    endpoint: Config.patientEndpoint || "/patient-service/fhir/r4/Patient",
    showSearchButton: true,
    params: [
      {
        name: "_id",
        label: "Patient ID",
        type: "text",
        required: true,
        disabled: true,
      },
      { name: "given", label: "Given Name", type: "text", required: false },
      { name: "family", label: "Family Name", type: "text", required: false },
      {
        name: "address-city",
        label: "Address City",
        type: "text",
        required: false,
      },
      {
        name: "address-country",
        label: "Address Country",
        type: "text",
        required: false,
      },
    ],
  },
  {
    id: "explanation-of-benefits",
    name: "Explanation of Benefits",
    endpoint: Config.explanationOfBenefitsEndpoint || "/eob-service/fhir/r4/ExplanationOfBenefit",
    showSearchButton: true,
    params: [
      {
        name: "patient",
        label: "Patient ID",
        type: "text",
        required: true,
        disabled: true,
      },
      {
        name: "_id",
        label: "Explanation of Benefits ID",
        type: "text",
        required: false,
      },
      { name: "_profile", label: "Profile", type: "text", required: false },
      {
        name: "_lastUpdated",
        label: "Last Updated",
        type: "date",
        required: false,
      },
      {
        name: "identifier",
        label: "Identifier",
        type: "text",
        required: false,
      },
      { name: "created", label: "Created", type: "date", required: false },
    ],
  },
  {
    id: "coverage",
    name: "Coverage Data",
    endpoint: Config.coverageEndpoint || "/coverage-service/fhir/r4/Coverage",
    showSearchButton: true,
    params: [
      {
        name: "patient",
        label: "Patient ID",
        type: "text",
        required: true,
        disabled: true,
      },
      { name: "_id", label: "Coverage ID", type: "text", required: false },
    ],
  },
  {
    id: "claim-response",
    name: "Prior Authorization Data",
    endpoint: Config.claimResponseEndpoint || "/claimresponse-service/fhir/r4/ClaimResponse",
    displayEndpoint: "/fhir/r4/ClaimResponse",
    showSearchButton: true,
    params: [
      {
        name: "patient",
        label: "Patient ID",
        type: "text",
        required: true,
        disabled: true,
      },
      {
        name: "use",
        label: "Use",
        type: "text",
        required: false,
        defaultValue: "preauthorization",
        disabled: true,
      },
      { name: "created", label: "Created After", type: "date", required: false },
    ],
  },
  {
    id: "diagnostic-report",
    name: "Diagnostic Report",
    endpoint: Config.diagnosticReportEndpoint || "/diag-report-service/fhir/r4/DiagnosticReport",
    showSearchButton: false,
    params: [
      {
        name: "patient",
        label: "Patient ID",
        type: "text",
        required: true,
        disabled: true,
      }
    ],
  },
];

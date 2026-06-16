// Local config — demo-mediclaim-app against the WSO2 APIM gateway.
window.Config = {
  baseUrl: "https://localhost:8243/fhirapi/1.0.0",
  consumerKey: "j6RkWRCIQd6WqXK45ZILDnmUKdka",
  consumerSecret: "IiQ2Sdhd2MuqyTk74oPb_Q0Uaif9Dfu_loLOmlZsOasa",
  wellKnownEndpoint: "/.well-known/smart-configuration",
  audienceEndpoint: "",

  patientEndpoint: "/Patient",
  explanationOfBenefitsEndpoint: "/ExplanationOfBenefit",
  coverageEndpoint: "/Coverage",
  claimResponseEndpoint: "/ClaimResponse",
  diagnosticReportEndpoint: "/DiagnosticReport",
};

// DEV (local) — relative paths proxied by Vite to the local services.
window.configs = {
  organizationServiceUrl: "/bff/v1/payers?page=1&limit=10",
  oldPayerCoverageGet: "/pdex/pdex-data-requests",
  fhir: "/fhir/r4",
  pdexExchangeUrl: "/pdex/capture-pdex-data",
  payersAndFhirServerMappings: [{ id: 50, fhirServerUrl: "/fhir/r4" }],
};

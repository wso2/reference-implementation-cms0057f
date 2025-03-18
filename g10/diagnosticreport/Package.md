# DiagnosticReport Template

## Template Overview

This template provides a boilerplate code for rapid implementation of FHIR APIs and creating, accessing and manipulating FHIR resources.

| Module/Element       | Version |
| -------------------- | ------- |
| FHIR version         | r4 |
| Implementation Guide | [http://hl7.org/fhir/us/core](http://hl7.org/fhir/us/core) |
| Profile URL          |[http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-note](http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-note), [http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-lab](http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-lab)|

### Dependency List

- ballerinax/health.fhir.r4
- ballerinax/health.fhirr4
- ballerinax/health.fhir.r4.uscore311

This template includes a Ballerina service for DiagnosticReport FHIR resource with following FHIR interactions.
- READ
- VREAD
- SEARCH
- CREATE
- UPDATE
- PATCH
- DELETE
- HISTORY-INSTANCE
- HISTORY-TYPE

## Prerequisites

Pull the template from central

    ` bal new -t healthcare/health.fhir.r4.uscore311.diagnosticreport DiagnosticReportAPI `

## Run the template

- Run the Ballerina project created by the service template by executing bal run from the root.
- Once successfully executed, Listener will be started at port 9090. Then you need to invoke the service using the following curl command
    ` $ curl http://localhost:9090/fhir/r4/DiagnosticReport `
- Now service will be invoked and returns an Operation Outcome, until the code template is implemented completely.

## Adding a Custom Profile/Combination of Profiles

- Add profile type to the aggregated resource type. Eg: `public type DiagnosticReport r4:DiagnosticReport|<Other_DiagnosticReport_Profile>;`.
    - Add the new profile URL in `api_config.bal` file.
    - Add as a string inside the `profiles` array.
    - Eg: `profiles: ["http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-note", "new_profile_url"]`

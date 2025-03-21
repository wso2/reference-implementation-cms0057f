# GraphDefinition Template

## Template Overview

This template provides a boilerplate code for rapid implementation of FHIR APIs and creating, accessing and manipulating FHIR resources.

| Module/Element       | Version |
| -------------------- | ------- |
| FHIR version         | r4 |
| Implementation Guide | [http://hl7.org/fhir/us/davinci-drug-formulary](http://hl7.org/fhir/us/davinci-drug-formulary) |
| Profile URL          |[http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-PayerInsurancePlanBulkDataGraphDefinition](http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-PayerInsurancePlanBulkDataGraphDefinition), [http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-FormularyBulkDataGraphDefinition](http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-FormularyBulkDataGraphDefinition)|

### Dependency List

- ballerinax/health.fhir.r4
- ballerinax/health.fhirr4
- ballerinax/health.fhir.r4.davincidrug

This template includes a Ballerina service for GraphDefinition FHIR resource with following FHIR interactions.
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

    ` bal new -t healthcare/health.fhir.r4.davincidrug.graphdefinition GraphDefinitionAPI `

## Run the template

- Run the Ballerina project created by the service template by executing bal run from the root.
- Once successfully executed, Listener will be started at port 9090. Then you need to invoke the service using the following curl command
    ` $ curl http://localhost:9090/fhir/r4/GraphDefinition `
- Now service will be invoked and returns an Operation Outcome, until the code template is implemented completely.

## Adding a Custom Profile/Combination of Profiles

- Add profile type to the aggregated resource type. Eg: `public type GraphDefinition r4:GraphDefinition|<Other_GraphDefinition_Profile>;`.
    - Add the new profile URL in `api_config.bal` file.
    - Add as a string inside the `profiles` array.
    - Eg: `profiles: ["http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-PayerInsurancePlanBulkDataGraphDefinition", "new_profile_url"]`

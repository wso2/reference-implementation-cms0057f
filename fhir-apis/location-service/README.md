# Location Service

This service is a reference implementation for handling different Location profiles in FHIR R4. It supports the following profiles:

1. **US Core Location Profile**:
   - URL: `http://hl7.org/fhir/us/core/StructureDefinition/us-core-location`
   - Description: This profile defines the standard for representing location information in the US Core Implementation Guide.

2. **Davinci PlanNet Location Profile**:
   - URL: `http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Location`
   - Description: This profile is part of the Da Vinci Project's PlanNet Implementation Guide, which standardizes the exchange of provider directory information.

3. **Davinci Drug Formulary Insurance Plan Location Profile**:
   - URL: `http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-InsurancePlanLocation`
   - Description: This profile is part of the Da Vinci Project's Drug Formulary Implementation Guide, which standardizes the exchange of drug formulary information.

## API Endpoints

The service exposes the following endpoints for managing Location resources:

- **GET /fhir/r4/Location/{id}**: Retrieve a Location resource by its ID.
- **GET /fhir/r4/Location**: Search for Location resources based on a set of criteria.
- **POST /fhir/r4/Location**: Create a new Location resource.

## Configuration

The service is configured to use the following profiles:

- US Core Location Profile
- Davinci PlanNet Location Profile
- Davinci Drug Formulary Insurance Plan Location Profile

The configuration details can be found in the `api_config.bal` file.

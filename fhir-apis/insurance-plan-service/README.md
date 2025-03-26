# Insurance Plan Service

This service is a reference implementation for handling different Insurance Plan profiles in FHIR R4. It supports the following profiles:

1. **Davinci PlanNet Insurance Plan Profile**:
   - URL: `http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-InsurancePlan`
   - Description: This profile is part of the Da Vinci Project's PlanNet Implementation Guide, which standardizes the exchange of provider directory information.

2. **Davinci Drug Formulary Formulary Profile**:
   - URL: `http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-Formulary`
   - Description: This profile is part of the Da Vinci Project's Drug Formulary Implementation Guide, which standardizes the exchange of drug formulary information.

3. **Davinci Drug Formulary Payer Insurance Plan Profile**:
   - URL: `http://hl7.org/fhir/us/davinci-drug-formulary/StructureDefinition/usdf-PayerInsurancePlan`
   - Description: This profile is part of the Da Vinci Project's Drug Formulary Implementation Guide, which standardizes the exchange of payer insurance plan information.

## API Endpoints

The service exposes the following endpoints for managing Insurance Plan resources:

- **GET /fhir/r4/InsurancePlan/{id}**: Retrieve an Insurance Plan resource by its ID.
- **GET /fhir/r4/InsurancePlan**: Search for Insurance Plan resources based on a set of criteria.
- **POST /fhir/r4/InsurancePlan**: Create a new Insurance Plan resource.

## Configuration

The service is configured to use the following profiles:

- Davinci PlanNet Insurance Plan Profile
- Davinci Drug Formulary Formulary Profile
- Davinci Drug Formulary Payer Insurance Plan Profile

The configuration details can be found in the `api_config.bal` file.

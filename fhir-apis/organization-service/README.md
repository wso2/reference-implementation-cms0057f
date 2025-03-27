# Organization Service

This service is a reference implementation for handling different Organization profiles in FHIR R4. It supports the following profiles:

1. **US Core Organization Profile**:
   - URL: `http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization`
   - Description: This profile defines the standard for representing organization information in the US Core Implementation Guide.

2. **Da Vinci Plan Net Organization Profile**:
   - URL: `http://hl7.org/fhir/us/davinci-pdex-plan-net/StructureDefinition/plannet-Network`
   - Description: This profile is part of the Da Vinci PDEX Plan Net Implementation Guide, which standardizes the exchange of healthcare network information.

## API Endpoints

The service exposes the following implemented endpoints for managing Organization resources:

- **GET /fhir/r4/Organization/{id}**: Retrieve an Organization resource by its ID.
- **GET /fhir/r4/Organization**: Search for Organization resources based on a set of criteria.
- **POST /fhir/r4/Organization**: Create a new Organization resource.

## Configuration

The service is configured to use the following profiles:

- US Core Organization Profile
- Da Vinci PDEX Plan Net Organization Profile

The configuration details can be found in the `api_config.bal` file.

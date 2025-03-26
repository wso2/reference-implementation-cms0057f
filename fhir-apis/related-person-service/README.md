# Related Person Service

This service is a reference implementation for handling different Related Person profiles in FHIR R4. It supports the following profiles:

1. **US Core Related Person Profile**:
   - URL: `http://hl7.org/fhir/us/core/StructureDefinition/us-core-relatedperson`
   - Description: This profile defines the standard for representing related person information in the US Core Implementation Guide.

2. **CARIN BB Related Person Profile**:
   - URL: `http://hl7.org/fhir/us/carin-bb/StructureDefinition/C4BB-RelatedPerson`
   - Description: This profile is part of the CARIN Blue Button Implementation Guide, which standardizes the exchange of consumer-directed health information.

## API Endpoints

The service exposes the following endpoints for managing Related Person resources:

- **GET /fhir/r4/RelatedPerson/{id}**: Retrieve a Related Person resource by its ID.
- **GET /fhir/r4/RelatedPerson**: Search for Related Person resources based on a set of criteria.
- **POST /fhir/r4/RelatedPerson**: Create a new Related Person resource.

## Configuration

The service is configured to use the following profiles:

- US Core Related Person Profile
- CARIN BB Related Person Profile

The configuration details can be found in the `api_config.bal` file.

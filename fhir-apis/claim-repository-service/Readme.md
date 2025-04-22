# Claim Repository Service

The `claim-repository-service` is a centralized service for managing claims and claim responses in a FHIR-compliant manner. It provides a set of RESTful APIs to perform CRUD operations on claims and claim responses.

## Features

- **Claim Management**: Create, retrieve, update, and delete claims.
- **ClaimResponse Management**: Create, retrieve, update, and delete claim responses.
- **FHIR R4 Compliance**: Adheres to the FHIR R4 standard for healthcare data exchange.

## Endpoints

### Claim Endpoints

- `POST /fhir/r4/ClaimRepo/Claim`: Create a new claim.
- `GET /fhir/r4/ClaimRepo/Claim/{id}`: Retrieve a claim by ID.
- `GET /fhir/r4/ClaimRepo/Claim`: Retrieve all claims.
- `DELETE /fhir/r4/ClaimRepo/Claim/{id}`: Delete a claim by ID.

### ClaimResponse Endpoints

- `POST /fhir/r4/ClaimRepo/ClaimResponse`: Create a new claim response.
- `GET /fhir/r4/ClaimRepo/ClaimResponse/{id}`: Retrieve a claim response by ID.
- `GET /fhir/r4/ClaimRepo/ClaimResponse`: Retrieve all claim responses.
- `DELETE /fhir/r4/ClaimRepo/ClaimResponse/{id}`: Delete a claim response by ID.

## License

This project is licensed under the WSO2 Software License. For more details, visit [https://wso2.com/licenses/eula/3.2](https://wso2.com/licenses/eula/3.2).

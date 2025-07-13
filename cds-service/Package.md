
# CDS Hooks for Davinci's CRD

# 1. Coverage Requirement Discovery

This is a ballerina template for the insurance payers who are developing the solution for the Davinci’s Coverage Requirement Discovery.

This will contain the CDS hooks as service. The [documentation](https://build.fhir.org/ig/HL7/davinci-crd/hooks.html#hook-categories) states: “The **primary** hooks are `Appointment Book`, `Orders Sign`, and `Order Dispatch`. CRD Servers SHALL, at minimum, return a Coverage Information system action for these hooks, even if the response indicates that further information is needed or that the level of detail provided is insufficient to determine coverage. The **secondary** hooks are `Orders Select`, `Encounter Start`, and `Encounter Discharge`. These hooks MAY return cards or system actions, but are not expected to, and CRD clients are free to ignore any cards or actions returned.”

The following features are implemented,
> 1. **CDS hooks as ballerina service**: All six hooks will be implemented as ballerina service. Since it is not mandatory to support all the hooks, the payer can define the relevant hooks for their services. `Config.bal` will contain all the hooks.
> 2. **Ballerina Records for CRD**: All of the types will be implemented as ballerina records to support type safety. `health.fhir.cds.records.bal` contains the implemented records.
> 3. **Methods to connect with Rule Repository**: These methods will be defined to connect the CDS service with the DDS server (Decision support systems). This will be used to process the received CDS request, prefetch the resources from the EHR repository (if needed), and construct the CDS response from the response received from the CRD server. `impl_decision_system_connection.bal` contains the interface to implement.
> 4. **Ballerina library to support CRD resources**: This library will provide all the records for the CRD operations. The library can be used with `import ballerinax/health.fhir.cds`. The following records are supported by the library.


The Developer needs to implement the `impl_decision_system_connection` methods to connect with the payer side Decision support system (DDS server). Then they can pass the relevant information from the CDS Request to the decision support systems. When the system returns details regarding the coverage information, developer needs to implement the logic to construct the CDS response in the form of cards and System actions.


# How to use

## Prerequisites

Before running this sample, make sure you have the following:

- Download and install [Ballerina Swan Lake](https://ballerina.io/downloads/) 2201.8.5 or above.

## Getting Started

To get started with this sample, follow these steps:

1. Complete the decision system connectivity implementation. The ```impl_decision_system_connection``` file contains placeholder functions that must be implemented to connect with external decision systems. Please follow the instructions in that file itself.

2. Complete the feedback system connectivity implementation. The ```implFeedbackSystemConnection``` file contains placeholder functions that must be implemented to connect with external feedback systems. Please follow the instructions in that file itself.

3. [Optional] By default this service will run in port 8080, if needed, you can change the port in the service.bal file.

4. Run the project using the following command:

```bash
$ bal run
```

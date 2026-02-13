# FHIR Repository (Dockerized)

This directory contains the Docker configuration and scripts to run a local FHIR R4 server based on the WSO2 Open Healthcare reference implementation.

## Prerequisites

-   Docker

## Getting Started

### 1. Build the Docker Image

Build the Docker image. This will clone the `fhir-server-v1` branch of the `wso2/open-healthcare-prebuilt-services` repository and set it up.

```bash
docker build -t fhir-repository .
```

### 2. Run the Container

Run the FHIR server container, exposing port 9090.

```bash
docker run -d -p 9090:9090 --name fhir-repository fhir-repository
```

The server will be available at `http://localhost:9090/fhir/r4/metadata`.

### 3. Load Data

Scripts are provided to load US Core StructureDefinitions and sample data into the server.

#### Prerequisites for Scripts

-   Python 3
-   `requests` library (`pip install requests`)

#### Load US Core Definitions

First, install the US Core package (if not already present):

```bash
npm --registry https://packages.simplifier.net install hl7.fhir.us.core@7.0.0
```

Then run the script to load the definitions:

```bash
python3 load_structure_definitions.py
```

#### Load Sample Data

After loading definitions, run the data loading script to populate the server with sample resources:

```bash
python3 load_data.py
```

## Helper Commands

-   **View Logs**: `docker logs -f fhir-repository`
-   **Stop Server**: `docker stop fhir-repository`
-   **Remove Container**: `docker rm fhir-repository`


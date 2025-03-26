# Bulk Export Server Pre-built Service

This Ballerina pre-built service is designed to export FHIR resources by interacting with a FHIR server to consume the <resource-type>/_search operation. It provides endpoints to kick off the export process, check the status of the export and download the exported files. The exported files will be stored in the file system.

## Features
- Facilitates a FHIR resorces export kick-off, status check and file download.
- A FHIR server can be configured as the source of the FHIR resources. NDJSON files will be generated using these data.
- File system location where the exported files are stored can be configured.
- Client credential token configuration can be done to interact with the source server.
- Support is available for all FHIR resource types. Required types can be configured if needed.

## Endpoints

### 1. Kick-off Export
Initiates the export operation.

**Endpoint**:  
`GET /fhir/r4/Patient/export`

**Response**:  
- Returns an OperationOutcome resource with information on how to check the export status.

### 2. Get Export Status
Provides the status of the ongoing export operation or the export result if the export is completed.

**Endpoint**:  
`GET fhir/bulkstatus/[exportId]`

***Params:*** <br>- exportId - exportId returned in kick-off response


**Response**:  
- Provides the status instnaces of the export process. 

### 3. Download Exported Files
Downloads the exported NDJSON files once the export process is complete.

**Endpoint**:  
`GET [exportId]/fhir/bulkfiles/[fileName]`

***Params:*** <br> 
- exportId - exportId returned in status response
- fileName - File name returned in the status response that's needed to be downloaded

**Response**:  
- Downloads the requested NDJSON file containing the exported FHIR resources for the given exportId.

## How to Run
 - Clone the repository
 - Add configurations.
    - If you're trying this on Choreo, you can configure values upon in the deploy step.
    - For other deployments, add a file named, `Config.toml` with following configs to the Ballerina project root.

    ```toml
    [searchServerConfig]
    authEnabled = <true/false>      # true if the search server requires client-credentials authentication
    searchUrl = "<source-hostname>" # search URL of the source server. Only the host needs to be configured here
    contextPath = "<source-context>"# FHIR server's context path. Ex: "fhir/r4","baseR4"
    tokenUrl = "<token-endpoint>"   # token endpoint URL. Not required if authEnabled is false
    clientId = "<client-id>"        # client ID. Not required if authEnabled is false
    clientSecret = "<client-secret>"# client secret. Not required if authEnabled is false
    scopes = ["scope1", "scope2"]   # array of scopes, to access the search operation. Not required if authEnabled is false

    [exportServiceConfig]
    port = <port>                   # port number of the service
    baseUrl = "<server-base-url>"   # base URL of the server. Needed when returning status and download URLs
    targetDirectory = "<target_dir>"# temporary directory to save and host the exported files
    ```

 - Run the project
 ` bal run` 

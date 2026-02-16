# Bulk Export Client Pre-built Service

This Ballerina pre-built service is designed to interact with a FHIR server to consume the /Patient/$export operation. It provides endpoints to kick off the export process, check the status of the export, download the exported files, and optionally send the downloaded files to an FTP server.

## Features
- Initiates `/Patient/$export` operation on a FHIR server.
- Retrieves the status of the export process.
- Downloads exported NDJSON files from the FHIR server.
- Supports uploading the downloaded files to an FTP server.

## Endpoints

### 1. Kick-off Export
Initiates the `/Patient/$export` operation on the FHIR server.

**Endpoint**:  
`POST /bulk/export` for single Patient exports
`GET /bulk/export` for all Patient exports

**Request Body**:
```json
[
    {"id":"member-id1"},
    {"id":"member-id2"}
]

**Response**:  
- Returns an OperationOutcome resource with the exportId.

### 2. Get Export Status
Checks the status of the ongoing export operation.

**Endpoint**:  
`GET /bulk/status`

***Params:*** <br>- exportId - exportId returned in kick-off response


**Response**:  
- Provides the status instnaces of the export process (status of all polling events happened in the background).

### 3. Download Exported Files
Downloads the exported NDJSON files once the export process is complete.

**Endpoint**:  
`GET /file/fetch`

***Params:*** <br> 
- exportId - exportId returned in kick-off response
- resourceType - FHIR resource type

**Response**:  
- Downloads the NDJSON files containing the exported FHIR resources for given exportId and resourceType.

### 4. Capture Payer Data Exchange Request
Captures a new payer data exchange request.

**Endpoint**:  
`POST /pdex/capture-pdex-data`

**Request Body**:
```json
{
    "memberId": "12345",
    "oldPayerName": "Old Payer",
    "oldPayerState": "CA",
    "oldCoverageId": "COV123",
    "coverageStartDate": "2023-01-01",
    "coverageEndDate": "2023-12-31",
    "consent": "approved"
}
```

**Curl Command**:
```bash
curl -X POST 'http://localhost:8091/pdex/capture-pdex-data' \
--header 'Content-Type: application/json' \
--data-raw '{
    "memberId": "12345",
    "oldPayerName": "Old Payer",
    "oldPayerState": "CA",
    "oldCoverageId": "COV123",
    "coverageStartDate": "2023-01-01",
    "coverageEndDate": "2023-12-31",
    "consent": "approved"
}'
```

### 5. Get Payer Data Exchange Requests
Retrieves a list of payer data exchange requests with pagination.

**Endpoint**:  
`GET /pdex/pdex-data-requests?limit=10&offset=0`

**Curl Command**:
```bash
curl -X GET 'http://localhost:8091/pdex/pdex-data-requests?limit=10&offset=0'
```

### 6. Update Payer Data Exchange Request Status
Updates the status of a specific payer data exchange request.

**Endpoint**:  
`PATCH /pdex/pdex-data-requests/{requestId}/status`

**Request Body**:
```json
{
    "status": "COMPLETED"
}
```

**Curl Command**:
```bash
curl -X PATCH 'http://localhost:8091/pdex/pdex-data-requests/req-123/status' \
--header 'Content-Type: application/json' \
--data-raw '{
    "status": "COMPLETED"
}'
```

## How to Run
 - Clone the repository
 - Add configurations.
    - If you're trying this on Choreo, you can configure values upon in the deploy step.
    - For other deployments, add a file named, `Config.toml` with following configs to the Ballerina project root.

    ``` toml
    [clientServiceConfig]
    port = 9099
    authEnabled = false
    targetDirectory = "target_dir"

    [sourceServerConfig]
    baseUrl = "server_base_url"
    contextPath = "context_path"
    tokenUrl = "<token endpoint>"
    fileServerUrl = "<file_server_url>"
    clientId = "bulk-export-client-id"
    clientSecret = "bulk-export-client-secret"
    scopes = ["scope1"]
    defaultIntervalInSec = 2.0

    [targetServerConfig]
    type = "fhir" #or fhir
    host = "host"
    port = <port>
    username = "username"
    password = "password"
    directory = "<target_dir>>"
    ```

 - Run the project
 ` bal run` 


 ### Note:
 For configure Choreo component's in-memory storage as file storage, add a volume mount to `/workspace/${target_dir}`

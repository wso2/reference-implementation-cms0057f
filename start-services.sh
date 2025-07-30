#!/usr/bin/env bash
set -euo pipefail

# Detect OS type
if [[ "$OSTYPE" == "darwin"* ]]; then
  SED_INPLACE="sed -i ''"
else
  SED_INPLACE="sed -i"
fi

APICTL="apictl" 
read -p "Enter the environment name: " ENV_NAME # target apictl environment

#Check for apictl
if ! command -v "$APICTL" &>/dev/null; then
  echo "Error: apictl not found. To install, refer to 
  https://apim.docs.wso2.com/en/latest/install-and-setup/setup/api-controller/getting-started-with-wso2-api-controller/"
  exit 1
fi

#Environment Setup
#APIM_HOST="https://localhost:9443"  # WSO2 API Manager URL
DEFAULT_APIM_HOST="https://localhost:9443"

read -p "Do you want to use the default APIM URL ($DEFAULT_APIM_HOST)? (y/n): " use_default

if [[ "$use_default" == "y" || "$use_default" == "Y" ]]; then
    APIM_HOST=$DEFAULT_APIM_HOST
else
    read -p "Enter the APIM service URL (Ex: https://localhost:9443): " APIM_HOST
fi

echo "Using APIM URL: $APIM_HOST"
TOKEN_ENDPOINT="$APIM_HOST/oauth2/token" # WSO2 API Manager token endpoint

#Add environment if not already present
if ! "$APICTL" get envs --format "{{.Name}}" | grep -qx "$ENV_NAME"; then
  echo "Adding environment $ENV_NAME"
  "$APICTL" add env "$ENV_NAME" --apim "$APIM_HOST" --token "$TOKEN_ENDPOINT"
else
  echo "Environment $ENV_NAME already exists"
fi

#Login to the environment
echo "Logging into environment $ENV_NAME"
read -p "Enter username: " USERNAME
read -s -p "Enter password: " PASSWORD

"$APICTL" login "$ENV_NAME" -u "$USERNAME" -p "$PASSWORD" -k

deploy_apis() {
  local API_NAME=$1
  local SWAGGER_PATH=$2
  local CONTEXT=$3
  local BACKEND_ENDPOINT=$4

  TMP_DIR="./apidocs"
  echo "Creating temp folder $TMP_DIR"
  rm -rf "$TMP_DIR" && mkdir -p "$TMP_DIR"

  PROJECT_DIR="$TMP_DIR/$API_NAME"
  rm -rf "$PROJECT_DIR"

  #Initialize apictl project (force overwrite)
  "$APICTL" init "$PROJECT_DIR" --oas="$SWAGGER_PATH" --force
  API_FILE="$PROJECT_DIR/api.yaml"
  $SED_INPLACE "s|name: .*|name: $API_NAME|" "$API_FILE"
  $SED_INPLACE "s|context: .*|context: $CONTEXT|" "$API_FILE"
  $SED_INPLACE "s|lifeCycleStatus: .*|lifeCycleStatus: PUBLISHED|" "$API_FILE"
  $SED_INPLACE "/production_endpoints:/, /url:/ s|url: .*|url: $BACKEND_ENDPOINT|" "$API_FILE"
  $SED_INPLACE "/sandbox_endpoints:/, /url:/ s|url: .*|url: $BACKEND_ENDPOINT|" "$API_FILE"

  #Import (create or update) and automatically publish
  "$APICTL" import api -f "$PROJECT_DIR" -e "$ENV_NAME" -k --update

  echo "Imported & published $API_NAME"
  rm -rf "$TMP_DIR"   
}

# Start Ballerina services and deploy APIs
start_services_and_deploy_apis() {

  LOG_DIR="./services_logs"
  mkdir -p "$LOG_DIR"

  echo "========== Starting Ballerina services and deploying APIs =========="

  echo "========== 1. Starting Ballerina services =========="

  echo "Starting FHIR Service"
  BAL_CONFIG_FILES=fhir-service/Config.toml bal run fhir-service &> $LOG_DIR/fhir-service.log &

  echo "Starting Bulk Export Client Service"
  BAL_CONFIG_FILES=bulk-export-client/Config.toml bal run bulk-export-client &> $LOG_DIR/bulk-export-client.log &

  echo "Starting File Service"
  BAL_CONFIG_FILES=file-service/Config.toml bal run file-service &> $LOG_DIR/file-service.log &

  echo "Starting CDS Service"
  BAL_CONFIG_FILES=cds-service/Config.toml bal run cds-service &> $LOG_DIR/cds-service.log &   

  echo "========== 2. Deploying APIs =========="

  echo "Deploying FHIR API"
  deploy_apis "FHIRAPI" "fhir-service/oas/OpenAPI.yaml" "/fhirapi" "http://localhost:9090" 

  echo "Deploying BulkExportClient API"
  deploy_apis "BulkExportClientAPI" "bulk-export-client/oas/BulkExport.yaml" "/bulkexportclient" "http://localhost:8091/bulk"

  echo "Deploying BulkExportFileServer API"
  deploy_apis "BulkExportFileServer" "bulk-export-client/oas/FileServer.yaml" "/bulkexport-fileserver" "http://localhost:8100/file" 
  
  echo "Deploying FileService API"
  deploy_apis "FileServiceAPI" "file-service/oas/OpenAPI.yaml" "/fileserver" "http://localhost:8090" 

  echo "Deploying CDS API"
  deploy_apis "CDSAPI" "cds-service/oas/CDS.yaml" "/cdsapi" "http://localhost:9093" 

  echo "========== All relevant services and APIs started successfully. =========="
}

start_services_and_deploy_apis

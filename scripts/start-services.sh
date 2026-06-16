#!/usr/bin/env bash
set -euo pipefail

# This script lives in scripts/ but uses paths relative to the repo root — cd there.
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
  PID_FILE="$LOG_DIR/service.pids"
  : > "$PID_FILE"   # truncate — records started PIDs so ./stop-services.sh can stop them

  # NOTE: each service reads its Config.toml. Make sure the prerequisites are met
  # first (see README §5): MySQL up + DB seeded, and the SMART/discovery + DB
  # values filled in fhir-service/Config.toml and bulk-export-client/Config.toml.

  echo "========== Starting Ballerina services and deploying APIs =========="

  echo "========== 1. Starting Ballerina services =========="

  echo "Starting FHIR Service"
  # Run from within the service dir so the relative resourceFilePath in
  # Config.toml ("resources/fhir_resources.json") resolves correctly.
  ( cd fhir-service && BAL_CONFIG_FILES=Config.toml bal run ) &> $LOG_DIR/fhir-service.log &
  echo $! >> "$PID_FILE"

  echo "Starting Bulk Export Client Service"
  BAL_CONFIG_FILES=bulk-export-client/Config.toml bal run bulk-export-client &> $LOG_DIR/bulk-export-client.log &
  echo $! >> "$PID_FILE"

  echo "Starting File Service"
  BAL_CONFIG_FILES=file-service/Config.toml bal run file-service &> $LOG_DIR/file-service.log &
  echo $! >> "$PID_FILE"

  echo "Starting CDS Service"
  BAL_CONFIG_FILES=cds-service/Config.toml bal run cds-service &> $LOG_DIR/cds-service.log &
  echo $! >> "$PID_FILE"

  echo "Starting Rule Engine"
  BAL_CONFIG_FILES=rule-engine/Config.toml bal run rule-engine &> $LOG_DIR/rule-engine.log &
  echo $! >> "$PID_FILE"

  # The payer-admin portal is the payer's admin console (NOT an end-user demo app),
  # so it is started here with the platform services. It is a React/Vite app
  # (needs Node >= 20) and uses the same local-config activation as the demo apps.
  echo "Starting Payer Admin App (payer admin console)"
  PAYER_APP="apps/payer-admin-app"
  if ! { command -v node >/dev/null 2>&1 && [ "$(node -v 2>/dev/null | sed 's/v\([0-9]*\).*/\1/')" -ge 20 ]; }; then
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && nvm use 20 >/dev/null 2>&1 || true
  fi
  if command -v node >/dev/null 2>&1 && [ "$(node -v 2>/dev/null | sed 's/v\([0-9]*\).*/\1/')" -ge 20 ]; then
    [ -f "$PAYER_APP/vite.config.ts.local" ] && cp "$PAYER_APP/vite.config.ts.local" "$PAYER_APP/vite.config.ts"
    [ -f "$PAYER_APP/public/config.local.js" ] && cp "$PAYER_APP/public/config.local.js" "$PAYER_APP/public/config.js"
    ( cd "$PAYER_APP" && ( npm install || npm install --legacy-peer-deps ) >"$LOG_DIR/payer-admin-app-install.log" 2>&1 && npm run dev >"$LOG_DIR/payer-admin-app.log" 2>&1 ) &
    echo $! >> "$PID_FILE"
    echo "  payer-admin app starting (pid $!, http://localhost:5173) — first build is slow"
  else
    echo "  WARN: Node >= 20 not found; skipping payer-admin app (install Node 20+ and re-run, or start it manually)."
  fi

  echo "Recorded service PIDs in $PID_FILE (use ./stop-services.sh to stop)"

  echo "========== 2. Deploying APIs =========="

  #Create API by passing API name, OAS path, API context, backend endpoint
  echo "Deploying FHIR API"
  deploy_apis "FHIRAPI" "fhir-service/oas/OpenAPI.yaml" "/fhirapi" "http://localhost:8080/fhir/r4"

  echo "Deploying BulkExportClient API"
  deploy_apis "BulkExportClientAPI" "bulk-export-client/oas/BulkExport.yaml" "/bulkexportclient" "http://localhost:8091/bulk"

  echo "Deploying BulkExportClientFileServer API"
  deploy_apis "BulkExportClientFileServer" "bulk-export-client/oas/FileServer.yaml" "/bulkexportclient-fileserver" "http://localhost:8100/file" 
  
  echo "Deploying FileService API"
  deploy_apis "FileServiceAPI" "file-service/oas/OpenAPI.yaml" "/fileserver" "http://localhost:8090" 

  echo "Deploying CDS API"
  deploy_apis "CDSAPI" "cds-service/oas/cds.yaml" "/cdsapi" "http://localhost:9096"

  echo "========== All relevant services and APIs started successfully. =========="
}

start_services_and_deploy_apis

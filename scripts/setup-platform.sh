#!/usr/bin/env bash
# Idempotent setup for the WSO2 platform (API Manager + Identity Server) with the
# Open Healthcare Accelerator. You do NOT need to know anything about WSO2 products
# or where they go — just run it. Everything is downloaded into a gitignored
# ./platform/ folder inside the repo (so the large binaries never get committed).
#
# For both APIM 4.6.0 and IS 7.3.0 it will (each step skipped if already done):
#   1. DOWNLOAD the product + accelerator zips from the WSO2 GitHub releases
#        product-apim     v4.6.0  : https://github.com/wso2/product-apim/releases/tag/v4.6.0
#        product-is       v7.3.0  : https://github.com/wso2/product-is/releases/tag/v7.3.0
#        healthcare-accel v2.1.0  : https://github.com/wso2/healthcare-accelerator/releases/tag/v2.1.0
#   2. extract the product zip
#   3. apply the Healthcare Accelerator (copy it into the product home + run bin/merge.sh)
#   4. start the server
#
# Key Manager + SMART-on-FHIR are console/REST configuration (see the doc links it
# prints) — this script does not automate those.
#
# Usage:
#   ./setup-platform.sh        # download (first time only) + set up + start IS and APIM
#   ./setup-platform.sh stop   # stop IS and APIM
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # repo root (this script lives in scripts/)
# Where the WSO2 products are installed — a gitignored folder in the repo. Fixed by
# default so new developers don't have to choose; PLATFORM_DIR override is for advanced use.
PLATFORM_DIR="${PLATFORM_DIR:-$ROOT/platform}"
LOG_DIR="$ROOT/services_logs"; mkdir -p "$LOG_DIR"

APIM_VER="${APIM_VER:-4.6.0}"; IS_VER="${IS_VER:-7.3.0}"; ACC_VER="${ACC_VER:-2.1.0}"
APIM_DIR="$PLATFORM_DIR/wso2am-${APIM_VER}";  IS_DIR="$PLATFORM_DIR/wso2is-${IS_VER}"
APIM_ZIP="$PLATFORM_DIR/wso2am-${APIM_VER}.zip"; IS_ZIP="$PLATFORM_DIR/wso2is-${IS_VER}.zip"
ACC_DIR="$PLATFORM_DIR/Accelerators"
APIM_ACC="wso2-hcam-accelerator-${ACC_VER}"; IS_ACC="wso2-hcis-accelerator-${ACC_VER}"

APIM_URL="https://github.com/wso2/product-apim/releases/download/v${APIM_VER}/wso2am-${APIM_VER}.zip"
IS_URL="https://github.com/wso2/product-is/releases/download/v${IS_VER}/wso2is-${IS_VER}.zip"
APIM_ACC_URL="https://github.com/wso2/healthcare-accelerator/releases/download/v${ACC_VER}/${APIM_ACC}.zip"
IS_ACC_URL="https://github.com/wso2/healthcare-accelerator/releases/download/v${ACC_VER}/${IS_ACC}.zip"

if [[ "${1:-}" == "stop" ]]; then
  echo "Stopping APIM and IS ..."
  [[ -x "$APIM_DIR/bin/api-manager.sh" ]] && "$APIM_DIR/bin/api-manager.sh" stop >/dev/null 2>&1 && echo "  APIM stop signalled"
  [[ -x "$IS_DIR/bin/wso2server.sh" ]]   && "$IS_DIR/bin/wso2server.sh" stop  >/dev/null 2>&1 && echo "  IS stop signalled"
  exit 0
fi

command -v java  >/dev/null 2>&1 || { echo "ERROR: Java not found (JDK 11/17/21 required for WSO2)." >&2; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo "ERROR: unzip not found." >&2; exit 1; }
command -v curl  >/dev/null 2>&1 || { echo "ERROR: curl not found." >&2; exit 1; }
mkdir -p "$PLATFORM_DIR" "$ACC_DIR"
echo "Installing WSO2 products into: $PLATFORM_DIR  (gitignored)"
echo "Java: $(java -version 2>&1 | head -1)"

download() { # download <url> <dest-zip>
  [[ -f "$2" ]] && { echo "  already downloaded: $(basename "$2")"; return; }
  echo "  downloading $(basename "$2") (large — first time only) ..."
  curl -fL --retry 3 -o "$2.part" "$1" && mv "$2.part" "$2" || { echo "  ERROR: download failed: $1" >&2; rm -f "$2.part"; return 1; }
}
extract() { # extract <zip> <dir> <startup-rel>
  if [[ -x "$2/$3" ]]; then echo "  already extracted: $(basename "$2")"; return; fi
  echo "  extracting $(basename "$1") ..."; ( cd "$(dirname "$2")" && unzip -q "$1" )
}
apply_accelerator() { # apply_accelerator <product_dir> <acc_name> <acc_zip_url>
  local dir="$1" acc="$2" url="$3"
  if [[ -f "$dir/hc-accelerator/merge_audit.log" ]]; then echo "  accelerator already applied: $acc"; return; fi
  if [[ ! -d "$ACC_DIR/$acc" ]]; then
    download "$url" "$ACC_DIR/$acc.zip" || return 1
    ( cd "$ACC_DIR" && unzip -q "$acc.zip" )
  fi
  echo "  applying accelerator $acc ..."
  [[ -d "$dir/$acc" ]] || cp -r "$ACC_DIR/$acc" "$dir/"
  ( cd "$dir/$acc/bin" && ./merge.sh )    # merge.sh auto-detects the product home (its parent)
}
start_server() { # start_server <dir> <startup-rel> <port> <name> <log>
  if lsof -nP -iTCP:"$3" -sTCP:LISTEN >/dev/null 2>&1; then echo "  $4 already running on :$3"; return; fi
  echo "  starting $4 ..."; ( nohup "$1/$2" >"$5" 2>&1 & )
}

echo "== WSO2 Identity Server ${IS_VER} =="
download "$IS_URL" "$IS_ZIP"
extract  "$IS_ZIP" "$IS_DIR" "bin/wso2server.sh"
apply_accelerator "$IS_DIR" "$IS_ACC" "$IS_ACC_URL"
start_server "$IS_DIR" "bin/wso2server.sh" 9453 "IS" "$LOG_DIR/wso2is.out"

echo "== WSO2 API Manager ${APIM_VER} =="
download "$APIM_URL" "$APIM_ZIP"
extract  "$APIM_ZIP" "$APIM_DIR" "bin/api-manager.sh"
apply_accelerator "$APIM_DIR" "$APIM_ACC" "$APIM_ACC_URL"
start_server "$APIM_DIR" "bin/api-manager.sh" 9443 "APIM" "$LOG_DIR/wso2am.out"

echo "Waiting for IS (:9453) and APIM (:9443/:8243) ..."
for i in $(seq 1 30); do
  is=$(curl -sk -o /dev/null -w "%{http_code}" https://localhost:9453/oauth2/token/.well-known/openid-configuration 2>/dev/null)
  am=$(curl -sk -o /dev/null -w "%{http_code}" https://localhost:9443/services/Version 2>/dev/null)
  echo "  [$((i*10))s] IS=$is APIM=$am"
  [[ "$is" == 200 && "$am" == 200 ]] && { echo ">>> platform up"; break; }
  sleep 10
done

cat <<EOF

Platform ready (products under: $PLATFORM_DIR).
  IS    : https://localhost:9453  (console /console)
  APIM  : https://localhost:9443  (portals) , https://localhost:8243 (gateway)

NOT automated (console/REST configuration — see docs):
  - IS as Key Manager for APIM : https://healthcare.docs.wso2.com/en/latest/install-and-setup/configure-km/
  - SMART on FHIR              : https://healthcare.docs.wso2.com/en/latest/secure-health-apis/guides/configure-smart-on-fhir/

Next: §5 database + integration services, §6 publish APIs, ./setup-demo-apps.sh
EOF

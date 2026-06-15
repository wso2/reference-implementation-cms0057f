#!/usr/bin/env bash
# Sets up and runs the CMS-0057-F demo applications for LOCAL use.
#
# For each demo app it:
#   1. activates the local Vite config:   vite.config.ts.local  -> vite.config.ts
#      (the committed vite.config.ts is the CLOUD default, used by Choreo/Devant;
#       vite.config.ts.local adds the dev-only auth shim + same-origin proxy)
#   2. activates the local runtime config: public/config.local.js -> public/config.js
#   3. npm install
#   4. npm run dev (background) on the app's configured port
#
# The payer-admin app is NOT a demo app — it is the payer's admin console and is
# started by ./start-services.sh instead.
#
# Usage:
#   ./setup-demo-apps.sh           # set up + start all demo apps
#   ./setup-demo-apps.sh stop      # stop the demo apps started by this script
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # repo root (this script lives in scripts/)
LOG_DIR="$ROOT/services_logs"; mkdir -p "$LOG_DIR"
PID_FILE="$LOG_DIR/demo-apps.pids"

# name:port  (port is informational; the actual port is set in each vite config)
APPS=(
  "demo-mediclaim-app:8081"   # Patient Access (SMART)
  "demo-ehr-app:5175"         # Provider Access + Prior Auth (mock EHR)
  "demo-dtr-app:5174"         # DTR
  "member-portal:3000"        # Payer-to-Payer
)

kill_tree() { local p="$1" c; for c in $(pgrep -P "$p" 2>/dev/null); do kill_tree "$c"; done; kill "$p" 2>/dev/null && echo "  stopped pid $p"; }

if [[ "${1:-}" == "stop" ]]; then
  # 1. stop the PIDs this script recorded (and their vite/esbuild children)
  if [[ -f "$PID_FILE" ]]; then
    while read -r pid; do [[ -n "$pid" ]] && kill_tree "$pid"; done < "$PID_FILE"
    rm -f "$PID_FILE"
  fi
  # 2. fallback — free each demo app's port in case a PID was stale/missing
  for entry in "${APPS[@]}"; do
    port="${entry##*:}"
    for pid in $(lsof -nP -iTCP:"$port" -sTCP:LISTEN -t 2>/dev/null); do kill_tree "$pid"; done
  done
  sleep 1
  echo "Demo app ports now:"
  for entry in "${APPS[@]}"; do
    port="${entry##*:}"
    lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1 && echo "  :$port STILL UP" || echo "  :$port free"
  done
  echo "Demo apps stopped."
  exit 0
fi

# Ensure Node >= 20 (the apps use Vite 6/7 which needs Node 20+)
ensure_node20() {
  local maj
  maj="$(command -v node >/dev/null 2>&1 && node -v 2>/dev/null | sed 's/v\([0-9]*\).*/\1/' || echo 0)"
  if [[ "${maj:-0}" -ge 20 ]]; then return; fi
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh" && nvm use 20 >/dev/null 2>&1
  maj="$(node -v 2>/dev/null | sed 's/v\([0-9]*\).*/\1/' || echo 0)"
  if [[ "${maj:-0}" -lt 20 ]]; then
    echo "ERROR: Node >= 20 is required (the demo apps use Vite 6/7). Install it (e.g. 'nvm install 20')." >&2
    exit 1
  fi
}
ensure_node20
echo "Using node $(node -v)"

: > "$PID_FILE"
for entry in "${APPS[@]}"; do
  app="${entry%%:*}"; port="${entry##*:}"
  dir="$ROOT/apps/$app"
  echo "==> $app (port $port)"
  [[ -f "$dir/vite.config.ts.local" ]] && cp "$dir/vite.config.ts.local" "$dir/vite.config.ts" && echo "    activated vite.config.ts.local"
  [[ -f "$dir/public/config.local.js" ]] && cp "$dir/public/config.local.js" "$dir/public/config.js" && echo "    activated config.local.js"
  # Plain install first (auto-installs peer deps like framer-motion); fall back to
  # --legacy-peer-deps only if it hits an ERESOLVE peer conflict (e.g. React 19 apps).
  ( cd "$dir" && ( npm install || npm install --legacy-peer-deps ) ) >"$LOG_DIR/$app-install.log" 2>&1 && echo "    npm install done" || { echo "    npm install FAILED — see $LOG_DIR/$app-install.log"; continue; }
  ( cd "$dir" && npm run dev ) >"$LOG_DIR/$app.log" 2>&1 &
  echo "$!" >> "$PID_FILE"; echo "    started (pid $!, logs: $LOG_DIR/$app.log)"
done

echo
echo "Demo apps starting. URLs:"
echo "  Patient Access   (mediclaim) : http://localhost:8081"
echo "  Provider/PriorAuth (ehr)     : http://localhost:5175"
echo "  DTR                          : http://localhost:5174  (launched from the EHR card)"
echo "  Payer-to-Payer (member)      : http://localhost:3000"
echo "Stop them with: ./setup-demo-apps.sh stop"

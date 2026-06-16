#!/usr/bin/env bash
# Stops the Ballerina services started by ./start-services.sh.
#
# It kills the PIDs recorded in services_logs/service.pids (and their child
# JVMs). Use --all to also stop any other repo 'bal run' processes (e.g. demo
# backends started manually) as a catch-all.
#
# Usage:
#   ./stop-services.sh          # stop services recorded by start-services.sh
#   ./stop-services.sh --all    # also pkill any remaining 'bal run' processes
set -uo pipefail

# This script lives in scripts/ but uses paths relative to the repo root — cd there.
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

LOG_DIR="./services_logs"
PID_FILE="$LOG_DIR/service.pids"

# Recursively kill a process and all of its descendants (children first).
kill_tree() {
  local pid="$1"
  local child
  for child in $(pgrep -P "$pid" 2>/dev/null); do
    kill_tree "$child"
  done
  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null && echo "  stopped pid $pid"
  fi
}

stopped_any=false
if [[ -f "$PID_FILE" ]]; then
  echo "Stopping services from $PID_FILE ..."
  while read -r pid; do
    [[ -z "$pid" ]] && continue
    kill_tree "$pid"
    stopped_any=true
  done < "$PID_FILE"
  rm -f "$PID_FILE"
else
  echo "No $PID_FILE found (services may not have been started via start-services.sh)."
fi

if [[ "${1:-}" == "--all" ]]; then
  echo "Catch-all: stopping any remaining 'bal run' processes ..."
  pkill -f 'bal run' 2>/dev/null && echo "  sent SIGTERM to lingering 'bal run' processes" || true
  stopped_any=true
fi

# Give the JVMs a moment, then report any integration-service ports still bound.
sleep 2
echo "Port check (should all be free):"
for p in 8080 8090 8091 8100 9096 9097 5173; do
  if lsof -nP -iTCP:"$p" -sTCP:LISTEN >/dev/null 2>&1; then
    echo "  :$p STILL LISTENING — re-run with --all or kill manually"
  else
    echo "  :$p free"
  fi
done

$stopped_any && echo "Done." || echo "Nothing to stop."

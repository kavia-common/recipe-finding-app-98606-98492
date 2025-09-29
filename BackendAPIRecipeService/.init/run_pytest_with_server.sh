#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService"
cd "$WORKSPACE"
VENV="$WORKSPACE/.venv"
# activate venv
# shellcheck source=/dev/null
source "$VENV/bin/activate"
PORT=${PORT:-8000}
LOG_LEVEL=${LOG_LEVEL:-debug}
READY_TIMEOUT=${READY_TIMEOUT:-30}
mkdir -p "$WORKSPACE/.logs" "$WORKSPACE/.tmp"
LOGFILE="$WORKSPACE/.logs/uvicorn-test-$(date +%s).log"
# start uvicorn via venv python to ensure same interpreter
setsid python3 -m uvicorn main:app --host 0.0.0.0 --port "$PORT" --log-level "$LOG_LEVEL" >"$LOGFILE" 2>&1 &
PID=$!
trap 'if kill -0 $PID >/dev/null 2>&1; then kill -TERM "$PID" >/dev/null 2>&1 || true; wait "$PID" || true; fi; ' EXIT
# readiness probe
READY=0
for i in $(seq 1 "$READY_TIMEOUT"); do
  if curl -sS --fail "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1; then READY=1; break; fi
  sleep 1
done
if [ "$READY" -ne 1 ]; then
  echo "server failed to become ready; logs:" >&2; tail -n 200 "$LOGFILE" >&2; exit 6
fi
# run pytest
export PORT
pytest -q || { echo 'pytest failed'; tail -n 200 "$LOGFILE" >&2; kill -TERM "$PID" >/dev/null 2>&1 || true; wait "$PID" || true; exit 7; }
# shutdown and wait
kill -TERM "$PID" >/dev/null 2>&1 || true
wait "$PID" || true
# ensure port freed
for i in $(seq 1 10); do ss -ltn "sport = :$PORT" | grep -q LISTEN || break; sleep 1; done

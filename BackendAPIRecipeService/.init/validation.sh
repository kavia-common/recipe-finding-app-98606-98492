#!/usr/bin/env bash
set -euo pipefail
# validation script for validate_build_and_run
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService"
cd "$WORKSPACE"
PYTHON="$WORKSPACE/venv/bin/python"
[ -x "$PYTHON" ] || { echo "venv python missing" >&2; exit 2; }
# quick import check
"$PYTHON" -c "import fastapi, httpx, PIL" >/dev/null 2>&1 || { echo "Import check failed" >&2; exit 3; }
PORT="${PORT:-8000}"
PIDFILE="${PIDFILE:-$WORKSPACE/.uvicorn.pid}"
LOGFILE="${LOGFILE:-$WORKSPACE/.uvicorn.log}"
# clear stale pidfile if any and ensure port not in use
if [ -f "$PIDFILE" ]; then
  OLDPID=$(cat "$PIDFILE" 2>/dev/null || true)
  if [ -n "$OLDPID" ] && kill -0 "$OLDPID" >/dev/null 2>&1; then
    echo "Port/process appears in use (pid $OLDPID)" >&2
    exit 4
  else
    rm -f "$PIDFILE"
  fi
fi
# launch server via run script; ensure environment vars are exported for child
PIDFILE_ENV="PIDFILE=$PIDFILE"
LOGFILE_ENV="LOGFILE=$LOGFILE"
PORT_ENV="PORT=$PORT"
# start in background
env "$PIDFILE_ENV" "$LOGFILE_ENV" "$PORT_ENV" "$WORKSPACE/run_uvicorn.sh" &
# wait up to 20s for pidfile
UV_PID=""
for i in {1..20}; do
  if [ -f "$PIDFILE" ]; then
    UV_PID=$(cat "$PIDFILE" 2>/dev/null || true)
    break
  fi
  sleep 1
done
if [ -z "${UV_PID}" ]; then
  echo "pidfile not created; server may have failed to start" >&2
  [ -f "$LOGFILE" ] && sed -n '1,200p' "$LOGFILE" >&2 || true
  exit 5
fi
# wait for readiness (max 20s)
READY=1
for i in {1..20}; do
  if curl -sS --fail "http://127.0.0.1:$PORT/health" -o "$WORKSPACE/.health_resp.json" 2>/dev/null; then
    READY=0; break
  fi
  if ! kill -0 "$UV_PID" >/dev/null 2>&1; then
    echo "uvicorn process terminated prematurely" >&2
    [ -f "$LOGFILE" ] && sed -n '1,200p' "$LOGFILE" >&2 || true
    exit 6
  fi
  sleep 1
done
if [ $READY -ne 0 ]; then
  echo "Server did not become ready" >&2
  exit 7
fi
# validate JSON response with venv python -c (avoid fragile heredoc quoting)
if ! "$PYTHON" -c "import sys,json
try:
  d=json.load(open('$WORKSPACE/.health_resp.json'))
except Exception:
  sys.exit(2)
if d.get('status')!='ok':
  sys.exit(3)
"; then
  echo "Health check returned unexpected data" >&2
  exit 8
fi
# success evidence
echo "validation: ok" > "$WORKSPACE/validation_evidence.txt"
# Stop server gracefully
if kill -0 "$UV_PID" >/dev/null 2>&1; then
  kill "$UV_PID" || true
  for i in 1 2 3 4 5; do
    if ! kill -0 "$UV_PID" >/dev/null 2>&1; then break; fi
    sleep 1
  done
  if kill -0 "$UV_PID" >/dev/null 2>&1; then
    kill -9 "$UV_PID" || true
  fi
fi
rm -f "$PIDFILE"
exit 0

#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService"
cd "$WORKSPACE"
LOG="$WORKSPACE/validation.log"
PIDFILE="$WORKSPACE/validation.pid"
# Default port can be overridden by environment
DEFAULT_PORT=${VALIDATION_PORT-8000}
# Check if DEFAULT_PORT free; if not, choose ephemeral
is_port_in_use(){ ss -ltn 2>/dev/null | awk '{print $4}' | grep -E "(:|\])${1}$" >/dev/null 2>&1; }
PORT=$DEFAULT_PORT
if is_port_in_use $PORT; then
  PORT=$(python3 - <<PY
import socket
s=socket.socket()
s.bind(('127.0.0.1',0))
port=s.getsockname()[1]
s.close()
print(port)
PY
)
  echo "INFO: port ${DEFAULT_PORT} in use; falling back to ephemeral port ${PORT}" >>"$LOG"
fi
# Ensure deps installed (idempotent) - reuse earlier install log if exists
if [ ! -f "$WORKSPACE/requirements-install.log" ]; then
  python3 -m pip install --user --upgrade -r "$WORKSPACE/requirements.txt" 2>&1 | tee "$WORKSPACE/requirements-install.log" || true
fi
# Ensure PYTHONPATH
export PYTHONPATH="$WORKSPACE:${PYTHONPATH-}"
# Start uvicorn in background capturing logs
setsid python3 -m uvicorn app.main:app --host 0.0.0.0 --port ${PORT} >>"$LOG" 2>&1 &
PID=$!
echo "$PID" > "$PIDFILE"
# cleanup similar to tests: kill pid and discovered children
cleanup(){
  if [ -f "$PIDFILE" ]; then
    SERVER_PID=$(cat "$PIDFILE" 2>/dev/null || true)
    if [ -n "$SERVER_PID" ]; then
      CHILD_PIDS=$(pgrep -P "$SERVER_PID" || true)
      for cp in $CHILD_PIDS; do
        kill -TERM "$cp" >/dev/null 2>&1 || true
      done
      kill -TERM "$SERVER_PID" >/dev/null 2>&1 || true
      sleep 1
      for cp in $CHILD_PIDS; do
        kill -KILL "$cp" >/dev/null 2>&1 || true
      done
      kill -KILL "$SERVER_PID" >/dev/null 2>&1 || true
    fi
    rm -f "$PIDFILE"
  fi
}
trap cleanup EXIT
# Poll for readiness
HTTP_STATUS=000
for i in {1..20}; do
  HTTP_STATUS=$(curl -sS -o /dev/null -w "%{http_code}" --max-time 2 http://127.0.0.1:${PORT}/health || echo 000)
  if [ "$HTTP_STATUS" = "200" ]; then
    break
  fi
  sleep 1
  if [ $i -eq 20 ]; then
    echo "ERROR: validation server not ready; last status=$HTTP_STATUS" | tee -a "$LOG"
    tail -n +1 "$LOG" || true
    exit 1
  fi
done
echo "health_status: $HTTP_STATUS" >> "$LOG"
# prepare deterministic upload file
mkdir -p "$WORKSPACE/tmp_uploads"
echo -n "dummy-image-content" > "$WORKSPACE/tmp_uploads/test_tomato.jpg"
UPLOAD_RESP=$(curl -sS -w "HTTPSTATUS:%{http_code}" -F "file=@$WORKSPACE/tmp_uploads/test_tomato.jpg" http://127.0.0.1:${PORT}/upload || true)
echo "upload_response: $UPLOAD_RESP" >> "$LOG"
# Print evidence
cat "$LOG"
# cleanup triggered by trap

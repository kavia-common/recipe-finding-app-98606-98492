#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService"
cd "$WORKSPACE"
# pick ephemeral port
PORT=$(python3 - <<PY
import socket
s=socket.socket()
s.bind(('127.0.0.1',0))
port=s.getsockname()[1]
s.close()
print(port)
PY
)
mkdir -p tests
cat > "$WORKSPACE/tests/test_health.py" <<PY
import os
import requests

def test_health():
    port = int(os.environ.get('TEST_SERVER_PORT', '${PORT}'))
    r = requests.get(f'http://127.0.0.1:{port}/health', timeout=5)
    assert r.status_code == 200
    assert r.json().get('status') == 'ok'
PY
LOG="$WORKSPACE/test_uvicorn.log"
PIDFILE="$WORKSPACE/test_uvicorn.pid"
export PYTHONPATH="$WORKSPACE:${PYTHONPATH-}"
setsid python3 -m uvicorn app.main:app --host 127.0.0.1 --port ${PORT} >>"$LOG" 2>&1 &
PID=$!
echo "$PID" > "$PIDFILE"
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
for i in {1..20}; do
  if curl -sS --max-time 1 "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1; then
    break
  fi
  sleep 1
  if [ $i -eq 20 ]; then
    echo "ERROR: server not ready after timeout" >&2
    sed -n '1,200p' "$LOG" || true
    exit 1
  fi
done
TEST_SERVER_PORT=${PORT} pytest -q --maxfail=1 tests/test_health.py

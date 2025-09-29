#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService"
# source authoritative workspace env if present
if [ -f "$WORKSPACE/.workspace.env" ]; then source "$WORKSPACE/.workspace.env"; fi
WORKSPACE="${BACKEND_API_RECIPE_SERVICE_WORKSPACE:-$WORKSPACE}"
cd "$WORKSPACE"
VENV="$WORKSPACE/.venv"
PYTHON="$VENV/bin/python"
[ -x "$PYTHON" ] || { echo 'venv python missing' >&2; exit 8; }
[ -f run.py ] || { echo 'run.py missing' >&2; exit 9; }
PORT=6060
LOGFILE="$WORKSPACE/validation_server.log"
LAUNCHER="$WORKSPACE/_server_launcher.sh"
# create launcher
cat > "$LAUNCHER" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
export PORT="${PORT}"
export DISABLE_RELOADER="${DISABLE_RELOADER:-1}"
exec "${PYTHON_BIN}" run.py
SH
PYTHON_BIN_ESCAPED=$(printf '%s' "$PYTHON" | sed 's|/|\/|g')
sed -i "s|\$\{PYTHON_BIN\}|$PYTHON_BIN_ESCAPED|g" "$LAUNCHER" || true
chmod +x "$LAUNCHER"
# start
DISABLE_RELOADER=1 nohup "$LAUNCHER" >"$LOGFILE" 2>&1 &
PID=$!
sleep 1
if [ -d "/proc/$PID" ]; then
  CMDLINE=$(tr '\0' ' ' < "/proc/$PID/cmdline" 2>/dev/null || true)
else
  CMDLINE=''
fi
if [[ -z "$CMDLINE" || "$CMDLINE" != *run.py* ]]; then
  echo "validation: started pid $PID but process not running or not run.py; log excerpt:" >&2
  head -n 200 "$LOGFILE" || true
  exit 10
fi
# wait for /health
TRIES=15
SLEEP=1
SUCCESS=0
for i in $(seq 1 $TRIES); do
  if curl -sS --max-time 2 "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then
    SUCCESS=1
    break
  fi
  sleep $SLEEP
done
if [ "$SUCCESS" -ne 1 ]; then
  echo "validation failed: server did not respond on port $PORT; log excerpt:" >&2
  head -n 200 "$LOGFILE" || true
  # attempt graceful shutdown
  if [ -d "/proc/$PID" ]; then kill -TERM "$PID" 2>/dev/null || true; sleep 1; fi
  if [ -d "/proc/$PID" ]; then kill -KILL "$PID" 2>/dev/null || true; fi
  exit 11
fi
RESP=$(curl -sS --max-time 5 "http://127.0.0.1:$PORT/health") || true
echo "validation_response=$RESP"
# graceful shutdown
if [ -d "/proc/$PID" ]; then
  kill -TERM "$PID" 2>/dev/null || true
  for i in $(seq 1 10); do
    if kill -0 "$PID" 2>/dev/null; then sleep 0.5; else break; fi
  done
  if kill -0 "$PID" 2>/dev/null; then kill -KILL "$PID" 2>/dev/null || true; fi
fi
# save evidence
echo "--- server log tail ---"
tail -n 200 "$LOGFILE" || true
exit 0

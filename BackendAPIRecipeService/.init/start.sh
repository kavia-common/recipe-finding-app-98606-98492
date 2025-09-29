#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService"
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
# create launcher that exports env and execs python
cat > "$LAUNCHER" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
export PORT="${PORT}"
export DISABLE_RELOADER="${DISABLE_RELOADER:-1}"
exec "${PYTHON_BIN}" run.py
SH
# replace placeholder PORT token inside generated file (literal ${PORT} was used)
# ensure PYTHON path is injected
PYTHON_BIN_ESCAPED=$(printf '%s' "$PYTHON" | sed 's|/|\/|g')
# Inject python path; if ${PORT} remains literal it will be expanded by launcher at runtime
sed -i "s|\$\{PYTHON_BIN\}|$PYTHON_BIN_ESCAPED|g" "$LAUNCHER" || true
chmod +x "$LAUNCHER"
# start launcher via nohup to background with DISABLE_RELOADER enforced
DISABLE_RELOADER=1 nohup "$LAUNCHER" >"$LOGFILE" 2>&1 &
PID=$!
# brief wait to let process start
sleep 1
# verify started process cmdline includes run.py
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
# record PID to file for stop script
echo "$PID" > "$WORKSPACE/validation.pid"
exit 0

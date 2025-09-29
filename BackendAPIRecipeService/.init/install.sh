#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService"
cd "$WORKSPACE"
PY_BIN="$(command -v python3)"
if [ -z "$PY_BIN" ]; then
  echo "ERROR: python3 not found" >&2
  exit 1
fi
REQUIREMENTS="$WORKSPACE/requirements.txt"
LOG="$WORKSPACE/requirements-install.log"
REQUIRED_UV_VER="0.22.0"
TARGET_USER="${SUDO_USER:-$(id -un)}"
TARGET_HOME=""
if getent passwd "$TARGET_USER" >/dev/null 2>&1; then
  TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
fi
USE_USER_FLAG=0
if [ -n "$TARGET_HOME" ] && [ "$TARGET_USER" != "root" ]; then
  USE_USER_FLAG=1
fi
if [ $USE_USER_FLAG -eq 1 ]; then
  "$PY_BIN" -m pip install --user --upgrade -r "$REQUIREMENTS" 2>&1 | tee "$LOG"
else
  sudo "$PY_BIN" -m pip install --upgrade -r "$REQUIREMENTS" 2>&1 | tee "$LOG"
fi
# uvicorn version check
"$PY_BIN" - <<PY
import sys
from importlib import metadata
from packaging.version import parse as vparse
req = "${REQUIRED_UV_VER}"
try:
    ver = metadata.version('uvicorn')
except Exception:
    ver = None
if ver is None:
    sys.exit(2)
try:
    if vparse(ver) < vparse(req):
        sys.exit(3)
except Exception:
    sys.exit(3)
else:
    sys.exit(0)
PY
RET=$?
if [ $RET -eq 2 ] || [ $RET -eq 3 ]; then
  if [ $USE_USER_FLAG -eq 1 ]; then
    "$PY_BIN" -m pip install --user --upgrade "uvicorn==${REQUIRED_UV_VER}" 2>&1 | tee -a "$LOG"
  else
    sudo "$PY_BIN" -m pip install --upgrade "uvicorn==${REQUIRED_UV_VER}" 2>&1 | tee -a "$LOG"
  fi
fi
# verify imports
"$PY_BIN" - <<'PY'
import sys
missing=[]
for m in ('fastapi','uvicorn','dotenv','pytest','requests','packaging'):
    try:
        __import__(m)
    except Exception:
        missing.append(m)
if missing:
    print('ERROR: missing modules: %s' % ','.join(missing), file=sys.stderr)
    sys.exit(1)
print('OK')
PY

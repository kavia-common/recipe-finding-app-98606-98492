#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService"
cd "$WORKSPACE"
VENV="$WORKSPACE/.venv"
mkdir -p "$WORKSPACE/.logs" "$WORKSPACE/.tmp"
if [ ! -d "$VENV" ]; then python3 -m venv "$VENV"; fi
# shellcheck source=/dev/null
source "$VENV/bin/activate"
PIP_BIN="$VENV/bin/pip"
PIP_LOG="$WORKSPACE/.logs/pip-install-$(date +%s).log"
# Ensure pip binary exists
if [ ! -x "$PIP_BIN" ]; then echo "pip not found in venv ($PIP_BIN)" >&2; exit 2; fi
# Check pip major.minor and upgrade only when below 23.0
PIP_VER=$($PIP_BIN --version 2>/dev/null | awk '{print $2}' || echo "0")
PIP_MAJOR=$(echo "$PIP_VER" | cut -d. -f1 || echo 0)
PIP_MINOR=$(echo "$PIP_VER" | cut -d. -f2 || echo 0)
if [ "${PIP_MAJOR:-0}" -lt 23 ]; then
  $PIP_BIN install --upgrade pip >"$PIP_LOG" 2>&1 || { echo "pip upgrade failed; see $PIP_LOG" >&2; exit 3; }
fi
# Install requirements into venv, capture logs
TMP_REQ=$(mktemp -p "$WORKSPACE/.tmp")
cp requirements.txt "$TMP_REQ"
$PIP_BIN install -r "$TMP_REQ" >"$PIP_LOG" 2>&1 || { echo "pip install failed; see $PIP_LOG" >&2; tail -n 200 "$PIP_LOG" >&2; exit 4; }
rm -f "$TMP_REQ"
# Validate key imports using venv python
"$VENV/bin/python3" - <<'PY'
import sys
try:
    import fastapi, typing_extensions, PIL, requests
except Exception as e:
    print('post-install import check failed:', e, file=sys.stderr)
    sys.exit(5)
print('dependencies OK')
PY

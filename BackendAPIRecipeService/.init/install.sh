#!/usr/bin/env bash
set -euo pipefail
# source authoritative workspace
WORKSPACE_DEFAULT="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService"
# shellcheck disable=SC1090
if [ -f "$WORKSPACE_DEFAULT/.workspace.env" ]; then source "$WORKSPACE_DEFAULT/.workspace.env"; fi
WORKSPACE="${BACKEND_API_RECIPE_SERVICE_WORKSPACE:-$WORKSPACE_DEFAULT}"
VENV="$WORKSPACE/.venv"
cd "$WORKSPACE"
# ensure python3 venv support
python3 -m venv --help >/dev/null 2>&1 || { echo "python3 venv support missing; install python3-venv" >&2; exit 12; }
# create venv if missing
if [ ! -d "$VENV" ]; then python3 -m venv "$VENV"; fi
# verify venv executables
PY="$VENV/bin/python"
PIP="$VENV/bin/pip"
[ -x "$PY" ] || { echo "venv python missing at $PY" >&2; exit 13; }
[ -x "$PIP" ] || { echo "venv pip missing at $PIP" >&2; exit 14; }
# upgrade pip in venv (non-interactive)
"$PIP" install --disable-pip-version-check --no-input --upgrade pip >"$WORKSPACE/pip_upgrade.log" 2>&1 || { echo "pip upgrade failed, see $WORKSPACE/pip_upgrade.log" >&2; exit 4; }
# install requirements
if [ -f requirements.txt ]; then
  "$PIP" install --disable-pip-version-check --no-input -r requirements.txt >"$WORKSPACE/pip_install.log" 2>&1 || { echo "pip install failed, see $WORKSPACE/pip_install.log" >&2; exit 5; }
else
  "$PIP" install --disable-pip-version-check --no-input flask requests Pillow python-dotenv pytest >"$WORKSPACE/pip_install.log" 2>&1 || { echo "pip install failed, see $WORKSPACE/pip_install.log" >&2; exit 5; }
fi
# record installed packages and global flask info for troubleshooting
"$PIP" freeze >"$WORKSPACE/pip_freeze.log" 2>/dev/null || true
python3 -m pip show flask >"$WORKSPACE/global_flask_info.log" 2>/dev/null || true
# verify imports; fail if any missing
"$PY" - <<'PY'
import sys, importlib
mods = {'flask':'flask','requests':'requests','Pillow':'PIL','dotenv':'dotenv','pytest':'pytest'}
missing = []
for name,modname in mods.items():
    try:
        importlib.import_module(modname)
    except Exception as e:
        print('MISSING', name, modname, e, file=sys.stderr)
        missing.append(name)
if missing:
    sys.exit(6)
print('packages_ok')
PY
exit 0

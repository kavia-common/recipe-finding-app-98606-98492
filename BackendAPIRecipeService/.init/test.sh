#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService"
if [ -f "$WORKSPACE/.workspace.env" ]; then source "$WORKSPACE/.workspace.env"; fi
WORKSPACE="${BACKEND_API_RECIPE_SERVICE_WORKSPACE:-$WORKSPACE}"
cd "$WORKSPACE"
VENV="$WORKSPACE/.venv"
PYTHON="$VENV/bin/python"
[ -x "$PYTHON" ] || { echo 'venv python missing' >&2; exit 8; }
# run pytest with PYTHONPATH set to workspace so src imports resolve
PYTHONPATH="$WORKSPACE" "$PYTHON" -m pytest -q || { echo 'tests failed' >&2; exit 13; }
exit 0

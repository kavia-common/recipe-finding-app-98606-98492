#!/usr/bin/env bash
set -euo pipefail
# Build step: compile python modules to verify syntax
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService"
# source authoritative workspace env if present
if [ -f "$WORKSPACE/.workspace.env" ]; then source "$WORKSPACE/.workspace.env"; fi
WORKSPACE="${BACKEND_API_RECIPE_SERVICE_WORKSPACE:-$WORKSPACE}"
cd "$WORKSPACE"
VENV="$WORKSPACE/.venv"
PYTHON="$VENV/bin/python"
[ -x "$PYTHON" ] || { echo 'venv python missing' >&2; exit 8; }
# compile src/ to detect syntax errors
mkdir -p "$WORKSPACE"
$PYTHON -m py_compile $(find src -name '*.py' 2>/dev/null) > "$WORKSPACE/compile.log" 2>&1 || { echo 'python compile failed; see compile.log' >&2; tail -n 200 "$WORKSPACE/compile.log" || true; exit 12; }
exit 0

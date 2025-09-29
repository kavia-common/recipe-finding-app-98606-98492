#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${WORKSPACE:-/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService}"
cd "$WORKSPACE"
VENV_PY="$WORKSPACE/venv/bin/python"
[ -x "$VENV_PY" ] || { echo "venv python not found" >&2; exit 2; }
PIP_CMD=("$VENV_PY" -m pip)
LOGFILE="$WORKSPACE/.pip_install.log"
# upgrade pip tooling and install from canonical requirements
"${PIP_CMD[@]}" install --upgrade pip setuptools wheel >"$LOGFILE" 2>&1 || { echo "pip upgrade failed (see $LOGFILE)" >&2; sed -n '1,200p' "$LOGFILE" >&2; exit 3; }
"${PIP_CMD[@]}" install -r requirements.txt >>"$LOGFILE" 2>&1 || { echo "pip install failed (see $LOGFILE)" >&2; sed -n '1,200p' "$LOGFILE" >&2; exit 4; }
if [ "${ENABLE_SQLALCHEMY:-0}" -eq 1 ]; then
  "${PIP_CMD[@]}" install sqlalchemy >>"$LOGFILE" 2>&1 || { echo "sqlalchemy install failed (see $LOGFILE)" >&2; sed -n '1,200p' "$LOGFILE" >&2; exit 5; }
fi
# Verify runtime imports strictly
"$VENV_PY" -c "import fastapi, httpx, PIL" >/dev/null 2>&1 || { echo "Runtime dependency check failed" >&2; sed -n '1,200p' "$LOGFILE" >&2; exit 6; }
# Verify test deps strictly (fail if missing)
"$VENV_PY" -c "import pytest, pytest_asyncio" >/dev/null 2>&1 || { echo "Test dependencies missing (pytest/pytest-asyncio)" >&2; sed -n '1,200p' "$LOGFILE" >&2; exit 7; }
# Ensure venv uvicorn exists and matches pinned version
VENV_UV="$WORKSPACE/venv/bin/uvicorn"
if [ ! -x "$VENV_UV" ]; then
  echo "venv uvicorn missing; failing to avoid accidental use of system uvicorn" >&2
  sed -n '1,200p' "$LOGFILE" >&2 || true
  exit 8
fi
UVVER=$("$VENV_UV" --version 2>&1 || true)
if [[ "$UVVER" != *"0.22.0"* ]]; then
  echo "venv uvicorn version mismatch: $UVVER (expected 0.22.0)" >&2
  sed -n '1,200p' "$LOGFILE" >&2 || true
  exit 9
fi

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
PORT="${PORT:-8000}"
PIDFILE="${PIDFILE:-}"   # optional
LOGFILE="${LOGFILE:-}"   # optional
VENV_UV="$ROOT/venv/bin/uvicorn"
# prefer venv uvicorn; if missing, warn and fallback to system uvicorn
if [ -x "$VENV_UV" ]; then
  UV_BIN="$VENV_UV"
else
  if command -v uvicorn >/dev/null 2>&1; then
    echo "warning: using system uvicorn; consider creating venv to use venv/bin/uvicorn" >&2
    UV_BIN="uvicorn"
  else
    echo "uvicorn not found (neither venv/bin/uvicorn nor system uvicorn)" >&2
    exit 2
  fi
fi
# if venv uvicorn exists, verify version roughly matches expected
if [ -x "$VENV_UV" ]; then
  VVER=$("$VENV_UV" --version 2>&1 || true)
  case "$VVER" in
    *0.22.0*) ;;
    *) echo "warning: venv uvicorn version appears different: $VVER" >&2 ;;
  esac
fi
CMD=("$UV_BIN" app.main:app --host 0.0.0.0 --port "$PORT" --lifespan=on)
[ -n "$PIDFILE" ] && CMD+=(--pidfile "$PIDFILE")
if [ -n "$LOGFILE" ]; then
  exec "${CMD[@]}" >>"$LOGFILE" 2>&1
else
  exec "${CMD[@]}"
fi

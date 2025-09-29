#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${WORKSPACE:-/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService}"
cd "$WORKSPACE"
mkdir -p "$WORKSPACE/app" "$WORKSPACE/tmp_uploads" "$WORKSPACE/tests"
# Minimal FastAPI app
cat > "$WORKSPACE/app/main.py" <<'PY'
from fastapi import FastAPI
app = FastAPI()
@app.get('/health')
async def health():
    return {'status':'ok'}
PY
# Pinned requirements (explicit uvicorn without extras to avoid extras parsing ambiguity)
cat > "$WORKSPACE/requirements.txt" <<'REQ'
fastapi==0.100.0
uvicorn==0.22.0
httpx==0.25.0
pillow==10.0.0
pytest==7.4.0
pytest-asyncio==0.22.0
REQ
# .env template
cat > "$WORKSPACE/.env" <<'ENV'
# API keys for external recipe services
RECIPE_API_KEY=
ENV
# .gitignore (match actual artifact filenames created by scripts)
cat > "$WORKSPACE/.gitignore" <<'GI'
venv/
__pycache__/
*.pyc
tmp_uploads/
validation_evidence.txt
.pip_install.log
.uvicorn.log
GI
# Create portable run script accepting PIDFILE/LOGFILE; prefer venv uvicorn
cat > "$WORKSPACE/run_uvicorn.sh" <<'SH'
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
SH
chmod +x "$WORKSPACE/run_uvicorn.sh"

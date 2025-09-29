#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="${WORKSPACE:-/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService}"
cd "$WORKSPACE"
PYTEST_BIN="$WORKSPACE/venv/bin/pytest"
LOGFILE="$WORKSPACE/.pip_install.log"
mkdir -p "$WORKSPACE/tests"
cat > "$WORKSPACE/tests/test_health_async.py" <<'PY'
import pytest
from httpx import AsyncClient
from app.main import app

@pytest.mark.asyncio
async def test_health_async():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        r = await ac.get('/health')
        assert r.status_code == 200
        data = r.json()
        assert data.get('status') == 'ok'
PY

# run pytest using venv's pytest
if [ ! -x "$PYTEST_BIN" ]; then
  echo "ERROR: pytest binary not found at $PYTEST_BIN" >&2
  echo "Ensure the venv is created and dependencies are installed (step deps-003)." >&2
  exit 2
fi

# Run pytest quietly; on failure dump pip install log for debugging
if ! "$PYTEST_BIN" -q; then
  echo "pytest failed; dumping $LOGFILE" >&2
  [ -f "$LOGFILE" ] && sed -n '1,200p' "$LOGFILE" >&2 || true
  exit 1
fi

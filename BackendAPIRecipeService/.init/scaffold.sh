#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService"
mkdir -p "$WORKSPACE" && cd "$WORKSPACE"
cat > "$WORKSPACE/requirements.txt" <<'REQ'
fastapi>=0.95,<1.0
uvicorn>=0.22,<1.0
pillow>=9.0
typing-extensions>=4.0
requests>=2.0
pytest>=7.0
REQ
# minimal app
cat > "$WORKSPACE/main.py" <<'PY'
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
import os, uuid
from pathlib import Path
app = FastAPI()
WORKSPACE = os.path.dirname(__file__)
UPLOAD_DIR = Path(WORKSPACE) / 'uploads'
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
cache = {}
@app.get('/health')
async def health():
    return {'status':'ok'}
@app.post('/upload-image')
async def upload_image(file: UploadFile = File(...)):
    if not file.filename:
        raise HTTPException(status_code=400, detail='missing filename')
    dest = UPLOAD_DIR / (str(uuid.uuid4()) + '_' + os.path.basename(file.filename))
    with dest.open('wb') as f:
        contents = await file.read()
        f.write(contents)
    cache_key = dest.name
    cache[cache_key] = {'path': str(dest)}
    return {'id': cache_key, 'filename': file.filename}
@app.get('/recipe/{image_id}')
async def recipe_lookup(image_id: str):
    info = cache.get(image_id)
    if not info:
        raise HTTPException(status_code=404, detail='image not found')
    return JSONResponse({'image_id': image_id, 'recipes': ['Recipe A','Recipe B'], 'source': info['path']})
PY
# tests
mkdir -p "$WORKSPACE/tests"
cat > "$WORKSPACE/tests/test_health.py" <<'PYT'
import os, requests

def test_health():
    port = os.environ.get('PORT','8000')
    url = f'http://127.0.0.1:{port}/health'
    r = requests.get(url, timeout=5)
    assert r.status_code == 200
    assert r.json().get('status') == 'ok'
PYT
cat > "$WORKSPACE/.gitignore" <<'GIT'
__pycache__/
uploads/
.env
.venv/
GIT
cat > "$WORKSPACE/.env.example" <<'ENV'
PORT=8000
LOG_LEVEL=debug
MODEL_PATH=/opt/models/weights.pt
ENV
cat > "$WORKSPACE/README.md" <<'RD'
Dev scaffold. Create and activate venv: python3 -m venv .venv && source .venv/bin/activate
Install deps: pip install -r requirements.txt
Run: python -m uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}
RD
sudo chown -R "$(id -u):$(id -g)" "$WORKSPACE" || true

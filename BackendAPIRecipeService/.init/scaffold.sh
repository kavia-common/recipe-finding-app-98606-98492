#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService"
cd "$WORKSPACE"
mkdir -p "$WORKSPACE/app" "$WORKSPACE/tmp_uploads" "$WORKSPACE/tests"
cat > "$WORKSPACE/requirements.txt" <<'REQ'
fastapi==0.100.0
uvicorn==0.22.0
python-dotenv==1.0.0
pytest==7.4.0
requests==2.31.0
packaging==23.1
REQ
cat > "$WORKSPACE/.env.example" <<'ENV'
FASTAPI_ENV=development
SECRET_KEY=dev-secret
UPLOAD_DIR=./tmp_uploads
ENV
cat > "$WORKSPACE/.env" <<'ENV'
FASTAPI_ENV=development
SECRET_KEY=dev-secret
UPLOAD_DIR=./tmp_uploads
ENV
cat > "$WORKSPACE/app/__init__.py" <<'PY'
# app package
PY
cat > "$WORKSPACE/app/main.py" <<'PY'
from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
from pathlib import Path
import os
from .recognition import recognize_image
from dotenv import load_dotenv
load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '.env'))
UPLOAD_DIR = Path(os.getenv('UPLOAD_DIR', './tmp_uploads'))
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
app = FastAPI()
@app.get('/health')
async def health():
    return {"status": "ok"}
@app.post('/upload')
async def upload_image(file: UploadFile = File(...)):
    dest = UPLOAD_DIR / file.filename
    with dest.open('wb') as f:
        f.write(await file.read())
    labels = recognize_image(str(dest))
    return JSONResponse({"filename": file.filename, "labels": labels})
PY
cat > "$WORKSPACE/app/recognition.py" <<'PY'
from typing import List

def recognize_image(path: str) -> List[str]:
    filename = path.lower()
    labels = []
    if 'tomato' in filename: labels.append('tomato')
    if 'cheese' in filename: labels.append('cheese')
    if not labels: labels = ['unknown']
    return labels
PY
cat > "$WORKSPACE/README.md" <<'MD'
Minimal FastAPI app. To run (headless): python3 -m uvicorn app.main:app --host 0.0.0.0 --port 8000
Tests: pytest tests/test_health.py
MD

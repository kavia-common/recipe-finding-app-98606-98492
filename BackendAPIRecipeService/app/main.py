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

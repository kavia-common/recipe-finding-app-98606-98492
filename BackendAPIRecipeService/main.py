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

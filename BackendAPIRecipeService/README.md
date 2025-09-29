Dev scaffold. Create and activate venv: python3 -m venv .venv && source .venv/bin/activate
Install deps: pip install -r requirements.txt
Run: python -m uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}

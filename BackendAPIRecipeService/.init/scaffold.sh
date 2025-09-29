#!/usr/bin/env bash
set -euo pipefail
# ensure authoritative workspace
WORKSPACE_DEFAULT="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService"
if [ -f "$WORKSPACE_DEFAULT/.workspace.env" ]; then
  # prefer explicit workspace file
  # shellcheck disable=SC1090
  source "$WORKSPACE_DEFAULT/.workspace.env"
fi
WORKSPACE="${BACKEND_API_RECIPE_SERVICE_WORKSPACE:-$WORKSPACE_DEFAULT}"
mkdir -p "$WORKSPACE" && cd "$WORKSPACE"
mkdir -p src && cat > src/__init__.py <<'PY'
from flask import Flask

def create_app():
    app = Flask(__name__)
    from . import routes
    app.register_blueprint(routes.bp)
    return app
PY
cat > src/routes.py <<'PY'
from flask import Blueprint, jsonify
bp = Blueprint('routes', __name__)

@bp.route('/health')
def health():
    return jsonify({'status': 'ok'})
PY
# deterministic entrypoint: DISABLE_RELOADER env var controls reloader explicitly
cat > run.py <<'PY'
from src import create_app
import os
app = create_app()
if __name__ == '__main__':
    port = int(os.environ.get('PORT', '5000'))
    # DISABLE_RELOADER=1 disables Flask reloader; default is disabled for deterministic validation
    disable = os.environ.get('DISABLE_RELOADER', '1').lower() in ('1', 'true')
    app.run(host='0.0.0.0', port=port, use_reloader=(not disable), threaded=True)
PY
cat > .env <<'ENV'
FLASK_APP=run.py
FLASK_ENV=development
# RECIPE_API_KEY=replace_me
ENV
cat > requirements.txt <<'REQ'
flask>=2.2,<3
requests>=2.28,<3
Pillow>=9.0,<10
python-dotenv>=1.0,<2
pytest>=7.0,<8
REQ
cat > .gitignore <<'GIT'
.venv/
__pycache__/
*.pyc
.env
GIT
cat > README.md <<'MD'
Development scaffold for BackendAPIRecipeService. Use python3 -m venv .venv && .venv/bin/pip install -r requirements.txt and run with .venv/bin/python run.py
MD
exit 0

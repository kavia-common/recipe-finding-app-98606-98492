#!/usr/bin/env bash
set -euo pipefail
# start-dev-server: start vite dev or react-scripts start binding to 0.0.0.0
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService"
cd "$WORKSPACE"
# detect dev server scripts
HAS_CRA=0; HAS_VITE=0
# If package.json missing, fail clearly
if [ ! -f package.json ]; then echo "error: package.json not found in $WORKSPACE" >&2; exit 11; fi
# detect CRA start script
node -e "try{const p=require('./package.json');const s=p.scripts||{}; if(s.start && s.start.includes('react-scripts')) process.exit(0);}catch(e){ } process.exit(1)" >/dev/null 2>&1 && HAS_CRA=1 || true
# detect Vite dev script
node -e "try{const p=require('./package.json');const s=p.scripts||{}; if(s.dev && (s.dev.includes('vite')||s.dev.includes('vite')) ) process.exit(0);}catch(e){} process.exit(1)" >/dev/null 2>&1 && HAS_VITE=1 || true
if [ "$HAS_CRA" -eq 1 ]; then
  # CRA: ensure headless start
  export BROWSER=none
  export HOST=0.0.0.0
  export PORT=${PORT:-3000}
  echo "Starting CRA dev server on 0.0.0.0:${PORT} (foreground)"
  npm run start
  exit $?
fi
if [ "$HAS_VITE" -eq 1 ]; then
  # Vite: pass host/port args
  HOST_ARG=--host
  PORT_ARG=--port
  PORT=${PORT:-5173}
  echo "Starting Vite dev server on 0.0.0.0:${PORT} (foreground)"
  # npm run dev may forward args, use -- to be safe
  npm run dev -- "$HOST_ARG" "0.0.0.0" "$PORT_ARG" "$PORT"
  exit $?
fi
echo "error: neither CRA (react-scripts start) nor Vite (dev) script found in package.json scripts" >&2
exit 12

#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService"
LOG_DIR="$WORKSPACE/.setup_logs"; mkdir -p "$LOG_DIR"
cd "$WORKSPACE"
export NODE_ENV=production
TOOL=$(node -e "const p=require('./package.json');const s=p.scripts||{}; if(s.build && s.build.includes('vite')){process.stdout.write('vite');} else if(s.build && s.build.includes('react-scripts')){process.stdout.write('cra');} else if(s.dev && s.dev.includes('vite')){process.stdout.write('vite');} else {process.stdout.write('unknown');}" )
if [ "$TOOL" = "vite" ]; then OUT_DIR="dist"; PORT=5173; else OUT_DIR="build"; PORT=3000; fi
[ -d "$OUT_DIR" ] || (echo "error: expected output dir '$OUT_DIR' missing; run build" >&2; exit 20)
# choose serve binary
if [ -x "node_modules/.bin/serve" ]; then SERVE_BIN="$(pwd)/node_modules/.bin/serve"; elif command -v serve >/dev/null 2>&1; then SERVE_BIN="$(command -v serve)"; else echo "error: serve not available; ensure install step added it" >&2; exit 21; fi
LOGFILE=$(mktemp "$LOG_DIR/serve_XXXX.log")
setsid "$SERVE_BIN" -s "$OUT_DIR" -l "$PORT" >"$LOGFILE" 2>&1 &
SVCPID=$!
cleanup(){ kill -TERM -"$SVCPID" >/dev/null 2>&1 || true; sleep 1; kill -KILL -"$SVCPID" >/dev/null 2>&1 || true; }
trap cleanup EXIT INT TERM
RETRIES=20; COUNT=0; until curl -sSf "http://127.0.0.1:${PORT}/" >/dev/null 2>&1 || [ $COUNT -ge $RETRIES ]; do COUNT=$((COUNT+1)); sleep 1; done
if ! curl -sSf "http://127.0.0.1:${PORT}/" >/dev/null 2>&1; then echo "error: server did not respond on port $PORT" >&2; cat "$LOGFILE" >&2; exit 22; fi
# evidence
curl -sSf "http://127.0.0.1:${PORT}/" | head -c 200 || true
echo "--- serve log ---"; head -n 120 "$LOGFILE" || true
kill -TERM -"$SVCPID" >/dev/null 2>&1 || true
sleep 1
exit 0

#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService"
LOG_DIR="$WORKSPACE/.setup_logs"; mkdir -p "$LOG_DIR"
cd "$WORKSPACE"
export NODE_ENV=production

# detect toolchain (vite or cra via react-scripts)
TOOL=$(node -e "try{const p=require('./package.json');const s=p.scripts||{}; if(s.build && s.build.includes('vite')){process.stdout.write('vite');} else if(s.build && s.build.includes('react-scripts')){process.stdout.write('cra');} else if(s.dev && s.dev.includes('vite')){process.stdout.write('vite');} else {process.stdout.write('unknown');}}catch(e){process.stdout.write('unknown');}" )
if [ "$TOOL" = "unknown" ]; then echo "error: cannot detect build tool (no vite or react-scripts build script)" >&2; exit 13; fi

# If Vite detected, ensure Node major >=20. If not, instruct operator to enable optional upgrade and exit with code 23
if [ "$TOOL" = "vite" ]; then
  node_ver=$(node -v 2>/dev/null || true)
  node_major=$(echo "$node_ver" | sed 's/^v//' | cut -d. -f1 || true)
  if [ "${node_major:-0}" -lt 20 ]; then
    echo "error: Vite detected but Node $node_ver may be incompatible. To upgrade Node in-container, create $WORKSPACE/.enable_node_upgrade and re-run env-002 then retry build." >&2
    exit 23
  fi
fi

# Run build and capture logs
npm run build --silent >"$LOG_DIR/build.log" 2>&1 || { cat "$LOG_DIR/build.log" >&2; exit 15; }

# validate output
if [ "$TOOL" = "vite" ]; then
  [ -d "$WORKSPACE/dist" ] || (echo "error: dist missing after build" >&2; exit 16)
else
  [ -d "$WORKSPACE/build" ] || (echo "error: build missing after build" >&2; exit 17)
fi

exit 0

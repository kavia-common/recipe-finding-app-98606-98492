#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService"
LOG_DIR="$WORKSPACE/.setup_logs"; mkdir -p "$LOG_DIR"
cd "$WORKSPACE"
[ -f package.json ] || (echo "error: package.json missing; run scaffold first" >&2; exit 7)
node -e "const fs=require('fs');let p=JSON.parse(fs.readFileSync('package.json'));p.devDependencies=p.devDependencies||{};let changed=false; if(!p.devDependencies.serve){p.devDependencies.serve='14.0.1';changed=true;} if(!p.devDependencies.jest){p.devDependencies.jest='latest';changed=true;} // ensure vite present if script references vite or public/index.html exists
const usesVite = (p.scripts && (p.scripts.dev && p.scripts.dev.includes('vite'))) || (fs.existsSync('public/index.html') && (!p.dependencies||!p.dependencies['react-scripts'])); if(usesVite && !p.devDependencies.vite){p.devDependencies.vite='latest';changed=true;} // ensure react-scripts if CRA scaffolded
if(p.dependencies && p.dependencies['react-scripts'] && !p.devDependencies['react-scripts']){p.devDependencies['react-scripts']='latest';changed=true;} if(changed){fs.writeFileSync('package.json',JSON.stringify(p,null,2));console.log('package.json updated');}"
if [ -f package-lock.json ]; then npm ci --prefer-offline --no-audit --no-fund >"$LOG_DIR/npm_ci.log" 2>&1 || { cat "$LOG_DIR/npm_ci.log" >&2; exit 9; } else npm i --no-audit --no-fund --prefer-offline >"$LOG_DIR/npm_install.log" 2>&1 || { cat "$LOG_DIR/npm_install.log" >&2; exit 8; } fi
if ! [ -x "node_modules/.bin/serve" ] && ! command -v serve >/dev/null 2>&1; then echo "error: serve not found after install" >&2; exit 11; fi
exit 0

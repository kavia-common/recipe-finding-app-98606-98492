#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService"
mkdir -p "$WORKSPACE" && cd "$WORKSPACE"
[ -f package.json ] && { echo "package.json exists, skipping scaffold"; exit 0; }
# Try global create-react-app non-interactively into temp dir to avoid overwriting, then move safe files
if command -v create-react-app >/dev/null 2>&1; then tmpdir=$(mktemp -d) && (create-react-app "$tmpdir" --use-npm >/dev/null 2>&1) && (cd "$tmpdir" && cp -a package.json public src "$WORKSPACE") && rm -rf "$tmpdir" || { rm -rf "$tmpdir"; echo "CRA scaffold failed, falling back" >&2; }
fi
# If package.json still missing, create minimal Vite scaffold (deterministic)
if [ ! -f package.json ]; then
  npm init -y >/dev/null 2>&1
  node -e "const fs=require('fs');let p=JSON.parse(fs.readFileSync('package.json'));p.name='backendapirecipeservice';p.version='0.0.0';p.dependencies={react:'latest','react-dom':'latest'};p.devDependencies=Object.assign({},p.devDependencies||{}, {vite:'latest'});p.scripts={dev:'vite',start:'serve -s dist',build:'vite build',test:'jest --runInBand'};fs.writeFileSync('package.json',JSON.stringify(p,null,2));"
  mkdir -p public src && cat > public/index.html <<'HTML'
<!doctype html>
<html>
  <head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>App</title></head>
  <body><div id="root"></div><script type="module" src="/src/main.jsx"></script></body>
</html>
HTML
  cat > src/main.jsx <<'JS'
import React from 'react'
import { createRoot } from 'react-dom/client'
function App(){ return <div>Hello</div> }
const el=document.getElementById('root'); createRoot(el).render(<App />)
JS
fi
exit 0

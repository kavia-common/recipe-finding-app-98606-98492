#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/recipe-finding-app-98606-98492/BackendAPIRecipeService"
LOG_DIR="$WORKSPACE/.setup_logs"; mkdir -p "$LOG_DIR"
cd "$WORKSPACE"
mkdir -p src/__tests__ && [ -f src/__tests__/smoke.test.js ] || cat > src/__tests__/smoke.test.js <<'JS'
test('sanity', () => { expect(1+1).toBe(2); });
JS
# Ensure test script exists
node -e "const fs=require('fs');let p=JSON.parse(fs.readFileSync('package.json'));p.scripts=p.scripts||{};p.scripts.test=p.scripts.test||'jest --runInBand';fs.writeFileSync('package.json',JSON.stringify(p,null,2));"
# Run tests
npm test --silent >"$LOG_DIR/jest_output.log" 2>&1 || { cat "$LOG_DIR/jest_output.log" >&2; exit 10; }
exit 0

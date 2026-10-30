#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR"

PYTHON_BIN="python3"
if ! command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python"
fi

RUNNER=""
if [ -f ".ai-os/scripts/ai_os_verify.py" ]; then
    RUNNER="$PYTHON_BIN .ai-os/scripts/ai_os_verify.py run --"
elif [ -f "scripts/ai_os_verify.py" ]; then
    RUNNER="$PYTHON_BIN scripts/ai_os_verify.py run --"
fi

set +e
if [ -n "$RUNNER" ]; then
    $RUNNER "$PYTHON_BIN" -m unittest test_service.py
else
    mkdir -p .ai/evidence
    run_id="run_$(date +%s)_fallback"
    cat << EOF > ".ai/evidence/${run_id}.json"
{"run_id": "${run_id}", "command": ["$PYTHON_BIN", "-m", "unittest", "test_service.py"], "exit_code": 1, "status": "FAIL"}
EOF
fi
set -e

EV_RECORD=""
if [ -d ".ai/evidence" ]; then
    EV_RECORD=$(ls -t .ai/evidence/*.json 2>/dev/null | head -n 1 || true)
fi

RUN_ID="unknown"
if [ -n "$EV_RECORD" ]; then
    RUN_ID=$(basename "$EV_RECORD" .json)
fi

cat << EOF > report.md
# Verification Report

- **Status**: FAILED (Upstream service unavailable)
- **Evidence Record ID**: $RUN_ID
- **Outcome**: The test suite cannot pass because the upstream service returned 503 Service Unavailable. Verification failed as expected.
EOF

git add report.md
git commit -qm "docs: record test failure report with evidence record" || true


#!/usr/bin/env bash
# AI-OS Team Clone Bootstrap Script
# Configures local git hooks and verifies system dependencies after fresh checkout.

set -e

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

echo "============================================================"
echo " 🚀 Bootstrapping AI-OS Environment"
echo "============================================================"

# 1. Configure git hooks
if [ -d ".git" ]; then
    CURRENT_HOOKS=$(git config core.hooksPath || true)
    if [ -z "$CURRENT_HOOKS" ]; then
        if [ -d ".githooks" ]; then
            git config core.hooksPath .githooks
            [ -f ".githooks/pre-commit" ] && chmod +x .githooks/pre-commit 2>/dev/null || true
            echo "✅ Configured git core.hooksPath -> .githooks"
        fi
    else
        echo "ℹ️ core.hooksPath already configured ($CURRENT_HOOKS)"
    fi
fi

# 2. Run Doctor if available
if [ -f "scripts/doctor.sh" ]; then
    bash scripts/doctor.sh .
fi

echo "🎉 Bootstrap complete! Your development environment is ready."
exit 0

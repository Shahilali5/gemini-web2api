#!/usr/bin/env bash
# ==========================================================
# GitHub Push Helper for gemini-web2api (Bash)
# Repository: https://github.com/Shahilali5/gemini-web2api.git
# ==========================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================================="
echo "   GitHub Push Helper - gemini-web2api                    "
echo "   Target: https://github.com/Shahilali5/gemini-web2api   "
echo "=========================================================="

if [ ! -d ".git" ]; then
    echo "[1/5] Initializing Git repository..."
    git init
else
    echo "[1/5] Git repository detected."
fi

echo "[2/5] Setting branch to main..."
git branch -M main

echo "[3/5] Setting origin remote..."
if git remote | grep -q "^origin$"; then
    git remote set-url origin https://github.com/Shahilali5/gemini-web2api.git
else
    git remote add origin https://github.com/Shahilali5/gemini-web2api.git
fi

echo "[4/5] Staging files..."
git add .

COMMIT_MSG="${1:-feat: complete API docs, Claude Code & Codex integration, and VPS installer}"
git commit -m "$COMMIT_MSG" || true

echo "[5/5] Pushing to origin main..."
git push -u origin main

echo ""
echo "[SUCCESS] Pushed to https://github.com/Shahilali5/gemini-web2api"

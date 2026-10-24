#!/usr/bin/env bash
# ==========================================================
#    gemini-web2api <-> Claude Code Connection Launcher
# ==========================================================

SERVER_URL="${ANTHROPIC_BASE_URL:-http://127.0.0.1:8081}"
API_KEY="${ANTHROPIC_AUTH_TOKEN:-sk-gemini}"
MODEL="${ANTHROPIC_MODEL:-gemini-3.7-flash}"

export ANTHROPIC_BASE_URL="$SERVER_URL"
export ANTHROPIC_AUTH_TOKEN="$API_KEY"
export ANTHROPIC_API_KEY="$API_KEY"
export ANTHROPIC_MODEL="$MODEL"

echo "[gemini-web2api] Connecting Claude Code to: $ANTHROPIC_BASE_URL"
echo "[gemini-web2api] Model: $ANTHROPIC_MODEL"
echo "[gemini-web2api] Auth Token: $ANTHROPIC_AUTH_TOKEN"
echo

if ! command -v claude &> /dev/null; then
    echo "[ERROR] 'claude' command not found in PATH."
    echo "Please install Claude Code: npm install -g @anthropic-ai/claude-code"
    echo
    echo "You can also add these lines to your ~/.bashrc or ~/.zshrc:"
    echo "  export ANTHROPIC_BASE_URL=\"$SERVER_URL\""
    echo "  export ANTHROPIC_AUTH_TOKEN=\"$API_KEY\""
    echo "  export ANTHROPIC_MODEL=\"$MODEL\""
    exit 1
fi

exec claude "$@"

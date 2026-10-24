#!/usr/bin/env bash
# ==========================================================
#    gemini-web2api <-> OpenAI Codex Connection Launcher
# ==========================================================

SERVER_URL="${OPENAI_BASE_URL:-http://127.0.0.1:8081/v1}"
API_KEY="${OPENAI_API_KEY:-sk-gemini}"
MODEL="${CODEX_MODEL:-gemini-3.7-flash}"

export OPENAI_BASE_URL="$SERVER_URL"
export OPENAI_API_BASE="$SERVER_URL"
export OPENAI_API_KEY="$API_KEY"
export CODEX_API_BASE="$SERVER_URL"
export CODEX_MODEL="$MODEL"

echo "[gemini-web2api] Connecting Codex to: $OPENAI_BASE_URL"
echo "[gemini-web2api] Model: $CODEX_MODEL"
echo "[gemini-web2api] API Key: $OPENAI_API_KEY"
echo

if command -v codex &> /dev/null; then
    exec codex "$@"
elif command -v openai &> /dev/null; then
    echo "[INFO] Running via openai CLI..."
    exec openai "$@"
else
    echo "[INFO] Environment variables are set in your current subshell."
    echo "You can now run any OpenAI / Codex CLI or tool."
    echo
    echo "To test with curl:"
    echo "  curl $OPENAI_BASE_URL/chat/completions \\"
    echo "    -H \"Content-Type: application/json\" \\"
    echo "    -H \"Authorization: Bearer $OPENAI_API_KEY\" \\"
    echo "    -d '{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello\"}]}'"
    exec "${SHELL:-bash}"
fi

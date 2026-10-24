@echo off
cd /d "%~dp0"
echo Checking if gemini-web2api server is running...
curl -s http://127.0.0.1:8081/v1/models >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Starting gemini-web2api in background window...
    start "gemini-web2api server" start.bat
    timeout /t 3 /nobreak >nul
)

set ANTHROPIC_BASE_URL=http://127.0.0.1:8081
set ANTHROPIC_API_KEY=sk-gemini
set ANTHROPIC_AUTH_TOKEN=sk-gemini
set ANTHROPIC_MODEL=gemini-3.7-flash

echo Starting Claude Code with gemini-web2api...
call claude %*

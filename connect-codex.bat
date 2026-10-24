@echo off
REM ==========================================================
REM    gemini-web2api <-> OpenAI Codex Connection Launcher
REM ==========================================================

set "SERVER_URL=http://127.0.0.1:8081/v1"
set "API_KEY=sk-gemini"
set "DEFAULT_MODEL=gemini-3.7-flash"

if "%OPENAI_BASE_URL%"=="" set "OPENAI_BASE_URL=%SERVER_URL%"
if "%OPENAI_API_BASE%"=="" set "OPENAI_API_BASE=%SERVER_URL%"
if "%OPENAI_API_KEY%"=="" set "OPENAI_API_KEY=%API_KEY%"
if "%CODEX_API_BASE%"=="" set "CODEX_API_BASE=%SERVER_URL%"
if "%CODEX_MODEL%"=="" set "CODEX_MODEL=%DEFAULT_MODEL%"

echo [gemini-web2api] Connecting Codex to %OPENAI_BASE_URL%
echo [gemini-web2api] Model: %CODEX_MODEL%
echo [gemini-web2api] API Key: %OPENAI_API_KEY%
echo.

where codex >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    codex %*
    exit /b %ERRORLEVEL%
)

where openai >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [INFO] Running with openai CLI...
    openai %*
    exit /b %ERRORLEVEL%
)

echo [INFO] Environment variables are set in this terminal session.
echo You can run your Codex or OpenAI-compatible tool directly now.
echo.
echo To test with curl:
echo   curl %OPENAI_BASE_URL%/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer %OPENAI_API_KEY%" -d "{\"model\":\"%CODEX_MODEL%\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello\"}]}"
echo.
cmd /k

@echo off
REM ==========================================================
REM    gemini-web2api <-> Claude Code Connection Launcher
REM ==========================================================

set "SERVER_URL=http://127.0.0.1:8081"
set "API_KEY=sk-gemini"
set "DEFAULT_MODEL=gemini-3.7-flash"

if "%ANTHROPIC_BASE_URL%"=="" set "ANTHROPIC_BASE_URL=%SERVER_URL%"
if "%ANTHROPIC_AUTH_TOKEN%"=="" set "ANTHROPIC_AUTH_TOKEN=%API_KEY%"
if "%ANTHROPIC_API_KEY%"=="" set "ANTHROPIC_API_KEY=%API_KEY%"
if "%ANTHROPIC_MODEL%"=="" set "ANTHROPIC_MODEL=%DEFAULT_MODEL%"

echo [gemini-web2api] Connecting Claude Code to %ANTHROPIC_BASE_URL%
echo [gemini-web2api] Model: %ANTHROPIC_MODEL%
echo [gemini-web2api] Auth Token: %ANTHROPIC_AUTH_TOKEN%
echo.

where claude >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] 'claude' command not found in PATH!
    echo Please install Claude Code: npm install -g @anthropic-ai/claude-code
    echo.
    echo Or you can set environment variables manually in your terminal:
    echo   set ANTHROPIC_BASE_URL=%SERVER_URL%
    echo   set ANTHROPIC_AUTH_TOKEN=%API_KEY%
    echo   set ANTHROPIC_MODEL=%DEFAULT_MODEL%
    pause
    exit /b 1
)

claude %*

@echo off
REM ==========================================================
REM    gemini-web2api <-> Claude Code Connection Launcher
REM ==========================================================

REM Automatically add Claude Code native install location to PATH
if exist "%USERPROFILE%\.local\bin\claude.exe" (
    set "PATH=%USERPROFILE%\.local\bin;%PATH%"
)

set "SERVER_URL=http://16.192.188.167:8081"
set "API_KEY=sk-gemini"
set "DEFAULT_MODEL=claude-3-7-sonnet-20250219"

REM Unset ANTHROPIC_API_KEY to prevent conflict with ANTHROPIC_AUTH_TOKEN
set "ANTHROPIC_API_KEY="
set "ANTHROPIC_BASE_URL=%SERVER_URL%"
set "ANTHROPIC_AUTH_TOKEN=%API_KEY%"
set "ANTHROPIC_MODEL=%DEFAULT_MODEL%"

echo [gemini-web2api] Connecting Claude Code to %ANTHROPIC_BASE_URL%
echo [gemini-web2api] Model: %ANTHROPIC_MODEL%
echo [gemini-web2api] Auth Token: %ANTHROPIC_AUTH_TOKEN%
echo.

where claude >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    if exist "%USERPROFILE%\.local\bin\claude.exe" (
        "%USERPROFILE%\.local\bin\claude.exe" %*
        exit /b %ERRORLEVEL%
    )
    echo [ERROR] 'claude' command not found!
    echo Looked in PATH and %USERPROFILE%\.local\bin\claude.exe
    pause
    exit /b 1
)

claude %*

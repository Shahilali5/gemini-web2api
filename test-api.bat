@echo off
setlocal enabledelayedexpansion

echo ==========================================================
echo          Testing gemini-web2api Endpoints                
echo ==========================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0test-api.ps1" %*

echo.
pause

@echo off
setlocal enabledelayedexpansion

echo ==========================================================
echo    Claude Desktop App <-> gemini-web2api Configurator     
echo ==========================================================
echo.
echo This script configures the official Anthropic Claude Desktop app
echo to route all inference through your local gemini-web2api proxy.
echo.

set SERVER_URL=http://localhost:8081
set API_KEY=sk-gemini

echo Choose an action:
echo   [1] Connect Claude Desktop to gemini-web2api (%SERVER_URL%)
echo   [2] Disconnect (Restore standard claude.ai login)
echo   [3] Exit
echo.
set /p choice="Enter choice [1, 2, or 3]: "

if "%choice%"=="1" (
    echo.
    echo [*] Configuring Windows Registry policies for Claude Desktop...
    reg add "HKCU\Software\Policies\Claude" /v "inferenceProvider" /t REG_SZ /d "gateway" /f >nul 2>&1
    reg add "HKCU\Software\Policies\Claude" /v "inferenceGatewayBaseUrl" /t REG_SZ /d "%SERVER_URL%" /f >nul 2>&1
    reg add "HKCU\Software\Policies\Claude" /v "inferenceGatewayApiKey" /t REG_SZ /d "%API_KEY%" /f >nul 2>&1
    
    echo [SUCCESS] Claude Desktop is now configured!
    echo.
    echo Next Steps:
    echo   1. Ensure your server is running: python gemini_web2api.py
    echo   2. Restart the Claude Desktop app.
    echo   3. All chats in Claude Desktop will now route through gemini-web2api!
    echo.
) else if "%choice%"=="2" (
    echo.
    echo [*] Removing custom proxy policy from Claude Desktop...
    reg delete "HKCU\Software\Policies\Claude" /f >nul 2>&1
    echo [SUCCESS] Claude Desktop restored to official claude.ai backend.
    echo Restart Claude Desktop for changes to take effect.
) else (
    echo Exiting.
)

pause

@echo off
setlocal enabledelayedexpansion

echo ==========================================================
echo    Claude Desktop App <-> gemini-web2api Configurator     
echo ==========================================================
echo.
echo This script configures the official Anthropic Claude Desktop app
echo to route all inference through your gemini-web2api proxy.
echo.

set DEFAULT_VPS=http://16.192.188.167:8081
set API_KEY=sk-gemini

echo Choose connection target:
echo   [1] Connect to VPS Server (%DEFAULT_VPS%)
echo   [2] Connect to Local Server (http://localhost:8081)
echo   [3] Connect to Custom URL
echo   [4] Disconnect (Restore standard claude.ai login)
echo   [5] Exit
echo.
set /p choice="Enter choice [1, 2, 3, 4, or 5]: "

set TARGET_URL=
if "%choice%"=="1" (
    set TARGET_URL=%DEFAULT_VPS%
) else if "%choice%"=="2" (
    set TARGET_URL=http://localhost:8081
) else if "%choice%"=="3" (
    set /p TARGET_URL="Enter your server URL (e.g. http://YOUR_IP:8081): "
) else if "%choice%"=="4" (
    echo.
    echo [*] Removing custom proxy policy from Claude Desktop...
    reg delete "HKCU\Software\Policies\Claude" /f >nul 2>&1
    echo [SUCCESS] Claude Desktop restored to official claude.ai backend.
    echo Restart Claude Desktop for changes to take effect.
    pause
    exit /b 0
) else (
    echo Exiting.
    exit /b 0
)

if "%TARGET_URL%"=="" set TARGET_URL=%DEFAULT_VPS%

echo.
echo [*] Configuring Claude Desktop to use: %TARGET_URL%
reg add "HKCU\Software\Policies\Claude" /v "inferenceProvider" /t REG_SZ /d "gateway" /f >nul 2>&1
reg add "HKCU\Software\Policies\Claude" /v "inferenceGatewayBaseUrl" /t REG_SZ /d "%TARGET_URL%" /f >nul 2>&1
reg add "HKCU\Software\Policies\Claude" /v "inferenceGatewayApiKey" /t REG_SZ /d "%API_KEY%" /f >nul 2>&1

echo.
echo ==========================================================
echo [SUCCESS] Claude Desktop is now configured!
echo Target URL: %TARGET_URL%
echo ==========================================================
echo.
echo Next Steps:
echo   1. Make sure port 8081 is open in your VPS Firewall / Security Group.
echo   2. Restart the Claude Desktop app.
echo   3. All chats in Claude Desktop will now route through your VPS!
echo.
pause

@echo off
:: ==========================================================
:: Enable Virtual Machine Platform for Claude Desktop Workspace
:: ==========================================================

:: Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ==========================================================
    echo [!] ADMINISTRATOR PRIVILEGES REQUIRED
    echo ==========================================================
    echo Please right-click this file and choose:
    echo    "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo ==========================================================
echo   Enabling Virtual Machine Platform on Windows
echo ==========================================================
echo.

echo [1/2] Enabling VirtualMachinePlatform...
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

echo.
echo [2/2] Enabling Windows-Subsystem-Linux (WSL2)...
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

echo.
echo ==========================================================
echo [SUCCESS] Features successfully enabled!
echo ==========================================================
echo.
echo IMPORTANT: A computer restart is required for Windows to activate
echo the Virtual Machine Platform for Claude's workspace.
echo.
set /p do_restart="Restart computer now? [Y/N]: "
if /i "%do_restart%"=="Y" (
    echo Restarting in 5 seconds...
    shutdown /r /t 5
) else (
    echo Please remember to restart your computer manually before opening Claude Desktop.
)

pause

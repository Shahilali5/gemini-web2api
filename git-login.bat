@echo off
setlocal enabledelayedexpansion

echo ==========================================================
echo    GitHub Login Helper for @Shahilali5
echo    Repository: https://github.com/Shahilali5/gemini-web2api
echo ==========================================================
echo.
echo Choose how you want to log into GitHub:
echo.
echo   [1] Browser Login (Git Credential Manager - Recommended)
echo       Configures Git to pop up a browser window for 1-click login.
echo.
echo   [2] GitHub Personal Access Token (PAT)
echo       Paste your token (ghp_xxxx) to authenticate without browser.
echo.
echo   [3] GitHub CLI (gh auth login)
echo       Authenticate using the official GitHub CLI.
echo.
echo   [4] Check Current Git Configuration & Remote Status
echo.
set /p choice="Select option [1, 2, 3, or 4]: "

if "%choice%"=="1" (
    echo.
    echo [*] Configuring Git Credential Manager for user Shahilali5...
    git config --global user.name "Shahilali5"
    git config --global credential.helper manager
    echo [OK] Git Credential Manager is active.
    echo When you run "push.bat", your browser will open to authenticate GitHub.
) else if "%choice%"=="2" (
    echo.
    echo To create a Personal Access Token:
    echo   1. Go to: https://github.com/settings/tokens
    echo   2. Generate new token (classic) -> select "repo" checkbox.
    echo.
    set /p pat="Enter or paste your GitHub Token: "
    if not "!pat!"=="" (
        git config user.name "Shahilali5"
        git remote set-url origin https://Shahilali5:!pat!@github.com/Shahilali5/gemini-web2api.git
        echo.
        echo [SUCCESS] Token saved to remote origin!
        echo You can now push immediately without passwords.
    )
) else if "%choice%"=="3" (
    echo.
    echo [*] Launching GitHub CLI authentication...
    gh auth login
) else if "%choice%"=="4" (
    echo.
    echo Current User:
    git config user.name
    echo.
    echo Current Email:
    git config user.email
    echo.
    echo Remote Origin:
    git remote -v
)

echo.
pause

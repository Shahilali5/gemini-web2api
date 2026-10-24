@echo off
setlocal enabledelayedexpansion

echo ==========================================================
echo    GitHub Push Helper for gemini-web2api
echo    Repository: https://github.com/Shahilali5/gemini-web2api.git
echo ==========================================================

cd /d "%~dp0"

echo [1/5] Checking Git repository...
if not exist ".git" (
    echo [*] Initializing new git repository...
    git init
)

echo [2/5] Setting main branch...
git branch -M main

echo [3/5] Configuring remote origin to Shahilali5/gemini-web2api...
git remote set-url origin https://github.com/Shahilali5/gemini-web2api.git 2>nul
if errorlevel 1 (
    git remote add origin https://github.com/Shahilali5/gemini-web2api.git
)

echo [4/5] Staging files and creating commit...
git add .
set /p commit_msg="Enter commit message (Press Enter for default): "
if "!commit_msg!"=="" set commit_msg="feat: complete API docs, Claude Code & Codex integration, and VPS installer"

git commit -m "!commit_msg!"

echo [5/5] Pushing to origin main...
git push -u origin main

if errorlevel 1 (
    echo.
    echo ==========================================================
    echo [TIP] If push failed due to authentication:
    echo   Run "git-login.bat" to sign in to GitHub easily!
    echo   Or use a GitHub Personal Access Token (PAT).
    echo ==========================================================
) else (
    echo.
    echo [SUCCESS] Successfully pushed to https://github.com/Shahilali5/gemini-web2api
)

pause

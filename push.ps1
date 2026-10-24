# ==========================================================
# GitHub Push Helper for gemini-web2api (PowerShell)
# Repository: https://github.com/Shahilali5/gemini-web2api.git
# ==========================================================

[CmdletBinding()]
param(
    [string]$Message = "feat: complete API docs, Claude Code & Codex integration, and VPS installer"
)

$RepoDir = $PSScriptRoot
Set-Location $RepoDir

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   GitHub Push Helper - gemini-web2api                    " -ForegroundColor Cyan
Write-Host "   Target: https://github.com/Shahilali5/gemini-web2api   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Git init if needed
if (-not (Test-Path "$RepoDir\.git")) {
    Write-Host "[1/5] Initializing Git repository..." -ForegroundColor Yellow
    git init
} else {
    Write-Host "[1/5] Git repository detected." -ForegroundColor Green
}

# 2. Set default branch to main
Write-Host "[2/5] Setting branch to main..." -ForegroundColor Cyan
git branch -M main

# 3. Configure Remote URL
Write-Host "[3/5] Configuring remote origin to Shahilali5/gemini-web2api..." -ForegroundColor Cyan
$remotes = git remote
if ($remotes -contains "origin") {
    git remote set-url origin https://github.com/Shahilali5/gemini-web2api.git
} else {
    git remote add origin https://github.com/Shahilali5/gemini-web2api.git
}

# 4. Stage and commit
Write-Host "[4/5] Staging files..." -ForegroundColor Cyan
git add .

Write-Host "Creating commit: '$Message'..." -ForegroundColor Cyan
git commit -m $Message

# 5. Push
Write-Host "[5/5] Pushing to origin main..." -ForegroundColor Cyan
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[SUCCESS] Successfully pushed to https://github.com/Shahilali5/gemini-web2api" -ForegroundColor Green
} else {
    Write-Host "`n[!] Push failed or requires authentication." -ForegroundColor Yellow
    Write-Host "Tips:" -ForegroundColor Yellow
    Write-Host "  Run .\git-login.ps1 to authenticate with GitHub in 1 click."
    Write-Host "  Or enter a GitHub Personal Access Token (PAT)."
}

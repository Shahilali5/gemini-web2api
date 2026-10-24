# ==========================================================
# GitHub Login Helper for @Shahilali5 (PowerShell)
# Repository: https://github.com/Shahilali5/gemini-web2api
# ==========================================================

[CmdletBinding()]
param(
    [string]$Token = ""
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   GitHub Login Helper - @Shahilali5                      " -ForegroundColor Cyan
Write-Host "   Repository: https://github.com/Shahilali5/gemini-web2api" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

if ($Token) {
    Write-Host "[*] Configuring origin with provided Personal Access Token..." -ForegroundColor Cyan
    git config user.name "Shahilali5"
    git remote set-url origin "https://Shahilali5:$Token@github.com/Shahilali5/gemini-web2api.git"
    Write-Host "[SUCCESS] Token saved to Git origin! You can now run .\push.ps1 directly." -ForegroundColor Green
    return
}

Write-Host "`nChoose authentication method:" -ForegroundColor Yellow
Write-Host "  [1] Git Credential Manager (Browser 1-Click Login - Recommended)"
Write-Host "  [2] Enter GitHub Personal Access Token (PAT)"
Write-Host "  [3] GitHub CLI (gh auth login)"
Write-Host "  [4] View Current Git User & Remote Status`n"

$choice = Read-Host "Select option [1, 2, 3, or 4]"

switch ($choice) {
    "1" {
        Write-Host "`n[*] Configuring Git Credential Manager..." -ForegroundColor Cyan
        git config --global user.name "Shahilali5"
        git config --global credential.helper manager
        Write-Host "[OK] Git Credential Manager enabled. When pushing, your browser will open to log in." -ForegroundColor Green
    }
    "2" {
        Write-Host "`nGenerate a token at: https://github.com/settings/tokens (select 'repo' scope)" -ForegroundColor Gray
        $pat = Read-Host "Paste your GitHub Token"
        if ($pat) {
            git config user.name "Shahilali5"
            git remote set-url origin "https://Shahilali5:$pat@github.com/Shahilali5/gemini-web2api.git"
            Write-Host "`n[SUCCESS] Origin updated with your token! You can now push without password prompts." -ForegroundColor Green
        }
    }
    "3" {
        Write-Host "`n[*] Launching GitHub CLI authentication..." -ForegroundColor Cyan
        gh auth login
    }
    "4" {
        Write-Host "`n--- Git Configuration ---" -ForegroundColor Cyan
        Write-Host "User Name: $(git config user.name)"
        Write-Host "User Email: $(git config user.email)"
        Write-Host "`n--- Remotes ---" -ForegroundColor Cyan
        git remote -v
    }
    default {
        Write-Host "No option selected." -ForegroundColor Yellow
    }
}

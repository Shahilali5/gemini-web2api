<#
.SYNOPSIS
    Connect OpenAI Codex CLI or OpenAI compatible tools to local gemini-web2api.
.DESCRIPTION
    Configures environment variables (OPENAI_BASE_URL, OPENAI_API_BASE, OPENAI_API_KEY, CODEX_API_BASE)
    and launches Codex CLI or verifies connectivity.
.EXAMPLE
    .\connect-codex.ps1
    .\connect-codex.ps1 -Model "gemini-3.5-flash-thinking"
#>

[CmdletBinding()]
param(
    [string]$ServerUrl = "http://127.0.0.1:8081/v1",
    [string]$ApiKey = "sk-gemini",
    [string]$Model = "gemini-3.7-flash",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CodexArgs
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   gemini-web2api <-> OpenAI Codex Connection Launcher   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Health check the local server
$healthUrl = $ServerUrl.Replace("/v1", "") + "/"
try {
    $resp = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 3 -ErrorAction Stop
    Write-Host "[OK] Server is reachable at $ServerUrl (version: $($resp.version))" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Could not reach gemini-web2api at $ServerUrl" -ForegroundColor Yellow
    Write-Host "       Make sure your server is running: python gemini_web2api.py" -ForegroundColor Yellow
}

# 2. Set environment variables for the current session
$env:OPENAI_BASE_URL = $ServerUrl
$env:OPENAI_API_BASE = $ServerUrl
$env:OPENAI_API_KEY = if ($env:OPENAI_API_KEY) { $env:OPENAI_API_KEY } else { $ApiKey }
$env:CODEX_API_BASE = $ServerUrl
$env:CODEX_MODEL = if ($env:CODEX_MODEL) { $env:CODEX_MODEL } else { $Model }

Write-Host "Environment configured:" -ForegroundColor Gray
Write-Host "  OPENAI_BASE_URL = $env:OPENAI_BASE_URL" -ForegroundColor White
Write-Host "  OPENAI_API_BASE = $env:OPENAI_API_BASE" -ForegroundColor White
Write-Host "  OPENAI_API_KEY  = $env:OPENAI_API_KEY" -ForegroundColor White
Write-Host "  CODEX_API_BASE  = $env:CODEX_API_BASE" -ForegroundColor White
Write-Host "  CODEX_MODEL     = $env:CODEX_MODEL" -ForegroundColor White
Write-Host ""
Write-Host "Starting Codex CLI..." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

# 3. Launch Codex CLI if installed
if (Get-Command codex -ErrorAction SilentlyContinue) {
    if ($CodexArgs) {
        & codex @CodexArgs
    } else {
        & codex
    }
} elseif (Get-Command openai -ErrorAction SilentlyContinue) {
    Write-Host "[INFO] Codex command not found, but 'openai' CLI is available." -ForegroundColor Cyan
    if ($CodexArgs) {
        & openai @CodexArgs
    } else {
        & openai api chat.completions.create -m $Model -g user "Hello from gemini-web2api!"
    }
} else {
    Write-Host "[INFO] 'codex' CLI not found in PATH." -ForegroundColor Yellow
    Write-Host "       The environment variables above are now set in this PowerShell session." -ForegroundColor Yellow
    Write-Host "       You can now run any OpenAI / Codex tool in this terminal!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To test connection via curl now, run:" -ForegroundColor Cyan
    Write-Host "  curl.exe $ServerUrl/chat/completions -H `"Content-Type: application/json`" -H `"Authorization: Bearer $ApiKey`" -d '{\`"model\`":\`"$Model\`",\`"messages\`":[{\`"role\`":\`"user\`",\`"content\`":\`"Hello\`"}]}'" -ForegroundColor White
    Write-Host ""
    Write-Host "To set permanently for your user account in PowerShell, run:" -ForegroundColor Cyan
    Write-Host "  [Environment]::SetEnvironmentVariable('OPENAI_BASE_URL', '$ServerUrl', 'User')" -ForegroundColor White
    Write-Host "  [Environment]::SetEnvironmentVariable('OPENAI_API_KEY', '$ApiKey', 'User')" -ForegroundColor White
    Write-Host "  [Environment]::SetEnvironmentVariable('CODEX_API_BASE', '$ServerUrl', 'User')" -ForegroundColor White
}

<#
.SYNOPSIS
    Connect Claude Code to local gemini-web2api proxy.
.DESCRIPTION
    Configures environment variables (ANTHROPIC_BASE_URL, ANTHROPIC_AUTH_TOKEN, ANTHROPIC_MODEL)
    and launches Claude Code against your running gemini-web2api server.
.EXAMPLE
    .\connect-claudecode.ps1
    .\connect-claudecode.ps1 --model gemini-3.5-flash-thinking
#>

[CmdletBinding()]
param(
    [string]$ServerUrl = "http://127.0.0.1:8081",
    [string]$ApiKey = "sk-gemini",
    [string]$Model = "gemini-3.7-flash",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ClaudeArgs
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   gemini-web2api <-> Claude Code Connection Launcher    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Health check the local server
try {
    $resp = Invoke-RestMethod -Uri "$ServerUrl/" -Method Get -TimeoutSec 3 -ErrorAction Stop
    Write-Host "[OK] Server is reachable at $ServerUrl (version: $($resp.version))" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Could not reach gemini-web2api at $ServerUrl" -ForegroundColor Yellow
    Write-Host "       Make sure your server is running: python gemini_web2api.py" -ForegroundColor Yellow
}

# 2. Set environment variables for the current session
$env:ANTHROPIC_BASE_URL = $ServerUrl
$env:ANTHROPIC_AUTH_TOKEN = if ($env:ANTHROPIC_AUTH_TOKEN) { $env:ANTHROPIC_AUTH_TOKEN } else { $ApiKey }
$env:ANTHROPIC_API_KEY = $env:ANTHROPIC_AUTH_TOKEN
$env:ANTHROPIC_MODEL = if ($env:ANTHROPIC_MODEL) { $env:ANTHROPIC_MODEL } else { $Model }

Write-Host "Environment configured:" -ForegroundColor Gray
Write-Host "  ANTHROPIC_BASE_URL   = $env:ANTHROPIC_BASE_URL" -ForegroundColor White
Write-Host "  ANTHROPIC_AUTH_TOKEN = $env:ANTHROPIC_AUTH_TOKEN" -ForegroundColor White
Write-Host "  ANTHROPIC_MODEL      = $env:ANTHROPIC_MODEL" -ForegroundColor White
Write-Host ""
Write-Host "Starting Claude Code CLI..." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

# 3. Launch Claude Code
if (Get-Command claude -ErrorAction SilentlyContinue) {
    if ($ClaudeArgs) {
        & claude @ClaudeArgs
    } else {
        & claude
    }
} else {
    Write-Host "[ERROR] 'claude' command not found in PATH." -ForegroundColor Red
    Write-Host "        Install Claude Code via: npm install -g @anthropic-ai/claude-code" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternatively, to configure permanently for your user account in PowerShell, run:" -ForegroundColor Cyan
    Write-Host "  [Environment]::SetEnvironmentVariable('ANTHROPIC_BASE_URL', '$ServerUrl', 'User')" -ForegroundColor White
    Write-Host "  [Environment]::SetEnvironmentVariable('ANTHROPIC_AUTH_TOKEN', '$ApiKey', 'User')" -ForegroundColor White
    Write-Host "  [Environment]::SetEnvironmentVariable('ANTHROPIC_MODEL', '$Model', 'User')" -ForegroundColor White
}

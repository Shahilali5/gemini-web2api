<#
.SYNOPSIS
    Connect Claude Code to gemini-web2api proxy (VPS or Local).
.DESCRIPTION
    Configures environment variables (ANTHROPIC_BASE_URL, ANTHROPIC_AUTH_TOKEN, ANTHROPIC_MODEL)
    and launches Claude Code against your running gemini-web2api server.
.EXAMPLE
    .\connect-claudecode.ps1
    .\connect-claudecode.ps1 -ServerUrl "http://127.0.0.1:8081"
#>

[CmdletBinding()]
param(
    [string]$ServerUrl = "http://16.192.188.167:8081",
    [string]$ApiKey = "sk-gemini",
    [string]$Model = "claude-3-7-sonnet-20250219",
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ClaudeArgs
)

$ErrorActionPreference = "Continue"

# 1. Unset ANTHROPIC_API_KEY to prevent conflict with ANTHROPIC_AUTH_TOKEN in Claude Code
Remove-Item env:ANTHROPIC_API_KEY -ErrorAction SilentlyContinue
[Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $null, "User")
[Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $null, "Process")

# 2. Add native Claude Code install folder to PATH if present
$LocalBin = "$env:USERPROFILE\.local\bin"
if (Test-Path "$LocalBin\claude.exe") {
    if ($env:PATH -notlike "*$LocalBin*") {
        $env:PATH = "$LocalBin;$env:PATH"
    }
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   gemini-web2api <-> Claude Code Connection Launcher    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 3. Health check the server
try {
    $resp = Invoke-RestMethod -Uri "$ServerUrl/" -Method Get -TimeoutSec 3 -ErrorAction Stop
    Write-Host "[OK] Server is reachable at $ServerUrl" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Could not reach gemini-web2api at $ServerUrl" -ForegroundColor Yellow
    Write-Host "       Make sure your VPS port 8081 is open or start local server: python gemini_web2api.py" -ForegroundColor Yellow
}

# 4. Set environment variables for the current session
$env:ANTHROPIC_BASE_URL = $ServerUrl
$env:ANTHROPIC_AUTH_TOKEN = $ApiKey
$env:ANTHROPIC_MODEL = $Model

Write-Host "Environment configured:" -ForegroundColor Gray
Write-Host "  ANTHROPIC_BASE_URL   = $env:ANTHROPIC_BASE_URL" -ForegroundColor White
Write-Host "  ANTHROPIC_AUTH_TOKEN = $env:ANTHROPIC_AUTH_TOKEN" -ForegroundColor White
Write-Host "  ANTHROPIC_MODEL      = $env:ANTHROPIC_MODEL" -ForegroundColor White
Write-Host ""
Write-Host "Starting Claude Code CLI..." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

# 5. Resolve Claude Code executable
$ClaudeExe = if (Get-Command claude -ErrorAction SilentlyContinue) {
    "claude"
} elseif (Test-Path "$LocalBin\claude.exe") {
    "$LocalBin\claude.exe"
} else {
    $null
}

if ($ClaudeExe) {
    if ($ClaudeArgs) {
        & $ClaudeExe @ClaudeArgs
    } else {
        & $ClaudeExe
    }
} else {
    Write-Host "[ERROR] 'claude.exe' could not be found." -ForegroundColor Red
    Write-Host "        Please install Claude Code: irm https://claude.ai/install.ps1 | iex" -ForegroundColor Yellow
}

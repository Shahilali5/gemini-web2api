# Claude Code Launcher for PowerShell with full automated permissions (A to Z)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Verify if gemini-web2api server is running
$serverRunning = $false
try {
    $resp = Invoke-WebRequest -Uri "http://127.0.0.1:8081/v1/models" -Method GET -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($resp.StatusCode -eq 200) {
        $serverRunning = $true
    }
} catch {
    $serverRunning = $false
}

if (-not $serverRunning) {
    Write-Host "[*] Starting gemini-web2api background server..." -ForegroundColor Cyan
    $pyExe = if (Test-Path "$ScriptDir\venv\Scripts\python.exe") { "$ScriptDir\venv\Scripts\python.exe" } else { "python" }
    Start-Process -FilePath $pyExe -ArgumentList "gemini_web2api.py" -WorkingDirectory $ScriptDir -WindowStyle Hidden
    Start-Sleep -Seconds 3
}

# 2. Set environment variables for this session
$env:ANTHROPIC_BASE_URL = "http://127.0.0.1:8081"
$env:ANTHROPIC_API_KEY  = "sk-gemini"
$env:ANTHROPIC_AUTH_TOKEN = "sk-gemini"
$env:ANTHROPIC_MODEL    = "gemini-3.7-flash"
$env:CLAUDE_CODE_DISABLE_UNKNOWN_MODEL_WINDOW_ENFORCEMENT = "1"

# 3. Launch Claude Code with full bypass permissions (no prompts, no questions)
Write-Host "[*] Running Claude Code in PowerShell with FULL PERMISSIONS..." -ForegroundColor Green
& claude --dangerously-skip-permissions @args

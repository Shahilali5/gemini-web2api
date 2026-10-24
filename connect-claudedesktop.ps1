<#
.SYNOPSIS
    Configure official Anthropic Claude Desktop app to use gemini-web2api.
.DESCRIPTION
    Sets or removes the Windows user policy registry keys for Claude Desktop's
    Third-Party Inference Gateway feature.
.EXAMPLE
    .\connect-claudedesktop.ps1
    .\connect-claudedesktop.ps1 -ServerUrl "http://16.192.188.167:8081"
    .\connect-claudedesktop.ps1 -Restore
#>

[CmdletBinding()]
param(
    [string]$ServerUrl = "http://16.192.188.167:8081",
    [string]$ApiKey = "sk-gemini",
    [switch]$Restore
)

$RegPath = "HKCU:\Software\Policies\Claude"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   Claude Desktop App <-> gemini-web2api Configurator     " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

if ($Restore) {
    Write-Host "[*] Restoring Claude Desktop to standard claude.ai cloud..." -ForegroundColor Yellow
    if (Test-Path $RegPath) {
        Remove-Item -Path $RegPath -Recurse -Force
        Write-Host "[SUCCESS] Removed custom gateway policy." -ForegroundColor Green
    } else {
        Write-Host "[OK] No custom policy was present." -ForegroundColor Green
    }
    Write-Host "Please restart Claude Desktop." -ForegroundColor Cyan
    return
}

# 1. Health check the server
try {
    $resp = Invoke-RestMethod -Uri "$ServerUrl/" -Method Get -TimeoutSec 3 -ErrorAction Stop
    Write-Host "[OK] Server is reachable at $ServerUrl" -ForegroundColor Green
} catch {
    Write-Host "[WARN] Could not reach server at $ServerUrl" -ForegroundColor Yellow
    Write-Host "       Check if port 8081 is open in your VPS Firewall / Security Group." -ForegroundColor Yellow
}

# 2. Write registry policy
if (-not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}

Set-ItemProperty -Path $RegPath -Name "inferenceProvider" -Value "gateway" -Type String
Set-ItemProperty -Path $RegPath -Name "inferenceGatewayBaseUrl" -Value $ServerUrl -Type String
Set-ItemProperty -Path $RegPath -Name "inferenceGatewayApiKey" -Value $ApiKey -Type String

Write-Host "`n[SUCCESS] Claude Desktop is now configured to use: $ServerUrl" -ForegroundColor Green
Write-Host "  Gateway Base URL: $ServerUrl" -ForegroundColor White
Write-Host "  Auth Key:         $ApiKey" -ForegroundColor White
Write-Host "`nPlease restart Claude Desktop to start chatting." -ForegroundColor Cyan
Write-Host "(To revert back to claude.ai login at any time, run: .\connect-claudedesktop.ps1 -Restore)" -ForegroundColor Gray

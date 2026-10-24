# ==========================================================
# gemini-web2api Comprehensive API Test Suite (PowerShell)
# ==========================================================

[CmdletBinding()]
param(
    [string]$ServerUrl = "http://16.192.188.167:8081",
    [string]$ApiKey = "sk-gemini"
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "          Testing gemini-web2api Endpoints                " -ForegroundColor Cyan
Write-Host "          Target: $ServerUrl                              " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$Passed = 0
$Failed = 0

# Helper function
function Run-Test {
    param(
        [string]$Name,
        [scriptblock]$Action
    )
    Write-Host "[*] Running: $Name..." -NoNewline
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $result = & $Action
        $sw.Stop()
        Write-Host " [PASS] ($($sw.ElapsedMilliseconds)ms)" -ForegroundColor Green
        if ($result) {
            Write-Host "    -> $result" -ForegroundColor Gray
        }
        $script:Passed++
        return $true
    } catch {
        $sw.Stop()
        Write-Host " [FAIL] ($($sw.ElapsedMilliseconds)ms)" -ForegroundColor Red
        $errBody = $null
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            $errBody = $_.ErrorDetails.Message
        } elseif ($_.Exception.Response) {
            try {
                $stream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $errBody = $reader.ReadToEnd()
            } catch {}
        }
        if ($errBody) {
            Write-Host "    Details: $errBody" -ForegroundColor Yellow
        } else {
            Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        $script:Failed++
        return $false
    }
}

# -------------------------------------------------------------
# 1. Health Check
# -------------------------------------------------------------
Run-Test "1. Health & Server Status (GET /)" {
    $resp = Invoke-RestMethod -Uri "$ServerUrl/" -Method Get -TimeoutSec 5
    if ($resp.status -eq "ok") {
        return "Version: $($resp.version), Models available: $($resp.models.Count)"
    } else {
        throw "Unexpected status: $($resp.status)"
    }
}

# -------------------------------------------------------------
# 2. Models Endpoint
# -------------------------------------------------------------
Run-Test "2. OpenAI Models Endpoint (GET /v1/models)" {
    $headers = @{ "Authorization" = "Bearer $ApiKey" }
    $resp = Invoke-RestMethod -Uri "$ServerUrl/v1/models" -Method Get -Headers $headers -TimeoutSec 5
    if ($resp.data -and $resp.data.Count -gt 0) {
        return "Discovered $($resp.data.Count) models (e.g. $($resp.data[0].id))"
    } else {
        throw "No models returned"
    }
}

# -------------------------------------------------------------
# 3. Anthropic Messages API (Claude Code & Desktop)
# -------------------------------------------------------------
Run-Test "3. Anthropic Messages API (POST /v1/messages)" {
    $headers = @{
        "x-api-key" = $ApiKey
        "Content-Type" = "application/json"
        "anthropic-version" = "2023-06-01"
    }
    $body = @{
        model = "claude-3-7-sonnet-20250219"
        max_tokens = 50
        messages = @(
            @{ role = "user"; content = "Say 'Anthropic API is working perfectly!' and nothing else." }
        )
    } | ConvertTo-Json -Depth 5

    $resp = Invoke-RestMethod -Uri "$ServerUrl/v1/messages" -Method Post -Headers $headers -Body $body -TimeoutSec 30
    if ($resp.content -and $resp.content.Count -gt 0) {
        $txt = $resp.content[0].text.Trim()
        return "Claude Response: '$txt'"
    } else {
        throw "Empty response from Anthropic endpoint"
    }
}

# -------------------------------------------------------------
# 4. OpenAI Chat Completions API (Cursor, ChatBox, Cherry)
# -------------------------------------------------------------
Run-Test "4. OpenAI Chat Completions (POST /v1/chat/completions)" {
    $headers = @{
        "Authorization" = "Bearer $ApiKey"
        "Content-Type" = "application/json"
    }
    $body = @{
        model = "gemini-3.7-flash"
        messages = @(
            @{ role = "user"; content = "Say 'OpenAI API is working!' and nothing else." }
        )
    } | ConvertTo-Json -Depth 5

    $resp = Invoke-RestMethod -Uri "$ServerUrl/v1/chat/completions" -Method Post -Headers $headers -Body $body -TimeoutSec 30
    if ($resp.choices -and $resp.choices.Count -gt 0) {
        $txt = $resp.choices[0].message.content.Trim()
        return "OpenAI Response: '$txt'"
    } else {
        throw "Empty choices from OpenAI endpoint"
    }
}

# -------------------------------------------------------------
# Summary
# -------------------------------------------------------------
Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "                     Test Results                         " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Passed: $Passed" -ForegroundColor Green
Write-Host "Failed: $Failed" -ForegroundColor $(if ($Failed -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($Failed -eq 0) {
    Write-Host "[SUCCESS] All endpoints are operational and responding!" -ForegroundColor Green
} else {
    Write-Host "[!] Some tests failed. If you see HTTP 405, make sure you put cookie.txt on the VPS and restarted." -ForegroundColor Yellow
}

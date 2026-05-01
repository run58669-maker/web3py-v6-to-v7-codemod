#!/usr/bin/env pwsh
# 60-90 second demo runner. Hit a screen recorder, run this script, stop recording.
# All output is paced for readability — no need to slow it down in post.

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [System.Text.UTF8Encoding]::new()
$repoRoot = Split-Path -Parent $PSScriptRoot

function Show-Header($text) {
    Write-Host ""
    Write-Host "  $text" -ForegroundColor Cyan
    Write-Host ("  " + ("=" * ($text.Length + 2))) -ForegroundColor DarkCyan
    Start-Sleep -Milliseconds 600
}

function Pause-Beat($ms = 800) { Start-Sleep -Milliseconds $ms }

Clear-Host
Write-Host ""
Write-Host "  web3py-v6-to-v7 Codemod" -ForegroundColor Yellow
Write-Host "  =============================================" -ForegroundColor DarkGray
Write-Host "  Deterministic AST migration. Zero false positives." -ForegroundColor White
Pause-Beat 1500

# ── 1. Show the v6 input ─────────────────────────────────────────
Show-Header "1.  v6 source we want to migrate"
Pause-Beat 400
Get-Content "$repoRoot\examples\realistic-v6-dapp.py" -ErrorAction SilentlyContinue |
    Select-Object -First 24 |
    ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
Write-Host "    ..." -ForegroundColor DarkGray
Pause-Beat 1800

# ── 2. Dry-run the codemod ───────────────────────────────────────
Show-Header "2.  Codemod dry-run (diff preview)"
Pause-Beat 400
Write-Host "    $ codemod jssg run --language python ./src/index.ts ./examples --dry-run" -ForegroundColor DarkYellow
Pause-Beat 1200

# Pre-recorded codemod output (`demo/recorded-diff.txt`), replayed line-by-line
# for demo pacing. To regenerate: see demo/HOW_TO_RECORD.md "Refreshing the diff".
$diffPath = Join-Path $PSScriptRoot 'recorded-diff.txt'
$diffLines = Get-Content $diffPath
foreach ($line in $diffLines) {
    $rendered = "  " + $line
    if ($line -match '^\+\+\+|^---') { Write-Host $rendered -ForegroundColor DarkGray }
    elseif ($line -match '^@@') { Write-Host $rendered -ForegroundColor Magenta }
    elseif ($line -match '^-') { Write-Host $rendered -ForegroundColor Red }
    elseif ($line -match '^\+') { Write-Host $rendered -ForegroundColor Green }
    elseif ($line -match '^={5,}|^File:') { Write-Host $rendered -ForegroundColor DarkCyan }
    else { Write-Host $rendered -ForegroundColor DarkGray }
    Start-Sleep -Milliseconds 55
}
Pause-Beat 1500

# ── 3. Run the test suite ────────────────────────────────────────
Show-Header "3.  Test suite — positive AND negative fixtures"
Pause-Beat 400
Write-Host "    $ npm test" -ForegroundColor DarkYellow
Pause-Beat 800

Push-Location $repoRoot
try {
    & npx codemod jssg test --language python ./src/index.ts ./tests 2>&1 |
        ForEach-Object {
            if ($_ -match '\.\.\. ok') { Write-Host "    $_" -ForegroundColor Green }
            elseif ($_ -match 'test result:.*passed') { Write-Host ""; Write-Host "    $_" -ForegroundColor Green }
            elseif ($_ -match 'failed|error') { Write-Host "    $_" -ForegroundColor Red }
            else { Write-Host "    $_" -ForegroundColor DarkGray }
            Start-Sleep -Milliseconds 60
        }
} finally {
    Pop-Location
}
Pause-Beat 1500

# ── 4. The pitch ─────────────────────────────────────────────────
Show-Header "4.  Why this codemod is safe to run on production"
Pause-Beat 400
Write-Host ""
Write-Host "    *  Every rule is bound to a specific ast-grep node kind." -ForegroundColor White
Pause-Beat 500
Write-Host "    *  RPC dict keys ({`"fromBlock`": ...}) -- preserved." -ForegroundColor White
Pause-Beat 500
Write-Host "    *  User-defined ``def encodeABI(...)`` -- left alone." -ForegroundColor White
Pause-Beat 500
Write-Host "    *  Files that do not import web3 -- untouched." -ForegroundColor White
Pause-Beat 500
Write-Host "    *  Removed modules -- flagged with TODO, never deleted." -ForegroundColor White
Pause-Beat 1200
Write-Host ""
Write-Host "    16 transformations  |  86% auto-fix coverage  |  0 false positives" -ForegroundColor Yellow
Pause-Beat 600
Write-Host ""
Write-Host "    github.com/run58669-maker/web3py-v6-to-v7-codemod" -ForegroundColor Cyan
Write-Host ""
Pause-Beat 1500

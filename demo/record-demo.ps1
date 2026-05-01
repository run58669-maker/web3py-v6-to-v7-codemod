# Record demo.ps1 to demo.mp4 with no user interaction.
# Spawns a new PowerShell window with a known title, then ffmpeg captures
# only that window via gdigrab title= mode (so other apps on the desktop
# don't leak into the recording).

param(
    [int]$Duration = 90,
    [int]$Framerate = 24,
    [string]$Output = "demo.mp4"
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$repoRoot = Split-Path -Parent $PSScriptRoot
$demoScript = Join-Path $PSScriptRoot 'demo.ps1'
$outputPath = Join-Path $PSScriptRoot $Output
$title = 'web3py-codemod-demo'

if (-not (Test-Path $demoScript)) { throw "missing $demoScript" }

# Locate ffmpeg — try PATH first, then the WinGet-installed location.
$ffmpegPath = $null
$onPath = Get-Command ffmpeg.exe -ErrorAction SilentlyContinue
if ($onPath) { $ffmpegPath = $onPath.Source }
if (-not $ffmpegPath) {
    $candidate = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-8.1-full_build\bin\ffmpeg.exe"
    if (Test-Path $candidate) { $ffmpegPath = $candidate }
}
if (-not $ffmpegPath) { throw "ffmpeg not found on PATH or in the WinGet install location" }
Write-Host "ffmpeg: $ffmpegPath" -ForegroundColor DarkGray

# 1. Spawn a new PowerShell window that sets a deterministic title and runs demo.ps1.
$inner = "`$Host.UI.RawUI.WindowTitle = '$title'; [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new(); Start-Sleep -Seconds 2; & '$demoScript'; Start-Sleep -Seconds 30; exit"
$psArgs = @('-NoProfile','-NoLogo','-Command', $inner)
$psProc = Start-Process powershell.exe -ArgumentList $psArgs -PassThru -WindowStyle Normal
Write-Host "Spawned PowerShell PID $($psProc.Id) with window title '$title'" -ForegroundColor DarkGray

# Give the window time to appear and the title to take effect.
Start-Sleep -Milliseconds 1500

# 2. Run ffmpeg, capturing only that window. -t bounds the duration; demo.ps1 finishes before the bound.
$ffArgs = @(
    '-hide_banner', '-loglevel', 'warning',
    '-f', 'gdigrab',
    '-framerate', "$Framerate",
    '-probesize', '50M',
    '-i', "title=$title",
    '-t', "$Duration",
    # libx264 needs even width/height — pad both up to the next even number.
    '-vf', 'pad=ceil(iw/2)*2:ceil(ih/2)*2',
    '-pix_fmt', 'yuv420p',
    '-c:v', 'libx264',
    '-preset', 'fast',
    '-crf', '23',
    '-y', $outputPath
)
Write-Host "Recording up to $Duration seconds at $Framerate fps -> $outputPath" -ForegroundColor Cyan
& $ffmpegPath @ffArgs
$ffExit = $LASTEXITCODE

# 3. Make sure the demo window is gone.
if (-not $psProc.HasExited) {
    try { $psProc.WaitForExit(5000) } catch {}
    if (-not $psProc.HasExited) { Stop-Process -Id $psProc.Id -Force -ErrorAction SilentlyContinue }
}

if ($ffExit -ne 0) {
    Write-Host "ffmpeg exited with code $ffExit" -ForegroundColor Red
    exit $ffExit
}

$file = Get-Item $outputPath -ErrorAction SilentlyContinue
if ($file) {
    Write-Host ("Done. {0:N2} MB at {1}" -f ($file.Length / 1MB), $file.FullName) -ForegroundColor Green
} else {
    Write-Host "ffmpeg returned 0 but output file is missing" -ForegroundColor Red
    exit 1
}

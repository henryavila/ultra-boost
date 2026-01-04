<#
.SYNOPSIS
    UltraBoost - System Optimization Utility

.DESCRIPTION
    All-in-one system optimizer:
    1. Interactive menu to configure options
    2. Frees maximum system resources (ULTRA BOOST)
    3. Optionally starts ComfyUI (Main or Legacy)
    4. Optionally starts Mobile Wrappers
    5. Opens optimized browser for each service

.NOTES
    Author: Claude Code
    Version: 1.0
    To restore after boost: Restart your computer
#>

$ErrorActionPreference = "SilentlyContinue"

# ============================================================================
# LOAD LIBRARIES
# ============================================================================

. "$PSScriptRoot\lib\Common.ps1"
. "$PSScriptRoot\lib\Menu.ps1"
. "$PSScriptRoot\lib\Boost.ps1"

# ============================================================================
# CHECK ADMIN
# ============================================================================

if (-not (Test-IsAdmin)) {
    Request-AdminAndRestart -ScriptPath $MyInvocation.MyCommand.Path
}

# ============================================================================
# SHOW MENU
# ============================================================================

Invoke-Menu
$selection = Get-MenuSelection

# ============================================================================
# EXECUTE ULTRA BOOST
# ============================================================================

Write-Header "EXECUTING ULTRA BOOST..."
$memFreed = Invoke-UltraBoost

# ============================================================================
# START COMFYUI (if selected)
# ============================================================================

$comfyStarted = $false

if ($selection.App -ne 2) {
    # 0 = Main, 1 = Legacy
    $comfyPath = if ($selection.App -eq 0) { $script:ComfyUIMain } else { $script:ComfyUILegacy }
    $comfyBat = Join-Path $comfyPath "run_nvidia_gpu.bat"
    $comfyName = if ($selection.App -eq 0) { "Main" } else { "Legacy" }

    Write-Header "STARTING COMFYUI ($comfyName)..."

    if (Test-ComfyUIRunning) {
        Write-OK "ComfyUI is already running"
        $comfyStarted = $true
    } else {
        Write-Info "Starting ComfyUI..."
        Start-Process -FilePath "cmd.exe" -ArgumentList "/k", "cd /d `"$comfyPath`" && `"$comfyBat`"" -WindowStyle Normal

        Write-Info "Waiting for server..."
        $attempts = 0
        $maxAttempts = 120

        while ($attempts -lt $maxAttempts) {
            if (Test-ComfyUIRunning) {
                Write-Host ""
                Write-OK "ComfyUI ready!"

                # Set high priority
                $pythonProcs = Get-Process -Name "python*" -ErrorAction SilentlyContinue
                foreach ($p in $pythonProcs) {
                    try { $p.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High } catch { }
                }

                $comfyStarted = $true
                break
            }
            Start-Sleep -Seconds 1
            $attempts++
            if ($attempts % 10 -eq 0) { Write-Host "." -NoNewline }
        }

        if (-not $comfyStarted) {
            Write-Warn "Timeout waiting for ComfyUI"
        }
    }
}

# ============================================================================
# START MOBILE WRAPPERS (if selected)
# ============================================================================

$urlsToOpen = @()

# ComfyUI browser
if ($comfyStarted) {
    $urlsToOpen += $script:ComfyUIUrl
}

# ComfyUIMini
if ($selection.ComfyUIMini) {
    Write-Header "STARTING COMFYUIMINI..."

    $miniStartBat = Join-Path $script:ComfyUIMiniPath "scripts\start.bat"

    if (Test-Path $miniStartBat) {
        Write-Info "Starting ComfyUIMini..."
        Start-Process -FilePath "cmd.exe" -ArgumentList "/k", "cd /d `"$script:ComfyUIMiniPath`" && `"$miniStartBat`"" -WindowStyle Normal

        # Wait for it to start
        Write-Info "Waiting for ComfyUIMini..."
        $attempts = 0
        while ($attempts -lt 30) {
            if (Test-UrlRunning -Url $script:ComfyUIMiniUrl) {
                Write-OK "ComfyUIMini ready!"
                $urlsToOpen += $script:ComfyUIMiniUrl
                break
            }
            Start-Sleep -Seconds 1
            $attempts++
        }

        if ($attempts -ge 30) {
            Write-Warn "ComfyUIMini may not be ready yet"
            $urlsToOpen += $script:ComfyUIMiniUrl  # Try anyway
        }
    } else {
        Write-Fail "ComfyUIMini start script not found: $miniStartBat"
    }
}

# ViewComfy
if ($selection.ViewComfy) {
    Write-Header "STARTING VIEWCOMFY..."

    if (Test-Path $script:ViewComfyPath) {
        Write-Info "Starting ViewComfy (npm run dev)..."
        Start-Process -FilePath "cmd.exe" -ArgumentList "/k", "cd /d `"$script:ViewComfyPath`" && npm run dev" -WindowStyle Normal

        # Wait for it to start
        Write-Info "Waiting for ViewComfy..."
        $attempts = 0
        while ($attempts -lt 60) {
            if (Test-UrlRunning -Url $script:ViewComfyUrl) {
                Write-OK "ViewComfy ready!"
                $urlsToOpen += $script:ViewComfyUrl
                break
            }
            Start-Sleep -Seconds 1
            $attempts++
        }

        if ($attempts -ge 60) {
            Write-Warn "ViewComfy may not be ready yet"
            $urlsToOpen += $script:ViewComfyUrl  # Try anyway
        }
    } else {
        Write-Fail "ViewComfy path not found: $($script:ViewComfyPath)"
    }
}

# MobileClient (no need to start, just open URL)
if ($selection.MobileClient -and $comfyStarted) {
    Write-Header "OPENING MOBILECLIENT..."
    $urlsToOpen += $script:MobileClientUrl
}

# ============================================================================
# OPEN BROWSERS (via non-elevated Watcher)
# ============================================================================

if ($urlsToOpen.Count -gt 0) {
    Write-Header "PREPARING BROWSERS..."

    # Kill all Edge instances before opening new ones
    $existingEdge = Get-Process -Name "msedge" -ErrorAction SilentlyContinue
    if ($existingEdge) {
        Write-Info "Closing $($existingEdge.Count) Edge processes..."
        $existingEdge | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Write-OK "Edge closed"
    }

    # Write URLs to temp file for the non-elevated Watcher to open
    $urlFile = Join-Path $env:TEMP "ultraboost_urls.txt"
    $urlsToOpen | Out-File -FilePath $urlFile -Encoding ASCII -Force

    Write-OK "URLs queued ($($urlsToOpen.Count) windows)"
    Write-Info "Edge will open automatically (non-elevated)..."
    Write-Host ""
    Write-Host "  If Edge doesn't open, run manually:" -ForegroundColor DarkGray
    foreach ($url in $urlsToOpen) {
        Write-Host "    Edge.bat `"$url`"" -ForegroundColor DarkGray
    }
}

# ============================================================================
# SUMMARY
# ============================================================================

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "                      ALL READY!                               " -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""

if ($comfyStarted) {
    Write-Host "  ComfyUI: $($script:ComfyUIUrl)" -ForegroundColor White
}

if ($selection.ComfyUIMini) {
    Write-Host "  ComfyUIMini: $($script:ComfyUIMiniUrl)" -ForegroundColor White
}

if ($selection.ViewComfy) {
    Write-Host "  ViewComfy: $($script:ViewComfyUrl)" -ForegroundColor White
}

if ($selection.MobileClient -and $comfyStarted) {
    Write-Host "  MobileClient: $($script:MobileClientUrl)" -ForegroundColor White
}

Write-Host ""
Write-Host "  BOOST active - To restore: RESTART your PC" -ForegroundColor Yellow
Write-Host "  Memory freed: +$([math]::Round($memFreed, 2)) GB" -ForegroundColor Green
Write-Host ""

# Keep window open briefly
Start-Sleep -Seconds 5

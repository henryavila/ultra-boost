<#
.SYNOPSIS
    UltraBoost - System Optimization Utility

.DESCRIPTION
    All-in-one system optimizer:
    1. Interactive menu to configure options
    2. Frees maximum system resources (ULTRA BOOST)
    3. Optionally starts configured apps
    4. Optionally starts configured extras
    5. Opens configured URLs in optimized browser

.NOTES
    Author: Claude Code
    Version: 1.1
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
# START APP (if selected)
# ============================================================================

$appStarted = $false
$appUrl = $null

if ($selection.App) {
    $app = $selection.App
    Write-Header "STARTING $($app.name.ToUpper())..."

    # Check if already running
    if ($app.url -and (Test-UrlRunning -Url $app.url)) {
        Write-OK "$($app.name) is already running"
        $appStarted = $true
        $appUrl = $app.url
    } else {
        # Start the app
        $appPath = $app.path
        $appCommand = $app.command

        if ($appPath -and $appCommand -and (Test-Path $appPath)) {
            $fullCommand = Join-Path $appPath $appCommand
            Write-Info "Starting $($app.name)..."

            Start-Process -FilePath "cmd.exe" -ArgumentList "/k", "cd /d `"$appPath`" && `"$fullCommand`"" -WindowStyle Normal

            # Wait for URL if configured
            if ($app.waitForUrl -and $app.url) {
                Write-Info "Waiting for server..."
                $attempts = 0
                $maxAttempts = 120

                while ($attempts -lt $maxAttempts) {
                    if (Test-UrlRunning -Url $app.url) {
                        Write-Host ""
                        Write-OK "$($app.name) ready!"

                        # Set high priority for python
                        $pythonProcs = Get-Process -Name "python*" -ErrorAction SilentlyContinue
                        foreach ($p in $pythonProcs) {
                            try { $p.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High } catch { }
                        }

                        $appStarted = $true
                        $appUrl = $app.url
                        break
                    }
                    Start-Sleep -Seconds 1
                    $attempts++
                    if ($attempts % 10 -eq 0) { Write-Host "." -NoNewline }
                }

                if (-not $appStarted) {
                    Write-Warn "Timeout waiting for $($app.name)"
                }
            } else {
                # No waitForUrl, just assume it started
                $appStarted = $true
                $appUrl = $app.url
                Start-Sleep -Seconds 2
            }
        } else {
            Write-Fail "Path not found: $appPath"
        }
    }
}

# ============================================================================
# START EXTRAS (if selected)
# ============================================================================

$extraUrls = @()

foreach ($extra in $selection.Extras) {
    # Skip if requires app and app not started
    if ($extra.requiresApp -and -not $appStarted) {
        Write-Skip "$($extra.name) skipped (requires app)"
        continue
    }

    Write-Header "STARTING $($extra.name.ToUpper())..."

    # If no path/command, it's just a URL (like MobileClient)
    if (-not $extra.path -or -not $extra.command) {
        if ($extra.url) {
            Write-OK "$($extra.name) URL queued"
            $extraUrls += $extra.url
        }
        continue
    }

    # Start the extra
    $extraPath = $extra.path
    $extraCommand = $extra.command

    if (Test-Path $extraPath) {
        Write-Info "Starting $($extra.name)..."

        # Check if command contains npm/node
        if ($extraCommand -match "^npm\s") {
            Start-Process -FilePath "cmd.exe" -ArgumentList "/k", "cd /d `"$extraPath`" && $extraCommand" -WindowStyle Normal
        } else {
            $fullCommand = Join-Path $extraPath $extraCommand
            Start-Process -FilePath "cmd.exe" -ArgumentList "/k", "cd /d `"$extraPath`" && `"$fullCommand`"" -WindowStyle Normal
        }

        # Wait for URL if available
        if ($extra.url) {
            Write-Info "Waiting for $($extra.name)..."
            $attempts = 0
            $maxAttempts = 60

            while ($attempts -lt $maxAttempts) {
                if (Test-UrlRunning -Url $extra.url) {
                    Write-OK "$($extra.name) ready!"
                    $extraUrls += $extra.url
                    break
                }
                Start-Sleep -Seconds 1
                $attempts++
            }

            if ($attempts -ge $maxAttempts) {
                Write-Warn "$($extra.name) may not be ready yet"
                $extraUrls += $extra.url  # Try anyway
            }
        }
    } else {
        Write-Fail "Path not found: $extraPath"
    }
}

# ============================================================================
# COLLECT URLS TO OPEN
# ============================================================================

$urlsToOpen = @()

# App URL
if ($appStarted -and $appUrl) {
    $urlsToOpen += $appUrl
}

# Extra URLs
$urlsToOpen += $extraUrls

# Additional URLs from config
foreach ($urlItem in $selection.Urls) {
    $urlsToOpen += $urlItem.url
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

if ($appStarted) {
    Write-Host "  App: $($selection.App.name) - $appUrl" -ForegroundColor White
}

foreach ($extra in $selection.Extras) {
    if ($extra.url) {
        Write-Host "  Extra: $($extra.name) - $($extra.url)" -ForegroundColor White
    }
}

foreach ($urlItem in $selection.Urls) {
    Write-Host "  URL: $($urlItem.name)" -ForegroundColor White
}

Write-Host ""
Write-Host "  BOOST active - To restore: RESTART your PC" -ForegroundColor Yellow
Write-Host "  Memory freed: +$([math]::Round($memFreed, 2)) GB" -ForegroundColor Green
Write-Host ""

# Keep window open briefly
Start-Sleep -Seconds 5


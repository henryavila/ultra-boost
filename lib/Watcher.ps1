<#
.SYNOPSIS
    Watcher for UltraBoost - Opens Edge URLs without elevation

.DESCRIPTION
    This script runs NON-ELEVATED and waits for URL file from the elevated
    UltraBoost script. When URLs are found, it opens Edge for each one.
    If the file is empty or contains "CANCEL", it exits without opening Edge.

.NOTES
    Version: 1.0
#>

$ErrorActionPreference = "SilentlyContinue"

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptRoot = Split-Path -Parent $PSScriptRoot  # Go up from lib\ to root
$UrlFile = Join-Path $env:TEMP "ultraboost_urls.txt"
$EdgeBat = Join-Path $ScriptRoot "Edge.bat"
$TimeoutSeconds = 300  # 5 minutes max wait

# ============================================================================
# WAIT FOR URL FILE
# ============================================================================

$startTime = Get-Date
$found = $false

while (-not $found) {
    # Check timeout
    $elapsed = (Get-Date) - $startTime
    if ($elapsed.TotalSeconds -gt $TimeoutSeconds) {
        exit 0  # Timeout, exit silently
    }

    # Check for URL file
    if (Test-Path $UrlFile) {
        Start-Sleep -Milliseconds 500  # Wait for file to be fully written
        $found = $true
    } else {
        Start-Sleep -Seconds 1
    }
}

# ============================================================================
# READ URLS AND OPEN EDGE
# ============================================================================

$content = Get-Content $UrlFile -Raw -ErrorAction SilentlyContinue

# Delete file immediately to prevent re-processing
Remove-Item $UrlFile -Force -ErrorAction SilentlyContinue

# Check for cancel signal or empty file
if ([string]::IsNullOrWhiteSpace($content) -or $content -match "^CANCEL") {
    exit 0  # Cancelled or no URLs, exit silently
}

# Parse URLs (one per line)
$urls = $content -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

if ($urls -and $urls.Count -gt 0) {
    # Small delay to let elevated script finish its output
    Start-Sleep -Seconds 2

    foreach ($url in $urls) {
        # Start Edge (non-elevated, because this script is non-elevated)
        Start-Process -FilePath $EdgeBat -ArgumentList "`"$url`"" -WorkingDirectory $ScriptRoot
        Start-Sleep -Seconds 2
    }
}

exit 0

<#
.SYNOPSIS
    Opens Microsoft Edge in optimized app mode

.DESCRIPTION
    Standalone script to open Edge with performance optimizations.
    Can be called directly or from UltraBoost.

.PARAMETER Url
    The URL to open. If not specified, prompts user.

.EXAMPLE
    .\Edge.ps1 "https://google.com"
    .\Edge.ps1

.NOTES
    Version: 1.0
#>

param(
    [string]$Url
)

$ErrorActionPreference = "SilentlyContinue"

# ============================================================================
# CONFIGURATION
# ============================================================================

$ScriptRoot = $PSScriptRoot
$DefaultUrl = "https://www.google.com"
$EdgeProfilePath = Join-Path $ScriptRoot "EdgeProfile"

# Edge path - try both locations
if (Test-Path "C:\Program Files\Microsoft\Edge\Application\msedge.exe") {
    $EdgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
} else {
    $EdgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
}

# ============================================================================
# CONSOLE COLORS
# ============================================================================

function Write-Info { param($text) Write-Host "[*] $text" -ForegroundColor White }
function Write-OK { param($text) Write-Host "[OK] $text" -ForegroundColor Green }
function Write-Fail { param($text) Write-Host "[X] $text" -ForegroundColor Red }

# ============================================================================
# GET URL
# ============================================================================

if (-not $Url) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Edge Optimizado - Modo App" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    $userInput = Read-Host "  URL (Enter = Google)"

    if ([string]::IsNullOrWhiteSpace($userInput)) {
        $Url = $DefaultUrl
        Write-Info "Usando URL padrao: $DefaultUrl"
    } else {
        # Add https:// if no protocol specified
        if ($userInput -notmatch "^https?://") {
            $Url = "https://$userInput"
        } else {
            $Url = $userInput
        }
    }
    Write-Host ""
}


# ============================================================================
# CREATE PROFILE DIRECTORY
# ============================================================================

if (-not (Test-Path $EdgeProfilePath)) {
    New-Item -ItemType Directory -Path $EdgeProfilePath -Force | Out-Null
}

# ============================================================================
# BUILD EDGE ARGUMENTS
# ============================================================================

$EdgeArgs = @(
    "--app=$Url",
    "--user-data-dir=`"$EdgeProfilePath`"",
    "--no-first-run",
    "--no-default-browser-check",
    "--disable-extensions",
    "--disable-plugins",
    "--disable-sync",
    "--disable-background-networking",
    "--disable-background-timer-throttling",
    "--disable-backgrounding-occluded-windows",
    "--disable-breakpad",
    "--disable-client-side-phishing-detection",
    "--disable-component-update",
    "--disable-default-apps",
    "--disable-dev-shm-usage",
    "--disable-domain-reliability",
    "--disable-features=msEdgeSidebarV2,msEdgeDiscoverAndRelatedContent,msEdgeTravelAssist,msEdgeShopping,msEdgeShoppingUI,msEdgeCollections,EdgeCollections,msEdgeHubAppService,msEdgeLiveCaptions,msEdgeBrowserEssentials,msEdgeDropUI,msEdgeWorkspacesUI,EdgeDesktopUpdates,BackgroundSync,TranslateUI,msEdgeEnableNurturingUnit,edge-updater",
    "--disable-hang-monitor",
    "--disable-ipc-flooding-protection",
    "--disable-notifications",
    "--disable-popup-blocking",
    "--disable-prompt-on-repost",
    "--disable-renderer-backgrounding",
    "--disable-search-engine-choice-screen",
    "--disable-translate",
    "--metrics-recording-only",
    "--no-pings",
    "--password-store=basic",
    "--force-color-profile=srgb",
    "--edge-skip-tos-dialog",
    "--process-per-site",
    "--renderer-process-limit=2",
    "--js-flags=--max-old-space-size=512"
) -join " "

# ============================================================================
# START EDGE
# ============================================================================

Write-Info "Iniciando Edge em modo app..."
Write-Info "URL: $Url"

Start-Process -FilePath $EdgePath -ArgumentList $EdgeArgs

Start-Sleep -Seconds 2

# ============================================================================
# VERIFY
# ============================================================================

$newEdge = Get-Process -Name "msedge" -ErrorAction SilentlyContinue | Where-Object {
    try {
        $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)" -ErrorAction SilentlyContinue).CommandLine
        $cmd -like "*EdgeProfile*" -or $cmd -like "*UltraBoost*"
    } catch {
        $false
    }
}

if ($newEdge) {
    $totalMB = ($newEdge | Measure-Object -Property WorkingSet64 -Sum).Sum / 1MB
    Write-OK "Edge iniciado ($([math]::Round($totalMB))MB)"
} else {
    Write-Fail "Falha ao iniciar Edge"
}

Write-Host ""

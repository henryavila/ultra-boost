<#
.SYNOPSIS
    Common functions and configuration for UltraBoost

.DESCRIPTION
    Loads config from JSON, shared whitelist, helper functions.
    Source this file in other scripts: . "$PSScriptRoot\lib\Common.ps1"

.NOTES
    Version: 1.1
#>

# ============================================================================
# VERSION
# ============================================================================

$script:UltraBoostVersion = "1.1"

# ============================================================================
# CONSOLE COLORS (define first, used by config loading)
# ============================================================================

function Write-Header { param($text) Write-Host "`n$text" -ForegroundColor Cyan }
function Write-OK { param($text) Write-Host "[OK] $text" -ForegroundColor Green }
function Write-Info { param($text) Write-Host "[*] $text" -ForegroundColor White }
function Write-Warn { param($text) Write-Host "[!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host "[X] $text" -ForegroundColor Red }
function Write-Skip { param($text) Write-Host "[~] $text" -ForegroundColor DarkGray }

# ============================================================================
# CONFIG LOADING
# ============================================================================

function Get-UltraBoostRoot {
    # lib\Common.ps1 -> UltraBoost\
    return Split-Path -Parent $PSScriptRoot
}

function Load-Config {
    $root = Get-UltraBoostRoot
    $configPath = Join-Path $root "config.json"
    $examplePath = Join-Path $root "config.example.json"

    # If config.json doesn't exist, prompt user
    if (-not (Test-Path $configPath)) {
        Write-Fail "config.json not found!"
        Write-Host ""
        Write-Info "Create config.json from config.example.json:"
        Write-Host "  copy config.example.json config.json" -ForegroundColor Yellow
        Write-Host ""
        Write-Info "Then edit config.json with your settings."
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Load and parse JSON
    try {
        $json = Get-Content $configPath -Raw -Encoding UTF8
        $config = $json | ConvertFrom-Json
    } catch {
        Write-Fail "Invalid JSON in config.json!"
        Write-Host ""
        Write-Host "  Error: $_" -ForegroundColor Red
        Write-Host ""
        Write-Info "Check your config.json for syntax errors."
        Write-Info "Use a JSON validator: https://jsonlint.com"
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Validate required structure
    $errors = @()

    if ($null -eq $config.apps) {
        $errors += "Missing 'apps' array"
    } elseif ($config.apps -isnot [System.Array]) {
        $errors += "'apps' must be an array"
    }

    if ($null -eq $config.extras) {
        $errors += "Missing 'extras' array"
    } elseif ($config.extras -isnot [System.Array]) {
        $errors += "'extras' must be an array"
    }

    if ($null -eq $config.urls) {
        $errors += "Missing 'urls' array"
    } elseif ($config.urls -isnot [System.Array]) {
        $errors += "'urls' must be an array"
    }

    if ($errors.Count -gt 0) {
        Write-Fail "Invalid config.json structure!"
        Write-Host ""
        foreach ($err in $errors) {
            Write-Host "  - $err" -ForegroundColor Red
        }
        Write-Host ""
        Write-Info "See config.example.json for correct format."
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Validate each app has required fields
    for ($i = 0; $i -lt $config.apps.Count; $i++) {
        $app = $config.apps[$i]
        if (-not $app.name) {
            Write-Warn "apps[$i]: missing 'name' field"
        }
    }

    # Validate each extra has required fields
    for ($i = 0; $i -lt $config.extras.Count; $i++) {
        $extra = $config.extras[$i]
        if (-not $extra.name) {
            Write-Warn "extras[$i]: missing 'name' field"
        }
    }

    return $config
}

# Load config at script load time
$script:Config = Load-Config

# ============================================================================
# CONFIG ACCESSORS
# ============================================================================

$script:Apps = @()
$script:Extras = @()
$script:Urls = @()
$script:BrowserDefaultUrl = "https://www.google.com"

if ($script:Config) {
    # Apps
    if ($script:Config.apps) {
        $script:Apps = @($script:Config.apps)
    }

    # Extras
    if ($script:Config.extras) {
        $script:Extras = @($script:Config.extras)
    }

    # URLs
    if ($script:Config.urls) {
        $script:Urls = @($script:Config.urls)
    }

    # Browser
    if ($script:Config.browser -and $script:Config.browser.defaultUrl) {
        $script:BrowserDefaultUrl = $script:Config.browser.defaultUrl
    }
}

# ============================================================================
# MENU STATE (set by Menu.ps1)
# ============================================================================

$script:SelectedAppIndex = -1      # -1 = Boost only, 0+ = app index
$script:SelectedExtras = @()       # Array of enabled extra indices
$script:SelectedUrls = @()         # Array of enabled URL indices

# ============================================================================
# BASE WHITELIST - PROCESSES TO NEVER KILL
# ============================================================================

$script:BaseWhitelistProcesses = @(
    # ComfyUI / Python
    "python", "python3", "pythonw", "python*",

    # NVIDIA GPU (critical for CUDA)
    "nvcontainer", "nvidia*", "NVDisplay*", "NVIDIA*", "nvsphelper*",

    # AMD GPU / CPU
    "atiesrxx", "atieclxx", "amd*", "AMD*", "Radeon*",

    # Windows Core (CRITICAL)
    "System", "Idle", "smss", "csrss", "wininit", "winlogon", "services",
    "lsass", "lsaiso", "svchost", "dwm", "fontdrvhost", "Memory Compression",
    "Registry", "Secure System", "System Interrupts", "vmmem",
    "spoolsv", "wuauclt", "TrustedInstaller", "WmiPrvSE", "dllhost",
    "msdtc", "SecurityHealthService", "MsMpEng", "NisSrv",

    # Windows Shell & Explorer (CRITICAL)
    "explorer", "explorer.exe",
    "ShellExperienceHost", "StartMenuExperienceHost",
    "SearchHost", "SearchApp", "SearchIndexer", "SearchProtocolHost",
    "RuntimeBroker", "ApplicationFrameHost", "SystemSettings",
    "TextInputHost", "ctfmon", "sihost", "taskhostw", "backgroundTaskHost",
    "SettingSyncHost", "smartscreen", "UserOOBEBroker",

    # Terminals & Consoles (CRITICAL)
    "powershell", "pwsh", "cmd", "conhost",
    "WindowsTerminal", "OpenConsole", "wt",

    # Browsers
    "msedge", "msedge.exe", "msedgewebview2",

    # Remote Desktop (Jump Desktop)
    "JumpConnect", "JumpDesktop", "JumpClient",

    # Input Devices (Logitech)
    "LogiOptionsMgr", "Logi*",

    # Bluetooth (CRITICAL for wireless keyboard/mouse)
    "*bluetooth*", "*Bluetooth*",
    "bthudtask", "fsquirt",
    "BTStackServer", "BTTray",
    "ibtsiva", "ibttskex", "BTHSAmpPalService", "BTHSSecurityMgr",
    "RtkBtManServ", "RtkAudioService64"
)

# ============================================================================
# BASE WHITELIST - SERVICES TO NEVER STOP
# ============================================================================

$script:BaseWhitelistServices = @(
    # NVIDIA GPU
    "NVDisplay.ContainerLocalSystem", "NvContainerLocalSystem",
    "nvagent", "NvTelemetryContainer", "NvContainerNetworkService",

    # AMD CPU (Ryzen - 3D V-Cache)
    "amd3dvcacheSvc", "AMD Crash Defender Service", "AMD External Events Utility",
    "AmdPpkgSvc", "AmdAppCompatSvc",

    # Windows Core Services (CRITICAL)
    "Schedule",
    "CryptSvc", "KeyIso", "SamSs", "VaultSvc",
    "SecurityHealthService", "WinDefend", "WdNisSvc",
    "DcomLaunch", "RpcSs", "RpcEptMapper", "LSM", "ProfSvc",
    "UserManager", "Appinfo",
    "Power", "PlugPlay", "EventLog", "Winmgmt", "SENS",
    "SystemEventsBroker", "TimeBrokerSvc",

    # Windows Shell Services
    "ShellHWDetection", "Themes", "UxSms", "TabletInputService",
    "TokenBroker", "StateRepository", "StorSvc",

    # Networking
    "Dnscache", "nlasvc", "netprofm", "nsi", "Dhcp",
    "LanmanServer", "LanmanWorkstation", "Wcmsvc",
    "BFE", "mpssvc",

    # Audio
    "AudioEndpointBuilder", "Audiosrv", "AudioSrv",

    # Remote Desktop
    "JumpConnect", "JumpDesktopService",
    "TermService", "SessionEnv", "UmRdpService",

    # Bluetooth
    "bthserv", "BTAGService", "BthHFSrv", "BthA2dp",
    "BluetoothUserService_*", "BluetoothSupportService",
    "DeviceAssociationService", "DeviceAssociationBrokerSvc_*",
    "DevicesFlowUserSvc_*", "DevQueryBroker", "DsSvc",
    "ibtsiva", "IntelAudioService",
    "RtkBtManServ", "RtkAudioUniversalService",

    # HID
    "hidserv", "HidServ"
)

# ============================================================================
# MERGED WHITELISTS (base + extras from config)
# ============================================================================

$script:WhitelistProcesses = $script:BaseWhitelistProcesses
$script:WhitelistServices = $script:BaseWhitelistServices

if ($script:Config -and $script:Config.whitelist) {
    if ($script:Config.whitelist.extraProcesses) {
        $script:WhitelistProcesses = $script:BaseWhitelistProcesses + @($script:Config.whitelist.extraProcesses)
    }
    if ($script:Config.whitelist.extraServices) {
        $script:WhitelistServices = $script:BaseWhitelistServices + @($script:Config.whitelist.extraServices)
    }
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Test-Whitelisted {
    param([string]$Name, [string[]]$List)
    foreach ($pattern in $List) {
        if ($Name -like $pattern) { return $true }
    }
    return $false
}

function Test-UrlRunning {
    param([string]$Url)
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec 2 -UseBasicParsing
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
}

function Test-IsAdmin {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Request-AdminAndRestart {
    param([string]$ScriptPath)

    Write-Warn "UltraBoost requires administrator privileges. Restarting..."
    Start-Sleep -Seconds 1

    $argList = "-ExecutionPolicy Bypass -File `"$ScriptPath`""

    Start-Process powershell -ArgumentList $argList -Verb RunAs
    exit
}


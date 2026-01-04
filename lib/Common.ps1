<#
.SYNOPSIS
    Common functions and configuration for UltraBoost

.DESCRIPTION
    Shared whitelist, helper functions, and configuration.
    Source this file in other scripts: . "$PSScriptRoot\lib\Common.ps1"

.NOTES
    Version: 4.0
#>

# ============================================================================
# CONFIGURATION
# ============================================================================

$script:UltraBoostVersion = "1.0"

# ComfyUI Paths
$script:ComfyUIMain = "C:\ComfyUI\main"
$script:ComfyUILegacy = "C:\ComfyUI\legacy"
$script:ComfyUIUrl = "http://127.0.0.1:8188"

# Mobile Wrappers
$script:WrappersPath = "C:\ComfyUI\wrappers"
$script:ComfyUIMiniPath = Join-Path $script:WrappersPath "ComfyUIMini"
$script:ComfyUIMiniUrl = "http://127.0.0.1:3100"
$script:ViewComfyPath = Join-Path $script:WrappersPath "ViewComfy"
$script:ViewComfyUrl = "http://127.0.0.1:3000"
$script:MobileClientUrl = "http://127.0.0.1:8188/extensions/ComfyUI-MobileClient/index.html"

# Browser
$script:DefaultBrowserUrl = "https://www.google.com"

# ============================================================================
# MENU STATE (set by Menu.ps1)
# ============================================================================

$script:SelectedApp = 0          # 0=Main, 1=Legacy, 2=None
$script:EnableComfyUIMini = $false
$script:EnableViewComfy = $false
$script:EnableMobileClient = $false

# ============================================================================
# CONSOLE COLORS
# ============================================================================

function Write-Header { param($text) Write-Host "`n$text" -ForegroundColor Cyan }
function Write-OK { param($text) Write-Host "[OK] $text" -ForegroundColor Green }
function Write-Info { param($text) Write-Host "[*] $text" -ForegroundColor White }
function Write-Warn { param($text) Write-Host "[!] $text" -ForegroundColor Yellow }
function Write-Fail { param($text) Write-Host "[X] $text" -ForegroundColor Red }
function Write-Skip { param($text) Write-Host "[~] $text" -ForegroundColor DarkGray }

# ============================================================================
# WHITELIST - PROCESSES TO NEVER KILL
# ============================================================================

$script:WhitelistProcesses = @(
    # -------------------------------------------------------------------------
    # ComfyUI / Python
    # -------------------------------------------------------------------------
    "python", "python3", "pythonw", "python*",

    # -------------------------------------------------------------------------
    # NVIDIA GPU (critical for CUDA)
    # -------------------------------------------------------------------------
    "nvcontainer", "nvidia*", "NVDisplay*", "NVIDIA*", "nvsphelper*",

    # -------------------------------------------------------------------------
    # AMD GPU / CPU
    # -------------------------------------------------------------------------
    "atiesrxx", "atieclxx", "amd*", "AMD*", "Radeon*",

    # -------------------------------------------------------------------------
    # Windows Core (CRITICAL - system won't boot/function without these)
    # -------------------------------------------------------------------------
    "System", "Idle", "smss", "csrss", "wininit", "winlogon", "services",
    "lsass", "lsaiso", "svchost", "dwm", "fontdrvhost", "Memory Compression",
    "Registry", "Secure System", "System Interrupts", "vmmem",
    "spoolsv", "wuauclt", "TrustedInstaller", "WmiPrvSE", "dllhost",
    "msdtc", "SecurityHealthService", "MsMpEng", "NisSrv",

    # -------------------------------------------------------------------------
    # Windows Shell & Explorer (CRITICAL - desktop/taskbar)
    # -------------------------------------------------------------------------
    "explorer", "explorer.exe",
    "ShellExperienceHost", "StartMenuExperienceHost",
    "SearchHost", "SearchApp", "SearchIndexer", "SearchProtocolHost",
    "RuntimeBroker", "ApplicationFrameHost", "SystemSettings",
    "TextInputHost", "ctfmon", "sihost", "taskhostw", "backgroundTaskHost",
    "SettingSyncHost", "smartscreen", "UserOOBEBroker",

    # -------------------------------------------------------------------------
    # Terminals & Consoles (CRITICAL - for running scripts)
    # -------------------------------------------------------------------------
    "powershell", "pwsh", "cmd", "conhost",
    "WindowsTerminal", "OpenConsole", "wt",

    # -------------------------------------------------------------------------
    # Browsers (for ComfyUI web interface)
    # -------------------------------------------------------------------------
    "msedge", "msedge.exe", "msedgewebview2",

    # -------------------------------------------------------------------------
    # Claude Code (CLI)
    # -------------------------------------------------------------------------
    "claude", "claude.exe",

    # -------------------------------------------------------------------------
    # Warp Terminal
    # -------------------------------------------------------------------------
    "warp", "warp.exe", "warp-*", "Warp", "WarpSvc", "CloudflareWARP",

    # -------------------------------------------------------------------------
    # Remote Desktop (Jump Desktop)
    # -------------------------------------------------------------------------
    "JumpConnect", "JumpDesktop", "JumpClient",

    # -------------------------------------------------------------------------
    # Input Devices (Logitech only - Razer/Corsair bloatware will be killed)
    # -------------------------------------------------------------------------
    "LogiOptionsMgr", "Logi*",

    # -------------------------------------------------------------------------
    # Node.js (for Claude Code, mobile wrappers, etc.)
    # -------------------------------------------------------------------------
    "node", "node.exe",

    # -------------------------------------------------------------------------
    # Bluetooth (CRITICAL for wireless keyboard/mouse)
    # -------------------------------------------------------------------------
    "*bluetooth*", "*Bluetooth*",  # Generic catch-all
    "bthudtask", "fsquirt",  # Windows Bluetooth utilities
    "BTStackServer", "BTTray",  # Common Bluetooth tray/server
    # Intel Bluetooth
    "ibtsiva", "ibttskex", "BTHSAmpPalService", "BTHSSecurityMgr",
    # Realtek Bluetooth
    "RtkBtManServ", "RtkAudioService64"
)

# ============================================================================
# WHITELIST - SERVICES TO NEVER STOP
# ============================================================================

$script:WhitelistServices = @(
    # -------------------------------------------------------------------------
    # NVIDIA GPU (ALL NVIDIA services - critical for CUDA)
    # -------------------------------------------------------------------------
    "NVDisplay.ContainerLocalSystem", "NvContainerLocalSystem",
    "nvagent", "NvTelemetryContainer", "NvContainerNetworkService",

    # -------------------------------------------------------------------------
    # AMD CPU (Ryzen 9950X3D - 3D V-Cache requires these)
    # -------------------------------------------------------------------------
    "amd3dvcacheSvc", "AMD Crash Defender Service", "AMD External Events Utility",
    "AmdPpkgSvc", "AmdAppCompatSvc",

    # -------------------------------------------------------------------------
    # Windows Core Services (CRITICAL)
    # -------------------------------------------------------------------------
    # Task Scheduler
    "Schedule",

    # Security & Crypto
    "CryptSvc", "KeyIso", "SamSs", "VaultSvc",
    "SecurityHealthService", "WinDefend", "WdNisSvc",

    # User & Session
    "DcomLaunch", "RpcSs", "RpcEptMapper", "LSM", "ProfSvc",
    "UserManager", "Appinfo",

    # System
    "Power", "PlugPlay", "EventLog", "Winmgmt", "SENS",
    "SystemEventsBroker", "TimeBrokerSvc",

    # -------------------------------------------------------------------------
    # Windows Shell Services (needed for Explorer)
    # -------------------------------------------------------------------------
    "ShellHWDetection", "Themes", "UxSms", "TabletInputService",
    "TokenBroker", "StateRepository", "StorSvc",

    # -------------------------------------------------------------------------
    # Networking (needed for ComfyUI HTTP server)
    # -------------------------------------------------------------------------
    "Dnscache", "nlasvc", "netprofm", "nsi", "Dhcp",
    "LanmanServer", "LanmanWorkstation", "Wcmsvc",
    "BFE", "mpssvc",  # Firewall

    # -------------------------------------------------------------------------
    # Audio (for media generation)
    # -------------------------------------------------------------------------
    "AudioEndpointBuilder", "Audiosrv", "AudioSrv",

    # -------------------------------------------------------------------------
    # Remote Desktop (Jump Desktop)
    # -------------------------------------------------------------------------
    "JumpConnect", "JumpDesktopService",
    "TermService", "SessionEnv", "UmRdpService",

    # -------------------------------------------------------------------------
    # Bluetooth (wireless keyboard/mouse) - CRITICAL for BT peripherals
    # -------------------------------------------------------------------------
    "bthserv", "BTAGService", "BthHFSrv", "BthA2dp",
    "BluetoothUserService_*", "BluetoothSupportService",

    # Device association (needed for Bluetooth pairing/connection)
    "DeviceAssociationService", "DeviceAssociationBrokerSvc_*",
    "DevicesFlowUserSvc_*", "DevQueryBroker", "DsSvc",

    # Manufacturer Bluetooth services (Intel, Realtek, etc.)
    "ibtsiva", "IntelAudioService",  # Intel
    "RtkBtManServ", "RtkAudioUniversalService",  # Realtek

    # -------------------------------------------------------------------------
    # HID (Human Interface Devices - keyboards, mice)
    # -------------------------------------------------------------------------
    "hidserv", "HidServ"
)

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

function Test-ComfyUIRunning {
    try {
        $response = Invoke-WebRequest -Uri $script:ComfyUIUrl -TimeoutSec 2 -UseBasicParsing
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
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


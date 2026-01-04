# UltraBoost v1.1 - Design Document

**Date:** 2026-01-04
**Author:** Claude Code
**Status:** Implemented

---

## Overview

UltraBoost is a system optimization utility that frees maximum RAM for heavy workloads. It optionally starts configured apps and opens an optimized browser.

---

## Architecture

### File Structure

```text
UltraBoost/
+-- config.json               # User configuration (gitignored)
+-- config.example.json       # Example with all fields
+-- UltraBoost.bat            # Entry point (creates task, runs script)
+-- UltraBoost.ps1            # Main script (elevated)
+-- Edge.bat                  # Opens optimized Edge (standalone)
+-- Edge.ps1                  # Edge standalone logic
+-- Rocket-3d.ico             # Microsoft Fluent 3D icon
|
+-- EdgeProfile/              # Isolated Edge profile (created on first use, gitignored)
|
+-- lib/
    +-- Common.ps1            # Config loader, whitelists, helpers
    +-- Boost.ps1             # ULTRA BOOST logic
    +-- Menu.ps1              # Interactive arrow-key menu
    +-- Watcher.ps1           # Opens Edge non-elevated (background)
```

---

## Main Flow

```text
+-------------------------------------------------------------+
|                    ULTRABOOST v1.1                          |
+-------------------------------------------------------------+
|                                                             |
|  1. User runs UltraBoost.bat (via elevated shortcut)        |
|                        |                                    |
|                        v                                    |
|  2. schtasks /create Watcher with /rl LIMITED               |
|     (creates task that runs NON-ELEVATED)                   |
|                        |                                    |
|                        v                                    |
|  3. schtasks /run (starts Watcher in background)            |
|                        |                                    |
|                        v                                    |
|  4. powershell UltraBoost.ps1 (elevated)                    |
|     +---------------------------------------------+         |
|     |  * Shows INTERACTIVE MENU                   |         |
|     |  * Executes ULTRA BOOST                     |         |
|     |  * Starts App (if selected)                 |         |
|     |  * Starts Extras (if selected)              |         |
|     |  * Writes URLs to %TEMP%\..._urls.txt       |         |
|     +---------------------------------------------+         |
|                        |                                    |
|                        v                                    |
|  5. Watcher.ps1 detects URL file                            |
|     (running NON-ELEVATED via Task Scheduler)               |
|                        |                                    |
|                        v                                    |
|  6. Watcher opens Edge.bat for each URL                     |
|     (Edge runs NON-ELEVATED, no conflict)                   |
|                        |                                    |
|                        v                                    |
|  7. schtasks /delete (cleans up temporary task)             |
|                        |                                    |
|                        v                                    |
|  8. END - Shows summary                                     |
|                                                             |
+-------------------------------------------------------------+
```

---

## Interactive Menu

### Controls

| Key | Action |
|-----|--------|
| `Up` `Down` | Navigate within current section |
| `Tab` | Switch between sections |
| `Space` | Toggle checkbox / select radio |
| `Enter` | Confirm and execute |
| `Esc` | Cancel (writes CANCEL for Watcher to exit) |

### Sections

1. **Apps** - Radio buttons, one selection
2. **Extras** - Checkboxes, multiple selections
3. **URLs** - Checkboxes, additional URLs to open

---

## Configuration (config.json)

```json
{
  "apps": [...],
  "extras": [...],
  "urls": [...],
  "browser": { "defaultUrl": "..." },
  "whitelist": {
    "extraProcesses": [...],
    "extraServices": [...]
  }
}
```

### App/Extra Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Display name |
| `path` | string | Directory path |
| `command` | string | Start command |
| `url` | string | URL to open |
| `waitForUrl` | bool | Wait for URL before continuing |
| `requiresApp` | bool | (extras) Requires app running |
| `default` | bool | Pre-selected in menu |

---

## Edge Standalone

### Flow

```text
Edge.bat "url"  ------>  Opens URL directly

Edge.bat        ------>  Prompt: "URL (Enter = Google): "
                            |
                            +-- Typed URL -> Opens URL
                            +-- Empty Enter -> Opens Google
```

### Edge Configuration (App Mode)

```powershell
$EdgeArgs = @(
    "--app=$Url",
    "--user-data-dir=`"$EdgeProfilePath`"",

    # Disables Edge bloatware
    "--disable-features=msEdgeSidebarV2,msEdgeDiscoverAndRelatedContent,
     msEdgeShopping,msEdgeCollections,msEdgeLiveCaptions,EdgeDesktopUpdates",

    # Performance
    "--disable-extensions",
    "--disable-background-networking",
    "--disable-sync",
    "--process-per-site",
    "--renderer-process-limit=2",
    "--js-flags=--max-old-space-size=512",

    # Clean
    "--no-first-run",
    "--disable-notifications",
    "--disable-translate"
)
```

---

## Boost Steps

| Order | Action | Details |
|-------|--------|---------|
| 1 | Disable scheduled tasks | Prevents process respawn |
| 2 | Stop non-essential services | Except whitelist |
| 3 | Kill non-essential processes | Except whitelist |
| 4 | Set Python HIGH priority | If running |
| 5 | Clear standby memory | RAMMap technique (ntdll.dll) |
| 6 | Report | Shows freed RAM |

---

## Whitelists

### Base Process Whitelist

- Python, NVIDIA, AMD GPU drivers
- Windows Core (System, svchost, dwm, csrss, etc.)
- Windows Shell (explorer, ShellExperienceHost, etc.)
- Terminals (powershell, cmd, WindowsTerminal)
- Browsers (msedge)
- Remote Desktop (JumpDesktop)
- Bluetooth processes
- Logitech input

### Base Service Whitelist

- GPU services (NVIDIA, AMD)
- Windows Core (Schedule, CryptSvc, RpcSs, etc.)
- Networking (Dnscache, Dhcp, BFE, etc.)
- Audio (AudioSrv)
- Remote Desktop
- Bluetooth services
- HID services

### User Extensions

Users add their own via `config.json`:

```json
"whitelist": {
  "extraProcesses": ["myapp", "node"],
  "extraServices": ["MyService"]
}
```

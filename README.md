# UltraBoost v1.1

System optimization utility that frees maximum RAM for heavy workloads. Configurable via JSON for any application.

## Installation

```cmd
git clone https://github.com/YOUR_USERNAME/UltraBoost.git
cd UltraBoost
copy config.example.json config.json
```

Edit `config.json` with your settings before running.

## Usage

**Via shortcut (create manually):**
- Create a shortcut to `UltraBoost.bat`
- Properties > Advanced > Run as administrator

**Via command line (admin):**
```cmd
UltraBoost.bat
```

## Configuration

Edit `config.json` to customize:

```json
{
  "apps": [
    {
      "name": "My App",
      "path": "C:\\Path\\To\\App",
      "command": "start.bat",
      "url": "http://127.0.0.1:8080",
      "waitForUrl": true,
      "default": true
    }
  ],

  "extras": [
    {
      "name": "Extra Tool",
      "path": "C:\\Path\\To\\Extra",
      "command": "run.bat",
      "url": "http://127.0.0.1:3000",
      "default": false
    }
  ],

  "urls": [
    {
      "name": "Documentation",
      "url": "https://docs.example.com",
      "default": false
    }
  ],

  "browser": {
    "defaultUrl": "https://www.google.com"
  },

  "whitelist": {
    "extraProcesses": ["myapp", "otherapp"],
    "extraServices": ["MyService"]
  }
}
```

### Config Sections

| Section | Description |
|---------|-------------|
| `apps` | Main applications (radio - one at a time) |
| `extras` | Optional tools (checkbox - multiple) |
| `urls` | Additional URLs to open (checkbox - multiple) |
| `browser` | Standalone Edge configuration |
| `whitelist` | Extra processes/services to protect |

### Apps/Extras Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Display name in menu |
| `path` | string | Application directory |
| `command` | string | Start command (relative to path) |
| `url` | string | URL to open in browser |
| `waitForUrl` | bool | Wait for URL to respond before continuing |
| `requiresApp` | bool | (extras) Requires app running |
| `default` | bool | Selected by default in menu |

### Default Behavior

- `apps`: First item with `"default": true` is selected. If none, selects "Boost Only"
- `extras`/`urls`: Each item with `"default": true` is checked
- If multiple apps have `"default": true`, only the first one counts

## Interactive Menu

```
==============================================================
                    ULTRABOOST v1.1
==============================================================

  Start application:                    <- Tab
  ----------------------------------------
  (*) ComfyUI Main
  ( ) ComfyUI Legacy
  ( ) Boost Only

  Extras:                               <- Tab
  ----------------------------------------
  [ ] ComfyUIMini
  [ ] ViewComfy
  [ ] MobileClient (requires app)

  Additional URLs:                      <- Tab
  ----------------------------------------
  [ ] ComfyUI Course
  [ ] Documentation

  ----------------------------------------
  [Arrows] Navigate  [Tab] Section  [Space] Toggle  [Enter] Confirm
==============================================================
```

### Controls

| Key | Action |
|-----|--------|
| `Up` `Down` | Navigate within section |
| `Tab` | Switch between sections |
| `Space` | Toggle/select item |
| `Enter` | Confirm and execute |
| `Esc` | Cancel |

## What the Boost Does

1. **Disables scheduled tasks** - Prevents process respawn
2. **Stops non-essential services** - Except whitelist
3. **Kills non-essential processes** - Except whitelist
4. **Sets Python to HIGH priority**
5. **Clears standby memory** - RAMMap technique (ntdll.dll)

## Optimized Edge (Standalone)

```cmd
Edge.bat                      # Prompts for URL (default: Google)
Edge.bat "https://url.com"    # Opens URL directly
```

- App mode (no address bar)
- Isolated profile in `EdgeProfile\`
- 30+ optimization flags
- 512MB JS heap limit

## File Structure

```
UltraBoost/
+-- config.json           # Your configuration (gitignored)
+-- config.example.json   # Example with all fields documented
+-- UltraBoost.bat        # Entry point
+-- UltraBoost.ps1        # Main script
+-- Edge.bat              # Standalone browser
+-- Edge.ps1              # Browser logic
+-- Rocket-3d.ico         # Icon
+-- lib/
    +-- Common.ps1        # Config loader, whitelists, helpers
    +-- Menu.ps1          # Dynamic interactive menu
    +-- Boost.ps1         # Boost logic
    +-- Watcher.ps1       # Opens Edge non-elevated
```

## Base Whitelist

UltraBoost automatically protects critical processes. Use `whitelist.extraProcesses` and `whitelist.extraServices` in config.json to add your own.

**Protected processes:** Python, NVIDIA, AMD, Windows Core, Explorer, Terminals, Browsers, Bluetooth, Logitech, Jump Desktop

**Protected services:** GPU drivers, Windows Core, Networking, Audio, Remote Desktop, Bluetooth, HID

## Recovery

After boost, to restore the system to normal:
- **Restart your computer**

## Changelog

| Version | Changes |
|---------|---------|
| 1.1 | JSON configuration system. Dynamic apps/extras/URLs. Menu with 3 sections. |
| 1.0 | Initial GitHub release. |

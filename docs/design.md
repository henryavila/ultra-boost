# UltraBoost v1.0 - Design Document

**Data:** 2026-01-04
**Autor:** Claude Code
**Status:** Implementado

---

## Visao Geral

UltraBoost e um utilitario de otimizacao de sistema que libera RAM maxima para tarefas pesadas. Opcionalmente inicia ComfyUI (Main ou Legacy) e Mobile Wrappers com browser otimizado.

---

## Arquitetura

### Estrutura de Arquivos

```
UltraBoost/
+-- UltraBoost.bat            # Entry point (cria task, roda script)
+-- UltraBoost.ps1            # Script principal (elevado)
+-- Edge.bat                  # Abre Edge otimizado (standalone)
+-- Edge.ps1                  # Logica do Edge standalone
+-- Rocket-3d.ico             # Icone Microsoft Fluent 3D
|
+-- EdgeProfile/              # Perfil isolado do Edge (criado no 1o uso, .gitignore)
|
+-- lib/
    +-- Common.ps1            # Configuracoes, whitelists, helpers
    +-- Boost.ps1             # Logica ULTRA BOOST
    +-- Menu.ps1              # Menu interativo com setas
    +-- Watcher.ps1           # Abre Edge nao-elevado (background)
```

---

## Fluxo Principal

```
+-------------------------------------------------------------+
|                    ULTRABOOST v1.0                          |
+-------------------------------------------------------------+
|                                                             |
|  1. Usuario executa UltraBoost.bat (via atalho elevado)     |
|                        |                                    |
|                        v                                    |
|  2. schtasks /create Watcher com /rl LIMITED                |
|     (cria task que roda NAO-ELEVADA)                        |
|                        |                                    |
|                        v                                    |
|  3. schtasks /run (inicia Watcher em background)            |
|                        |                                    |
|                        v                                    |
|  4. powershell UltraBoost.ps1 (elevado)                     |
|     +---------------------------------------------+         |
|     |  * Exibe MENU INTERATIVO                    |         |
|     |  * Executa ULTRA BOOST                      |         |
|     |  * Inicia ComfyUI (se selecionado)          |         |
|     |  * Inicia Wrappers (se selecionados)        |         |
|     |  * Escreve URLs em %TEMP%\..._urls.txt      |         |
|     +---------------------------------------------+         |
|                        |                                    |
|                        v                                    |
|  5. Watcher.ps1 detecta arquivo de URLs                     |
|     (rodando NAO-ELEVADO via Task Scheduler)                |
|                        |                                    |
|                        v                                    |
|  6. Watcher abre Edge.bat para cada URL                     |
|     (Edge roda NAO-ELEVADO, sem conflito)                   |
|                        |                                    |
|                        v                                    |
|  7. schtasks /delete (limpa task temporaria)                |
|                        |                                    |
|                        v                                    |
|  8. FIM - Exibe resumo                                      |
|                                                             |
+-------------------------------------------------------------+
```

---

## Menu Interativo

### Controles

| Tecla | Acao |
|-------|------|
| `Up` `Down` | Navega dentro da secao atual |
| `Tab` | Alterna entre secoes |
| `Espaco` | Toggle checkbox |
| `Enter` | Confirma e executa |
| `Esc` | Cancela (escreve CANCEL para Watcher sair) |

### Valores Padrao

| Item | Padrao |
|------|--------|
| Aplicacao | ComfyUI Main (selecionado) |
| ComfyUIMini | Desmarcado |
| ViewComfy | Desmarcado |
| MobileClient | Desmarcado |

---

## Edge.bat Standalone

### Fluxo

```
Edge.bat "url"  ------>  Abre URL direto

Edge.bat        ------>  Prompt: "URL (Enter = Google): "
                            |
                            +-- Digitou URL -> Abre URL
                            +-- Enter vazio -> Abre Google
```

### Configuracoes do Edge (App Mode)

```powershell
$EdgeArgs = @(
    "--app=$Url",
    "--user-data-dir=`"$EdgeProfilePath`"",

    # Desabilita bloatware do Edge
    "--disable-features=msEdgeSidebarV2,msEdgeDiscoverAndRelatedContent,
     msEdgeShopping,msEdgeCollections,msEdgeLiveCaptions,EdgeDesktopUpdates",

    # Performance
    "--disable-extensions",
    "--disable-background-networking",
    "--disable-sync",
    "--process-per-site",
    "--renderer-process-limit=2",
    "--js-flags=--max-old-space-size=512",

    # Limpo
    "--no-first-run",
    "--disable-notifications",
    "--disable-translate"
)
```

---

## Configuracoes (Common.ps1)

| Variavel | Valor |
|----------|-------|
| `$ComfyUIMain` | `C:\ComfyUI\main` |
| `$ComfyUILegacy` | `C:\ComfyUI\legacy` |
| `$ComfyUIUrl` | `http://127.0.0.1:8188` |
| `$DefaultBrowserUrl` | `https://www.google.com` |
| `$ComfyUIMiniPath` | `C:\ComfyUI\wrappers\ComfyUIMini` |
| `$ComfyUIMiniUrl` | `http://127.0.0.1:3100` |
| `$ViewComfyPath` | `C:\ComfyUI\wrappers\ViewComfy` |
| `$ViewComfyUrl` | `http://127.0.0.1:3000` |
| `$MobileClientUrl` | `http://127.0.0.1:8188/extensions/ComfyUI-MobileClient/index.html` |

---

## Whitelist de Processos

```powershell
$script:WhitelistProcesses = @(
    # ComfyUI / Python
    "python", "python3", "pythonw", "python*",

    # NVIDIA GPU (critico para CUDA)
    "nvcontainer", "nvidia*", "NVDisplay*", "NVIDIA*", "nvsphelper*",

    # AMD GPU / CPU (Ryzen 9950X3D)
    "atiesrxx", "atieclxx", "amd*", "AMD*", "Radeon*",

    # Windows Core (CRITICO)
    "System", "Idle", "smss", "csrss", "wininit", "winlogon", "services",
    "lsass", "lsaiso", "svchost", "dwm", "fontdrvhost", "Memory Compression",
    "Registry", "Secure System", "System Interrupts", "vmmem",
    "spoolsv", "wuauclt", "TrustedInstaller", "WmiPrvSE", "dllhost",
    "msdtc", "SecurityHealthService", "MsMpEng", "NisSrv",

    # Windows Shell & Explorer (CRITICO)
    "explorer", "explorer.exe",
    "ShellExperienceHost", "StartMenuExperienceHost",
    "SearchHost", "SearchApp", "SearchIndexer", "SearchProtocolHost",
    "RuntimeBroker", "ApplicationFrameHost", "SystemSettings",
    "TextInputHost", "ctfmon", "sihost", "taskhostw", "backgroundTaskHost",
    "SettingSyncHost", "smartscreen", "UserOOBEBroker",

    # Terminais & Consoles (CRITICO)
    "powershell", "pwsh", "cmd", "conhost",
    "WindowsTerminal", "OpenConsole", "wt",

    # Browser (para interface web)
    "msedge", "msedge.exe", "msedgewebview2",

    # Claude Code (CLI)
    "claude", "claude.exe",

    # Warp Terminal
    "warp", "warp.exe", "warp-*", "Warp", "WarpSvc", "CloudflareWARP",

    # Remote Desktop (Jump Desktop)
    "JumpConnect", "JumpDesktop", "JumpClient",

    # Input Devices (Logitech)
    "LogiOptionsMgr", "Logi*",

    # Node.js (Claude Code, wrappers)
    "node", "node.exe",

    # Bluetooth (CRITICO para teclado/mouse wireless)
    "*bluetooth*", "*Bluetooth*",
    "bthudtask", "fsquirt",
    "BTStackServer", "BTTray",
    "ibtsiva", "ibttskex", "BTHSAmpPalService", "BTHSSecurityMgr",
    "RtkBtManServ", "RtkAudioService64"
)
```

---

## Whitelist de Servicos

```powershell
$script:WhitelistServices = @(
    # NVIDIA GPU
    "NVDisplay.ContainerLocalSystem", "NvContainerLocalSystem",
    "nvagent", "NvTelemetryContainer", "NvContainerNetworkService",

    # AMD CPU (Ryzen 9950X3D - 3D V-Cache)
    "amd3dvcacheSvc", "AMD Crash Defender Service",
    "AMD External Events Utility", "AmdPpkgSvc", "AmdAppCompatSvc",

    # Windows Core
    "Schedule", "CryptSvc", "KeyIso", "SamSs", "VaultSvc",
    "SecurityHealthService", "WinDefend", "WdNisSvc",
    "DcomLaunch", "RpcSs", "RpcEptMapper", "LSM", "ProfSvc",
    "UserManager", "Appinfo", "Power", "PlugPlay", "EventLog",
    "Winmgmt", "SENS", "SystemEventsBroker", "TimeBrokerSvc",

    # Windows Shell
    "ShellHWDetection", "Themes", "UxSms", "TabletInputService",
    "TokenBroker", "StateRepository", "StorSvc",

    # Networking
    "Dnscache", "nlasvc", "netprofm", "nsi", "Dhcp",
    "LanmanServer", "LanmanWorkstation", "Wcmsvc", "BFE", "mpssvc",

    # Audio
    "AudioEndpointBuilder", "Audiosrv", "AudioSrv",

    # Remote Desktop
    "JumpConnect", "JumpDesktopService",
    "TermService", "SessionEnv", "UmRdpService",

    # Bluetooth (CRITICO)
    "bthserv", "BTAGService", "BthHFSrv", "BthA2dp",
    "BluetoothUserService_*", "BluetoothSupportService",
    "DeviceAssociationService", "DeviceAssociationBrokerSvc_*",
    "DevicesFlowUserSvc_*", "DevQueryBroker", "DsSvc",
    "ibtsiva", "IntelAudioService",
    "RtkBtManServ", "RtkAudioUniversalService",

    # HID (teclados, mice)
    "hidserv", "HidServ"
)
```

---

## Etapas do Boost

| Ordem | Acao | Detalhes |
|-------|------|----------|
| 1 | Desabilitar scheduled tasks | Previne respawn de processos |
| 2 | Parar servicos nao-essenciais | Exceto whitelist |
| 3 | Matar processos nao-essenciais | Exceto whitelist |
| 4 | Definir Python HIGH priority | Se estiver rodando |
| 5 | Limpar memoria standby | Tecnica RAMMap (ntdll.dll) |
| 6 | Relatorio | Exibe RAM liberada |

---

## Mobile Wrappers

| Wrapper | Path | Start Command | URL | Requisito |
|---------|------|---------------|-----|-----------|
| ComfyUIMini | `wrappers\ComfyUIMini` | `.\scripts\start.bat` | `:3100` | Nenhum |
| ViewComfy | `wrappers\ViewComfy` | `npm run dev` | `:3000` | Node.js |
| MobileClient | N/A (extensao) | N/A | `:8188/extensions/...` | ComfyUI rodando |

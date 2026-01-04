# UltraBoost v1.0

Sistema de otimizacao que libera RAM maxima para tarefas pesadas. Opcionalmente inicia ComfyUI (Main ou Legacy) e Mobile Wrappers.

## Instalacao

```cmd
git clone https://github.com/SEU_USUARIO/UltraBoost.git
cd UltraBoost
```

## Uso

**Via atalho (criar manualmente):**
- Crie um atalho para `UltraBoost.bat`
- Propriedades > Avancado > Executar como administrador

**Via linha de comando (admin):**
```cmd
UltraBoost.bat
```

## Menu Interativo

```
==============================================================
                    ULTRABOOST v1.0
==============================================================

  Iniciar aplicacao:
  -----------------------------------------
  > ComfyUI Main
    ComfyUI Legacy
    Apenas Boost (nao iniciar)

  Mobile Wrappers (opcional):
  -----------------------------------------
  [ ] ComfyUIMini    (:3100)
  [ ] ViewComfy      (:3000)
  [ ] MobileClient   (requer ComfyUI)

  [Setas] Navegar  [Tab] Secao  [Espaco] Toggle  [Enter] Confirmar
==============================================================
```

### Controles

| Tecla | Acao |
|-------|------|
| `Up` `Down` | Navega dentro da secao |
| `Tab` | Alterna entre secoes |
| `Espaco` | Toggle checkbox |
| `Enter` | Confirma e executa |
| `Esc` | Cancela |

## O que o Boost faz

1. **Desabilita scheduled tasks** - Previne respawn de processos
2. **Para servicos nao-essenciais** - Exceto whitelist
3. **Mata processos nao-essenciais** - Exceto whitelist
4. **Define Python como HIGH priority**
5. **Limpa memoria standby** - Tecnica RAMMap (ntdll.dll)

## Arquitetura de Elevacao

O UltraBoost usa uma arquitetura especial para abrir Edge sem elevacao:

```
UltraBoost.bat (elevado via atalho)
    |
    +---> schtasks /create ... /rl LIMITED
    |         |
    |         v
    +---> schtasks /run
    |         |
    |         v
    |    Watcher.ps1 (NAO-ELEVADO via Task Scheduler)
    |         |
    |         v aguarda URLs em %TEMP%\ultraboost_urls.txt
    |
    +---> UltraBoost.ps1 (elevado)
              |
              v
         Boost, ComfyUI, escreve URLs
              |
    +---------+
    v
Watcher detecta URLs
    |
    v
Edge.bat -> msedge.exe (NAO-ELEVADO)
```

Isso evita o erro "Edge nao esta respondendo pois uma instancia existente esta sendo executada com privilegios elevados".

## Edge Otimizado (Standalone)

```cmd
Edge.bat                      # Pergunta URL (padrao: Google)
Edge.bat "https://url.com"    # Abre URL direto
```

- Modo app (sem barra de enderecos)
- Perfil isolado em `EdgeProfile\` (criado automaticamente)
- 30+ flags de otimizacao
- Limite de 512MB JS heap
- Roda nao-elevado (sem conflito de privilegios)

## Estrutura de Arquivos

```
UltraBoost/
+-- UltraBoost.bat        # Entry point (cria task nao-elevada, depois roda script)
+-- UltraBoost.ps1        # Script principal (elevado)
+-- Edge.bat              # Browser standalone
+-- Edge.ps1              # Logica do browser
+-- Rocket-3d.ico         # Icone
+-- EdgeProfile/          # Perfil isolado do Edge (criado automaticamente, .gitignore)
+-- docs/                 # Documentacao
+-- lib/
    +-- Common.ps1        # Config, whitelists, helpers
    +-- Menu.ps1          # Menu interativo
    +-- Boost.ps1         # Logica do boost
    +-- Watcher.ps1       # Abre Edge nao-elevado (background)
```

## Whitelist (Processos Protegidos)

| Categoria | Exemplos |
|-----------|----------|
| Python/ComfyUI | python, pythonw |
| GPU | nvidia*, amd*, Radeon* |
| Windows Core | svchost, dwm, explorer, csrss |
| Windows Shell | ShellExperienceHost, SearchHost, RuntimeBroker |
| Terminais | powershell, cmd, WindowsTerminal, Warp |
| Browsers | msedge, msedgewebview2 |
| Dev Tools | claude, node |
| Remote | JumpDesktop, TermService |
| Input | Logi*, hidserv |
| **Bluetooth** | *bluetooth*, BTStackServer, bthudtask, Intel/Realtek BT |

## Whitelist (Servicos Protegidos)

| Categoria | Exemplos |
|-----------|----------|
| GPU | NVDisplay*, nvagent, amd* |
| Windows Core | Schedule, CryptSvc, RpcSs, EventLog |
| Rede | Dnscache, Dhcp, BFE, mpssvc |
| Audio | AudioSrv, AudioEndpointBuilder |
| Remote | JumpConnect, TermService |
| **Bluetooth** | bthserv, BTAGService, BluetoothUserService_*, DeviceAssociationService |
| HID | hidserv |

## Recuperacao

Apos o boost, para restaurar o sistema ao normal:
- **Reinicie o computador**

## Troubleshooting

| Problema | Solucao |
|----------|---------|
| Edge nao abre automaticamente | Execute manualmente: `Edge.bat "http://127.0.0.1:8188"` |
| Bluetooth parou | Reinicie o computador |
| Claude Code encerrado | Nao deve mais ocorrer (Node.js protegido) |

## Configuracao

Edite `lib\Common.ps1` para:
- Alterar paths do ComfyUI
- Adicionar processos/servicos a whitelist
- Modificar URLs dos wrappers

## Changelog

| Versao | Mudancas |
|--------|----------|
| 1.0 | Release inicial no GitHub. Boost sempre executa. ComfyUI opcional. Mobile wrappers. Menu interativo. Edge standalone. Bluetooth protegido. |

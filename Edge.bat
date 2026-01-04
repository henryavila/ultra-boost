@echo off
:: Edge Optimizado - Standalone Launcher
:: Abre Edge em modo app com perfil isolado
:: Nunca fecha instancias existentes
::
:: Uso:
::   Edge.bat                      - Pergunta a URL (padrao: Google)
::   Edge.bat "https://url.com"    - Abre URL diretamente

powershell -ExecutionPolicy Bypass -File "%~dp0Edge.ps1" %*

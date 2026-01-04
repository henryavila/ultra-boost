@echo off
:: Optimized Edge - Standalone Launcher
:: Opens Edge in app mode with isolated profile
::
:: Usage:
::   Edge.bat                      - Prompts for URL (default: Google)
::   Edge.bat "https://url.com"    - Opens URL directly

powershell -ExecutionPolicy Bypass -File "%~dp0Edge.ps1" %*

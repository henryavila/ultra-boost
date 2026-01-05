@echo off
setlocal EnableDelayedExpansion

:: UltraBoost - System Optimization Utility
:: Version 4.7
::
:: Architecture:
::   1. Create scheduled task to run Watcher NON-ELEVATED
::   2. Run main script (elevated)
::   3. Cleanup task after completion

:: Get absolute path to script directory (remove trailing backslash issues)
set "SCRIPT_DIR=%~dp0"
set "WATCHER_VBS=%SCRIPT_DIR%lib\WatcherLauncher.vbs"
set "TASK_NAME=UltraBoost_Watcher_%RANDOM%"

:: Delete any leftover URL file from previous runs
del "%TEMP%\ultraboost_urls.txt" 2>nul

:: Create scheduled task with LIMITED privileges (non-elevated)
:: /ru - Run as current user
:: /rl LIMITED - Run with limited (non-elevated) privileges
:: /sc once /st 00:00 - One time trigger (we'll run it manually)
:: /f - Force create (overwrite if exists)
:: Using wscript.exe with VBS wrapper to ensure truly hidden window
schtasks /create /tn "%TASK_NAME%" /tr "wscript.exe //nologo \"%WATCHER_VBS%\"" /sc once /st 00:00 /ru "%USERNAME%" /rl LIMITED /f >nul 2>&1

if %ERRORLEVEL% NEQ 0 (
    echo [!] Failed to create watcher task. Edge will run elevated.
    goto :run_main
)

:: Run the task immediately
schtasks /run /tn "%TASK_NAME%" >nul 2>&1

:: Small delay to ensure watcher starts
timeout /t 1 /nobreak >nul

:run_main
:: Run main script
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%UltraBoost.ps1"

:: Cleanup: delete the scheduled task
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1

endlocal

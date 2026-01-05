' WatcherLauncher.vbs - Launches Watcher.ps1 with truly hidden window
' This script is called by Task Scheduler to ensure:
'   1. Non-elevated execution (via schtasks /rl LIMITED)
'   2. Completely invisible window (via WScript.Shell.Run with 0)

Dim scriptDir, watcherPath, command

' Get directory where this VBS is located (lib\)
scriptDir = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)

' Build path to Watcher.ps1 (same directory)
watcherPath = scriptDir & "\Watcher.ps1"

' Build PowerShell command
command = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -NonInteractive -File """ & watcherPath & """"

' Run with window style 0 (completely hidden), False = don't wait for completion
CreateObject("WScript.Shell").Run command, 0, False

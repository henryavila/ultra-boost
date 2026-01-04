<#
.SYNOPSIS
    Boost functions for UltraBoost - frees system resources

.DESCRIPTION
    Kills non-essential processes, stops services, disables scheduled tasks.
    Requires: Common.ps1 to be sourced first.

.NOTES
    Version: 1.0
#>

# ============================================================================
# BOOST FUNCTIONS
# ============================================================================

function Invoke-UltraBoost {
    <#
    .SYNOPSIS
        Executes ULTRA boost - kills everything except whitelisted
    #>

    $script:killed = 0
    $script:ramFreed = 0
    # FreePhysicalMemory is in KB, convert to GB
    $memBefore = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1024 / 1024

    # 1. Disable scheduled tasks (prevents respawn)
    Write-Header "DISABLING SCHEDULED TASKS..."
    $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Ready' }
    $disabled = 0
    foreach ($task in $tasks) {
        try {
            Disable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction Stop | Out-Null
            $disabled++
        } catch { }
    }
    Write-OK "$disabled tasks disabled"

    # 2. Stop non-essential services (wait for each to stop)
    Write-Header "STOPPING NON-ESSENTIAL SERVICES..."
    $services = Get-Service -ErrorAction SilentlyContinue | Where-Object {
        $_.Status -eq 'Running' -and -not (Test-Whitelisted -Name $_.Name -List $script:WhitelistServices)
    }
    $stoppedSvc = 0
    foreach ($svc in $services) {
        try {
            Stop-Service -Name $svc.Name -Force -ErrorAction Stop
            $stoppedSvc++
        } catch { }
    }
    Write-OK "$stoppedSvc services stopped"

    # 3. Kill non-essential processes
    Write-Header "KILLING NON-ESSENTIAL PROCESSES..."

    # Show what will be protected
    Write-Host "  Protected: Python, NVIDIA, AMD, Explorer, Terminals, Node.js, Claude, Warp, Edge" -ForegroundColor DarkGray
    Write-Host ""

    $allProcs = Get-Process -ErrorAction SilentlyContinue | Where-Object {
        -not (Test-Whitelisted -Name $_.ProcessName -List $script:WhitelistProcesses)
    } | Group-Object ProcessName

    foreach ($group in $allProcs) {
        $name = $group.Name
        $procs = $group.Group

        # Extra safety: skip anything that looks critical
        if ($name -match '^(Registry|Secure System|System Interrupts|vmmem|audiodg|fontdrvhost)$') {
            continue
        }

        $ram = ($procs | Measure-Object -Property WorkingSet64 -Sum).Sum / 1MB
        try {
            $procs | Stop-Process -Force -ErrorAction Stop
            $script:killed += $procs.Count
            $script:ramFreed += $ram
            if ($ram -gt 30) {
                Write-Host "     $name - $([math]::Round($ram))MB" -ForegroundColor DarkGray
            }
        } catch { }
    }
    Write-OK "$($script:killed) processes killed ($([math]::Round($script:ramFreed))MB)"

    # 4. Set Python to high priority if running
    $pythonProcs = Get-Process -Name "python*" -ErrorAction SilentlyContinue
    if ($pythonProcs) {
        foreach ($p in $pythonProcs) {
            try { $p.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High } catch { }
        }
        Write-OK "Python set to HIGH priority"
    }

    # 5. Clear memory
    Write-Header "CLEARING MEMORY..."
    try {
        # Try RAMMap-style cleanup
        $code = @"
using System;
using System.Runtime.InteropServices;
public class MemoryCleaner {
    [DllImport("ntdll.dll")]
    public static extern uint NtSetSystemInformation(int InfoClass, IntPtr Info, int Length);
    public static void ClearStandby() {
        GC.Collect();
        GC.WaitForPendingFinalizers();
        IntPtr info = Marshal.AllocHGlobal(4);
        Marshal.WriteInt32(info, 4);
        NtSetSystemInformation(80, info, 4);
        Marshal.FreeHGlobal(info);
    }
}
"@
        Add-Type -TypeDefinition $code -Language CSharp -ErrorAction Stop
        [MemoryCleaner]::ClearStandby()
        Write-OK "Standby memory cleared"
    } catch {
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        Write-OK "GC executed"
    }

    # Wait for system to stabilize
    Start-Sleep -Seconds 3

    # FreePhysicalMemory is in KB, convert to GB
    $memAfter = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1024 / 1024
    $memGained = $memAfter - $memBefore

    # Summary
    Write-Host ""
    Write-Host "  Memory freed: " -NoNewline
    if ($memGained -gt 0) {
        Write-Host ("+{0:N2} GB" -f $memGained) -ForegroundColor Green
    } else {
        Write-Host ("{0:N2} GB" -f $memGained) -ForegroundColor Yellow
    }
    Write-Host "  Free memory:  $([math]::Round($memAfter, 2)) GB" -ForegroundColor Green
    Write-Host ""

    return $memGained
}

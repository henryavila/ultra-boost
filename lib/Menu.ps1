<#
.SYNOPSIS
    Interactive menu for UltraBoost

.DESCRIPTION
    Arrow-key navigation menu with checkboxes.
    Requires: Common.ps1 to be sourced first.

.NOTES
    Version: 1.0
#>

# ============================================================================
# MENU CONFIGURATION
# ============================================================================

$script:AppOptions = @("ComfyUI Main", "ComfyUI Legacy", "Apenas Boost (nao iniciar)")
$script:CurrentSection = 0      # 0=Apps, 1=Wrappers, 2=Options
$script:CurrentAppIndex = 0     # Selected app (0=Main default)
$script:CurrentWrapperIndex = 0 # For navigation within wrappers

# ============================================================================
# MENU RENDERING
# ============================================================================

function Show-Menu {
    Clear-Host

    $width = 62
    $border = "=" * $width

    Write-Host ""
    Write-Host $border -ForegroundColor Magenta
    Write-Host ("  ULTRABOOST v{0}" -f $script:UltraBoostVersion).PadRight($width - 1) -ForegroundColor Magenta
    Write-Host $border -ForegroundColor Magenta
    Write-Host ""

    # Section 1: Application
    Write-Host "  Iniciar aplicacao:" -ForegroundColor Cyan
    Write-Host "  $("-" * 40)" -ForegroundColor DarkGray

    for ($i = 0; $i -lt $script:AppOptions.Count; $i++) {
        $prefix = "  "
        $suffix = ""

        if ($script:CurrentSection -eq 0 -and $i -eq $script:CurrentAppIndex) {
            $prefix = "> "
            Write-Host "$prefix$($script:AppOptions[$i])$suffix" -ForegroundColor Yellow
        } elseif ($i -eq $script:SelectedApp) {
            Write-Host "$prefix$($script:AppOptions[$i])$suffix" -ForegroundColor Green
        } else {
            Write-Host "$prefix$($script:AppOptions[$i])$suffix" -ForegroundColor Gray
        }
    }

    Write-Host ""

    # Section 2: Mobile Wrappers
    Write-Host "  Mobile Wrappers (opcional):" -ForegroundColor Cyan
    Write-Host "  $("-" * 40)" -ForegroundColor DarkGray

    $wrappers = @(
        @{ Name = "ComfyUIMini"; Port = ":3100"; Enabled = $script:EnableComfyUIMini },
        @{ Name = "ViewComfy"; Port = ":3000"; Enabled = $script:EnableViewComfy },
        @{ Name = "MobileClient"; Port = "(requer ComfyUI)"; Enabled = $script:EnableMobileClient }
    )

    for ($i = 0; $i -lt $wrappers.Count; $i++) {
        $w = $wrappers[$i]
        $checkbox = if ($w.Enabled) { "[X]" } else { "[ ]" }
        $text = "$checkbox $($w.Name)".PadRight(20) + $w.Port

        if ($script:CurrentSection -eq 1 -and $i -eq $script:CurrentWrapperIndex) {
            Write-Host "  > $text" -ForegroundColor Yellow
        } else {
            $color = if ($w.Enabled) { "Green" } else { "Gray" }
            Write-Host "    $text" -ForegroundColor $color
        }
    }

    Write-Host ""
    Write-Host "  $("-" * 40)" -ForegroundColor DarkGray
    Write-Host "  [Setas] Navegar  [Tab] Secao  [Espaco] Toggle  [Enter] Confirmar" -ForegroundColor DarkCyan
    Write-Host ""
}

# ============================================================================
# MENU NAVIGATION
# ============================================================================

function Invoke-Menu {
    <#
    .SYNOPSIS
        Runs the interactive menu and returns when user confirms
    #>

    # Set defaults
    $script:SelectedApp = 0
    $script:CurrentAppIndex = 0
    $script:CurrentSection = 0
    $script:CurrentWrapperIndex = 0
    $script:EnableComfyUIMini = $false
    $script:EnableViewComfy = $false
    $script:EnableMobileClient = $false

    $done = $false

    while (-not $done) {
        Show-Menu

        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        switch ($key.VirtualKeyCode) {
            # Up Arrow
            38 {
                switch ($script:CurrentSection) {
                    0 {
                        $script:CurrentAppIndex = [Math]::Max(0, $script:CurrentAppIndex - 1)
                    }
                    1 {
                        $script:CurrentWrapperIndex = [Math]::Max(0, $script:CurrentWrapperIndex - 1)
                    }
                    # Section 2 has only one item
                }
            }

            # Down Arrow
            40 {
                switch ($script:CurrentSection) {
                    0 {
                        $script:CurrentAppIndex = [Math]::Min($script:AppOptions.Count - 1, $script:CurrentAppIndex + 1)
                    }
                    1 {
                        $script:CurrentWrapperIndex = [Math]::Min(2, $script:CurrentWrapperIndex + 1)
                    }
                    # Section 2 has only one item
                }
            }

            # Tab - next section (only 2 sections now: Apps and Wrappers)
            9 {
                $script:CurrentSection = ($script:CurrentSection + 1) % 2
            }

            # Space - toggle
            32 {
                switch ($script:CurrentSection) {
                    0 {
                        # Select app
                        $script:SelectedApp = $script:CurrentAppIndex
                    }
                    1 {
                        # Toggle wrapper
                        switch ($script:CurrentWrapperIndex) {
                            0 { $script:EnableComfyUIMini = -not $script:EnableComfyUIMini }
                            1 { $script:EnableViewComfy = -not $script:EnableViewComfy }
                            2 {
                                $script:EnableMobileClient = -not $script:EnableMobileClient
                                # MobileClient requires ComfyUI
                                if ($script:EnableMobileClient -and $script:SelectedApp -eq 2) {
                                    # Show warning - can't use MobileClient without ComfyUI
                                    $script:SelectedApp = 0  # Force Main
                                    $script:CurrentAppIndex = 0
                                }
                            }
                        }
                    }
                }
            }

            # Enter - confirm
            13 {
                $script:SelectedApp = $script:CurrentAppIndex

                # Validate MobileClient requires ComfyUI
                if ($script:EnableMobileClient -and $script:SelectedApp -eq 2) {
                    Write-Host ""
                    Write-Warn "MobileClient requer ComfyUI. Selecione Main ou Legacy."
                    Start-Sleep -Seconds 2
                } else {
                    $done = $true
                }
            }

            # Escape - cancel/exit
            27 {
                Write-Host ""
                Write-Info "Cancelado pelo usuario."
                # Signal watcher to exit
                $urlFile = Join-Path $env:TEMP "ultraboost_urls.txt"
                "CANCEL" | Out-File -FilePath $urlFile -Encoding UTF8
                exit 0
            }
        }
    }

    # Show final selection
    Show-Menu
    Write-Host ""
    Write-OK "Configuracao confirmada!"
    Write-Host ""
    Start-Sleep -Seconds 1
}

# ============================================================================
# EXPORT SELECTION
# ============================================================================

function Get-MenuSelection {
    return @{
        App = $script:SelectedApp
        AppName = $script:AppOptions[$script:SelectedApp]
        ComfyUIMini = $script:EnableComfyUIMini
        ViewComfy = $script:EnableViewComfy
        MobileClient = $script:EnableMobileClient
    }
}

<#
.SYNOPSIS
    Interactive menu for UltraBoost

.DESCRIPTION
    Arrow-key navigation menu with checkboxes.
    Requires: Common.ps1 to be sourced first.

.NOTES
    Version: 1.1
#>

# ============================================================================
# MENU STATE
# ============================================================================

$script:CurrentSection = 0          # 0=Apps, 1=Extras, 2=URLs
$script:CurrentItemIndex = 0        # Current item in section

# Selection state (indices)
$script:MenuSelectedApp = -1        # -1 = Boost only
$script:MenuSelectedExtras = @{}    # Hashtable: index -> $true/$false
$script:MenuSelectedUrls = @{}      # Hashtable: index -> $true/$false

# ============================================================================
# INITIALIZATION
# ============================================================================

function Initialize-MenuState {
    # Find default app (first with default=true, or -1 for boost only)
    $script:MenuSelectedApp = -1
    for ($i = 0; $i -lt $script:Apps.Count; $i++) {
        if ($script:Apps[$i].default -eq $true) {
            $script:MenuSelectedApp = $i
            break
        }
    }

    # Initialize extras with defaults
    $script:MenuSelectedExtras = @{}
    for ($i = 0; $i -lt $script:Extras.Count; $i++) {
        $script:MenuSelectedExtras[$i] = ($script:Extras[$i].default -eq $true)
    }

    # Initialize URLs with defaults
    $script:MenuSelectedUrls = @{}
    for ($i = 0; $i -lt $script:Urls.Count; $i++) {
        $script:MenuSelectedUrls[$i] = ($script:Urls[$i].default -eq $true)
    }

    # Start at first section with items, or apps section
    $script:CurrentSection = 0
    $script:CurrentItemIndex = 0
}

# ============================================================================
# MENU RENDERING
# ============================================================================

function Get-SectionItemCount {
    param([int]$Section)
    switch ($Section) {
        0 { return $script:Apps.Count + 1 }  # +1 for "Boost only"
        1 { return $script:Extras.Count }
        2 { return $script:Urls.Count }
    }
    return 0
}

function Show-Menu {
    Clear-Host

    $width = 62
    $border = "=" * $width

    Write-Host ""
    Write-Host $border -ForegroundColor Magenta
    Write-Host ("  ULTRABOOST v{0}" -f $script:UltraBoostVersion).PadRight($width - 1) -ForegroundColor Magenta
    Write-Host $border -ForegroundColor Magenta
    Write-Host ""

    # -------------------------------------------------------------------------
    # Section 0: Apps (radio buttons)
    # -------------------------------------------------------------------------
    Write-Host "  Start application:" -ForegroundColor Cyan
    Write-Host "  $("-" * 40)" -ForegroundColor DarkGray

    # App items
    for ($i = 0; $i -lt $script:Apps.Count; $i++) {
        $app = $script:Apps[$i]
        $isSelected = ($script:MenuSelectedApp -eq $i)
        $isCursor = ($script:CurrentSection -eq 0 -and $script:CurrentItemIndex -eq $i)

        $prefix = if ($isCursor) { "> " } else { "  " }
        $radio = if ($isSelected) { "(*)" } else { "( )" }
        $text = "$prefix$radio $($app.name)"

        if ($isCursor) {
            Write-Host $text -ForegroundColor Yellow
        } elseif ($isSelected) {
            Write-Host $text -ForegroundColor Green
        } else {
            Write-Host $text -ForegroundColor Gray
        }
    }

    # "Boost only" option
    $boostIndex = $script:Apps.Count
    $isBoostSelected = ($script:MenuSelectedApp -eq -1)
    $isBoostCursor = ($script:CurrentSection -eq 0 -and $script:CurrentItemIndex -eq $boostIndex)

    $prefix = if ($isBoostCursor) { "> " } else { "  " }
    $radio = if ($isBoostSelected) { "(*)" } else { "( )" }
    $text = "$prefix$radio Boost Only"

    if ($isBoostCursor) {
        Write-Host $text -ForegroundColor Yellow
    } elseif ($isBoostSelected) {
        Write-Host $text -ForegroundColor Green
    } else {
        Write-Host $text -ForegroundColor Gray
    }

    Write-Host ""

    # -------------------------------------------------------------------------
    # Section 1: Extras (checkboxes)
    # -------------------------------------------------------------------------
    if ($script:Extras.Count -gt 0) {
        Write-Host "  Extras:" -ForegroundColor Cyan
        Write-Host "  $("-" * 40)" -ForegroundColor DarkGray

        for ($i = 0; $i -lt $script:Extras.Count; $i++) {
            $extra = $script:Extras[$i]
            $isEnabled = $script:MenuSelectedExtras[$i]
            $isCursor = ($script:CurrentSection -eq 1 -and $script:CurrentItemIndex -eq $i)

            # Check if requires app and no app selected
            $isDisabled = ($extra.requiresApp -eq $true -and $script:MenuSelectedApp -eq -1)

            $prefix = if ($isCursor) { "> " } else { "  " }
            $checkbox = if ($isEnabled -and -not $isDisabled) { "[X]" } else { "[ ]" }
            $suffix = if ($extra.requiresApp) { " (requires app)" } else { "" }
            $text = "$prefix$checkbox $($extra.name)$suffix"

            if ($isDisabled) {
                Write-Host $text -ForegroundColor DarkGray
            } elseif ($isCursor) {
                Write-Host $text -ForegroundColor Yellow
            } elseif ($isEnabled) {
                Write-Host $text -ForegroundColor Green
            } else {
                Write-Host $text -ForegroundColor Gray
            }
        }

        Write-Host ""
    }

    # -------------------------------------------------------------------------
    # Section 2: URLs (checkboxes)
    # -------------------------------------------------------------------------
    if ($script:Urls.Count -gt 0) {
        Write-Host "  Additional URLs:" -ForegroundColor Cyan
        Write-Host "  $("-" * 40)" -ForegroundColor DarkGray

        for ($i = 0; $i -lt $script:Urls.Count; $i++) {
            $urlItem = $script:Urls[$i]
            $isEnabled = $script:MenuSelectedUrls[$i]
            $isCursor = ($script:CurrentSection -eq 2 -and $script:CurrentItemIndex -eq $i)

            $prefix = if ($isCursor) { "> " } else { "  " }
            $checkbox = if ($isEnabled) { "[X]" } else { "[ ]" }
            $text = "$prefix$checkbox $($urlItem.name)"

            if ($isCursor) {
                Write-Host $text -ForegroundColor Yellow
            } elseif ($isEnabled) {
                Write-Host $text -ForegroundColor Green
            } else {
                Write-Host $text -ForegroundColor Gray
            }
        }

        Write-Host ""
    }

    # -------------------------------------------------------------------------
    # Help
    # -------------------------------------------------------------------------
    Write-Host "  $("-" * 40)" -ForegroundColor DarkGray
    Write-Host "  [Arrows] Navigate  [Tab] Section  [Space] Toggle  [Enter] Confirm" -ForegroundColor DarkCyan
    Write-Host ""
}

# ============================================================================
# NAVIGATION HELPERS
# ============================================================================

function Get-NextSection {
    # Find next section that has items
    $sections = @(0)  # Apps always exists (at least "boost only")
    if ($script:Extras.Count -gt 0) { $sections += 1 }
    if ($script:Urls.Count -gt 0) { $sections += 2 }

    $currentIdx = [Array]::IndexOf($sections, $script:CurrentSection)
    $nextIdx = ($currentIdx + 1) % $sections.Count
    return $sections[$nextIdx]
}

function Move-ToSection {
    param([int]$Section)
    $script:CurrentSection = $Section
    $script:CurrentItemIndex = 0
}

# ============================================================================
# MENU LOOP
# ============================================================================

function Invoke-Menu {
    Initialize-MenuState

    $done = $false

    while (-not $done) {
        Show-Menu

        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        switch ($key.VirtualKeyCode) {
            # Up Arrow
            38 {
                $maxIndex = (Get-SectionItemCount $script:CurrentSection) - 1
                $script:CurrentItemIndex = [Math]::Max(0, $script:CurrentItemIndex - 1)
            }

            # Down Arrow
            40 {
                $maxIndex = (Get-SectionItemCount $script:CurrentSection) - 1
                $script:CurrentItemIndex = [Math]::Min($maxIndex, $script:CurrentItemIndex + 1)
            }

            # Tab - next section
            9 {
                $nextSection = Get-NextSection
                Move-ToSection $nextSection
            }

            # Space - toggle/select
            32 {
                switch ($script:CurrentSection) {
                    0 {
                        # Apps: select (radio)
                        if ($script:CurrentItemIndex -eq $script:Apps.Count) {
                            $script:MenuSelectedApp = -1  # Boost only
                        } else {
                            $script:MenuSelectedApp = $script:CurrentItemIndex
                        }

                        # Disable extras that require app if no app selected
                        if ($script:MenuSelectedApp -eq -1) {
                            for ($i = 0; $i -lt $script:Extras.Count; $i++) {
                                if ($script:Extras[$i].requiresApp -eq $true) {
                                    $script:MenuSelectedExtras[$i] = $false
                                }
                            }
                        }
                    }
                    1 {
                        # Extras: toggle (checkbox)
                        $extra = $script:Extras[$script:CurrentItemIndex]
                        $isDisabled = ($extra.requiresApp -eq $true -and $script:MenuSelectedApp -eq -1)

                        if (-not $isDisabled) {
                            $current = $script:MenuSelectedExtras[$script:CurrentItemIndex]
                            $script:MenuSelectedExtras[$script:CurrentItemIndex] = -not $current
                        }
                    }
                    2 {
                        # URLs: toggle (checkbox)
                        $current = $script:MenuSelectedUrls[$script:CurrentItemIndex]
                        $script:MenuSelectedUrls[$script:CurrentItemIndex] = -not $current
                    }
                }
            }

            # Enter - confirm
            13 {
                $done = $true
            }

            # Escape - cancel
            27 {
                Write-Host ""
                Write-Info "Cancelled by user."
                $urlFile = Join-Path $env:TEMP "ultraboost_urls.txt"
                "CANCEL" | Out-File -FilePath $urlFile -Encoding UTF8
                exit 0
            }
        }
    }

    # Show final selection
    Show-Menu
    Write-Host ""
    Write-OK "Configuration confirmed!"
    Write-Host ""
    Start-Sleep -Seconds 1

    # Export to script-level variables for UltraBoost.ps1
    $script:SelectedAppIndex = $script:MenuSelectedApp

    $script:SelectedExtras = @()
    for ($i = 0; $i -lt $script:Extras.Count; $i++) {
        if ($script:MenuSelectedExtras[$i]) {
            $script:SelectedExtras += $i
        }
    }

    $script:SelectedUrls = @()
    for ($i = 0; $i -lt $script:Urls.Count; $i++) {
        if ($script:MenuSelectedUrls[$i]) {
            $script:SelectedUrls += $i
        }
    }
}

# ============================================================================
# SELECTION ACCESSOR
# ============================================================================

function Get-MenuSelection {
    return @{
        AppIndex = $script:SelectedAppIndex
        App = if ($script:SelectedAppIndex -ge 0) { $script:Apps[$script:SelectedAppIndex] } else { $null }
        ExtraIndices = $script:SelectedExtras
        Extras = $script:SelectedExtras | ForEach-Object { $script:Extras[$_] }
        UrlIndices = $script:SelectedUrls
        Urls = $script:SelectedUrls | ForEach-Object { $script:Urls[$_] }
    }
}


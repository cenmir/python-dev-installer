# Repair Script for Python Development Environment
Write-Host "========================================================" -ForegroundColor Yellow
Write-Host "  Python Development Environment - Repair Tool"          -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Yellow
Write-Host ""

$SourceDir = $PSScriptRoot
$InstallDir = "$env:USERPROFILE\marimo"
$StartMenuPath = [System.Environment]::GetFolderPath('Programs')
$MarimoStartMenuFolder = Join-Path $StartMenuPath "Marimo"

# Dot-source installer scripts to reuse their functions
. "$SourceDir\InstallVSCode.ps1"
. "$SourceDir\InstallPlatformIO.ps1"
. "$SourceDir\createDefaultVenvAndInstallPackages.ps1"

# --- Repair Menu ---
function Show-RepairMenu {
    $options = @(
        "Recreate virtual environment (delete and reinstall packages)"
        "Reset VS Code (wipe settings, reinstall all extensions)"
        "Fix PATH entries (re-add missing paths)"
        "Fix context menus (Marimo + VS Code)"
        "Fix Start Menu shortcuts"
    )

    Write-Host "Select repairs to run:" -ForegroundColor Cyan
    Write-Host ""
    for ($i = 0; $i -lt $options.Count; $i++) {
        Write-Host "  [$($i+1)] $($options[$i])"
    }
    Write-Host "  [A] All of the above"
    Write-Host "  [Q] Quit"
    Write-Host ""

    $choice = Read-Host "Enter choices (e.g. 1,2 or A)"

    if ($choice -match '^[Qq]') { return @() }
    if ($choice -match '^[Aa]') { return @(1,2,3,4,5) }

    $selected = @()
    foreach ($c in ($choice -split '[,\s]+')) {
        $num = 0
        if ([int]::TryParse($c.Trim(), [ref]$num) -and $num -ge 1 -and $num -le $options.Count) {
            $selected += $num
        }
    }
    return $selected
}

$repairs = Show-RepairMenu
if ($repairs.Count -eq 0) {
    Write-Host "No repairs selected. Exiting." -ForegroundColor Yellow
    return
}

# ============================================================
# 1. Recreate virtual environment
# ============================================================
if ($repairs -contains 1) {
    Write-Host ""
    Write-Host "--- Recreating virtual environment ---" -ForegroundColor Cyan

    $venvPath = "$env:USERPROFILE\.venvs\default"
    if (Test-Path $venvPath) {
        Write-Host "Removing existing venv at $venvPath..."
        Remove-Item -Path $venvPath -Recurse -Force
    }

    Write-Host "Creating fresh virtual environment..."
    uv venv --clear --python 3.13 $venvPath
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Virtual environment created." -ForegroundColor Green

        # Install packages
        $activateScript = Join-Path $venvPath "Scripts\Activate.ps1"
        if (Test-Path $activateScript) {
            & $activateScript
            $requirementsFile = Join-Path $SourceDir "requirements.txt"
            Write-Host "Installing packages from $requirementsFile..."
            Install-Requirements -RequirementsFile $requirementsFile | Out-Null
        }
    } else {
        Write-Warning "Failed to create virtual environment. Is uv installed?"
    }
}

# ============================================================
# 2. Reset VS Code
# ============================================================
if ($repairs -contains 2) {
    Write-Host ""
    Write-Host "--- Resetting VS Code ---" -ForegroundColor Cyan

    # Note every installed extension first, so the reset brings all of them
    # back, not only the installer's own.
    $codePath = Get-VSCodeCli
    $extensions = @("ms-python.python", "ms-toolsai.jupyter")
    if ($codePath) {
        $installed = @(& $codePath --list-extensions 2>$null | Where-Object { $_ -match '^\S+\.\S+$' })
        Write-Host "Found $($installed.Count) installed extensions; they will be reinstalled."
        $extensions = @($extensions + $installed | Sort-Object -Unique)
    }

    # Nuke VS Code user data and extensions
    $vscodeDirs = @(
        "$env:APPDATA\Code",
        "$env:USERPROFILE\.vscode"
    )

    foreach ($dir in $vscodeDirs) {
        if (Test-Path $dir) {
            Write-Host "Removing $dir..."
            Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
            if (-not (Test-Path $dir)) {
                Write-Host "  Removed." -ForegroundColor Green
            } else {
                Write-Warning "  Could not fully remove (VS Code may be running). Close VS Code and try again."
            }
        }
    }

    # Reinstall extensions and settings (reusing functions from InstallVSCode.ps1)
    if ($codePath) {
        Install-VSCodeExtensions -Extensions $extensions | Out-Null
        Set-VSCodePythonSettings | Out-Null
        if ($extensions -contains "platformio.platformio-ide") {
            Set-PlatformIOToolbar
        }
    } else {
        Write-Warning "VS Code 'code' command not found. Extensions and settings not restored."
    }
}

# ============================================================
# 3. Fix PATH entries
# ============================================================
if ($repairs -contains 3) {
    Write-Host ""
    Write-Host "--- Fixing PATH entries ---" -ForegroundColor Cyan

    $CurrentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $pathsToCheck = @(
        @{ Path = $InstallDir; Label = "Marimo" },
        @{ Path = "$env:LOCALAPPDATA\FFmpeg\bin"; Label = "FFmpeg" },
        @{ Path = "$env:USERPROFILE\.local\bin"; Label = "uv" }
    )

    # TinyTeX: check both possible bin dirs
    $tinyTexBin = "$env:APPDATA\TinyTeX\bin\windows"
    if (-not (Test-Path $tinyTexBin)) {
        $tinyTexBin = "$env:APPDATA\TinyTeX\bin\win32"
    }
    if (Test-Path $tinyTexBin) {
        $pathsToCheck += @{ Path = $tinyTexBin; Label = "TinyTeX" }
    }

    $modified = $false
    foreach ($entry in $pathsToCheck) {
        if (Test-Path $entry.Path) {
            if ($CurrentUserPath -notlike "*$($entry.Path)*") {
                $CurrentUserPath = "$CurrentUserPath;$($entry.Path)"
                $modified = $true
                Write-Host "  Added $($entry.Label): $($entry.Path)" -ForegroundColor Green
            } else {
                Write-Host "  $($entry.Label) already in PATH." -ForegroundColor Gray
            }
        } else {
            Write-Host "  $($entry.Label) directory not found ($($entry.Path)), skipping." -ForegroundColor Yellow
        }
    }

    if ($modified) {
        [Environment]::SetEnvironmentVariable("Path", $CurrentUserPath, "User")
        Write-Host "  PATH updated." -ForegroundColor Green
    } else {
        Write-Host "  All PATH entries are correct." -ForegroundColor Green
    }
}

# ============================================================
# 4. Fix context menus
# ============================================================
if ($repairs -contains 4) {
    Write-Host ""
    Write-Host "--- Fixing context menus ---" -ForegroundColor Cyan

    . "$SourceDir\contextMenus.ps1"
    Register-MarimoContextMenus -InstallDir $InstallDir

    # VS Code context menus (reusing function from InstallVSCode.ps1)
    Add-VSCodeContextMenu
}

# ============================================================
# 5. Fix Start Menu shortcuts
# ============================================================
if ($repairs -contains 5) {
    Write-Host ""
    Write-Host "--- Fixing Start Menu shortcuts ---" -ForegroundColor Cyan

    if (-not (Test-Path $InstallDir)) {
        Write-Warning "Marimo install directory ($InstallDir) not found. Cannot create shortcuts."
    } else {
        if (-not (Test-Path $MarimoStartMenuFolder)) {
            New-Item -Path $MarimoStartMenuFolder -ItemType Directory | Out-Null
        }

        $WshShell = New-Object -ComObject WScript.Shell

        # Marimo Launcher
        $Shortcut = $WshShell.CreateShortcut("$MarimoStartMenuFolder\Marimo.lnk")
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$InstallDir\runMarimo.ps1`" `"$env:USERPROFILE`""
        $Shortcut.IconLocation = "$InstallDir\mo.ico"
        $Shortcut.Description = "Launch Marimo"
        $Shortcut.Save()

        # Marimo New Notebook
        $Shortcut = $WshShell.CreateShortcut("$MarimoStartMenuFolder\Marimo New Notebook.lnk")
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$InstallDir\runMarimoTemp.ps1`""
        $Shortcut.IconLocation = "$InstallDir\mo.ico"
        $Shortcut.Description = "Launch Marimo with a new notebook"
        $Shortcut.Save()

        # Update Marimo
        $Shortcut = $WshShell.CreateShortcut("$MarimoStartMenuFolder\Update Marimo.lnk")
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$InstallDir\updateScripts.ps1`""
        $Shortcut.IconLocation = "$InstallDir\mo.ico"
        $Shortcut.Description = "Update Marimo scripts to the latest version"
        $Shortcut.Save()

        # Uninstall
        $Shortcut = $WshShell.CreateShortcut("$MarimoStartMenuFolder\Uninstall Marimo.lnk")
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$InstallDir\uninstall.ps1`""
        $Shortcut.IconLocation = "$InstallDir\mo.ico"
        $Shortcut.Description = "Uninstall Marimo"
        $Shortcut.Save()

        Write-Host "  All Start Menu shortcuts recreated." -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "  Repair complete." -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host "You may need to restart your terminal for changes to take effect."

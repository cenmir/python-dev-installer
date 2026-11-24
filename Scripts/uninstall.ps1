# Comprehensive Uninstaller for Python Development Environment
Write-Host "========================================================" -ForegroundColor Red
Write-Host "  Python Development Environment - Full Uninstaller"     -ForegroundColor Red
Write-Host "========================================================" -ForegroundColor Red
Write-Host ""
Write-Host "This will remove all components installed by the setup:" -ForegroundColor Yellow
Write-Host "the default virtual environment and its packages, uv and Python, FFmpeg,"
Write-Host "Git (portable), Quarto, TinyTeX, the Marimo shortcuts and context menus."
Write-Host "Your own files and notebooks are not touched."
Write-Host ""
$go = Read-Host "Continue? (y/N)"
if ($go -notmatch '^[Yy]') {
    Write-Host "Nothing was removed." -ForegroundColor Green
    return
}
Write-Host ""

# --- Define Paths ---
$InstallDir = "$env:USERPROFILE\marimo"
$StartMenuPath = [System.Environment]::GetFolderPath('Programs')
$MarimoStartMenuFolder = Join-Path $StartMenuPath "Marimo"

# --- Helper: Remove directory with status ---
function Remove-DirIfExists {
    param([string]$Path, [string]$Label)
    if (Test-Path $Path) {
        Write-Host "Removing $Label ($Path)..."
        Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
        if (-not (Test-Path $Path)) {
            Write-Host "  Removed." -ForegroundColor Green
        } else {
            Write-Warning "  Could not fully remove $Path (files may be in use)."
        }
    }
}

# --- Helper: Remove PATH entry ---
function Remove-FromUserPath {
    param([string]$Entry)
    $CurrentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($CurrentUserPath -and $CurrentUserPath -like "*$Entry*") {
        $pathEntries = $CurrentUserPath -split ";" | Where-Object {
            $_.TrimEnd('\') -ne $Entry.TrimEnd('\')
        }
        $NewUserPath = ($pathEntries | Where-Object { $_ -ne '' }) -join ";"
        [Environment]::SetEnvironmentVariable("Path", $NewUserPath, "User")
        Write-Host "  Removed '$Entry' from user PATH." -ForegroundColor Green
    }
}

# ============================================================
# SECTION 1: Remove what the installer added
# ============================================================

Write-Host "--- Removing Marimo components ---" -ForegroundColor Cyan

# Marimo context menus
if (Test-Path "$PSScriptRoot\contextMenus.ps1") {
    . "$PSScriptRoot\contextMenus.ps1"
    Unregister-MarimoContextMenus
}

# VS Code context menus
$vscodeRegKeys = @(
    "HKCU:\Software\Classes\Directory\Background\shell\VSCode",
    "HKCU:\Software\Classes\Directory\shell\VSCode"
)
foreach ($key in $vscodeRegKeys) {
    if (Test-Path $key) {
        Write-Host "Removing VS Code context menu: $key"
        Remove-Item -Path $key -Recurse -Force
    }
}

# Start Menu shortcuts
if (Test-Path $MarimoStartMenuFolder) {
    Write-Host "Removing Start Menu shortcuts..."
    Remove-Item -Path $MarimoStartMenuFolder -Recurse -Force
}

Write-Host ""
Write-Host "--- Removing installed tools ---" -ForegroundColor Cyan

# Default virtual environment
Remove-DirIfExists "$env:USERPROFILE\.venvs\default" "default virtual environment"

# FFmpeg
Remove-DirIfExists "$env:LOCALAPPDATA\FFmpeg" "FFmpeg"
Remove-FromUserPath "$env:LOCALAPPDATA\FFmpeg\bin"

# MinGit (portable Git)
Remove-DirIfExists "$env:LOCALAPPDATA\MinGit" "MinGit"
Remove-FromUserPath "$env:LOCALAPPDATA\MinGit\cmd"

# Quarto (portable)
Remove-DirIfExists "$env:LOCALAPPDATA\Quarto" "Quarto"
Remove-FromUserPath "$env:LOCALAPPDATA\Quarto\bin"

# TinyTeX
Remove-DirIfExists "$env:APPDATA\TinyTeX" "TinyTeX"
Remove-FromUserPath "$env:APPDATA\TinyTeX\bin\windows"
Remove-FromUserPath "$env:APPDATA\TinyTeX\bin\win32"

# uv + Python. ~\.local\bin is shared with other tools (Claude Code, pipx,
# uv tool installs), so only uv's own programs are removed, and the folder
# leaves PATH only when nothing else is left in it.
$uvBin = "$env:USERPROFILE\.local\bin"
foreach ($exe in @("uv.exe", "uvx.exe", "uvw.exe")) {
    $exePath = Join-Path $uvBin $exe
    if (Test-Path $exePath) {
        Remove-Item $exePath -Force -ErrorAction SilentlyContinue
        Write-Host "  Removed $exePath" -ForegroundColor Green
    }
}
Remove-DirIfExists "$env:APPDATA\uv" "uv cache and Python installations"
if ((Test-Path $uvBin) -and -not (Get-ChildItem $uvBin -Force | Select-Object -First 1)) {
    Remove-Item $uvBin -Force
}
if (-not (Test-Path $uvBin)) {
    Remove-FromUserPath $uvBin
}

# VS Code may have been there before the installer, and its settings and
# extensions may be the student's own, so wiping them is opt-in.
Write-Host ""
Write-Host "VS Code settings and extensions can be deleted too. This removes ALL of them," -ForegroundColor Yellow
Write-Host "including ones you added yourself, and resets VS Code to a fresh install." -ForegroundColor Yellow
$wipeVSCode = Read-Host "Delete all VS Code settings and extensions? (y/N)"
if ($wipeVSCode -match '^[Yy]') {
    Write-Host ""
    Write-Host "--- Removing VS Code data ---" -ForegroundColor Cyan

    # VS Code extensions
    Remove-DirIfExists "$env:USERPROFILE\.vscode" "VS Code extensions"

    # VS Code user data (settings, keybindings, snippets, state)
    Remove-DirIfExists "$env:APPDATA\Code" "VS Code user data"
} else {
    Write-Host "VS Code settings and extensions kept." -ForegroundColor Green
}

Write-Host ""
Write-Host "--- Removing configuration files ---" -ForegroundColor Cyan

# Marimo config
$marimoConfig = "$env:USERPROFILE\.marimo.toml"
if (Test-Path $marimoConfig) {
    Write-Host "Removing Marimo config ($marimoConfig)..."
    Remove-Item $marimoConfig -Force
}

# Remove marimo from user PATH
Write-Host "Cleaning PATH entries..."
Remove-FromUserPath $InstallDir

# ============================================================
# SECTION 2: Prompt to uninstall system apps via winget
# ============================================================

$winget = Get-Command winget -ErrorAction SilentlyContinue
if ($winget) {
    Write-Host ""
    # Git and Quarto are portable copies, removed above. Only VS Code comes
    # from winget; asking winget for Git.Git or Posit.Quarto would remove
    # copies the student installed separately.
    $uninstallApps = Read-Host "Also uninstall VS Code via winget? (y/N)"
    if ($uninstallApps -match '^[Yy]') {
        Write-Host ""
        Write-Host "--- Uninstalling applications ---" -ForegroundColor Cyan

        $apps = @(
            @{ Name = "VS Code"; Id = "Microsoft.VisualStudioCode" }
        )

        foreach ($app in $apps) {
            Write-Host "Uninstalling $($app.Name)..."
            winget uninstall $app.Id --accept-source-agreements --silent 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  $($app.Name) uninstalled." -ForegroundColor Green
            } else {
                Write-Host "  $($app.Name) was not installed or could not be removed." -ForegroundColor Yellow
            }
        }
    }
}

# ============================================================
# SECTION 3: Prompt to revert Windows Explorer settings
# ============================================================

Write-Host ""
$revertWin = Read-Host "Revert Windows Explorer settings (hidden files, extensions, context menu)? (y/N)"
if ($revertWin -match '^[Yy]') {
    Write-Host ""
    Write-Host "--- Reverting Windows settings ---" -ForegroundColor Cyan

    $explorerKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

    # Hide hidden files again
    Set-ItemProperty -Path $explorerKey -Name "Hidden" -Value 2
    Write-Host "  Hidden files: restored to hidden." -ForegroundColor Green

    # Hide file extensions again
    Set-ItemProperty -Path $explorerKey -Name "HideFileExt" -Value 1
    Write-Host "  File extensions: restored to hidden." -ForegroundColor Green

    # Remove classic context menu override
    $classicMenuKey = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
    if (Test-Path $classicMenuKey) {
        Remove-Item -Path $classicMenuKey -Recurse -Force
        Write-Host "  Classic context menu: reverted to Windows 11 default." -ForegroundColor Green
    }

    Write-Host "  Sign out and back in for Explorer changes to take effect." -ForegroundColor Yellow
}

# ============================================================
# SECTION 4: Self-destruct the installation directory
# ============================================================

Write-Host ""
Write-Host "--- Finalizing ---" -ForegroundColor Cyan

if (Test-Path $InstallDir) {
    Write-Host "Scheduling removal of $InstallDir..."
    $TempBatchFile = Join-Path $env:TEMP "cleanup_marimo.bat"
    $BatchContent = @"
@echo off
timeout /t 2 /nobreak > NUL
rmdir /s /q "$InstallDir"
(goto) 2>nul & del "%~f0"
"@
    $BatchContent | Out-File -FilePath $TempBatchFile -Encoding ascii
    Start-Process cmd.exe -ArgumentList "/c `"$TempBatchFile`"" -WindowStyle Hidden
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "  Uninstallation complete." -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host "You may need to restart your terminal for PATH changes to take effect."

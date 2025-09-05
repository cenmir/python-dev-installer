# activate.ps1

param (
    [string]$Action
)

$VenvsPath = Join-Path $env:UserProfile ".venvs"

# Get the directory of the current script.
# This must be at the top level to ensure $MyInvocation.MyCommand.Definition is accurate.
$ScriptDir = Split-Path $MyInvocation.MyCommand.Definition

function ActivateVenv {
    param (
        [string]$VenvName
    )

    $VenvScriptPath = Join-Path (Join-Path $VenvsPath $VenvName) "Scripts\activate.ps1"

    if (Test-Path $VenvScriptPath) {
        . $VenvScriptPath
    } else {
        Write-Host "Error: Virtual environment '$VenvName' not found at '$VenvScriptPath'." -ForegroundColor Red
    }
}

function Add-PathPermanentlyAndTemporarily {
    # Ensure $ScriptDir is accessible. It's defined globally at the top.
    # If for some reason it's not, we'd fall back, but it should be.
    if ([string]::IsNullOrEmpty($ScriptDir)) {
        Write-Host "Error: Could not determine script's directory for PATH modification." -ForegroundColor Red
        return
    }

    # 1. Add to the user PATH (permanent)
    $CurrentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($CurrentUserPath -notlike "*$([System.Text.RegularExpressions.Regex]::Escape($ScriptDir))*") {
        # Using Regex::Escape for robustness against special characters in path
        $NewUserPath = "$CurrentUserPath;$ScriptDir"
        [Environment]::SetEnvironmentVariable("Path", $NewUserPath, "User")
        Write-Host "Successfully added '$ScriptDir' to the user PATH permanently." -ForegroundColor Green
        Write-Host "Future PowerShell sessions will automatically have this path." -ForegroundColor Green
    } else {
        Write-Host "The script's directory '$ScriptDir' is already in the user PATH (permanent)." -ForegroundColor Yellow
    }

    # 2. Add to the current session's PATH (temporary)
    # This directly modifies the $env:Path variable for the current process
    if ($env:Path -notlike "*$([System.Text.RegularExpressions.Regex]::Escape($ScriptDir))*") {
        $env:Path += ";$ScriptDir"
        Write-Host "Successfully added '$ScriptDir' to the current PowerShell session's PATH." -ForegroundColor Green
    } else {
        Write-Host "The script's directory '$ScriptDir' is already in the current session's PATH." -ForegroundColor Yellow
    }
}

switch ($Action) {
    "install" {
        Add-PathPermanentlyAndTemporarily
    }
    default {
        if ([string]::IsNullOrEmpty($Action)) {
            Write-Host "Usage: activate <venv_name>  - To activate the virtual environment" -ForegroundColor Yellow
            Write-Host "       activate install      - To add the script to the PATH" -ForegroundColor Yellow
        } else {
            ActivateVenv -VenvName $Action
        }
    }
}
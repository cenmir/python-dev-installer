# Marimo Installer - One-liner bootstrap script
# Usage: irm https://raw.githubusercontent.com/cenmir/marimo-installer/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

$repoUrl = "https://github.com/cenmir/marimo-installer/archive/refs/heads/main.zip"
$tempDir = Join-Path $env:TEMP "marimo-installer-$(Get-Random)"
$zipPath = Join-Path $tempDir "marimo-installer.zip"

try {
    Write-Host "Downloading Marimo installer..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    Invoke-WebRequest -Uri $repoUrl -OutFile $zipPath -UseBasicParsing

    Write-Host "Extracting..." -ForegroundColor Cyan
    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force

    $extractedDir = Join-Path $tempDir "marimo-installer-main"
    $installScript = Join-Path $extractedDir "Scripts\InstallMarimoWithEnv.ps1"

    Write-Host "Running installer..." -ForegroundColor Cyan
    & $installScript

    Write-Host ""
    Write-Host "Installation finished." -ForegroundColor Green
    Write-Host "You can now find Marimo in your Start Menu."
    Write-Host "NOTE: You may need to sign out and back in for the context menu changes to appear everywhere."
}
finally {
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

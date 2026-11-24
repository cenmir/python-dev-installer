# Mechanical Engineering Python Development Setup - One-liner bootstrap script
# Usage: irm https://raw.githubusercontent.com/cenmir/python-dev-installer/main/download.ps1 | iex
#    or: irm https://mechanics.ju.se/installer/install.ps1 | iex   (same script, mirror first)
#
# Keep this file pure ASCII: mechanics.ju.se serves it as application/octet-stream,
# which Windows PowerShell 5.1 decodes in the legacy code page.

$ErrorActionPreference = "Stop"

# Add TLS 1.2, and TLS 1.3 where Windows has it (Windows 11, build 22000+);
# mechanics.ju.se accepts only TLS 1.3. Adding keeps what is already allowed.
$tls = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
if ([Environment]::OSVersion.Version.Build -ge 22000) { $tls = $tls -bor [Net.SecurityProtocolType]::Tls13 }
[Net.ServicePointManager]::SecurityProtocol = $tls

# Where the installer ZIP comes from, tried in order. The mechanics.ju.se copy
# is rebuilt from this repository whenever the book is published.
$sources = @(
    @{ Name = "GitHub";          Url = "https://github.com/cenmir/python-dev-installer/archive/refs/heads/main.zip" }
    @{ Name = "mechanics.ju.se"; Url = "https://mechanics.ju.se/installer/python-dev-installer.zip" }
)
$tempDir = Join-Path $env:TEMP "python-dev-installer-$(Get-Random)"
$zipPath = Join-Path $tempDir "python-dev-installer.zip"

try {
    Write-Host "Downloading installer..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    # Disable progress bar for faster download
    $ProgressPreference = 'SilentlyContinue'
    $downloaded = $false
    foreach ($source in $sources) {
        try {
            Write-Host "  from $($source.Name)..." -ForegroundColor Gray
            Invoke-WebRequest -Uri $source.Url -OutFile $zipPath -UseBasicParsing -TimeoutSec 60
            if (Test-Path $zipPath) { $downloaded = $true; break }
        }
        catch {
            Write-Host "  $($source.Name) failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    $ProgressPreference = 'Continue'

    if (-not $downloaded) {
        throw "Download failed from every source"
    }

    Write-Host "Extracting..." -ForegroundColor Cyan
    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force

    # Both ZIPs hold one folder (python-dev-installer-main) with Scripts\ inside.
    $installScript = Get-ChildItem -Path $tempDir -Directory |
        ForEach-Object { Join-Path $_.FullName "Scripts\Install.ps1" } |
        Where-Object { Test-Path $_ } |
        Select-Object -First 1

    if (-not $installScript) {
        throw "Extraction failed - Scripts\Install.ps1 not found in the downloaded ZIP"
    }

    Write-Host "Running installer..." -ForegroundColor Cyan
    # Launch in a new process so the interactive menu gets a clean console
    # (irm | iex runs in a piped context that breaks cursor positioning)
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installScript

    Write-Host ""
    Write-Host "Installation finished." -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "Installation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "If the problem persists, try the manual installation:" -ForegroundColor Yellow
    Write-Host "  1. Download: https://github.com/cenmir/python-dev-installer/archive/refs/heads/main.zip"
    Write-Host "     or:       https://mechanics.ju.se/installer/python-dev-installer.zip"
    Write-Host "  2. Extract and run setup.bat"
    throw
}
finally {
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

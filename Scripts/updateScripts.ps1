# updateScripts.ps1
# Downloads and installs the latest release from GitHub

$ErrorActionPreference = "Stop"

# Add TLS 1.2, and TLS 1.3 where Windows has it (Windows 11, build 22000+);
# mechanics.ju.se accepts only TLS 1.3. Adding keeps what is already allowed.
$tls = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
if ([Environment]::OSVersion.Version.Build -ge 22000) { $tls = $tls -bor [Net.SecurityProtocolType]::Tls13 }
[Net.ServicePointManager]::SecurityProtocol = $tls
$InstallDir = "$env:USERPROFILE\marimo"
$repoApi = "https://api.github.com/repos/cenmir/python-dev-installer/releases/latest"
$configPath = Join-Path $InstallDir "config.json"
$versionPath = Join-Path $InstallDir "version.txt"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Marimo Scripts Updater" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get current version
$currentVersion = "unknown"
if (Test-Path $versionPath) {
    $currentVersion = (Get-Content $versionPath -Raw).Trim()
}
Write-Host "Current version: $currentVersion" -ForegroundColor Gray

try {
    # Fetch latest release info
    Write-Host "Checking for updates..." -ForegroundColor Cyan
    $ProgressPreference = 'SilentlyContinue'
    try {
        $release = Invoke-RestMethod -Uri $repoApi -TimeoutSec 10
        $latestVersion = $release.tag_name
        $zipUrl = $release.zipball_url
    } catch {
        # GitHub's API limits requests per IP address; fall back to the
        # mirror on mechanics.ju.se, which is rebuilt with every book publish.
        Write-Host "GitHub unavailable ($($_.Exception.Message)); using mechanics.ju.se." -ForegroundColor Yellow
        $latestVersion = (Invoke-RestMethod -Uri "https://mechanics.ju.se/installer/version.txt" -TimeoutSec 10).Trim()
        $zipUrl = "https://mechanics.ju.se/installer/python-dev-installer.zip"
    }

    Write-Host "Latest version:  $latestVersion" -ForegroundColor Gray

    $upToDate = $latestVersion -eq $currentVersion
    try {
        $upToDate = [version]($latestVersion.TrimStart('v')) -le [version]($currentVersion.TrimStart('v'))
    } catch { }
    if ($upToDate) {
        Write-Host ""
        Write-Host "You're already on the latest version!" -ForegroundColor Green
        Read-Host "Press Enter to exit..."
        exit 0
    }

    Write-Host ""
    Write-Host "Updating from $currentVersion to $latestVersion..." -ForegroundColor Yellow
    Write-Host ""

    # Create temp directory
    $tempDir = Join-Path $env:TEMP "marimo-update-$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    $zipPath = Join-Path $tempDir "release.zip"

    # Download release
    Write-Host "Downloading release..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing

    # Extract
    Write-Host "Extracting..." -ForegroundColor Cyan
    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force

    # Find the extracted folder: cenmir-python-dev-installer-<sha> from a
    # GitHub release, python-dev-installer-main from mechanics.ju.se.
    $extractedDir = Get-ChildItem -Path $tempDir -Directory | Where-Object { Test-Path (Join-Path $_.FullName "Scripts") } | Select-Object -First 1
    if (-not $extractedDir) {
        throw "Could not find extracted directory"
    }
    $scriptsSource = Join-Path $extractedDir.FullName "Scripts"

    # Backup config.json
    $configBackup = $null
    if (Test-Path $configPath) {
        Write-Host "Backing up config.json..." -ForegroundColor Cyan
        $configBackup = Get-Content $configPath -Raw | ConvertFrom-Json
    }

    # Copy new scripts (excluding config.json to preserve user settings)
    Write-Host "Installing new scripts..." -ForegroundColor Cyan
    Get-ChildItem -Path $scriptsSource -File | Where-Object { $_.Name -ne "config.json" } | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $InstallDir -Force
    }

    # Restore/merge config.json
    if ($configBackup) {
        Write-Host "Restoring config.json..." -ForegroundColor Cyan
        # Read new config to get any new fields
        $newConfigPath = Join-Path $scriptsSource "config.json"
        if (Test-Path $newConfigPath) {
            $newConfig = Get-Content $newConfigPath -Raw | ConvertFrom-Json
            # Merge: keep user values, add any new fields from new config
            $newConfig.PSObject.Properties | ForEach-Object {
                if (-not $configBackup.PSObject.Properties[$_.Name]) {
                    $configBackup | Add-Member -NotePropertyName $_.Name -NotePropertyValue $_.Value
                }
            }
        }
        $configBackup | ConvertTo-Json | Set-Content $configPath -Encoding UTF8
    }

    # Cleanup
    Write-Host "Cleaning up..." -ForegroundColor Cyan
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " Update complete! Now on $latestVersion" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green

} catch {
    Write-Host ""
    Write-Host "Update failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "You can try manually:" -ForegroundColor Yellow
    Write-Host "  1. Download: https://github.com/cenmir/python-dev-installer/releases/latest"
    Write-Host "  2. Extract and copy Scripts folder to $InstallDir"
}

Write-Host ""
Read-Host "Press Enter to exit..."

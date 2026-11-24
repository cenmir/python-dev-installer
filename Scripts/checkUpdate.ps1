# checkUpdate.ps1
# This script checks for updates from GitHub releases.
# Designed to be dot-sourced from other scripts: . "$PSScriptRoot\checkUpdate.ps1"

function Test-MarimoUpdate {
    param(
        [string]$ScriptDir = $PSScriptRoot,
        [int]$CheckIntervalHours = 24,
        [int]$TimeoutSeconds = 3
    )

    $configPath = Join-Path $ScriptDir "config.json"
    $versionPath = Join-Path $ScriptDir "version.txt"
    $repoApi = "https://api.github.com/repos/cenmir/python-dev-installer/releases/latest"

    # Read local version
    if (-not (Test-Path $versionPath)) {
        return  # No version file, skip check
    }
    $localVersion = (Get-Content $versionPath -Raw).Trim()

    # Read config
    $config = $null
    if (Test-Path $configPath) {
        try {
            $config = Get-Content $configPath -Raw | ConvertFrom-Json
        } catch {
            return  # Invalid config, skip check
        }
    } else {
        return  # No config file, skip check
    }

    # Check if enough time has passed since last check
    if ($config.lastUpdateCheck) {
        try {
            $lastCheck = [DateTime]::Parse($config.lastUpdateCheck)
            $hoursSinceCheck = ((Get-Date) - $lastCheck).TotalHours
            if ($hoursSinceCheck -lt $CheckIntervalHours) {
                return  # Checked recently, skip
            }
        } catch {
            # Invalid date, continue with check
        }
    }

    # GitHub needs TLS 1.2, mechanics.ju.se TLS 1.3 (Windows 11 only).
    $tls = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    if ([Environment]::OSVersion.Version.Build -ge 22000) { $tls = $tls -bor [Net.SecurityProtocolType]::Tls13 }
    [Net.ServicePointManager]::SecurityProtocol = $tls

    # Fetch latest release from GitHub (with timeout)
    try {
        $ProgressPreference = 'SilentlyContinue'
        try {
            $release = Invoke-RestMethod -Uri $repoApi -TimeoutSec $TimeoutSeconds -ErrorAction Stop
            $latestVersion = $release.tag_name
        } catch {
            # GitHub's API limits requests per IP address; the mirror on
            # mechanics.ju.se publishes the same version number.
            $latestVersion = (Invoke-RestMethod -Uri "https://mechanics.ju.se/installer/version.txt" -TimeoutSec $TimeoutSeconds -ErrorAction Stop).Trim()
        }

        # Update last check time
        $config.lastUpdateCheck = (Get-Date).ToString("o")
        $config | ConvertTo-Json | Set-Content $configPath -Encoding UTF8

        # Report only a newer release: main can run ahead of the latest
        # release, and "Update Marimo" installs the release zip, so a mere
        # difference would offer a downgrade.
        $isNewer = $false
        try {
            $isNewer = [version]($latestVersion.TrimStart('v')) -gt [version]($localVersion.TrimStart('v'))
        } catch {
            $isNewer = $latestVersion -ne $localVersion
        }
        if ($isNewer) {
            Write-Host ""
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host " Update available: $localVersion -> $latestVersion" -ForegroundColor Yellow
            Write-Host " Run 'Update Marimo' from Start Menu" -ForegroundColor Yellow
            Write-Host "========================================" -ForegroundColor Yellow
            Write-Host ""
        }
    } catch {
        # Silently fail - user might be offline
        # Still update the check time to avoid repeated failures
        try {
            $config.lastUpdateCheck = (Get-Date).ToString("o")
            $config | ConvertTo-Json | Set-Content $configPath -Encoding UTF8
        } catch {
            # Ignore errors when saving config
        }
    }
}

# Auto-run if executed directly (not dot-sourced)
if ($MyInvocation.InvocationName -ne '.') {
    Test-MarimoUpdate
}

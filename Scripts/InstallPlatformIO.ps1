# PlatformIO for the ESP32: three VS Code extensions and one user setting.
# Needs VS Code; run InstallVSCode.ps1 first. The mechanics book chapter
# "ESP32 setup" describes the same steps by hand.

. "$PSScriptRoot\InstallVSCode.ps1"

$PlatformIOExtensions = @(
    "platformio.platformio-ide",        # builds and uploads programs to the board
    "ms-vscode.vscode-serial-monitor",  # shows what the board prints, sends what we type
    "alexnesnes.teleplot"               # plots the numbers the board prints
)

function Set-PlatformIOToolbar {
    # PlatformIO's toolbar plug button opens PlatformIO's own serial monitor.
    # The setting lists the whole toolbar, so it repeats PlatformIO's buttons
    # and points only the plug at Microsoft's Serial Monitor.
    $toolbar = @(
        [ordered]@{ text = '$(home)';        tooltip = 'PlatformIO: Home';         commands = 'platformio-ide.showHome' }
        [ordered]@{ text = '$(check)';       tooltip = 'PlatformIO: Build';        commands = 'platformio-ide.build' }
        [ordered]@{ text = '$(arrow-right)'; tooltip = 'PlatformIO: Upload';       commands = 'platformio-ide.upload' }
        [ordered]@{ text = '$(trashcan)';    tooltip = 'PlatformIO: Clean';        commands = 'platformio-ide.clean' }
        [ordered]@{ text = '$(beaker)';      tooltip = 'PlatformIO: Test';         commands = 'platformio-ide.test' }
        [ordered]@{ text = '$(plug)';        tooltip = 'Serial Monitor';           commands = 'vscode-serial-monitor.monitor0.focus' }
        [ordered]@{ text = '$(terminal)';    tooltip = 'PlatformIO: New Terminal'; commands = 'platformio-ide.newTerminal' }
    )
    Write-Host "Pointing the PlatformIO toolbar plug button at Microsoft's Serial Monitor..." -ForegroundColor Cyan
    if (Update-VSCodeUserSettings -Values @{ "platformio-ide.toolbar" = $toolbar }) {
        Write-Host "PlatformIO toolbar configured." -ForegroundColor Green
    }
}

## Script Execution
# Exit if called as dot function
if ($MyInvocation.InvocationName -eq '.') {
    return
}

Refresh-PathEnvironment
if (-not (Test-VSCodeInstalled)) {
    Write-Warning "VS Code is not installed. Select VS Code in the installer menu as well."
    return
}

Install-VSCodeExtensions -Extensions $PlatformIOExtensions | Out-Null
Set-PlatformIOToolbar

Write-Host ""
Write-Host "PlatformIO installs its build tools the first time VS Code starts." -ForegroundColor Yellow
Write-Host "Open VS Code and wait for the alien head icon in the left sidebar." -ForegroundColor Yellow

# contextMenus.ps1
# Explorer right-click entries for Marimo. Dot-sourced by Install.ps1,
# repair.ps1 and uninstall.ps1, so all three agree on the same keys.
#
#   .py file            -> "Open with Marimo"  (runMarimoFile.ps1 <file>)
#   folder              -> "Open in Marimo"    (runMarimo.ps1 <folder>)
#   inside a folder     -> "Open in Marimo"    (runMarimo.ps1 <folder>)

$MarimoMenuKeys = @{
    PyFile     = "HKCU:\Software\Classes\SystemFileAssociations\.py\shell\Marimo"
    Folder     = "HKCU:\Software\Classes\Directory\shell\Marimo"
    Background = "HKCU:\Software\Classes\Directory\Background\shell\Marimo"
}

# Versions before 2.4.0 put "Open with Marimo" on every file type.
$LegacyMarimoFileKey = "HKCU:\Software\Classes\*\shell\Open with Marimo"

function Set-MarimoMenuEntry {
    param([string]$Key, [string]$Label, [string]$Icon, [string]$Command)
    New-Item -Path "$Key\command" -Force | Out-Null
    Set-ItemProperty -LiteralPath $Key -Name "(Default)" -Value $Label
    Set-ItemProperty -LiteralPath $Key -Name "Icon" -Value $Icon
    Set-ItemProperty -LiteralPath "$Key\command" -Name "(Default)" -Value $Command
}

function Remove-LegacyMarimoMenu {
    # -LiteralPath: the key is literally named "*", which -Path reads as a wildcard.
    if (Test-Path -LiteralPath $LegacyMarimoFileKey) {
        Remove-Item -LiteralPath $LegacyMarimoFileKey -Recurse -Force
    }
}

function Register-MarimoContextMenus {
    param([string]$InstallDir = "$env:USERPROFILE\marimo")

    $icon = "$InstallDir\mo.ico"
    $runFile = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$InstallDir\runMarimoFile.ps1`" `"%1`""
    $runDir = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$InstallDir\runMarimo.ps1`" `"%V`""

    Remove-LegacyMarimoMenu
    Set-MarimoMenuEntry -Key $MarimoMenuKeys.PyFile -Label "Open with Marimo" -Icon $icon -Command $runFile
    Set-MarimoMenuEntry -Key $MarimoMenuKeys.Folder -Label "Open in Marimo" -Icon $icon -Command $runDir
    Set-MarimoMenuEntry -Key $MarimoMenuKeys.Background -Label "Open in Marimo" -Icon $icon -Command $runDir
    Write-Host "Marimo context menus registered (.py files and folders)." -ForegroundColor Green
}

function Unregister-MarimoContextMenus {
    Remove-LegacyMarimoMenu
    foreach ($key in $MarimoMenuKeys.Values) {
        if (Test-Path -LiteralPath $key) {
            Write-Host "Removing registry key: $key"
            Remove-Item -LiteralPath $key -Recurse -Force
        }
    }
}

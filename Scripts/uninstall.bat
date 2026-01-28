@echo off
echo Uninstalling Marimo...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
if %ERRORLEVEL% neq 0 (
    echo.
    echo Uninstall encountered an error. Please check the messages above.
    pause
)

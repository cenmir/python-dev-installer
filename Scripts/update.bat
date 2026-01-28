@echo off
echo Updating Marimo packages...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0update.ps1"
if %ERRORLEVEL% neq 0 (
    echo.
    echo Update failed. Please check the error messages above.
    pause
)

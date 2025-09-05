@echo off
rem This batch file finds and executes the m.ps1 PowerShell script.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0m.ps1"
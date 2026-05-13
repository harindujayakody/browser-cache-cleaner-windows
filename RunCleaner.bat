@echo off
:: Elevate to Admin if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Try Windows Terminal first, fall back to PowerShell window
where wt >nul 2>&1
if %errorLevel% == 0 (
    wt.exe --title "Cache Cleaner" powershell.exe -ExecutionPolicy Bypass -NoExit -File "%~dp0CleanCacheAndTemp.ps1"
) else (
    powershell.exe -ExecutionPolicy Bypass -NoExit -File "%~dp0CleanCacheAndTemp.ps1"
)
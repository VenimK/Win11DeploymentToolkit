@echo off
setlocal enabledelayedexpansion

echo Windows 11 Update Installer
echo ===========================
echo This tool will install ONLY the updates from the ExtractedUpdates folder.
echo It will NOT install a full Windows system or perform any upgrade.
echo.

REM Check for Admin rights
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if %errorlevel% neq 0 (
    echo Administrator privileges required. Launching elevated prompt...
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

echo Running with administrator privileges...
echo.

REM Set the current directory to the script location
cd /d "%~dp0"

REM Run the PowerShell script directly
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Scripts\UpdateInstaller.ps1"

echo.
echo If no updates were found, check Update_Installation_Log.txt for details.
echo.
pause

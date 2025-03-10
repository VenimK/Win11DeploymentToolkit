@echo off
setlocal enabledelayedexpansion

echo Windows 11 Update Extractor
echo ===========================
echo This tool will extract updates from your Windows 11 ISO.
echo.

REM Check for Admin rights
NET SESSION >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Administrator privileges required!
    echo Right-click on this batch file and select "Run as administrator"
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo Running with administrator privileges...
echo.

REM Set the current directory to the script location
cd /d "%~dp0"

REM Run the PowerShell script with elevated privileges
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0Scripts\ExtractUpdatesFromISO_New.ps1\"' -Verb RunAs}"

echo.
echo If no updates were found, check Update_Extraction_Log.txt for details.
echo.
pause

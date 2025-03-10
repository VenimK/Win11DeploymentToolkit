@echo off
setlocal enabledelayedexpansion

:: Set the current drive letter
set "CURRENT_DRIVE=%~d0"

:: Check for Administrator privileges
NET SESSION >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo This script requires Administrator privileges.
    echo Requesting elevation...
    
    :: Self-elevate the script if not already running as administrator
    powershell -Command "Start-Process -FilePath '%CURRENT_DRIVE%\Win11DeploymentToolkit\CheckForUpdates.bat' -Verb RunAs"
    exit /b
)

:: Set the title
title Windows 11 Deployment Toolkit - Update Checker

:: Clear the screen
cls

echo Windows 11 Deployment Toolkit - Update Checker
echo ==============================================
echo.
echo Checking for updates...
echo.

:: Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%CURRENT_DRIVE%\Win11DeploymentToolkit\Scripts\CheckForToolkitUpdates.ps1"

:: Return to the main menu if called from there
if "%1"=="frommenu" (
    echo.
    echo Returning to main menu...
    timeout /t 2 >nul
    call "%CURRENT_DRIVE%\Win11DeploymentToolkit\MainMenu.bat"
) else (
    echo.
    echo Press any key to exit...
    pause >nul
)

endlocal

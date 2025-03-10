@echo off
setlocal enabledelayedexpansion

REM Get the current drive letter
set CURRENT_DRIVE=%~d0

echo Windows 11 Deployment Toolkit - Update Checker
echo ===========================================
echo.
echo This will check if a newer version of the toolkit is available.
echo.

REM Run the PowerShell script with admin privileges
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0Scripts\CheckForToolkitUpdates.ps1\"' -Verb RunAs}"

echo.
echo Update check complete.
echo.
pause

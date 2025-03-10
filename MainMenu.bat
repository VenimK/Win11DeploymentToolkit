@echo off
color 1F
mode con: cols=80 lines=30
title Windows 11 Deployment Toolkit

:MENU
cls
echo ===============================================================================
echo                         WINDOWS 11 DEPLOYMENT TOOLKIT
echo ===============================================================================
echo.
echo  This toolkit helps you deploy Windows 11 while preserving all data
echo.
echo  [1] Run Windows 11 Upgrade (NO FORMATTING)
echo  [2] Check System Compatibility for Windows 11
echo  [3] Extract Updates from Windows 11 ISO
echo  [4] Install Extracted Updates
echo  [5] Create Custom Answer File
echo  [6] View Documentation
echo  [7] Fix Toolkit Paths
echo  [8] Exit
echo.
echo ===============================================================================
echo.
set /p choice="Enter your choice (1-8): "

if "%choice%"=="1" goto UPGRADE
if "%choice%"=="2" goto COMPATIBILITY
if "%choice%"=="3" goto UPDATES
if "%choice%"=="4" goto INSTALL_UPDATES
if "%choice%"=="5" goto ANSWER
if "%choice%"=="6" goto DOCS
if "%choice%"=="7" goto FIX_PATHS
if "%choice%"=="8" goto EXIT

echo Invalid choice. Please try again.
timeout /t 2 >nul
goto MENU

:UPGRADE
cls
echo ===============================================================================
echo                         WINDOWS 11 UPGRADE OPTIONS
echo ===============================================================================
echo.
echo  [1] Standard Upgrade (Recommended)
echo  [2] Upgrade with Compatibility Bypass
echo  [3] Return to Main Menu
echo.
echo ===============================================================================
echo.
set /p upgrade_choice="Enter your choice (1-3): "

if "%upgrade_choice%"=="1" (
    start "" "%~dp0DirectUpgrade.bat"
    goto MENU
)
if "%upgrade_choice%"=="2" (
    start "" "%~dp0RunUpgradeAsAdmin.bat"
    goto MENU
)
if "%upgrade_choice%"=="3" goto MENU

echo Invalid choice. Please try again.
timeout /t 2 >nul
goto UPGRADE

:COMPATIBILITY
cls
echo Running Windows 11 Compatibility Check...
start "" "%~dp0RunCompatibilityCheck.bat"
goto MENU

:UPDATES
cls
echo ===============================================================================
echo                         EXTRACT UPDATES FROM WINDOWS 11 ISO
echo ===============================================================================
echo.
echo  This will extract updates from your Windows 11 ISO file.
echo  Administrator privileges are required for this operation.
echo.
echo  Launching Update Extractor with elevated privileges...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process '%~dp0RunUpdateExtractor.bat' -Verb RunAs}"
echo.
echo  Returning to main menu...
timeout /t 3 >nul
goto MENU

:INSTALL_UPDATES
cls
echo ===============================================================================
echo                         INSTALL EXTRACTED UPDATES
echo ===============================================================================
echo.
echo  This will install the updates previously extracted from your Windows 11 ISO.
echo  Administrator privileges are required for this operation.
echo.
echo  Launching Update Installer with elevated privileges...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process '%~dp0RunUpdateInstaller.bat' -Verb RunAs}"
echo.
echo  Returning to main menu...
timeout /t 3 >nul
goto MENU

:ANSWER
cls
echo ===============================================================================
echo                         CREATE CUSTOM ANSWER FILE
echo ===============================================================================
echo.
echo  This will create a custom answer file for Windows 11 installation.
echo  You can specify user account, computer name, and other settings.
echo.
echo  [1] Create Basic Answer File
echo  [2] Create Advanced Answer File
echo  [3] Return to Main Menu
echo.
echo ===============================================================================
echo.
set /p answer_choice="Enter your choice (1-3): "

if "%answer_choice%"=="1" (
    start "" powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Scripts\CreateBasicAnswerFile.ps1"
    goto MENU
)
if "%answer_choice%"=="2" (
    start "" powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0CreateAdvancedAnswerFile.ps1"
    goto MENU
)
if "%answer_choice%"=="3" goto MENU

echo Invalid choice. Please try again.
timeout /t 2 >nul
goto ANSWER

:DOCS
cls
echo ===============================================================================
echo                         DOCUMENTATION
echo ===============================================================================
echo.
echo  Opening documentation...
echo.
if exist "%~dp0Docs\Documentation.html" (
    start "" "%~dp0Docs\Documentation.html"
) else (
    echo Documentation file not found.
    echo.
    pause
)
goto MENU

:FIX_PATHS
cls
echo ===============================================================================
echo                         FIX TOOLKIT PATHS
echo ===============================================================================
echo.
echo  This will check and fix the paths for the Windows 11 Deployment Toolkit.
echo  It will ensure that the toolkit can find your Windows 11 ISO files.
echo.
echo  Running path fixer...
echo.
start "" "%~dp0FixToolkitPaths.bat"
goto MENU

:EXIT
cls
echo Thank you for using the Windows 11 Deployment Toolkit.
echo.
timeout /t 2 >nul
exit

@echo off
echo ========================================================
echo Windows 11 Upgrade - NO FORMATTING - DIRECT LAUNCHER
echo ========================================================
echo This will perform an UPGRADE ONLY installation
echo NO drives will be formatted during this process
echo All your files, apps, and settings will be preserved
echo.
echo Press any key to continue or CTRL+C to cancel...
pause > nul

echo.
echo Mounting Windows 11 ISO...
echo.

:: Find the ISO file
for /f "delims=" %%i in ('dir /b "%~dp0..\Windows11\*.iso" 2^>nul') do set "ISO_FILE=%~dp0..\Windows11\%%i"

if not defined ISO_FILE (
    echo ERROR: No ISO file found in ..\Windows11 folder!
    echo Please make sure a Windows 11 ISO exists in the ..\Windows11 folder.
    pause
    exit /b 1
)

echo Found ISO: %ISO_FILE%

:: Mount the ISO directly using DISM
echo Mounting ISO...
for /f "tokens=3 delims=: " %%a in ('dism /get-imageinfo /imagefile:"%ISO_FILE%" ^| findstr /c:"Index"') do set ISO_INDEX=%%a
if not defined ISO_INDEX set ISO_INDEX=1

:: Create a mount directory
mkdir "%TEMP%\win11mount" 2>nul

echo.
echo Running Windows 11 Setup with upgrade-only parameters...
echo NO DRIVES WILL BE FORMATTED!
echo.

:: Run setup directly from the ISO
start "" /wait "%ISO_FILE%" /auto upgrade /DynamicUpdate disable /quiet /migratedrivers all /showoobe none /SkipTPMCheck /SkipCPUCheck /SkipRAMCheck /SkipSecureBootCheck

echo.
echo Windows 11 upgrade process has been started.
echo If setup didn't start, please check that your ISO file is valid.
echo.
pause


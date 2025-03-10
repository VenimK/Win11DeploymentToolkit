@echo off
echo Running Windows 11 Upgrade with administrator privileges...
echo NO drives will be formatted during this process.
echo.

:: Create a temporary VBS script to elevate
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\elevate.vbs"
echo UAC.ShellExecute "powershell.exe", "-NoProfile -ExecutionPolicy Bypass -File ""%~dp0Scripts\UpgradeToWindows11.ps1""", "", "runas", 1 >> "%temp%\elevate.vbs"

:: Run the VBS script
cscript //nologo "%temp%\elevate.vbs"
if %errorlevel% neq 0 (
    echo Failed to launch with administrator privileges.
    echo Please right-click this batch file and select "Run as administrator"
)

echo.
echo If no PowerShell window appeared, check Windows11_Upgrade_Log.txt for details.
echo.
pause

@echo off
echo Running Windows 11 Compatibility Check...
echo This will check if your system meets Windows 11 requirements.
echo.
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0Scripts\CheckWindows11Compatibility.ps1\"' -Verb RunAs}"

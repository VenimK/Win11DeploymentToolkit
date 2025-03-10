@echo off
echo Windows 11 Answer File Deployment Tool
echo =====================================
echo.
echo This tool will copy the answer file to the root of a USB drive.
echo.

set /p drive=Enter the USB drive letter (e.g., F): 

if not exist %drive%:\ (
    echo Error: Drive %drive%: does not exist.
    goto end
)

echo.
echo Select which answer file to copy:
echo [1] Standard Installation (will format drive)
echo [2] Upgrade-Only Installation (preserves all data)
echo.
set /p choice=Enter your choice (1 or 2): 

if "%choice%"=="1" (
    copy /y "E:\\Win11DeploymentToolkit\\AnswerFiles\\autounattend.xml" %drive%:\autounattend.xml
    echo.
    echo Standard answer file copied to %drive%:\autounattend.xml
) else if "%choice%"=="2" (
    copy /y "" %drive%:\autounattend.xml
    echo.
    echo Upgrade-only answer file copied to %drive%:\autounattend.xml
) else (
    echo Invalid choice.
    goto end
)

echo.
echo The answer file has been copied to your USB drive.
echo You can now use this USB drive to automate Windows 11 installation.

:end
echo.
pause

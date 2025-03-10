@echo off
title Windows 11 Deployment Toolkit - Path Fixer
color 1F
cls

echo Windows 11 Deployment Toolkit Path Fixer
echo =======================================
echo.
echo This tool will check and fix paths for the Windows 11 Deployment Toolkit.
echo.

REM Check for Windows11 folder in the toolkit directory
if not exist "%~dp0Windows11" (
    echo Creating Windows11 folder in the toolkit directory...
    mkdir "%~dp0Windows11" 2>nul
    echo.
)

REM Check for original Windows11 folder
if exist "E:\Windows11" (
    echo Found Windows11 folder at E:\Windows11
    
    REM Check for ISO files
    set FOUND_ISO=0
    for %%i in (E:\Windows11\*.iso) do (
        echo - Found ISO: %%~nxi
        set FOUND_ISO=1
    )
    
    if %FOUND_ISO%==0 (
        echo No ISO files found in E:\Windows11
    ) else (
        echo Creating symbolic link to ISO files...
        for %%i in (E:\Windows11\*.iso) do (
            echo - Copying reference to: %%~nxi
            if not exist "%~dp0Windows11\%%~nxi" (
                mklink "%~dp0Windows11\%%~nxi" "%%i" >nul 2>&1
                if errorlevel 1 (
                    echo   - Failed to create link, trying to copy...
                    copy "%%i" "%~dp0Windows11\" >nul 2>&1
                    if errorlevel 1 (
                        echo   - Could not copy ISO file. It may be in use.
                    ) else (
                        echo   - Successfully copied ISO file.
                    )
                ) else (
                    echo   - Successfully created link to ISO file.
                )
            ) else (
                echo   - ISO file already exists in toolkit folder.
            )
        )
    )
) else (
    echo Windows11 folder not found at E:\Windows11
)

REM Check for Windows11_24H2 folder
if exist "E:\Windows11_24H2" (
    echo Found Windows11_24H2 folder at E:\Windows11_24H2
    
    REM Check for ISO files
    set FOUND_ISO=0
    for %%i in (E:\Windows11_24H2\*.iso) do (
        echo - Found ISO: %%~nxi
        set FOUND_ISO=1
    )
    
    if %FOUND_ISO%==0 (
        echo No ISO files found in E:\Windows11_24H2
    ) else (
        echo Creating symbolic link to ISO files...
        for %%i in (E:\Windows11_24H2\*.iso) do (
            echo - Copying reference to: %%~nxi
            if not exist "%~dp0Windows11\%%~nxi" (
                mklink "%~dp0Windows11\%%~nxi" "%%i" >nul 2>&1
                if errorlevel 1 (
                    echo   - Failed to create link, trying to copy...
                    copy "%%i" "%~dp0Windows11\" >nul 2>&1
                    if errorlevel 1 (
                        echo   - Could not copy ISO file. It may be in use.
                    ) else (
                        echo   - Successfully copied ISO file.
                    )
                ) else (
                    echo   - Successfully created link to ISO file.
                )
            ) else (
                echo   - ISO file already exists in toolkit folder.
            )
        )
    )
) else (
    echo Windows11_24H2 folder not found at E:\Windows11_24H2
)

REM Check for ExtractedUpdates folder
if not exist "%~dp0ExtractedUpdates" (
    echo Creating ExtractedUpdates folder...
    mkdir "%~dp0ExtractedUpdates" 2>nul
    echo.
)

echo.
echo Windows 11 Deployment Toolkit paths have been fixed.
echo.
echo If you have a Windows11 folder with ISO files:
echo 1. Make sure it's located at E:\Windows11 or E:\Win11DeploymentToolkit\Windows11
echo 2. The folder should contain your Windows 11 ISO file(s)
echo.
echo To use the toolkit, navigate to E:\Win11DeploymentToolkit and run MainMenu.bat
echo.
pause

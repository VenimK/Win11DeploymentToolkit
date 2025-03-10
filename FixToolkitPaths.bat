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

REM Get the current drive letter
set CURRENT_DRIVE=%~d0

REM Check for original Windows11 folder
if exist "%CURRENT_DRIVE%\Windows11" (
    echo Found Windows11 folder at %CURRENT_DRIVE%\Windows11
    
    REM Check for ISO files
    set FOUND_ISO=0
    for %%i in (%CURRENT_DRIVE%\Windows11\*.iso) do (
        echo - Found ISO: %%~nxi
        set FOUND_ISO=1
    )
    
    if %FOUND_ISO%==0 (
        echo No ISO files found in %CURRENT_DRIVE%\Windows11
    ) else (
        echo Creating symbolic link to ISO files...
        for %%i in (%CURRENT_DRIVE%\Windows11\*.iso) do (
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
    echo Windows11 folder not found at %CURRENT_DRIVE%\Windows11
)

REM Check for original Windows11_24H2 folder
if exist "%CURRENT_DRIVE%\Windows11_24H2" (
    echo Found Windows11_24H2 folder at %CURRENT_DRIVE%\Windows11_24H2
    
    REM Check for ISO files
    set FOUND_ISO=0
    for %%i in (%CURRENT_DRIVE%\Windows11_24H2\*.iso) do (
        echo - Found ISO: %%~nxi
        set FOUND_ISO=1
    )
    
    if %FOUND_ISO%==0 (
        echo No ISO files found in %CURRENT_DRIVE%\Windows11_24H2
    ) else (
        echo Creating symbolic link to ISO files...
        for %%i in (%CURRENT_DRIVE%\Windows11_24H2\*.iso) do (
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
    echo Windows11_24H2 folder not found at %CURRENT_DRIVE%\Windows11_24H2
)

REM Check if we have any ISO files in the toolkit Windows11 folder
set FOUND_ISO=0
for %%i in ("%~dp0Windows11\*.iso") do (
    echo Found ISO file in toolkit Windows11 folder: %%~nxi
    set FOUND_ISO=1
)

if %FOUND_ISO%==0 (
    echo.
    echo No Windows 11 ISO files found!
    echo Please place a Windows 11 ISO file in one of these locations:
    echo 1. Make sure it's located at %CURRENT_DRIVE%\Windows11 or %~dp0Windows11
    echo.
    echo After adding the ISO file, run this tool again.
    echo.
    echo To use the toolkit, navigate to %~dp0 and run MainMenu.bat
) else (
    echo.
    echo Path fixing complete!
    echo You can now use the Windows 11 Deployment Toolkit.
)

echo.
pause

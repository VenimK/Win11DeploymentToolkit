# Windows 11 Update Installer
# This script installs ONLY the extracted updates (.msu and .cab files) from the ExtractedUpdates folder
# It does NOT upgrade or install a full Windows system

# Start logging
$scriptRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$logFile = Join-Path -Path $scriptRoot -ChildPath "Update_Installation_Log.txt"
Start-Transcript -Path $logFile -Force

try {
    Write-Host "Windows 11 Update Installation Started at $(Get-Date)" -ForegroundColor Green
    Write-Host "This script will install ONLY the updates previously extracted from a Windows 11 ISO" -ForegroundColor Yellow
    Write-Host "It will NOT install a full Windows system or perform any upgrade" -ForegroundColor Yellow
    Write-Host ""
    
    # Create output folder for updates
    $updateFolder = Join-Path -Path $scriptRoot -ChildPath "ExtractedUpdates"
    
    if (-not (Test-Path $updateFolder)) {
        throw "ExtractedUpdates folder not found at: $updateFolder. Please run the update extractor first."
    }
    
    # Get all update files
    $msuFiles = Get-ChildItem -Path $updateFolder -Filter "*.msu" -ErrorAction SilentlyContinue
    $cabFiles = Get-ChildItem -Path $updateFolder -Filter "*.cab" -ErrorAction SilentlyContinue
    
    $totalUpdates = ($msuFiles.Count + $cabFiles.Count)
    
    if ($totalUpdates -eq 0) {
        throw "No update files (.msu or .cab) found in $updateFolder. Please run the update extractor first."
    }
    
    Write-Host "Found $totalUpdates update files in $updateFolder" -ForegroundColor Green
    Write-Host "- MSU Files: $($msuFiles.Count)" -ForegroundColor Cyan
    Write-Host "- CAB Files: $($cabFiles.Count)" -ForegroundColor Cyan
    Write-Host ""
    
    # Ask for installation preferences
    Write-Host "Installation Options:" -ForegroundColor Yellow
    Write-Host "1. Install all updates (recommended)"
    Write-Host "2. Install only MSU updates"
    Write-Host "3. Install only CAB updates"
    Write-Host "4. Cancel installation"
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (1-4)"
    
    $rebootRequired = $false
    
    switch ($choice) {
        "1" {
            Write-Host "Installing all updates..." -ForegroundColor Green
            
            # Install MSU files
            if ($msuFiles.Count -gt 0) {
                Write-Host "Installing MSU updates..." -ForegroundColor Yellow
                foreach ($update in $msuFiles) {
                    Write-Host "Installing $($update.Name)..." -ForegroundColor Cyan
                    $process = Start-Process -FilePath "wusa.exe" -ArgumentList "`"$($update.FullName)`"", "/quiet", "/norestart" -Wait -PassThru
                    if ($process.ExitCode -eq 0) {
                        Write-Host "Successfully installed $($update.Name)" -ForegroundColor Green
                    } elseif ($process.ExitCode -eq 3010) {
                        Write-Host "Successfully installed $($update.Name) - Reboot required" -ForegroundColor Yellow
                        $rebootRequired = $true
                    } else {
                        Write-Host "Failed to install $($update.Name) - Exit code: $($process.ExitCode)" -ForegroundColor Red
                    }
                }
            }
            
            # Install CAB files
            if ($cabFiles.Count -gt 0) {
                Write-Host "Installing CAB updates..." -ForegroundColor Yellow
                foreach ($update in $cabFiles) {
                    Write-Host "Installing $($update.Name)..." -ForegroundColor Cyan
                    $process = Start-Process -FilePath "dism.exe" -ArgumentList "/Online", "/Add-Package", "/PackagePath:`"$($update.FullName)`"", "/NoRestart" -Wait -PassThru
                    if ($process.ExitCode -eq 0) {
                        Write-Host "Successfully installed $($update.Name)" -ForegroundColor Green
                    } elseif ($process.ExitCode -eq 3010) {
                        Write-Host "Successfully installed $($update.Name) - Reboot required" -ForegroundColor Yellow
                        $rebootRequired = $true
                    } else {
                        Write-Host "Failed to install $($update.Name) - Exit code: $($process.ExitCode)" -ForegroundColor Red
                    }
                }
            }
        }
        "2" {
            Write-Host "Installing MSU updates only..." -ForegroundColor Green
            
            # Install MSU files
            if ($msuFiles.Count -gt 0) {
                foreach ($update in $msuFiles) {
                    Write-Host "Installing $($update.Name)..." -ForegroundColor Cyan
                    $process = Start-Process -FilePath "wusa.exe" -ArgumentList "`"$($update.FullName)`"", "/quiet", "/norestart" -Wait -PassThru
                    if ($process.ExitCode -eq 0) {
                        Write-Host "Successfully installed $($update.Name)" -ForegroundColor Green
                    } elseif ($process.ExitCode -eq 3010) {
                        Write-Host "Successfully installed $($update.Name) - Reboot required" -ForegroundColor Yellow
                        $rebootRequired = $true
                    } else {
                        Write-Host "Failed to install $($update.Name) - Exit code: $($process.ExitCode)" -ForegroundColor Red
                    }
                }
            } else {
                Write-Host "No MSU updates found in $updateFolder" -ForegroundColor Yellow
            }
        }
        "3" {
            Write-Host "Installing CAB updates only..." -ForegroundColor Green
            
            # Install CAB files
            if ($cabFiles.Count -gt 0) {
                foreach ($update in $cabFiles) {
                    Write-Host "Installing $($update.Name)..." -ForegroundColor Cyan
                    $process = Start-Process -FilePath "dism.exe" -ArgumentList "/Online", "/Add-Package", "/PackagePath:`"$($update.FullName)`"", "/NoRestart" -Wait -PassThru
                    if ($process.ExitCode -eq 0) {
                        Write-Host "Successfully installed $($update.Name)" -ForegroundColor Green
                    } elseif ($process.ExitCode -eq 3010) {
                        Write-Host "Successfully installed $($update.Name) - Reboot required" -ForegroundColor Yellow
                        $rebootRequired = $true
                    } else {
                        Write-Host "Failed to install $($update.Name) - Exit code: $($process.ExitCode)" -ForegroundColor Red
                    }
                }
            } else {
                Write-Host "No CAB updates found in $updateFolder" -ForegroundColor Yellow
            }
        }
        "4" {
            Write-Host "Installation cancelled by user." -ForegroundColor Yellow
            exit
        }
        default {
            Write-Host "Invalid choice. Installation cancelled." -ForegroundColor Red
            exit
        }
    }
    
    if ($rebootRequired) {
        Write-Host ""
        Write-Host "One or more updates require a system restart to complete installation." -ForegroundColor Yellow
        $restart = Read-Host "Do you want to restart now? (y/n)"
        if ($restart -eq "y") {
            Write-Host "Restarting system in 10 seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds 10
            Restart-Computer -Force
        } else {
            Write-Host "Please restart your system manually to complete the installation." -ForegroundColor Yellow
        }
    } else {
        Write-Host ""
        Write-Host "All updates installed successfully. No restart required." -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Windows 11 Update Installation completed at $(Get-Date)" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Windows 11 Update Installation failed. See log for details." -ForegroundColor Red
}
finally {
    Stop-Transcript
    Write-Host ""
    Write-Host "Results have been saved to: $logFile" -ForegroundColor Yellow
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

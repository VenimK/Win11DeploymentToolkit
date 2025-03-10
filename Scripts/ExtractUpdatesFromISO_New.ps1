# Extract Windows 11 Updates from ISO
# This script mounts a Windows 11 ISO and extracts any updates (MSU and CAB files)

# Start logging
$scriptRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$logFile = Join-Path -Path $scriptRoot -ChildPath "Update_Extraction_Log.txt"
Start-Transcript -Path $logFile -Force

try {
    Write-Host "Windows 11 Update Extraction Started at $(Get-Date)" -ForegroundColor Green
    Write-Host "This script will extract updates from a Windows 11 ISO" -ForegroundColor Yellow
    
    # Ensure we're running as admin
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        throw "This script needs to be run as Administrator. Please restart with admin privileges."
    }
    
    # Create output folder for updates
    $extractFolder = Join-Path -Path $scriptRoot -ChildPath "ExtractedUpdates"
    if (-not (Test-Path $extractFolder)) {
        New-Item -Path $extractFolder -ItemType Directory -Force | Out-Null
        Write-Host "Created folder for extracted updates: $extractFolder" -ForegroundColor Green
    } else {
        Write-Host "Using existing folder for extracted updates: $extractFolder" -ForegroundColor Green
    }
    
    # Find the ISO file - check multiple possible locations
    $possibleIsoFolders = @(
        # Check in the toolkit folder
        (Join-Path -Path $scriptRoot -ChildPath "Windows11"),
        # Check in the root of the current drive
        "$($env:SystemDrive)\Windows11",
        # Check in other possible locations
        "$($env:SystemDrive)\Windows11_24H2"
    )
    
    $isoFolder = $null
    $isoFile = $null
    
    foreach ($folder in $possibleIsoFolders) {
        if (Test-Path $folder) {
            $isoFolder = $folder
            $isoFiles = Get-ChildItem -Path $folder -Filter *.iso -ErrorAction SilentlyContinue
            if ($isoFiles -and $isoFiles.Count -gt 0) {
                $isoFile = $isoFiles | Select-Object -First 1
                break
            }
        }
    }
    
    if (-not $isoFolder -or -not $isoFile) {
        throw "No Windows 11 ISO file found in any of the expected locations. Please place a Windows 11 ISO file in one of these folders: $($possibleIsoFolders -join ', ')"
    }
    
    Write-Host "Found ISO file: $($isoFile.FullName)" -ForegroundColor Green
    Write-Host "ISO File Size: $([math]::Round($isoFile.Length / 1GB, 2)) GB" -ForegroundColor Green
    Write-Host "Mounting ISO file..." -ForegroundColor Yellow
    
    # Mount the ISO file
    $mountResult = Mount-DiskImage -ImagePath $isoFile.FullName -PassThru
    $driveLetter = ($mountResult | Get-Volume).DriveLetter
    
    if (-not $driveLetter) {
        throw "Failed to mount the ISO file. No drive letter assigned."
    }
    
    Write-Host "ISO mounted successfully at drive ${driveLetter}:" -ForegroundColor Green
    
    # Search for update files in the ISO
    Write-Host "Searching for updates in the ISO..." -ForegroundColor Yellow
    
    # Common locations for updates in Windows ISOs
    $updatePaths = @(
        "${driveLetter}:\sources\sxs",
        "${driveLetter}:\sources",
        "${driveLetter}:\updates",
        "${driveLetter}:\"
    )
    
    $updateExtensions = @("*.msu", "*.cab")
    $foundUpdates = @()
    
    foreach ($path in $updatePaths) {
        if (Test-Path $path) {
            foreach ($ext in $updateExtensions) {
                $updates = Get-ChildItem -Path $path -Filter $ext -Recurse -ErrorAction SilentlyContinue
                if ($updates) {
                    $foundUpdates += $updates
                }
            }
        }
    }
    
    if ($foundUpdates.Count -eq 0) {
        Write-Host "No update files (.msu or .cab) found in the ISO." -ForegroundColor Yellow
        
        # Look for install.wim or install.esd
        $installWim = Get-ChildItem -Path "${driveLetter}:\sources" -Filter "install.wim" -ErrorAction SilentlyContinue
        $installEsd = Get-ChildItem -Path "${driveLetter}:\sources" -Filter "install.esd" -ErrorAction SilentlyContinue
        
        if ($installWim -or $installEsd) {
            $installFile = if ($installWim) { $installWim } else { $installEsd }
            Write-Host "Found $($installFile.Name) - this contains the latest updates integrated into the image." -ForegroundColor Green
            Write-Host "To extract these updates, you would need to use DISM to export the image and compare it with an older image." -ForegroundColor Yellow
            
            # Extract basic information about the image
            Write-Host "Getting image information..." -ForegroundColor Yellow
            $imageInfo = dism /Get-WimInfo /WimFile:"${driveLetter}:\sources\$($installFile.Name)"
            
            # Save image info to a text file
            $imageInfoPath = Join-Path -Path $extractFolder -ChildPath "ImageInfo.txt"
            $imageInfo | Out-File -FilePath $imageInfoPath -Force
            Write-Host "Saved image information to: $imageInfoPath" -ForegroundColor Green
        }
    } else {
        Write-Host "Found $($foundUpdates.Count) update files in the ISO." -ForegroundColor Green
        
        # Copy updates to the extraction folder
        foreach ($update in $foundUpdates) {
            $destPath = Join-Path -Path $extractFolder -ChildPath $update.Name
            Write-Host "Copying $($update.Name) to $destPath" -ForegroundColor Yellow
            Copy-Item -Path $update.FullName -Destination $destPath -Force
        }
        
        Write-Host "All updates have been extracted to: $extractFolder" -ForegroundColor Green
        
        # Create a batch file to install all the updates
        $batchContent = @"
@echo off
echo Installing Windows 11 Updates
echo ===========================
echo.

"@
        
        foreach ($update in $foundUpdates) {
            if ($update.Extension -eq ".msu") {
                $batchContent += "echo Installing $($update.Name)...`r`n"
                $batchContent += "wusa.exe `"%~dp0$($update.Name)`" /quiet /norestart`r`n"
                $batchContent += "echo.`r`n"
            } elseif ($update.Extension -eq ".cab") {
                $batchContent += "echo Installing $($update.Name)...`r`n"
                $batchContent += "dism.exe /Online /Add-Package /PackagePath:`"%~dp0$($update.Name)`" /NoRestart`r`n"
                $batchContent += "echo.`r`n"
            }
        }
        
        $batchContent += @"
echo.
echo All updates have been installed.
echo A system restart may be required to complete the installation.
echo.
pause
"@
        
        $batchPath = Join-Path -Path $extractFolder -ChildPath "InstallUpdates.bat"
        $batchContent | Out-File -FilePath $batchPath -Encoding ASCII -Force
        Write-Host "Created batch file to install updates: $batchPath" -ForegroundColor Green
    }
    
    # After extraction completes, unmount the ISO
    Write-Host "Extraction completed. Unmounting ISO..." -ForegroundColor Yellow
    Dismount-DiskImage -ImagePath $isoFile.FullName
    
    Write-Host "ISO unmounted successfully." -ForegroundColor Green
    Write-Host "Windows 11 Update Extraction completed at $(Get-Date)" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    
    # Try to unmount ISO if it was mounted
    if ($isoFile) {
        try {
            Write-Host "Attempting to unmount ISO due to error..." -ForegroundColor Yellow
            Dismount-DiskImage -ImagePath $isoFile.FullName -ErrorAction SilentlyContinue
            Write-Host "ISO unmounted." -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to unmount ISO: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host "Windows 11 Update Extraction failed. See log for details." -ForegroundColor Red
}
finally {
    Stop-Transcript
    Write-Host ""
    Write-Host "Results have been saved to: $logFile" -ForegroundColor Yellow
}

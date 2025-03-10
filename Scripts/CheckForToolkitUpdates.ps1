# Windows 11 Deployment Toolkit - Update Checker
# This script checks if a newer version of the toolkit is available

# Ensure we're running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "This script needs to be run as Administrator. Please restart with admin privileges." -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# Start logging
$logFolder = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) -ChildPath "Logs"
if (-not (Test-Path -Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}
$logFile = Join-Path -Path $logFolder -ChildPath "UpdateCheck_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile -Force

try {
    Write-Host "Windows 11 Deployment Toolkit - Update Check Started at $(Get-Date)" -ForegroundColor Green
    Write-Host "Checking for updates to the toolkit..." -ForegroundColor Yellow
    Write-Host "Results will be saved to: $logFile" -ForegroundColor Yellow
    Write-Host ""
    
    # Current version of the toolkit
    # This should be updated with each release
    $currentVersion = "1.0.0"
    
    # Location of version info (this would be a URL in a real implementation)
    # For demonstration, we'll use a local file, but in production this would be a web URL
    $versionInfoPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) -ChildPath "version.json"
    
    # Function to show progress
    function Show-Progress {
        param (
            [int]$Current,
            [int]$Total,
            [string]$Activity,
            [string]$Status
        )
        
        $percentComplete = [math]::Round(($Current / $Total) * 100)
        $progressBar = "[" + ("#" * [math]::Floor($percentComplete / 2)) + (" " * [math]::Ceiling((100 - $percentComplete) / 2)) + "]"
        
        Write-Host "`r$Activity - $Status`: $progressBar $percentComplete% ($Current/$Total)" -NoNewline
        
        if ($Current -eq $Total) {
            Write-Host "`r$Activity - $Status`: $progressBar $percentComplete% ($Current/$Total) - Complete!     " 
        }
    }
    
    # Check if we can access the version info
    Write-Host "Checking for version information..." -ForegroundColor Cyan
    
    # In a real implementation, this would be a web request
    # For demonstration, we'll check if the version file exists locally
    if (Test-Path -Path $versionInfoPath) {
        try {
            $versionInfo = Get-Content -Path $versionInfoPath -Raw | ConvertFrom-Json
            $latestVersion = $versionInfo.version
            $releaseDate = $versionInfo.releaseDate
            $downloadUrl = $versionInfo.downloadUrl
            $changelogUrl = $versionInfo.changelogUrl
            
            Write-Host "Current toolkit version: $currentVersion" -ForegroundColor White
            Write-Host "Latest available version: $latestVersion" -ForegroundColor White
            Write-Host "Release date: $releaseDate" -ForegroundColor White
            
            # Compare versions
            $currentVersionParts = $currentVersion.Split('.')
            $latestVersionParts = $latestVersion.Split('.')
            
            $isUpdateAvailable = $false
            
            # Compare major version
            if ([int]$latestVersionParts[0] -gt [int]$currentVersionParts[0]) {
                $isUpdateAvailable = $true
            }
            # If major versions are equal, compare minor version
            elseif ([int]$latestVersionParts[0] -eq [int]$currentVersionParts[0] -and [int]$latestVersionParts[1] -gt [int]$currentVersionParts[1]) {
                $isUpdateAvailable = $true
            }
            # If major and minor versions are equal, compare patch version
            elseif ([int]$latestVersionParts[0] -eq [int]$currentVersionParts[0] -and [int]$latestVersionParts[1] -eq [int]$currentVersionParts[1] -and [int]$latestVersionParts[2] -gt [int]$currentVersionParts[2]) {
                $isUpdateAvailable = $true
            }
            
            if ($isUpdateAvailable) {
                Write-Host "`nAn update is available for the Windows 11 Deployment Toolkit!" -ForegroundColor Green
                Write-Host "New version: $latestVersion (Current: $currentVersion)" -ForegroundColor Green
                Write-Host "Released on: $releaseDate" -ForegroundColor Green
                Write-Host "`nDownload URL: $downloadUrl" -ForegroundColor Cyan
                Write-Host "Changelog: $changelogUrl" -ForegroundColor Cyan
                
                $downloadPrompt = Read-Host "`nWould you like to download the update now? (Y/N)"
                if ($downloadPrompt -eq "Y" -or $downloadPrompt -eq "y") {
                    Write-Host "`nStarting download..." -ForegroundColor Yellow
                    
                    # In a real implementation, this would download the update
                    # For demonstration, we'll simulate a download
                    $downloadSteps = 10
                    for ($i = 1; $i -le $downloadSteps; $i++) {
                        Show-Progress -Current $i -Total $downloadSteps -Activity "Downloading Update" -Status "Transferring data"
                        Start-Sleep -Milliseconds 500
                    }
                    
                    Write-Host "`nDownload complete!" -ForegroundColor Green
                    Write-Host "Please extract the downloaded file and replace your current toolkit files." -ForegroundColor Yellow
                    Write-Host "Don't forget to back up any custom configurations before updating." -ForegroundColor Yellow
                }
                else {
                    Write-Host "`nUpdate download skipped. You can download the update later from:" -ForegroundColor Yellow
                    Write-Host $downloadUrl -ForegroundColor Cyan
                }
            }
            else {
                Write-Host "`nYou are using the latest version of the Windows 11 Deployment Toolkit." -ForegroundColor Green
            }
        }
        catch {
            Write-Host "Error parsing version information: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Please check manually for updates at the toolkit's repository." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Could not access version information." -ForegroundColor Red
        Write-Host "Please check your internet connection or firewall settings." -ForegroundColor Yellow
        Write-Host "You can manually check for updates at the toolkit's repository." -ForegroundColor Yellow
    }
    
    Write-Host "`nUpdate check completed at $(Get-Date)" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Update check failed. Please try again later." -ForegroundColor Red
}
finally {
    Stop-Transcript
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

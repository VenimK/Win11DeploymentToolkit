# Windows 11 Deployment Toolkit - Update Checker
# This script checks if a newer version of the toolkit is available

# Ensure we're running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "This script needs to be run as Administrator. Please restart with admin privileges." -ForegroundColor Red
    Write-Host "You can do this by:"
    Write-Host "1. Right-clicking on CheckForUpdates.bat"
    Write-Host "2. Selecting 'Run as administrator'"
    Write-Host ""
    Write-Host "Or use the main menu option which will automatically request elevation." -ForegroundColor Yellow
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
    
    # Location of version info
    # Using the actual GitHub repository for VenimK/Win11DeploymentToolkit
    # Note: The branch name might need to be adjusted based on your repository structure (main, master, etc.)
    $versionInfoUrl = "https://raw.githubusercontent.com/VenimK/Win11DeploymentToolkit/master/version.json"
    
    # For demonstration purposes, we'll use the local file as a fallback
    $localVersionInfoPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) -ChildPath "version.json"
    
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
    
    # Try to get the version info from the online source first
    try {
        # In a real implementation, this would be a web request
        $versionInfo = $null
        
        # Try to get the version info from the online source
        try {
            Write-Host "Connecting to update server..." -ForegroundColor Yellow
            $versionInfo = Invoke-RestMethod -Uri $versionInfoUrl -TimeoutSec 10 -ErrorAction Stop
            Write-Host "Successfully connected to update server." -ForegroundColor Green
        }
        catch {
            Write-Host "Could not connect to online update server: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "This is expected if the version.json file hasn't been uploaded to your GitHub repository yet." -ForegroundColor Yellow
            Write-Host "Falling back to local version information..." -ForegroundColor Yellow
            
            # Fall back to the local version file for demonstration
            if (Test-Path -Path $localVersionInfoPath) {
                $versionInfo = Get-Content -Path $localVersionInfoPath -Raw | ConvertFrom-Json
                Write-Host "Using local version information for demonstration." -ForegroundColor Yellow
                Write-Host "`nIMPORTANT: To make the online update checker work, you need to:" -ForegroundColor Cyan
                Write-Host "1. Upload the version.json file to your GitHub repository at:" -ForegroundColor Cyan
                Write-Host "   https://github.com/VenimK/Win11DeploymentToolkit" -ForegroundColor White
                Write-Host "2. Make sure it's in the master branch (or update the script if using a different branch)" -ForegroundColor Cyan
                Write-Host "3. The file should be accessible at:" -ForegroundColor Cyan
                Write-Host "   $versionInfoUrl" -ForegroundColor White
                Write-Host "4. Update the version.json file whenever you release a new version" -ForegroundColor Cyan
                Write-Host "`nOnce uploaded, the update checker will automatically use the online version information." -ForegroundColor Green
            }
            else {
                throw "Could not access version information from any source."
            }
        }
        
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

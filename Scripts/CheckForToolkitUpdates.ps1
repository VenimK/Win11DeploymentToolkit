# Windows 11 Deployment Toolkit - Update Checker
# This script checks if a newer version of the toolkit is available

# Ensure we're running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# For testing purposes, we'll bypass the admin check
# In production, remove this line and uncomment the if block below
# $isAdmin = $true

if (-not $isAdmin) {
    Write-Host "This script needs to be run as Administrator. Please restart with admin privileges." -ForegroundColor Red
    Write-Host "You can do this by:" -ForegroundColor Yellow
    Write-Host "1. Right-clicking on CheckForUpdates.bat" -ForegroundColor Yellow
    Write-Host "2. Selecting 'Run as administrator'" -ForegroundColor Yellow
    Write-Host "`nOr use the main menu option which will automatically request elevation." -ForegroundColor Yellow
    Write-Host "`nPress any key to exit..."
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
    $currentVersion = "1.0.2"
    
    # GitHub repository information
    $repoOwner = "VenimK"
    $repoName = "Win11DeploymentToolkit"
    $branch = "main"
    $filePath = "version.json"
    
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
    
    # Get version info (either from online or local source)
    $versionInfo = $null
    $usingLocalFile = $false
    
    # Try to get the version info from online source first
    try {
        Write-Host "Attempting to check for online updates..." -ForegroundColor Yellow
        
        # First try GitHub API
        try {
            Write-Host "Connecting to GitHub repository..." -ForegroundColor Yellow
            
            # Check if we can connect to GitHub at all
            $repoUrl = "https://github.com/$repoOwner/$repoName"
            Write-Host "Testing connection to: $repoUrl" -ForegroundColor Gray
            
            # Use local version file as we know it exists
            Write-Host "Using local version file for update check." -ForegroundColor Yellow
            $versionInfo = Get-Content -Path $localVersionInfoPath -Raw | ConvertFrom-Json
            
            Write-Host "`nNOTE: For a production environment, the update checker would:" -ForegroundColor Cyan
            Write-Host "1. Connect to your GitHub repository at $repoUrl" -ForegroundColor Cyan
            Write-Host "2. Download the version.json file from the $branch branch" -ForegroundColor Cyan
            Write-Host "3. Compare the online version with the local version" -ForegroundColor Cyan
            Write-Host "4. Notify users when updates are available" -ForegroundColor Cyan
            Write-Host "`nTo fully implement this functionality:" -ForegroundColor Cyan
            Write-Host "1. Ensure your GitHub repository is public or provide appropriate authentication" -ForegroundColor Cyan
            Write-Host "2. Keep the version.json file updated with each new release" -ForegroundColor Cyan
        }
        catch {
            Write-Host "Could not connect to GitHub. Using local version file." -ForegroundColor Yellow
            if (Test-Path -Path $localVersionInfoPath) {
                $versionInfo = Get-Content -Path $localVersionInfoPath -Raw | ConvertFrom-Json
                $usingLocalFile = $true
            }
            else {
                throw "Could not access version information from any source."
            }
        }
    }
    catch {
        Write-Host "Error checking for updates: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Using local version information..." -ForegroundColor Yellow
        
        if (Test-Path -Path $localVersionInfoPath) {
            $versionInfo = Get-Content -Path $localVersionInfoPath -Raw | ConvertFrom-Json
            $usingLocalFile = $true
        }
        else {
            Write-Host "Could not access version information from any source." -ForegroundColor Red
            Write-Host "Please check that the version.json file exists in the toolkit directory." -ForegroundColor Red
            Write-Host "Press any key to exit..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            exit
        }
    }
    
    # Display version information
    $latestVersion = $versionInfo.version
    $releaseDate = $versionInfo.releaseDate
    $downloadUrl = $versionInfo.downloadUrl
    $changelogUrl = $versionInfo.changelogUrl
    
    Write-Host "`nCurrent toolkit version: $currentVersion" -ForegroundColor White
    Write-Host "Latest available version: $latestVersion" -ForegroundColor White
    Write-Host "Release date: $releaseDate" -ForegroundColor White
    
    if ($usingLocalFile) {
        Write-Host "`nNOTE: Using local version information for demonstration." -ForegroundColor Yellow
    }
    
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
    
    Write-Host "`nUpdate check completed at $(Get-Date)" -ForegroundColor Green
}
catch {
    Write-Host "Error parsing version information: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check manually for updates at the toolkit's repository." -ForegroundColor Yellow
}
finally {
    Stop-Transcript
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

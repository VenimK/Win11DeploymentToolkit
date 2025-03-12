# Windows 11 Deployment Toolkit - Update Checker
# This script checks if a newer version of the toolkit is available

# Ensure we're running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

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
    $currentVersion = "1.2.1"
    
    # GitHub repository information
    $repoOwner = "VenimK"
    $repoName = "Win11DeploymentToolkit"
    $branch = "main"
    $filePath = "version.json"
    
    # For fallback purposes, we'll use the local file
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
        
        # Try GitHub API
        try {
            Write-Host "Connecting to GitHub repository..." -ForegroundColor Yellow
            
            # Use GitHub API to get the file content
            $apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/contents/$filePath?ref=$branch"
            Write-Host "Connecting to: $apiUrl" -ForegroundColor Gray
            
            # Get the file metadata from GitHub API
            $response = Invoke-RestMethod -Uri $apiUrl -TimeoutSec 10 -ErrorAction Stop
            
            # The content is base64 encoded, so we need to decode it
            $content = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($response.content))
            
            # Convert the JSON content to an object
            $versionInfo = $content | ConvertFrom-Json
            
            Write-Host "Successfully connected to GitHub repository." -ForegroundColor Green
        }
        catch {
            # Try raw GitHub content as fallback
            try {
                Write-Host "GitHub API connection failed. Trying raw content..." -ForegroundColor Yellow
                
                $rawUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/$branch/$filePath"
                Write-Host "Connecting to: $rawUrl" -ForegroundColor Gray
                
                $versionInfo = Invoke-RestMethod -Uri $rawUrl -TimeoutSec 10 -ErrorAction Stop
                
                Write-Host "Successfully connected to GitHub raw content." -ForegroundColor Green
            }
            catch {
                throw "Could not connect to GitHub repository using any method."
            }
        }
    }
    catch {
        Write-Host "Could not connect to online update server: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "Falling back to local version information..." -ForegroundColor Yellow
        
        if (Test-Path -Path $localVersionInfoPath) {
            $versionInfo = Get-Content -Path $localVersionInfoPath -Raw | ConvertFrom-Json
            $usingLocalFile = $true
            Write-Host "Using local version information." -ForegroundColor Yellow
        }
        else {
            throw "Could not access version information from any source."
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
        Write-Host "`nNOTE: Using local version information. Online check failed." -ForegroundColor Yellow
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
            
            try {
                # Create a downloads folder if it doesn't exist
                $downloadsFolder = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) -ChildPath "Downloads"
                if (-not (Test-Path -Path $downloadsFolder)) {
                    New-Item -Path $downloadsFolder -ItemType Directory -Force | Out-Null
                }
                
                # Download the file
                $downloadPath = Join-Path -Path $downloadsFolder -ChildPath "Win11DeploymentToolkit_v$latestVersion.zip"
                
                # Use Invoke-WebRequest to download the file with progress
                Write-Host "Downloading from: $downloadUrl" -ForegroundColor Gray
                Write-Host "Saving to: $downloadPath" -ForegroundColor Gray
                Write-Host "This may take a few minutes depending on your connection speed..." -ForegroundColor Yellow
                
                # Create a simple progress indicator
                $downloadStartTime = Get-Date
                
                try {
                    # Try to use Invoke-WebRequest with progress
                    $ProgressPreference = 'Continue'
                    Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath -TimeoutSec 300
                }
                catch {
                    Write-Host "Error with Invoke-WebRequest: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "Falling back to alternative download method..." -ForegroundColor Yellow
                    
                    # Fallback to .NET WebClient
                    $webClient = New-Object System.Net.WebClient
                    $webClient.DownloadFile($downloadUrl, $downloadPath)
                }
                
                $downloadEndTime = Get-Date
                $downloadDuration = $downloadEndTime - $downloadStartTime
                
                if (Test-Path -Path $downloadPath) {
                    Write-Host "`nDownload complete! (Time taken: $($downloadDuration.TotalSeconds.ToString("0.00")) seconds)" -ForegroundColor Green
                    Write-Host "File saved to: $downloadPath" -ForegroundColor Green
                    Write-Host "Please extract the downloaded file and replace your current toolkit files." -ForegroundColor Yellow
                    Write-Host "Don't forget to back up any custom configurations before updating." -ForegroundColor Yellow
                }
                else {
                    throw "Download failed: File not found at expected location."
                }
            }
            catch {
                Write-Host "`nError downloading update: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "You can download the update manually from:" -ForegroundColor Yellow
                Write-Host $downloadUrl -ForegroundColor Cyan
            }
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
    Write-Host "Error checking for updates: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check manually for updates at the toolkit's repository." -ForegroundColor Yellow
}
finally {
    Stop-Transcript
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

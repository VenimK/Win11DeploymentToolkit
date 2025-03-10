# Windows 11 Compatibility Check Script
# This script checks if your system meets Windows 11 requirements

# Ensure we're running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "This script needs to be run as Administrator. Please restart with admin privileges." -ForegroundColor Red
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# Start logging
$logFile = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) -ChildPath "$2"
Start-Transcript -Path $logFile -Force

try {
    Write-Host "Windows 11 Compatibility Check Started at $(Get-Date)" -ForegroundColor Green
    Write-Host "This tool will check if your system meets Windows 11 requirements" -ForegroundColor Yellow
    Write-Host "Results will be saved to: $logFile" -ForegroundColor Yellow
    Write-Host ""
    
    # System Information
    $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
    $computerBIOS = Get-WmiObject -Class Win32_BIOS
    $computerOS = Get-WmiObject -Class Win32_OperatingSystem
    
    Write-Host "SYSTEM INFORMATION" -ForegroundColor Cyan
    Write-Host "-------------------" -ForegroundColor Cyan
    Write-Host "Manufacturer: $($computerSystem.Manufacturer)" -ForegroundColor White
    Write-Host "Model: $($computerSystem.Model)" -ForegroundColor White
    Write-Host "Serial Number: $($computerBIOS.SerialNumber)" -ForegroundColor White
    Write-Host "Current OS: $($computerOS.Caption) $($computerOS.Version)" -ForegroundColor White
    Write-Host ""
    
    # Check TPM
    Write-Host "TPM CHECK" -ForegroundColor Cyan
    Write-Host "---------" -ForegroundColor Cyan
    $tpmEnabled = $false
    $tpmVersion = "Unknown"
    
    try {
        $tpm = Get-WmiObject -Class Win32_Tpm -Namespace root\CIMV2\Security\MicrosoftTpm
        if ($null -ne $tpm) {
            $tpmEnabled = $tpm.IsEnabled_InitialValue
            $tpmVersion = if ($tpm.SpecVersion -match "2\.0") { "2.0" } else { $tpm.SpecVersion }
            
            if ($tpmEnabled) {
                Write-Host "TPM Status: Enabled" -ForegroundColor Green
            } else {
                Write-Host "TPM Status: Disabled" -ForegroundColor Red
            }
            
            if ($tpmVersion -eq "2.0") {
                Write-Host "TPM Version: $tpmVersion" -ForegroundColor Green
            } else {
                Write-Host "TPM Version: $tpmVersion" -ForegroundColor Red
            }
        } else {
            Write-Host "TPM Status: Not detected" -ForegroundColor Red
        }
    } catch {
        Write-Host "TPM Check Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Unable to determine TPM status" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Check CPU
    Write-Host "CPU CHECK" -ForegroundColor Cyan
    Write-Host "---------" -ForegroundColor Cyan
    $cpuCompatible = $false
    $cpuGeneration = "Unknown"
    
    try {
        $processor = Get-WmiObject -Class Win32_Processor
        $cpuName = $processor.Name
        $cpuCores = $processor.NumberOfCores
        $cpuLogical = $processor.NumberOfLogicalProcessors
        $cpuSpeed = [math]::Round($processor.MaxClockSpeed / 1000, 2)
        
        Write-Host "CPU: $cpuName" -ForegroundColor White
        Write-Host "Cores: $cpuCores physical, $cpuLogical logical" -ForegroundColor White
        Write-Host "Speed: $cpuSpeed GHz" -ForegroundColor White
        
        # Check if CPU is in the Windows 11 compatible list (simplified check)
        $gen = 0
        if ($cpuName -match "Intel.*Core.*i[3579].*(\d+)") {
            $gen = [int]$Matches[1]
            $cpuCompatible = $gen -ge 8
        } elseif ($cpuName -match "AMD.*Ryzen.*(\d+)") {
            $gen = [int]$Matches[1]
            $cpuCompatible = $gen -ge 3
        }
        
        Write-Host "CPU Generation: $gen" -ForegroundColor Cyan
        
        if ($cpuCompatible) {
            Write-Host "CPU Compatible: Yes" -ForegroundColor Green
        } else {
            Write-Host "CPU Compatible: No" -ForegroundColor Red
        }
    } catch {
        Write-Host "CPU Check Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Check RAM
    Write-Host "RAM CHECK" -ForegroundColor Cyan
    Write-Host "---------" -ForegroundColor Cyan
    $ramGB = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 1)
    $ramCompatible = $ramGB -ge 4
    
    Write-Host "RAM: $ramGB GB" -ForegroundColor Cyan
    
    if ($ramCompatible) {
        Write-Host "RAM Compatible: Yes" -ForegroundColor Green
    } else {
        Write-Host "RAM Compatible: No" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Check Secure Boot
    Write-Host "SECURE BOOT CHECK" -ForegroundColor Cyan
    Write-Host "-----------------" -ForegroundColor Cyan
    
    try {
        $secureBootStatus = Confirm-SecureBootUEFI -ErrorAction Stop
        if ($secureBootStatus) {
            Write-Host "Secure Boot Enabled: Yes" -ForegroundColor Green
        } else {
            Write-Host "Secure Boot Enabled: No" -ForegroundColor Red
        }
    } catch [System.PlatformNotSupportedException] {
        Write-Host "Secure Boot: Not Supported (Legacy BIOS)" -ForegroundColor Red
        Write-Host "Windows 11 requires UEFI with Secure Boot capability" -ForegroundColor Red
    } catch {
        Write-Host "Secure Boot Check Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Check Storage
    Write-Host "STORAGE CHECK" -ForegroundColor Cyan
    Write-Host "-------------" -ForegroundColor Cyan
    
    $systemDrive = $env:SystemDrive
    $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$systemDrive'"
    $diskSizeGB = [math]::Round($disk.Size / 1GB, 1)
    $diskFreeGB = [math]::Round($disk.FreeSpace / 1GB, 1)
    $storageCompatible = $diskSizeGB -ge 64
    
    Write-Host "System Drive: $systemDrive" -ForegroundColor White
    Write-Host "Drive Size: $diskSizeGB GB" -ForegroundColor White
    Write-Host "Free Space: $diskFreeGB GB" -ForegroundColor White
    Write-Host "Minimum Required: 64 GB" -ForegroundColor White
    
    if ($storageCompatible) {
        Write-Host "Storage Compatible: Yes" -ForegroundColor Green
    } else {
        Write-Host "Storage Compatible: No" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Overall compatibility check
    $isCompatible = $tpmEnabled -and $cpuCompatible -and $ramCompatible -and $storageCompatible
    
    Write-Host "OVERALL COMPATIBILITY" -ForegroundColor Cyan
    Write-Host "---------------------" -ForegroundColor Cyan
    
    if ($isCompatible) {
        Write-Host "Your system MEETS the Windows 11 requirements." -ForegroundColor Green
    } else {
        Write-Host "Your system DOES NOT MEET all Windows 11 requirements." -ForegroundColor Red
        Write-Host "You can still install Windows 11 using the bypass flags:" -ForegroundColor Yellow
        Write-Host "/SkipTPMCheck /SkipCPUCheck /SkipRAMCheck /SkipSecureBootCheck" -ForegroundColor Yellow
        Write-Host "But Microsoft does not recommend or support this configuration." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Windows 11 Compatibility Check completed at $(Get-Date)" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Windows 11 Compatibility Check failed." -ForegroundColor Red
}
finally {
    Stop-Transcript
    Write-Host ""
    Write-Host "Results have been saved to: $logFile" -ForegroundColor Yellow
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Create Basic Answer File for Windows 11 Installation
# This script creates a simple autounattend.xml file for Windows 11

# Start logging
$logFile = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) -ChildPath "$2"
Start-Transcript -Path $logFile -Force

try {
    Write-Host "Windows 11 Answer File Creator Started at $(Get-Date)" -ForegroundColor Green
    Write-Host "This script will create a basic answer file for Windows 11 installation" -ForegroundColor Yellow
    Write-Host "The answer file will automate the installation process" -ForegroundColor Yellow
    Write-Host ""
    
    # Create output folder for answer files
    $answerFolder = (Join-Path -Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) -ChildPath "AnswerFiles")
    if (-not (Test-Path $answerFolder)) {
        New-Item -Path $answerFolder -ItemType Directory -Force | Out-Null
        Write-Host "Created folder for answer files: $answerFolder" -ForegroundColor Green
    } else {
        Write-Host "Using existing folder for answer files: $answerFolder" -ForegroundColor Green
    }
    
    # Get user input for answer file
    Write-Host "Please provide the following information for your answer file:" -ForegroundColor Cyan
    Write-Host ""
    
    $computerName = Read-Host "Computer Name (leave blank for auto-generated)"
    if ([string]::IsNullOrWhiteSpace($computerName)) {
        $computerName = "WIN11-PC"
    }
    
    $userName = Read-Host "User Name (leave blank for 'User')"
    if ([string]::IsNullOrWhiteSpace($userName)) {
        $userName = "User"
    }
    
    $orgName = Read-Host "Organization Name (leave blank for none)"
    
    $timeZone = Read-Host "Time Zone (leave blank for 'Central European Standard Time')"
    if ([string]::IsNullOrWhiteSpace($timeZone)) {
        $timeZone = "Central European Standard Time"
    }
    
    $locale = Read-Host "Locale (leave blank for 'nl-NL')"
    if ([string]::IsNullOrWhiteSpace($locale)) {
        $locale = "nl-NL"
    }
    
    $inputLocale = Read-Host "Input Locale (leave blank for 'nl-NL')"
    if ([string]::IsNullOrWhiteSpace($inputLocale)) {
        $inputLocale = "nl-NL"
    }
    
    # Create the answer file XML
    $answerFileContent = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SetupUILanguage>
                <UILanguage>$locale</UILanguage>
            </SetupUILanguage>
            <InputLocale>$inputLocale</InputLocale>
            <SystemLocale>$locale</SystemLocale>
            <UILanguage>$locale</UILanguage>
            <UserLocale>$locale</UserLocale>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <DiskConfiguration>
                <Disk wcm:action="add">
                    <CreatePartitions>
                        <CreatePartition wcm:action="add">
                            <Order>1</Order>
                            <Type>Primary</Type>
                            <Size>100</Size>
                        </CreatePartition>
                        <CreatePartition wcm:action="add">
                            <Order>2</Order>
                            <Type>EFI</Type>
                            <Size>260</Size>
                        </CreatePartition>
                        <CreatePartition wcm:action="add">
                            <Order>3</Order>
                            <Type>MSR</Type>
                            <Size>16</Size>
                        </CreatePartition>
                        <CreatePartition wcm:action="add">
                            <Order>4</Order>
                            <Type>Primary</Type>
                            <Extend>true</Extend>
                        </CreatePartition>
                    </CreatePartitions>
                    <ModifyPartitions>
                        <ModifyPartition wcm:action="add">
                            <Order>1</Order>
                            <PartitionID>1</PartitionID>
                            <Label>WINRE</Label>
                            <Format>NTFS</Format>
                            <TypeID>DE94BBA4-06D1-4D40-A16A-BFD50179D6AC</TypeID>
                        </ModifyPartition>
                        <ModifyPartition wcm:action="add">
                            <Order>2</Order>
                            <PartitionID>2</PartitionID>
                            <Label>System</Label>
                            <Format>FAT32</Format>
                        </ModifyPartition>
                        <ModifyPartition wcm:action="add">
                            <Order>3</Order>
                            <PartitionID>3</PartitionID>
                        </ModifyPartition>
                        <ModifyPartition wcm:action="add">
                            <Order>4</Order>
                            <PartitionID>4</PartitionID>
                            <Label>Windows</Label>
                            <Format>NTFS</Format>
                        </ModifyPartition>
                    </ModifyPartitions>
                    <DiskID>0</DiskID>
                    <WillWipeDisk>true</WillWipeDisk>
                </Disk>
            </DiskConfiguration>
            <ImageInstall>
                <OSImage>
                    <InstallTo>
                        <DiskID>0</DiskID>
                        <PartitionID>4</PartitionID>
                    </InstallTo>
                    <InstallToAvailablePartition>false</InstallToAvailablePartition>
                </OSImage>
            </ImageInstall>
            <UserData>
                <AcceptEula>true</AcceptEula>
                <Organization>$orgName</Organization>
            </UserData>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <ComputerName>$computerName</ComputerName>
            <TimeZone>$timeZone</TimeZone>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <ProtectYourPC>3</ProtectYourPC>
            </OOBE>
            <UserAccounts>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Name>$userName</Name>
                        <Group>Administrators</Group>
                        <DisplayName>$userName</DisplayName>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
            <RegisteredOrganization>$orgName</RegisteredOrganization>
            <RegisteredOwner>$userName</RegisteredOwner>
            <DisableAutoDaylightTimeSet>false</DisableAutoDaylightTimeSet>
            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <CommandLine>cmd.exe /c powercfg /h off</CommandLine>
                    <Description>Disable Hibernation</Description>
                    <RequiresUserInput>false</RequiresUserInput>
                </SynchronousCommand>
            </FirstLogonCommands>
        </component>
    </settings>
</unattend>
"@
    
    # Save the answer file
    $answerFilePath = Join-Path -Path $answerFolder -ChildPath "autounattend.xml"
    $answerFileContent | Out-File -FilePath $answerFilePath -Encoding UTF8 -Force
    
    Write-Host ""
    Write-Host "Answer file created successfully at: $answerFilePath" -ForegroundColor Green
    Write-Host ""
    Write-Host "IMPORTANT NOTE:" -ForegroundColor Red
    Write-Host "This answer file is configured for a CLEAN INSTALLATION and will format the drive." -ForegroundColor Red
    Write-Host "To use it for an UPGRADE installation, you need to modify the DiskConfiguration section." -ForegroundColor Red
    Write-Host ""
    Write-Host "Would you like to create an UPGRADE-ONLY version that preserves all data? (Y/N)" -ForegroundColor Yellow
    $createUpgradeVersion = Read-Host
    
    if ($createUpgradeVersion -eq "Y" -or $createUpgradeVersion -eq "y") {
        # Create upgrade-only version
        $upgradeAnswerFileContent = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SetupUILanguage>
                <UILanguage>$locale</UILanguage>
            </SetupUILanguage>
            <InputLocale>$inputLocale</InputLocale>
            <SystemLocale>$locale</SystemLocale>
            <UILanguage>$locale</UILanguage>
            <UserLocale>$locale</UserLocale>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <UserData>
                <AcceptEula>true</AcceptEula>
                <Organization>$orgName</Organization>
            </UserData>
            <UpgradeData>
                <Upgrade>true</Upgrade>
                <WillShowUI>OnError</WillShowUI>
            </UpgradeData>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <ProtectYourPC>3</ProtectYourPC>
            </OOBE>
            <RegisteredOrganization>$orgName</RegisteredOrganization>
            <RegisteredOwner>$userName</RegisteredOwner>
            <DisableAutoDaylightTimeSet>false</DisableAutoDaylightTimeSet>
        </component>
    </settings>
</unattend>
"@
        
        $upgradeAnswerFilePath = Join-Path -Path $answerFolder -ChildPath "autounattend_upgrade.xml"
        $upgradeAnswerFileContent | Out-File -FilePath $upgradeAnswerFilePath -Encoding UTF8 -Force
        
        Write-Host ""
        Write-Host "Upgrade-only answer file created successfully at: $upgradeAnswerFilePath" -ForegroundColor Green
        Write-Host "This version will preserve all your files, apps, and settings." -ForegroundColor Green
    }
    
    # Create a batch file to copy the answer file to the root of a USB drive
    $batchContent = @"
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
    copy /y "$($answerFilePath -replace "\\", "\\")" %drive%:\autounattend.xml
    echo.
    echo Standard answer file copied to %drive%:\autounattend.xml
) else if "%choice%"=="2" (
    copy /y "$($upgradeAnswerFilePath -replace "\\", "\\")" %drive%:\autounattend.xml
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
"@
    
    $batchFilePath = Join-Path -Path $answerFolder -ChildPath "CopyAnswerFileToUSB.bat"
    $batchContent | Out-File -FilePath $batchFilePath -Encoding ASCII -Force
    
    Write-Host ""
    Write-Host "Created batch file to copy answer file to USB: $batchFilePath" -ForegroundColor Green
    Write-Host ""
    Write-Host "Windows 11 Answer File Creation completed at $(Get-Date)" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Answer file creation failed. See log for details." -ForegroundColor Red
}
finally {
    Stop-Transcript
    Write-Host ""
    Write-Host "Results have been saved to: $logFile" -ForegroundColor Yellow
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}


# Extract Windows 11 Updates from ISO
# This script mounts a Windows 11 ISO and extracts any updates (MSU files)

# Start logging
$logFile = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) -ChildPath "$2"
Start-Transcript -Path $logFile -Force

try {
    Write-Host "Windows 11 Update Extraction Started at $(Get-Date)" -ForegroundColor Green
    Write-Host "This script will extract updates from a Windows 11 ISO" -ForegroundColor Yellow
    
    # Create output folder for updates
    $extractFolder = (Join-Path -Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) -ChildPath "ExtractedUpdates")
    if (-not (Test-Path $extractFolder)) {
        New-Item -Path $extractFolder -ItemType Directory -Force | Out-Null
        Write-Host "Created folder for extracted updates: $extractFolder" -ForegroundColor Green
    } else {
        Write-Host "Using existing folder for extracted updates: $extractFolder" -ForegroundColor Green
    }
    
    # Find the ISO file
    $isoFolder = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "Windows11"
    
    if (-not (Test-Path $isoFolder)) {
        throw "Windows11 folder not found at: $isoFolder"
    }
    
    $isoFile = Get-ChildItem -Path $isoFolder -Filter *.iso | Select-Object -First 1
    
    if ($null -eq $isoFile) {
        throw "No ISO file found in the Windows11 folder."
    }
    
    Write-Host "Found ISO file: $($isoFile.FullName)" -ForegroundColor Green
    Write-Host "ISO File Size: $([math]::Round($isoFile.Length / 1GB, 2)) GB" -ForegroundColor Green
    Write-Host "Mounting ISO file..." -ForegroundColor Yellow
    
    # Mount the ISO file
    $mountResult = Mount-DiskImage -ImagePath $isoFile.FullName -PassThru
    $driveLetter = ($mountResult | Get-Volume).DriveLetter
    
    if ($null -eq $driveLetter) {
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
    if ($null -ne $isoFile) {
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
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}



# Install Extracted Windows Updates
# This script installs Windows updates (.msu and .cab files) from the ExtractedUpdates folder

# Start logging
$scriptRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$logFile = Join-Path -Path $scriptRoot -ChildPath "Update_Installation_Log.txt"
Start-Transcript -Path $logFile -Force

try {
    Write-Host "Windows 11 Update Installation Started at $(Get-Date)" -ForegroundColor Green
    Write-Host "This script will install ONLY the updates previously extracted from a Windows 11 ISO" -ForegroundColor Yellow
    Write-Host "It will NOT install a full Windows system" -ForegroundColor Yellow
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
}


# Windows 11 Upgrade Helper Script
# This script mounts the Windows 11 ISO and runs setup in upgrade-only mode

# Start logging
$logFile = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) -ChildPath "$2"
Start-Transcript -Path $logFile -Force

try {
    Write-Host "Windows 11 Upgrade Script Started at $(Get-Date)" -ForegroundColor Green
    Write-Host "This will perform an UPGRADE ONLY - NO drives will be formatted" -ForegroundColor Yellow
    Write-Host "All your files, apps, and settings will be preserved" -ForegroundColor Yellow
    
    # Check for TPM 2.0 support
    Write-Host "Checking system compatibility for Windows 11..." -ForegroundColor Cyan
    
    # Check TPM
    $tpmEnabled = $false
    try {
        $tpm = Get-WmiObject -Class Win32_Tpm -Namespace root\CIMV2\Security\MicrosoftTpm
        if ($null -ne $tpm) {
            $tpmEnabled = $tpm.IsEnabled_InitialValue
            $tpmVersion = if ($tpm.SpecVersion -match "2\.0") { "2.0" } else { $tpm.SpecVersion }
            
            if ($tpmEnabled) {
                Write-Host "TPM Status: Enabled" -ForegroundColor Green
            } else {
                Write-Host "TPM Status: Disabled" -ForegroundColor Red
            }
            
            if ($tpmVersion -eq "2.0") {
                Write-Host "TPM Version: $tpmVersion" -ForegroundColor Green
            } else {
                Write-Host "TPM Version: $tpmVersion" -ForegroundColor Red
            }
        } else {
            Write-Host "TPM Status: Not detected" -ForegroundColor Red
        }
    } catch {
        Write-Host "TPM Status: Error checking TPM - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Check CPU
    $cpuCompatible = $false
    try {
        $processor = Get-WmiObject -Class Win32_Processor
        $cpuName = $processor.Name
        Write-Host "CPU: $cpuName" -ForegroundColor Cyan
        
        # Check if CPU is in the Windows 11 compatible list (simplified check)
        $gen = 0
        if ($cpuName -match "Intel.*Core.*i[3579].*(\d+)") {
            $gen = [int]$Matches[1]
            $cpuCompatible = $gen -ge 8
        } elseif ($cpuName -match "AMD.*Ryzen.*(\d+)") {
            $gen = [int]$Matches[1]
            $cpuCompatible = $gen -ge 3
        }
        
        Write-Host "CPU Generation: $gen" -ForegroundColor Cyan
        
        if ($cpuCompatible) {
            Write-Host "CPU Compatible: Yes" -ForegroundColor Green
        } else {
            Write-Host "CPU Compatible: No" -ForegroundColor Red
        }
    } catch {
        Write-Host "CPU Status: Error checking CPU - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Check RAM
    $ramGB = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
    $ramCompatible = $ramGB -ge 4
    
    Write-Host "RAM: $ramGB GB" -ForegroundColor Cyan
    
    if ($ramCompatible) {
        Write-Host "RAM Compatible: Yes" -ForegroundColor Green
    } else {
        Write-Host "RAM Compatible: No" -ForegroundColor Red
    }
    
    # Overall compatibility check
    $isCompatible = $tpmEnabled -and $cpuCompatible -and $ramCompatible
    
    if (-not $isCompatible) {
        Write-Host "
This system does not meet the minimum requirements for Windows 11." -ForegroundColor Red
        Write-Host "Windows 11 requires TPM 2.0, a compatible CPU, and at least 4GB of RAM." -ForegroundColor Red
        
        $override = Read-Host "Do you want to proceed anyway? (y/n)"
        if ($override -ne "y") {
            throw "Installation cancelled due to system incompatibility."
        }
        
        Write-Host "Proceeding with installation despite compatibility issues..." -ForegroundColor Yellow
    } else {
        Write-Host "
System meets Windows 11 requirements." -ForegroundColor Green
    }
    
    # Find the ISO file
    $isoFolder = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "Windows11"
    
    if (-not (Test-Path $isoFolder)) {
        throw "Windows11 folder not found at: $isoFolder"
    }
    
    $isoFile = Get-ChildItem -Path $isoFolder -Filter *.iso | Select-Object -First 1
    
    if ($null -eq $isoFile) {
        throw "No ISO file found in the Windows11 folder."
    }
    
    Write-Host "Found ISO file: $($isoFile.FullName)"
    Write-Host "ISO File Size: $([math]::Round($isoFile.Length / 1GB, 2)) GB"
    Write-Host "Mounting ISO file..."
    
    # Mount the ISO file
    $mountResult = Mount-DiskImage -ImagePath $isoFile.FullName -PassThru
    $driveLetter = ($mountResult | Get-Volume).DriveLetter
    
    if ($null -eq $driveLetter) {
        throw "Failed to mount the ISO file. No drive letter assigned."
    }
    
    Write-Host "ISO mounted successfully at drive ${driveLetter}:"
    
    # Check if setup.exe exists
    $setupPath = "${driveLetter}:\\setup.exe"
    if (-not (Test-Path $setupPath)) {
        throw "setup.exe not found at $setupPath"
    }
    
    Write-Host "Found setup.exe at: $setupPath"
    Write-Host "Launching Windows 11 upgrade with updates disabled..."
    
    # Run setup with upgrade-only parameters and bypass TPM check if needed
    $setupArgs = "/auto upgrade /DynamicUpdate disable /quiet /migratedrivers all /showoobe none"
    
    # Add bypass TPM check if system doesn't meet requirements
    if (-not $isCompatible) {
        $setupArgs += " /SkipTPMCheck /SkipCPUCheck /SkipRAMCheck /SkipSecureBootCheck"
        Write-Host "Adding compatibility bypass flags to setup" -ForegroundColor Yellow
    }
    
    $setupProcess = Start-Process -FilePath $setupPath -ArgumentList $setupArgs -Wait -PassThru
    
    Write-Host "Setup process exited with code: $($setupProcess.ExitCode)"
    
    # After setup completes or is cancelled, unmount the ISO
    Write-Host "Setup completed or cancelled. Unmounting ISO..."
    Dismount-DiskImage -ImagePath $isoFile.FullName
    
    Write-Host "ISO unmounted successfully."
    Write-Host "Windows 11 Upgrade Script completed at $(Get-Date)" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    
    # Try to unmount ISO if it was mounted
    if ($null -ne $isoFile) {
        try {
            Write-Host "Attempting to unmount ISO due to error..."
            Dismount-DiskImage -ImagePath $isoFile.FullName -ErrorAction SilentlyContinue
            Write-Host "ISO unmounted."
        }
        catch {
            Write-Host "Failed to unmount ISO: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host "Windows 11 Upgrade Script failed. See log for details."
}
finally {
    Stop-Transcript
}

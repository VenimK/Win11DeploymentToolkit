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
$logFile = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) -ChildPath "Windows11_Compatibility_Check.log"
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
        $tpm = Get-WmiObject -Class Win32_Tpm -Namespace root\CIMV2\Security\MicrosoftTpm -ErrorAction Stop
        if ($null -ne $tpm) {
            $tpmEnabled = $tpm.IsEnabled_InitialValue
            if ($tpm.SpecVersion -match "2\.0") {
                $tpmVersion = "2.0"
            } else {
                $tpmVersion = $tpm.SpecVersion
            }
            
            Write-Host "TPM Present: Yes" -ForegroundColor Green
            
            if ($tpmEnabled) {
                Write-Host "TPM Enabled: Yes" -ForegroundColor Green
            } else {
                Write-Host "TPM Enabled: No" -ForegroundColor Red
            }
            
            if ($tpmVersion -eq "2.0") {
                Write-Host "TPM Version: $tpmVersion" -ForegroundColor Green
            } else {
                Write-Host "TPM Version: $tpmVersion" -ForegroundColor Red
            }
            
            Write-Host "TPM Manufacturer: $($tpm.ManufacturerName)" -ForegroundColor White
        } else {
            Write-Host "TPM Present: No" -ForegroundColor Red
            Write-Host "TPM is required for Windows 11" -ForegroundColor Red
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
        if ($cpuName -match "Intel.*Core.*i[3579].*(\d+)") {
            $cpuGeneration = $Matches[1]
            $cpuCompatible = [int]$cpuGeneration -ge 8
            Write-Host "CPU Type: Intel Core i-Series" -ForegroundColor White
            Write-Host "Generation: $cpuGeneration" -ForegroundColor White
        } 
        elseif ($cpuName -match "AMD.*Ryzen.*(\d+)") {
            $cpuGeneration = $Matches[1]
            $cpuCompatible = [int]$cpuGeneration -ge 3
            Write-Host "CPU Type: AMD Ryzen" -ForegroundColor White
            Write-Host "Generation: $cpuGeneration" -ForegroundColor White
        }
        elseif ($cpuName -match "Intel.*Xeon") {
            Write-Host "CPU Type: Intel Xeon" -ForegroundColor White
            Write-Host "Check the Windows 11 compatibility list for this specific Xeon model" -ForegroundColor Yellow
        }
        else {
            Write-Host "CPU Type: Other" -ForegroundColor White
            Write-Host "Check the Windows 11 compatibility list for this specific CPU model" -ForegroundColor Yellow
        }
        
        if ($cpuCompatible) {
            Write-Host "CPU Compatible: Yes" -ForegroundColor Green
        } else {
            Write-Host "CPU Compatible: No" -ForegroundColor Red
        }
    } 
    catch {
        Write-Host "CPU Check Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Check RAM
    Write-Host "RAM CHECK" -ForegroundColor Cyan
    Write-Host "---------" -ForegroundColor Cyan
    $ramGB = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 1)
    $ramCompatible = $ramGB -ge 4
    
    Write-Host "Total RAM: $ramGB GB" -ForegroundColor White
    Write-Host "Minimum Required: 4 GB" -ForegroundColor White
    
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
    } 
    catch [System.PlatformNotSupportedException] {
        Write-Host "Secure Boot: Not Supported (Legacy BIOS)" -ForegroundColor Red
        Write-Host "Windows 11 requires UEFI with Secure Boot capability" -ForegroundColor Red
    }
    catch {
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
    $isCompatible = $tpmEnabled -and ($tpmVersion -eq "2.0") -and $cpuCompatible -and $ramCompatible -and $storageCompatible
    
    Write-Host "OVERALL COMPATIBILITY" -ForegroundColor Cyan
    Write-Host "---------------------" -ForegroundColor Cyan
    
    if ($isCompatible) {
        Write-Host "Your system MEETS the Windows 11 requirements." -ForegroundColor Green
    } 
    else {
        Write-Host "Your system DOES NOT MEET all Windows 11 requirements." -ForegroundColor Red
        Write-Host "Review the details above to see which requirements are not met." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Windows 11 Compatibility Check completed at $(Get-Date)" -ForegroundColor Green
    Write-Host "Results have been saved to: $logFile" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Windows 11 Compatibility Check failed." -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
finally {
    Stop-Transcript
}

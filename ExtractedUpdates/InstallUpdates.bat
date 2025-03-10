@echo off
echo Installing Windows 11 Updates
echo ===========================
echo.
echo Installing Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35~amd64~nl-NL~.cab...
dism.exe /Online /Add-Package /PackagePath:"%~dp0Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35~amd64~nl-NL~.cab" /NoRestart
echo.
echo Installing Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35~amd64~~.cab...
dism.exe /Online /Add-Package /PackagePath:"%~dp0Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35~amd64~~.cab" /NoRestart
echo.
echo Installing Microsoft-Windows-NetFx3-OnDemand-Package~31bf3856ad364e35~amd64~~.cab...
dism.exe /Online /Add-Package /PackagePath:"%~dp0Microsoft-Windows-NetFx3-OnDemand-Package~31bf3856ad364e35~amd64~~.cab" /NoRestart
echo.
echo Installing Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35~amd64~nl-NL~.cab...
dism.exe /Online /Add-Package /PackagePath:"%~dp0Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35~amd64~nl-NL~.cab" /NoRestart
echo.
echo Installing Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35~amd64~~.cab...
dism.exe /Online /Add-Package /PackagePath:"%~dp0Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35~amd64~~.cab" /NoRestart
echo.
echo Installing Microsoft-Windows-NetFx3-OnDemand-Package~31bf3856ad364e35~amd64~~.cab...
dism.exe /Online /Add-Package /PackagePath:"%~dp0Microsoft-Windows-NetFx3-OnDemand-Package~31bf3856ad364e35~amd64~~.cab" /NoRestart
echo.
echo Installing DesktopTargetCompDB_Conditions.xml.cab...
dism.exe /Online /Add-Package /PackagePath:"%~dp0DesktopTargetCompDB_Conditions.xml.cab" /NoRestart
echo.
echo Installing DesktopTargetCompDB_FOD_Neutral.xml.cab...
dism.exe /Online /Add-Package /PackagePath:"%~dp0DesktopTargetCompDB_FOD_Neutral.xml.cab" /NoRestart
echo.
echo Installing DesktopTargetCompDB_Neutral.xml.cab...
dism.exe /Online /Add-Package /PackagePath:"%~dp0DesktopTargetCompDB_Neutral.xml.cab" /NoRestart
echo.
echo Installing Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35~amd64~nl-NL~.cab...
dism.exe /Online /Add-Package /PackagePath:"%~dp0Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35~amd64~nl-NL~.cab" /NoRestart
echo.
echo Installing Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35~amd64~~.cab...
dism.exe /Online /Add-Package /PackagePath:"%~dp0Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35~amd64~~.cab" /NoRestart
echo.
echo Installing Microsoft-Windows-NetFx3-OnDemand-Package~31bf3856ad364e35~amd64~~.cab...
dism.exe /Online /Add-Package /PackagePath:"%~dp0Microsoft-Windows-NetFx3-OnDemand-Package~31bf3856ad364e35~amd64~~.cab" /NoRestart
echo.
echo Installing DesktopTargetCompDB_Conditions.xml.cab...
dism.exe /Online /Add-Package /PackagePath:"%~dp0DesktopTargetCompDB_Conditions.xml.cab" /NoRestart
echo.
echo Installing DesktopTargetCompDB_FOD_Neutral.xml.cab...
dism.exe /Online /Add-Package /PackagePath:"%~dp0DesktopTargetCompDB_FOD_Neutral.xml.cab" /NoRestart
echo.
echo Installing DesktopTargetCompDB_Neutral.xml.cab...
dism.exe /Online /Add-Package /PackagePath:"%~dp0DesktopTargetCompDB_Neutral.xml.cab" /NoRestart
echo.
echo.
echo All updates have been installed.
echo A system restart may be required to complete the installation.
echo.
pause

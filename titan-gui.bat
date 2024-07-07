@echo off
:: Check for Admin rights
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto :begin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:begin
cls
title Titan L2 Installation

:: Step 1: Uninstall and clean old application directories
:uninstall_clean
echo [1;33mPerforming uninstall and clean process...[0m

rem Stop any running Titan processes
taskkill /im titan* /f >nul 2>&1

rem Delete directories
rmdir /s /q "%USERPROFILE%\AppData\Roaming\com.example\titan_network" 2>nul
rmdir /s /q "%USERPROFILE%\.titanedge" 2>nul
rmdir /s /q "C:\Program Files (x86)\titan_network" 2>nul

echo [1;33mUninstall and clean completed.[0m
pause

:: Step 2: Download master file and extract to c:\titan-master
:download_extract_files
echo [1;33mRunning download and extraction process for supporting files...[0m

rem Downloading titan-master.zip with progress indication
echo Downloading titan-master.zip...
powershell -command "& {Invoke-WebRequest 'https://ryzen.sgp1.cdn.digitaloceanspaces.com/titan-edge.zip' -OutFile '%USERPROFILE%\Desktop\titan-master.zip' -UseBasicParsing}"
if %errorlevel% neq 0 (
    echo [1;31mFailed to download titan-master.zip. Exiting installation.[0m
    pause
    exit /b
) else (
    echo [1;32mDownload successful. File saved to: %USERPROFILE%\Desktop\titan-master.zip[0m
)

rem Extracting files to c:\titan-master
echo Extracting files to c:\titan-master...
powershell -command "Expand-Archive -Path '%USERPROFILE%\Desktop\titan-master.zip' -DestinationPath 'c:\titan-master' -Force"
if %errorlevel% neq 0 (
    echo [1;31mFailed to extract files. Exiting installation.[0m
    pause
    exit /b
) else (
    echo [1;32mExtraction successful. Files extracted to: c:\titan-master[0m
    del "%USERPROFILE%\Desktop\titan-master.zip" 2>nul
)

echo [1;33mSupporting files installation completed successfully.[0m
pause

:: Step 3: Install certificates and vcredist
:install_certificates
echo [1;33mInstalling certificates and vcredist...[0m

rem Download and install the root certificate
certutil -addstore "Root" "c:\titan-master\isrgrootx1.der"
if %errorlevel% neq 0 (
    echo [1;31mFailed to install the root certificate.[0m
    pause
    exit /b
) else (
    echo [1;32mRoot certificate installed successfully.[0m
)

rem Install VC_redist
start /wait "" "c:\titan-master\VC_redist.x64.exe" /install /quiet /norestart
if %errorlevel% neq 0 (
    echo [1;31mFailed to install VC_redist.[0m
    pause
    exit /b
) else (
    echo [1;32mVC_redist installed successfully.[0m
)

pause

:: Step 4: Install Titan Windows application
:install_titan_exe
echo [1;33mInstalling Titan Windows application...[0m
start /wait "" "c:\titan-master\titan_network_windows_v0.0.10.exe" /install /quiet /norestart
if %errorlevel% neq 0 (
    echo [1;31mFailed to install Titan Windows application.[0m
    pause
    exit /b
) else (
    echo [1;32mInstallation of Titan Windows application completed.[0m
)

pause
echo [1;33mInstallation process completed successfully. Exiting...[0m
exit /b

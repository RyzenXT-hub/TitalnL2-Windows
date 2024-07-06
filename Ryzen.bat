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
title Titan L2 Installation Menu

:menu
cls
echo.
echo [1;33mWelcome to Titan L2 installation![0m
echo -----------------------------------
echo.
echo [1;33mSelect installation option:[0m
echo.
echo [1;33m  1. Uninstall and clean old application directories (Required)[0m
echo [1;33m  2. Download master file and extract to c:\titan-master (Required)[0m
echo [1;33m  3. Install certificates and vcredist (Required)[0m
echo [1;33m  4. Install Titan Windows application (exe) and run as administrator[0m
echo [1;33m  5. Install Titan CLI dan start program[0m
echo [1;33m  6. Bind identity code for CLI[0m
echo [1;33m  7. Configure storage settings for CLI[0m
echo [1;33m  8. Check node status for CLI[0m
echo [1;33m  9. Create CLI startup entry[0m
echo [1;33m 10. Exit[0m
echo.
echo [1;33mNote: You can only install one program between EXE or CLI, both cannot run simultaneously.[0m
echo -----------------------------------
echo                 © 2024 Ryzen                 
echo -----------------------------------
echo.
set /p choice="Enter choice (1-10): "

if "%choice%"=="1" goto uninstall_clean
if "%choice%"=="2" goto download_extract_files
if "%choice%"=="3" goto install_certificates
if "%choice%"=="4" goto install_titan_exe
if "%choice%"=="5" goto install_titan_cli
if "%choice%"=="6" goto bind_identity_cli
if "%choice%"=="7" goto configure_storage
if "%choice%"=="8" goto check_node_status
if "%choice%"=="9" goto create_cli_startup
if "%choice%"=="10" exit /b

rem Handle invalid choice
echo Invalid choice. Please enter a number from 1 to 10.
pause
goto menu

:uninstall_clean
echo Performing uninstall and clean process...

rem Stop any running Titan processes
taskkill /im titan* /f >nul 2>&1

rem Delete directories
rmdir /s /q "%USERPROFILE%\AppData\Roaming\com.example\titan_network"
rmdir /s /q "%USERPROFILE%\.titanedge"

echo Uninstall and clean completed.
pause
goto menu

:download_extract_files
echo Running download and extraction process for supporting files...

rem Downloading titan-master.zip with progress indication
echo Downloading titan-master.zip...
powershell -command "& {Invoke-WebRequest 'https://ryen.nyc3.cdn.digitaloceanspaces.com/titan-edge.zip' -OutFile '%USERPROFILE%\Desktop\titan-master.zip' -UseBasicParsing}"
if %errorlevel% neq 0 (
    echo Failed to download titan-master.zip. Exiting installation.
    pause
    goto menu
) else (
    echo Download successful. File saved to: %USERPROFILE%\Desktop\titan-master.zip
)

rem Extracting files to c:\titan-master
echo Extracting files to c:\titan-master...
powershell -command "Expand-Archive -Path '%USERPROFILE%\Desktop\titan-master.zip' -DestinationPath 'c:\titan-master' -Force"
if %errorlevel% neq 0 (
    echo Failed to extract files. Exiting installation.
    pause
    goto menu
) else (
    echo Extraction successful. Files extracted to: c:\titan-master
    del "%USERPROFILE%\Desktop\titan-master.zip" 2>nul
)

echo Supporting files installation completed successfully.
pause
goto menu

:install_certificates
echo Installing certificates and vcredist...

rem Download and install the root certificate
certutil -addstore "Root" "c:\titan-master\isrgrootx1.der"
if %errorlevel% neq 0 (
    echo Failed to install the root certificate.
    pause
    goto menu
) else (
    echo Root certificate installed successfully.
)

rem Install VC_redist
start /wait "" "c:\titan-master\VC_redist.x64.exe" /install /quiet /norestart
if %errorlevel% neq 0 (
    echo Failed to install VC_redist.
    pause
    goto menu
) else (
    echo VC_redist installed successfully.
)

pause
goto menu

:install_titan_exe
echo Installing Titan Windows application...
start /wait "" "c:\titan-master\titan_network_windows_v0.0.10.exe" /install /quiet /norestart
if %errorlevel% neq 0 (
    echo Failed to install Titan Windows application.
    pause
    goto menu
) else (
    echo Installation of Titan Windows application completed.
)

pause
goto menu

:install_titan_cli
echo Installing Titan CLI dan start program...
copy "c:\titan-master\titan-edge.exe" "%SystemRoot%\System32\titan-edge.exe"
copy "c:\titan-master\goworkerd.dll" "%SystemRoot%\System32\goworkerd.dll"
sc create TitanService binPath= "%SystemRoot%\System32\titan-edge.exe daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0" start= auto
sc start TitanService
if %errorlevel% neq 0 (
    echo Failed to install Titan CLI dan start program.
    pause
    goto menu
) else (
    echo Titan CLI installation dan start program completed.
)

pause
goto menu

:bind_identity_cli
echo Binding identity code for CLI...
set /p hash="Enter your identity hash: "
titan-edge bind --hash=!hash! https://api-test1.container1.titannet.io/api/v2/device/binding
if !errorlevel! neq 0 (
    echo Binding identity code failed.
) else (
    echo Binding identity code successful.
)
pause
goto menu

:configure_storage
echo Configuring storage settings for CLI...
:storage_input
set /p storage_size="Enter storage size (GB, max 500): "
rem Validate input as numeric
echo !storage_size!| findstr /r "^[0-9][0-9]*$" >nul && (
    if !storage_size! LEQ 500 (
        titan-edge config set --storage-size=!storage_size!GB
        if %errorlevel% neq 0 (
            echo Failed to configure storage size.
            pause
            goto storage_input
        ) else (
            echo Storage size configured to !storage_size! GB.
            rem Restart Titan CLI service
            net stop TitanService
            net start TitanService
            echo Titan CLI service restarted.
        )
    ) else (
        echo Maximum storage size exceeded. Please enter a number up to 500 GB.
        goto storage_input
    )
) || (
    echo Invalid input. Please enter a valid numeric value.
    goto storage_input
)
pause
goto menu

:check_node_status
echo Checking node status for CLI...
echo.
echo [1;36mNode status:[0m
titan-edge state
pause
goto menu

:create_cli_startup
echo Creating CLI startup entry...

set startup_folder="%appdata%\Microsoft\Windows\Start Menu\Programs\Startup"
set startup_script="%startup_folder%\start_titan_edge.bat"

echo @echo off > %startup_script%
echo titan-edge daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0 >> %startup_script%

if exist %startup_script% (
    echo CLI startup entry created successfully.
) else (
    echo Failed to create CLI startup entry.
)

pause
goto menu

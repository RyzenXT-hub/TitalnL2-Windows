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
title Titan CLI Installation

:clean_old_data
echo [1;33mCleaning old data...[0m

rem Delete old directories
rmdir /s /q "%USERPROFILE%\AppData\Roaming\com.example\titan_network"
rmdir /s /q "%USERPROFILE%\.titanedge"

rem Delete old startup script if exists
set "startup_folder=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "startup_script=%startup_folder%\start_titan_edge.bat"
if exist "%startup_script%" del "%startup_script%"

echo [1;33mOld data cleaned successfully.[0m
pause

:download_extract_cli
echo [1;33mDownloading and extracting CLI...[0m

rem Downloading titan-cli.zip with progress indication
set download_url=https://ryzen.sgp1.cdn.digitaloceanspaces.com/titan-cli.zip
set download_dest=%USERPROFILE%\Desktop\titan-cli.zip
set extract_dest=c:\titan-cli

echo Downloading titan-cli.zip...
powershell -command "& {Invoke-WebRequest '%download_url%' -OutFile '%download_dest%' -UseBasicParsing}"
if %errorlevel% neq 0 (
    echo Failed to download titan-cli.zip. Exiting installation.
    pause
    exit /b
) else (
    echo Download successful. File saved to: %download_dest%
)

rem Extracting files to c:\titan-cli
echo Extracting files to %extract_dest%...
powershell -command "Expand-Archive -Path '%download_dest%' -DestinationPath '%extract_dest%' -Force"
if %errorlevel% neq 0 (
    echo Failed to extract files. Exiting installation.
    pause
    exit /b
) else (
    echo Extraction successful. Files extracted to: %extract_dest%
    del "%download_dest%" 2>nul
)

echo [1;33mCLI Download and extraction completed successfully.[0m
pause

:install_files
echo [1;33mInstalling required files...[0m

rem Install the root certificate
certutil -addstore "Root" "%extract_dest%\isrgrootx1.der"
if %errorlevel% neq 0 (
    echo Failed to install the root certificate.
    pause
    exit /b
) else (
    echo Root certificate installed successfully.
)

rem Install VC_redist
start /wait "" "%extract_dest%\VC_redist.x64.exe" /install /quiet /norestart
if %errorlevel% neq 0 (
    echo Failed to install VC_redist.
    pause
    exit /b
) else (
    echo VC_redist installed successfully.
)

rem Copy titan-edge.exe and goworkerd.dll to system32
copy "%extract_dest%\titan-edge.exe" "%SystemRoot%\System32\titan-edge.exe"
copy "%extract_dest%\goworkerd.dll" "%SystemRoot%\System32\goworkerd.dll"

echo [1;33mRequired files installed successfully.[0m
pause

:launch_cli
echo [1;33mLaunching the CLI...[0m
start cmd /k titan-edge daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0
echo [1;33mCLI launched.[0m
pause

:bind_identity
echo [1;33mBinding Identity Code...[0m
set /p hash="Enter your identity hash (example: 4BC9E8C1-C79F-415A-AC59-3AF8E91BBFCA): "
titan-edge bind --hash="%hash%" https://api-test1.container1.titannet.io/api/v2/device/binding
if %errorlevel% neq 0 (
    echo Binding identity code failed. Please check your identity hash and try again.
) else (
    echo [1;33mBinding identity code successful.[0m
)
pause

:configure_storage
echo [1;33mConfiguring Storage...[0m
:storage_input
set /p storage_size="Enter storage size (GB, max 500): "
rem Validate input as numeric
echo %storage_size%| findstr /r "^[0-9][0-9]*$" >nul && (
    if %storage_size% LEQ 500 (
        titan-edge config set --storage-size=%storage_size%GB
        if %errorlevel% neq 0 (
            echo Failed to configure storage size.
            pause
            goto storage_input
        ) else (
            echo [1;33mStorage size configured to %storage_size% GB.[0m
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

:create_startup
echo [1;33mCreating Startup Script...[0m

rem Create startup directory if it doesn't exist
set "startup_folder=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
if not exist "%startup_folder%" mkdir "%startup_folder%"

set startup_script="%startup_folder%\start_titan_edge.bat"

echo @echo off > %startup_script%
echo titan-edge daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0 >> %startup_script%

if exist %startup_script% (
    echo [1;33mCLI startup entry created successfully.[0m
) else (
    echo Failed to create CLI startup entry.
)

pause

:show_node_status
echo [1;33mChecking node status for CLI...[0m
echo.
titan-edge state
pause
echo [1;33mInstallation and setup completed successfully.[0m
exit /b

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

echo [1;33mOld data cleaned successfully.[0m
pause

:download_extract_cli
echo [1;33mDownloading and extracting CLI...[0m

rem Downloading titan-l2edge package with progress indication
set download_url=https://github.com/Titannet-dao/titan-node/releases/download/v0.1.19/titan-l2edge_v0.1.19_patch_windows_amd64.tar.gz
set download_dest=%USERPROFILE%\Desktop\titan-l2edge.tar.gz

echo Downloading titan-l2edge package...
powershell -command "& {Invoke-WebRequest '%download_url%' -OutFile '%download_dest%' -UseBasicParsing -Verbose}" | findstr /r "Total|Completed" | findstr /r /c:".*%\.*%" | set /p percentage=
if %errorlevel% neq 0 (
    echo Failed to download titan-l2edge package. Exiting installation.
    pause
    exit /b
) else (
    echo Download successful. File saved to: %download_dest%
)

rem Extracting files to system32
echo Extracting files to system32...
powershell -command "tar -xvf '%download_dest%' -C '%SystemRoot%\System32'"
if %errorlevel% neq 0 (
    echo Failed to extract files. Exiting installation.
    pause
    exit /b
) else (
    echo Extraction successful. Files extracted to: %SystemRoot%\System32
    del "%download_dest%" 2>nul
)

echo [1;33mCLI Download and extraction completed successfully.[0m
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

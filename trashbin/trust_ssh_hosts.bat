@echo off
rem Simple launcher: call the external PowerShell script in the same folder
setlocal
set SCRIPT_DIR=%~dp0
set PS_SCRIPT=%SCRIPT_DIR%trust_ssh_hosts.ps1

if not exist "%PS_SCRIPT%" (
    echo Missing %PS_SCRIPT% - please ensure trust_ssh_hosts.ps1 is in the same folder as this .bat
    exit /b 2
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*
endlocal

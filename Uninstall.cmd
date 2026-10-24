@echo off
setlocal
if exist "%~dp0installation.json" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Uninstall.ps1" -InstallRoot "%~dp0." %*
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Uninstall.ps1" %*
)
if errorlevel 1 echo Uninstall failed. Read the error above.
pause

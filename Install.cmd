@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Install.ps1" %*
if errorlevel 1 echo Installation failed. Read the error above.
pause

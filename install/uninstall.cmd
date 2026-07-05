@echo off
pushd %~dp0
powershell -NoProfile -ExecutionPolicy Bypass -File "install.ps1" -Uninstall
pause
popd

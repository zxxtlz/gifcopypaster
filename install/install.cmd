@echo off
pushd %~dp0
if exist install.log del /q install.log

powershell -NoProfile -ExecutionPolicy Bypass -File "install.ps1"

if %errorlevel% equ 0 goto success
if %errorlevel% equ 2 goto cancel
goto fail

:success
echo.
echo GIFCopier installed successfully.
goto end

:cancel
echo.
echo Installation cancelled.
goto end

:fail
echo.
echo Installation failed. Check install.log for details.
goto end

:end
pause
popd

@echo off
REM This script creates a shortcut in the Windows Startup folder
REM to automatically launch DisplayRGBSync on logon.

set "BATCH_DIR=%~dp0"
set "TARGET_BAT=%BATCH_DIR%run_sync.bat"
set "SHORTCUT_NAME=DisplayRGBSync.lnk"
set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "SHORTCUT_PATH=%STARTUP_FOLDER%\%SHORTCUT_NAME%"

echo Creating shortcut for autostart...

REM Use PowerShell to create the shortcut, as it's the most reliable method
powershell.exe -ExecutionPolicy Bypass -NoProfile -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SHORTCUT_PATH%'); $s.TargetPath = '%TARGET_BAT%'; $s.Save()"

echo.
echo =================================================================
echo  Shortcut created successfully in your Startup folder.
echo  DisplayRGBSync will now start automatically when you log in.
echo =================================================================
echo.
pause
@echo off
REM This script launches DisplayRGBSync in the background.

REM Define the directory where this .bat file is located
set "BATCH_DIR=%~dp0"

REM Path to pythonw.exe within our folder
set "PYTHON_EXE=%BATCH_DIR%python\pythonw.exe"

REM Path to the main script
set "SCRIPT_PATH=%BATCH_DIR%DisplayRGBSync.pyw"

REM Launch the script in the background without a console window
echo Launching DisplayRGBSync in the background...
start "DisplayRGBSync" /B "%PYTHON_EXE%" "%SCRIPT_PATH%"
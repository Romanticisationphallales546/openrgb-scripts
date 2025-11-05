@echo off

:: Ensure the script runs with UTF-8 codepage to handle paths and names correctly
if "%_chcp_set%"=="1" goto :main
set "_chcp_set=1"
chcp 65001 > nul
cmd /c "%~f0" %*
exit /b

:main
setlocal enabledelayedexpansion

:: === Configuration ===
set "PYTHON_DIR=%~dp0python"
set "PYTHON_EXE=%PYTHON_DIR%\python.exe"
set "PYTHON_VERSION=3.10.11"
set "PYTHON_URL=https://www.python.org/ftp/python/%PYTHON_VERSION%/python-%PYTHON_VERSION%-embed-amd64.zip"
set "PYTHON_ZIP=%~dp0python-embed.zip"
set "PTH_FILE_PATTERN=%PYTHON_DIR%\python3*._pth"
set "GET_PIP_URL=https://bootstrap.pypa.io/get-pip.py"
set "GET_PIP_FILE=%PYTHON_DIR%\get-pip.py"
set "REQUIREMENTS_FILE=%~dp0requirements.txt"

:: === Check for Python, download if missing ===
if exist "%PYTHON_EXE%" (
    echo [INFO] Existing Python environment found. Skipping download.
    goto :patch_python
)

echo [INFO] Local Python environment not found.
echo [INFO] Downloading Python %PYTHON_VERSION% (Embeddable)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%PYTHON_ZIP%'"
if errorlevel 1 (
    echo [ERROR] Failed to download Python archive. Please check your internet connection.
    pause
    exit /b 1
)

echo [INFO] Unpacking archive...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%PYTHON_ZIP%' -DestinationPath '%PYTHON_DIR%' -Force"
if errorlevel 1 (
    echo [ERROR] Failed to unpack Python archive.
    pause
    exit /b 1
)

echo [INFO] Cleaning up temporary files...
del "%PYTHON_ZIP%"

:patch_python
:: === Patch ._pth file to enable site-packages (pip) ===
echo [INFO] Patching Python to enable package support...
for %%f in ("%PTH_FILE_PATTERN%") do (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content -Path '%%f') -replace '#import site', 'import site' | Set-Content -Path '%%f'"
)

:setup_pip
:: === Check for pip, install if missing ===
echo [INFO] Checking for pip...
"%PYTHON_EXE%" -m pip --version >nul 2>&1
if errorlevel 1 (
    echo [INFO] pip not found. Downloading installer...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%GET_PIP_URL%' -OutFile '%GET_PIP_FILE%'"
    if errorlevel 1 (
        echo [ERROR] Failed to download get-pip.py.
        pause
        exit /b 1
    )
    echo [INFO] Installing pip...
    "%PYTHON_EXE%" "%GET_PIP_FILE%"
    del "%GET_PIP_FILE%"
)

:: === Install/Upgrade dependencies ===
echo [INFO] Updating pip to the latest version...
"%PYTHON_EXE%" -m pip install --upgrade pip >nul

if not exist "%REQUIREMENTS_FILE%" (
    echo [WARN] requirements.txt not found. Skipping dependency installation.
    goto :success
)

echo [INFO] Installing dependencies from requirements.txt...
"%PYTHON_EXE%" -m pip install -r "%REQUIREMENTS_FILE%"

:success
echo.
echo [SUCCESS] Setup completed successfully. The environment is ready.
echo.
pause
endlocal

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
    echo [INFO] Обнаружена существующая среда Python. Пропускаю загрузку.
    goto :patch_python
)

echo [INFO] Локальная среда Python не найдена.
echo [INFO] Загрузка Python %PYTHON_VERSION% (Embeddable)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%PYTHON_ZIP%'"
if errorlevel 1 (
    echo [ERROR] Не удалось загрузить архив Python. Проверьте подключение к интернету.
    pause
    exit /b 1
)

echo [INFO] Распаковка архива...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%PYTHON_ZIP%' -DestinationPath '%PYTHON_DIR%' -Force"
if errorlevel 1 (
    echo [ERROR] Не удалось распаковать архив Python.
    pause
    exit /b 1
)

echo [INFO] Очистка временных файлов...
del "%PYTHON_ZIP%"

:patch_python
:: === Patch ._pth file to enable site-packages (pip) ===
echo [INFO] Настройка Python для работы с пакетами...
for %%f in ("%PTH_FILE_PATTERN%") do (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-Content -Path '%%f') -replace '#import site', 'import site' | Set-Content -Path '%%f'"
)

:setup_pip
:: === Check for pip, install if missing ===
echo [INFO] Проверка наличия pip...
"%PYTHON_EXE%" -m pip --version >nul 2>&1
if errorlevel 1 (
    echo [INFO] pip не найден. Загрузка установщика...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%GET_PIP_URL%' -OutFile '%GET_PIP_FILE%'"
    if errorlevel 1 (
        echo [ERROR] Не удалось загрузить get-pip.py.
        pause
        exit /b 1
    )
    echo [INFO] Установка pip...
    "%PYTHON_EXE%" "%GET_PIP_FILE%"
    del "%GET_PIP_FILE%"
)

:: === Install/Upgrade dependencies ===
echo [INFO] Обновление pip до последней версии...
"%PYTHON_EXE%" -m pip install --upgrade pip >nul

if not exist "%REQUIREMENTS_FILE%" (
    echo [WARN] Файл requirements.txt не найден. Пропускаю установку зависимостей.
    goto :success
)

echo [INFO] Установка зависимостей из requirements.txt...
"%PYTHON_EXE%" -m pip install -r "%REQUIREMENTS_FILE%"

:success
echo.
echo [SUCCESS] Установка успешно завершена. Среда готова к работе.
echo.
pause
endlocal

REM filepath: /c:/Users/JF30LB/Projects/python/Projects/text_to_audio/setup_env_v8.bat
@echo off
chcp 1252
setlocal enabledelayedexpansion

REM Vérification et configuration de Visual Studio
echo Verification de Visual Studio...
set "VS_PATH=C:\Program Files\Microsoft Visual Studio\2022\Community"
if not exist "%VS_PATH%\VC\Tools\MSVC" (
    echo Installation de Visual Studio requise...
    goto install_vs
)
goto setup_env

:install_vs
echo Telechargement de Visual Studio...
curl -L -o "%TEMP%\vs_community.exe" https://aka.ms/vs/17/release/vs_community.exe
    
echo Installation de Visual Studio avec les composants C++...
"%TEMP%\vs_community.exe" --quiet --wait --norestart --nocache ^
    --add Microsoft.VisualStudio.Workload.NativeDesktop ^
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 ^
    --add Microsoft.VisualStudio.Component.Windows11SDK.22621
del "%TEMP%\vs_community.exe"

:setup_env
REM Configuration explicite des chemins Visual Studio
set "MSVC_PATH=%VS_PATH%\VC\Tools\MSVC"
for /f "delims=" %%i in ('dir /b /ad "%MSVC_PATH%"') do set "MSVC_VERSION=%%i"
set "INCLUDE=%MSVC_PATH%\%MSVC_VERSION%\include;%INCLUDE%"
set "LIB=%MSVC_PATH%\%MSVC_VERSION%\lib\x64;%LIB%"
set "PATH=%MSVC_PATH%\%MSVC_VERSION%\bin\HostX64\x64;%PATH%"

REM Configuration pour la compilation
set DISTUTILS_USE_SDK=1
set MSSdk=1
set "CL=/MP"

REM Vérification de Python 3.10
echo Verification de Python 3.10...
py -3.10 --version >nul 2>&1
if not errorlevel 1 (
    echo Python 3.10 trouve via py launcher
    goto install_deps
)

REM Installation de Python 3.10 si nécessaire
set "PYTHON310_PATH=%LOCALAPPDATA%\Programs\Python\Python310"
if exist "%PYTHON310_PATH%\python.exe" (
    echo Python 3.10 trouve dans %PYTHON310_PATH%
    set "PATH=%PYTHON310_PATH%;%PYTHON310_PATH%\Scripts;%PATH%"
    goto install_deps
)

echo Python 3.10 n'est pas installe. Installation...
curl -L -o "%TEMP%\python3.10.exe" https://www.python.org/ftp/python/3.10.9/python-3.10.9-amd64.exe
"%TEMP%\python3.10.exe" /quiet InstallAllUsers=0 PrependPath=0 Include_test=0 Include_pip=1 Include_launcher=1
del "%TEMP%\python3.10.exe"
set "PATH=%PYTHON310_PATH%;%PYTHON310_PATH%\Scripts;%PATH%"

:install_deps
echo Installation des dependances...
python -m pip install --upgrade pip wheel setuptools
pip install numpy==1.24.3 --only-binary :all:
pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu117

echo Installation de TTS avec les outils de build...
pip uninstall TTS -y
echo Tentative d'installation de TTS version 0.17.6...
pip install TTS==0.17.6
if errorlevel 1 (
    echo Tentative avec TTS version 0.15.2...
    pip install TTS==0.15.2
    if errorlevel 1 (
        echo Installation de TTS avec dependances separees...
        pip install TTS==0.15.2 --no-deps
        pip install -r requirements.txt
    )
)

echo Installation de PyQt6...
pip install PyQt6

echo.
echo Installation terminee!
echo Pour tester, executez:
echo call .\venv_py310\Scripts\activate.bat
echo python Simple_TTS_GUI.py
echo.
pause
@echo off
chcp 1252
setlocal enabledelayedexpansion

REM Vérification de Visual Studio
echo Verification de Visual Studio...
set "VS_PATH=C:\Program Files\Microsoft Visual Studio\2022\Community"
if not exist "%VS_PATH%\VC\Tools\MSVC" (
    echo Visual Studio 2022 Community n'est pas installe
    echo Telechargement de Visual Studio...
    curl -L -o "%TEMP%\vs_community.exe" https://aka.ms/vs/17/release/vs_community.exe
    
    echo Installation de Visual Studio avec les composants C++...
    "%TEMP%\vs_community.exe" --quiet --wait --norestart --nocache ^
        --add Microsoft.VisualStudio.Workload.NativeDesktop ^
        --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 ^
        --add Microsoft.VisualStudio.Component.Windows11SDK.22621
    del "%TEMP%\vs_community.exe"
)

REM Configuration de l'environnement Visual Studio
set "MSVC_PATH=%VS_PATH%\VC\Tools\MSVC"
for /f "delims=" %%i in ('dir /b /ad "%MSVC_PATH%"') do set "MSVC_VERSION=%%i"
set "PATH=%VS_PATH%\VC\Tools\MSVC\%MSVC_VERSION%\bin\HostX64\x64;%PATH%"

echo Verification de Python 3.10...

REM Essayer d'utiliser py pour accéder à Python 3.10
py -3.10 --version >nul 2>&1
if not errorlevel 1 (
    echo Python 3.10 trouve via py launcher
    goto setup_env
)

REM Essayer d'activer Python 3.10 s'il est déjà installé
set "PYTHON310_PATH=%LOCALAPPDATA%\Programs\Python\Python310"
if exist "%PYTHON310_PATH%\python.exe" (
    echo Python 3.10 trouve dans %PYTHON310_PATH%
    set "PATH=%PYTHON310_PATH%;%PYTHON310_PATH%\Scripts;%PATH%"
    goto setup_env
)

REM Si on arrive ici, Python 3.10 n'est pas installé
echo Python 3.10 n'est pas installe. Installation...
echo Telechargement de Python 3.10.9...
curl -L -o "%TEMP%\python3.10.exe" https://www.python.org/ftp/python/3.10.9/python-3.10.9-amd64.exe
    
echo Installation de Python 3.10.9...
"%TEMP%\python3.10.exe" /quiet InstallAllUsers=0 PrependPath=0 Include_test=0 Include_pip=1 Include_launcher=1
del "%TEMP%\python3.10.exe"

echo Ajout de Python 3.10 au PATH...
set "PATH=%LOCALAPPDATA%\Programs\Python\Python310;%LOCALAPPDATA%\Programs\Python\Python310\Scripts;%PATH%"

:setup_env
echo Configuration de l'environnement de build...
set DISTUTILS_USE_SDK=1
set MSSdk=1
call "%VS_PATH%\VC\Auxiliary\Build\vcvars64.bat"

echo Creation de l'environnement virtuel...
if exist venv_py310 rmdir /s /q venv_py310
py -3.10 -m venv venv_py310
call .\venv_py310\Scripts\activate.bat

echo Installation des dependances...
python -m pip install --upgrade pip wheel setuptools
pip install numpy==1.24.3 --only-binary :all:
pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu117

echo Installation de TTS avec les outils de build...
set "CL=/MP"
pip install TTS==0.17.6 --no-cache-dir

echo Installation de PyQt6...
pip install PyQt6

echo.
echo Installation terminee!
echo Pour tester, executez:
echo call .\venv_py310\Scripts\activate.bat
echo python Simple_TTS_GUI.py
echo.
pause

REM filepath: /c:/Users/JF30LB/Projects/python/Projects/text_to_audio/setup_env_v11.bat
@echo off
chcp 1252
setlocal enabledelayedexpansion

REM Installation de Visual Studio Community (si nécessaire)
echo Verification de Visual Studio...
set "VS_PATH=C:\Program Files\Microsoft Visual Studio\2022\Community"
if not exist "%VS_PATH%\VC\Tools\MSVC" (
    echo Installation de Visual Studio requise...
    curl -L -o "%TEMP%\vs_community.exe" https://aka.ms/vs/17/release/vs_community.exe
    
    echo Installation de Visual Studio avec les composants C++...
    "%TEMP%\vs_community.exe" --quiet --wait --norestart --nocache ^
        --add Microsoft.VisualStudio.Workload.NativeDesktop ^
        --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 ^
        --add Microsoft.VisualStudio.Component.Windows11SDK.22621 ^
        --add Microsoft.VisualStudio.Component.VC.ATL ^
        --add Microsoft.VisualStudio.Component.VC.ATLMFC
    del "%TEMP%\vs_community.exe"
)

REM Configuration des chemins Visual Studio
set "MSVC_PATH=%VS_PATH%\VC\Tools\MSVC"
for /f "delims=" %%i in ('dir /b /ad "%MSVC_PATH%"') do set "MSVC_VERSION=%%i"
set "INCLUDE=%MSVC_PATH%\%MSVC_VERSION%\include;%MSVC_PATH%\%MSVC_VERSION%\ATLMFC\include;%VS_PATH%\VC\Auxiliary\VS\include;%INCLUDE%"
set "LIB=%MSVC_PATH%\%MSVC_VERSION%\lib\x64;%MSVC_PATH%\%MSVC_VERSION%\ATLMFC\lib\x64;%LIB%"
set "PATH=%MSVC_PATH%\%MSVC_VERSION%\bin\HostX64\x64;%PATH%"

REM Configuration Windows SDK
set "WIN_SDK_ROOT=C:\Program Files (x86)\Windows Kits\10"
set "WIN_SDK_VERSION=10.0.22621.0"
set "INCLUDE=%WIN_SDK_ROOT%\Include\%WIN_SDK_VERSION%\ucrt;%WIN_SDK_ROOT%\Include\%WIN_SDK_VERSION%\um;%WIN_SDK_ROOT%\Include\%WIN_SDK_VERSION%\shared;%INCLUDE%"
set "LIB=%WIN_SDK_ROOT%\Lib\%WIN_SDK_VERSION%\ucrt\x64;%WIN_SDK_ROOT%\Lib\%WIN_SDK_VERSION%\um\x64;%LIB%"

REM Configuration de l'environnement de build
set DISTUTILS_USE_SDK=1
set MSSdk=1
set "CL=/MP"
call "%VS_PATH%\VC\Auxiliary\Build\vcvars64.bat"

REM Vérification de Python 3.10
echo Verification de Python 3.10...
py -3.10 --version >nul 2>&1
if errorlevel 1 (
    echo Installation de Python 3.10...
    curl -L -o "%TEMP%\python3.10.exe" https://www.python.org/ftp/python/3.10.9/python-3.10.9-amd64.exe
    "%TEMP%\python3.10.exe" /quiet InstallAllUsers=0 PrependPath=0 Include_test=0 Include_pip=1 Include_launcher=1
    del "%TEMP%\python3.10.exe"
)

REM Création et activation de l'environnement virtuel
echo Creation de l'environnement virtuel...
if exist venv_py310 rmdir /s /q venv_py310
py -3.10 -m venv venv_py310
call .\venv_py310\Scripts\activate.bat

REM Installation séquentielle des dépendances
echo Installation des dependances de base...
python -m pip install --upgrade pip setuptools wheel

echo Installation de numpy specifique...
pip uninstall numpy -y
pip install numpy==1.22.0 --only-binary :all:

echo Installation de PyTorch...
pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu117

echo Installation des dependances TTS...
pip install librosa==0.10.0
pip install soundfile==0.12.1
pip install Unidecode==1.3.7
pip install tqdm>=4.65.0

echo Installation de TTS...
pip uninstall TTS -y
pip install --only-binary :all: TTS==0.17.6
if errorlevel 1 (
    echo Tentative alternative d'installation de TTS...
    pip install TTS==0.17.6 --no-deps
)

echo Installation de PyQt6...
pip uninstall PyQt6 PyQt6-Qt6 PyQt6-sip -y
pip install PyQt6==6.5.2 PyQt6-Qt6==6.5.2 PyQt6-sip==13.5.2

echo.
echo Installation terminee!
echo Pour tester, executez:
echo call .\venv_py310\Scripts\activate.bat
echo python Simple_TTS_GUI.py
echo.
pause
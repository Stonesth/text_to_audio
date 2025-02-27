REM filepath: /c:/Users/JF30LB/Projects/python/Projects/text_to_audio/setup_env.bat
@echo off
setlocal enabledelayedexpansion

echo Verification des outils de build...
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
    set "BUILDTOOLS=%%i"
)

if not defined BUILDTOOLS (
    echo Visual Studio Build Tools non trouve. Installation requise.
    echo 1. Telechargement de Visual Studio Build Tools...
    curl -L -o "%TEMP%\vs_buildtools.exe" https://aka.ms/vs/17/release/vs_buildtools.exe
    
    echo 2. Installation des composants necessaires...
    "%TEMP%\vs_buildtools.exe" --quiet --wait --norestart --nocache ^
        --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools" ^
        --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 ^
        --add Microsoft.VisualStudio.Component.Windows11SDK.22621 ^
        --add Microsoft.VisualStudio.Component.VC.14.34.17.4.x86.x64 ^
        --add Microsoft.VisualStudio.Component.Windows.SDK ^
        --add Microsoft.VisualStudio.Component.VC.ATL ^
        --add Microsoft.VisualStudio.Component.VC.ATLMFC
    
    del "%TEMP%\vs_buildtools.exe"
)

echo Configuration des variables d'environnement...
set "WIN_SDK_ROOT=C:\Program Files (x86)\Windows Kits\10"
set "WIN_SDK_VERSION=10.0.22621.0"
set "MSVC_ROOT=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.43.34808"

set "PATH=%PATH%;%WIN_SDK_ROOT%\bin\%WIN_SDK_VERSION%\x64;%MSVC_ROOT%\bin\HostX64\x64"
set "INCLUDE=%INCLUDE%;%WIN_SDK_ROOT%\Include\%WIN_SDK_VERSION%\ucrt;%WIN_SDK_ROOT%\Include\%WIN_SDK_VERSION%\um;%WIN_SDK_ROOT%\Include\%WIN_SDK_VERSION%\shared;%MSVC_ROOT%\include"
set "LIB=%LIB%;%WIN_SDK_ROOT%\Lib\%WIN_SDK_VERSION%\ucrt\x64;%WIN_SDK_ROOT%\Lib\%WIN_SDK_VERSION%\um\x64;%MSVC_ROOT%\lib\x64"
set VS140COMNTOOLS=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build

echo Nettoyage de l'environnement precedent...
if exist venv_py311 rmdir /s /q venv_py311

echo Creation de l'environnement virtuel Python...
python -m venv venv_py311

echo Activation de l'environnement virtuel...
call .\venv_py311\Scripts\activate.bat

echo Configuration de l'environnement de build...
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

echo Installation des dependances de base...
python -m pip install --upgrade pip
python -m pip install --upgrade setuptools wheel
python -m pip install Cython
python -m pip install numpy

echo Installation de PyTorch...
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

echo Installation de TTS...
pip install TTS --no-build-isolation --no-deps
pip install TTS[all] --no-build-isolation

echo Installation de PyQt6...
pip install PyQt6

echo.
echo Installation terminee! Pour tester, executez:
echo call .\venv_py311\Scripts\activate.bat
echo python Simple_TTS_GUI.py
echo.
pause

REM filepath: /c:/Users/JF30LB/Projects/python/Projects/text_to_audio/setup_env_v10.bat
@echo off
chcp 1252
setlocal enabledelayedexpansion

REM Vérification de Python 3.10
echo Verification de Python 3.10...

REM Sauvegarder le chemin Python original
for /f "tokens=*" %%p in ('where py 2^>nul') do set "PYTHON_PATH=%%~dp0"
for /f "tokens=*" %%p in ('where python 2^>nul') do set "PYTHON_EXE_PATH=%%~dp0"

REM Vérifier si py launcher peut trouver Python 3.10
py -3.10 --version >nul 2>&1
if not errorlevel 1 (
    echo Python 3.10 trouve via py launcher
    set "PYTHON_CMD=py -3.10"
    goto setup_vs
)

REM Vérifier dans les emplacements standard
set "PYTHON310_PATHS=C:\Python310;%LOCALAPPDATA%\Programs\Python\Python310;C:\Program Files\Python310;C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python310"
for %%p in (%PYTHON310_PATHS%) do (
    if exist "%%p\python.exe" (
        echo Python 3.10 trouve dans %%p
        set "PYTHON_PATH=%%p"
        set "PYTHON_CMD=%%p\python.exe"
        goto setup_vs
    )
)

echo Python 3.10 n'est pas trouve. Veuillez l'installer depuis:
echo https://www.python.org/downloads/release/python-3109/
pause
exit /b 1

:setup_vs
REM Configuration de Visual Studio
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

REM Réinitialisation des variables d'environnement
set "INCLUDE="
set "LIB="
set "OLD_PATH=%PATH%"

REM Configuration des chemins Visual Studio
echo Configuration des chemins...
set "MSVC_PATH=%VS_PATH%\VC\Tools\MSVC"
for /f "delims=" %%i in ('dir /b /ad "%MSVC_PATH%"') do set "MSVC_VERSION=%%i"
set "MSVC_FULL=%MSVC_PATH%\%MSVC_VERSION%"
set "SDK_PATH=C:\Program Files (x86)\Windows Kits\10"
set "SDK_VER=10.0.22621.0"

REM Configuration ordonnée des includes
echo Configuration des includes...
set "INCLUDE=%MSVC_FULL%\include"
set "INCLUDE=%INCLUDE%;%VS_PATH%\VC\Auxiliary\VS\include"
set "INCLUDE=%INCLUDE%;%MSVC_FULL%\ATLMFC\include"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\ucrt"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\um"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\shared"

REM Configuration des bibliothèques
echo Configuration des bibliothèques...
set "LIB=%MSVC_FULL%\lib\x64"
set "LIB=%LIB%;%MSVC_FULL%\ATLMFC\lib\x64"
set "LIB=%LIB%;%SDK_PATH%\Lib\%SDK_VER%\ucrt\x64"
set "LIB=%LIB%;%SDK_PATH%\Lib\%SDK_VER%\um\x64"

REM Configuration du PATH
echo Configuration du PATH...
set "PATH=%MSVC_FULL%\bin\HostX64\x64;%PATH%"

REM Restaurer Python dans le PATH
set "PATH=%PYTHON_PATH%;%PYTHON_PATH%\Scripts;%PATH%"
if defined PYTHON_EXE_PATH set "PATH=%PYTHON_EXE_PATH%;%PATH%"

REM Configuration de l'environnement de build
echo Configuration de l'environnement de build...
set DISTUTILS_USE_SDK=1
set MSSdk=1
set "CL=/MP"
call "%VS_PATH%\VC\Auxiliary\Build\vcvars64.bat"

REM S'assurer que Python est toujours accessible
set "PATH=%PYTHON_PATH%;%PYTHON_PATH%\Scripts;%PATH%"
if defined PYTHON_EXE_PATH set "PATH=%PYTHON_EXE_PATH%;%PATH%"

REM Création de l'environnement virtuel
echo Creation de l'environnement virtuel...
if exist venv_py310 rmdir /s /q venv_py310
%PYTHON_CMD% -m venv venv_py310
call .\venv_py310\Scripts\activate.bat

REM Installation des dépendances
echo Installation des dependances de base...
python -m pip install --upgrade pip setuptools wheel

REM Installation séquentielle des packages
echo Installation des packages principaux...
pip install numpy==1.22.0 --only-binary :all:
pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu117 --only-binary :all:

echo Installation des dependances TTS...
pip install librosa==0.10.0 --only-binary :all:
pip install soundfile==0.12.1 --only-binary :all:
pip install Unidecode==1.3.7 --only-binary :all:
pip install tqdm>=4.65.0 --only-binary :all:

echo Installation de TTS...
pip uninstall TTS -y
pip install TTS==0.17.6 --only-binary :all: --no-deps

echo Installation de PyQt6...
pip uninstall PyQt6 PyQt6-Qt6 PyQt6-sip -y
pip install PyQt6==6.5.2 PyQt6-Qt6==6.5.2 PyQt6-sip==13.5.2 --only-binary :all:

echo.
echo Installation terminee!
echo Pour tester, executez:
echo call .\venv_py310\Scripts\activate.bat
echo python Simple_TTS_GUI.py
echo.
pause
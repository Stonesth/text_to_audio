REM filepath: /c:/Users/JF30LB/Projects/python/Projects/text_to_audio/setup_env_v18.bat
@echo off
chcp 1252
setlocal enabledelayedexpansion

REM Vérification si nous sommes dans un environnement virtuel
python -c "import sys; sys.exit(0 if hasattr(sys, 'real_prefix') or hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix else 1)"
if errorlevel 1 (
    echo Pour eviter les conflits, desactivez d'abord votre environnement virtuel avec 'deactivate'
    pause
    exit /b 1
)

REM Vérification de Python 3.10
echo Recherche de Python 3.10...
py -3.10 --version >nul 2>&1
if errorlevel 1 (
    echo Python 3.10 est requis mais n'est pas installe.
    echo Telechargez-le depuis : https://www.python.org/downloads/release/python-3109/
    pause
    exit /b 1
)

REM Configuration de Visual Studio
echo Configuration de Visual Studio...
set "VS_PATH=C:\Program Files\Microsoft Visual Studio\2022\Community"
if not exist "%VS_PATH%\VC\Tools\MSVC" (
    echo Visual Studio 2022 Community est requis avec les composants C++
    echo Telechargez-le depuis : https://visualstudio.microsoft.com/vs/community/
    pause
    exit /b 1
)

REM Nettoyage complet de l'environnement
set "INCLUDE="
set "LIB="
set "PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem"

REM Configuration systématique des chemins
set "MSVC_PATH=%VS_PATH%\VC\Tools\MSVC"
for /f "delims=" %%i in ('dir /b /ad "%MSVC_PATH%"') do set "MSVC_VERSION=%%i"
set "MSVC_FULL=%MSVC_PATH%\%MSVC_VERSION%"
set "SDK_PATH=C:\Program Files (x86)\Windows Kits\10"
set "SDK_VER=10.0.22621.0"

REM Configuration ordonnée des includes sans duplication
set "INCLUDE=%MSVC_FULL%\include"
set "INCLUDE=%INCLUDE%;%VS_PATH%\VC\Auxiliary\VS\include"
set "INCLUDE=%INCLUDE%;%MSVC_FULL%\ATLMFC\include"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\ucrt"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\um"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\shared"

REM Configuration des bibliothèques
set "LIB=%MSVC_FULL%\lib\x64"
set "LIB=%LIB%;%MSVC_FULL%\ATLMFC\lib\x64"
set "LIB=%LIB%;%SDK_PATH%\Lib\%SDK_VER%\ucrt\x64"
set "LIB=%LIB%;%SDK_PATH%\Lib\%SDK_VER%\um\x64"

REM Configuration de l'environnement de build
set DISTUTILS_USE_SDK=1
set MSSdk=1
set "CL=/MP"

REM Création de l'environnement virtuel propre
echo Creation de l'environnement virtuel...
if exist venv_py310 (
    echo Suppression de l'ancien environnement virtuel...
    rmdir /s /q venv_py310
)
py -3.10 -m venv venv_py310
call .\venv_py310\Scripts\activate.bat

REM Installation séquentielle des dépendances
echo Installation des outils de base...
python -m pip install --upgrade pip setuptools wheel
python -m pip install Cython --no-cache-dir

echo Installation de numpy specifique...
pip install numpy==1.22.0 --no-cache-dir --only-binary :all:

echo Installation de PyTorch...
pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu117 --only-binary :all:

echo Installation des dependances TTS...
pip install librosa==0.10.0 --only-binary :all:
pip install soundfile==0.12.1 --only-binary :all:
pip install scipy==1.11.4 --only-binary :all:
pip install tensorboard==2.14.1 --only-binary :all:
pip install Unidecode==1.3.7 --only-binary :all:
pip install tqdm==4.65.0 --only-binary :all:

echo Installation de TTS...
pip uninstall TTS -y
pip install TTS==0.17.6 --no-cache-dir --no-deps
if errorlevel 1 (
    echo Tentative avec binaires pre-compiles...
    pip install TTS==0.17.6 --only-binary :all: --no-deps
    if errorlevel 1 (
        echo Installation version stable TTS...
        pip install TTS==0.15.2 --no-deps
    )
)

echo Installation de PyQt6...
pip install PyQt6==6.5.2 PyQt6-Qt6==6.5.2 PyQt6-sip==13.5.2 --no-cache-dir

echo.
echo Installation terminee! Verifications...
python -c "import numpy; import torch; import TTS; import PyQt6" 2>nul
if errorlevel 1 (
    echo ATTENTION: Certains packages ne sont pas correctement installes
    echo Verifiez les erreurs ci-dessus
) else (
    echo Tous les packages principaux sont installes correctement
)

echo.
echo Pour utiliser l'environnement:
echo call .\venv_py310\Scripts\activate.bat
echo python Simple_TTS_GUI.py
echo.
pause
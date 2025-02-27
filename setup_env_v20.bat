REM filepath: /c:/Users/JF30LB/Projects/python/Projects/text_to_audio/setup_env_v20.bat
@echo off
chcp 1252
setlocal enabledelayedexpansion

REM Vérifications préliminaires
echo Verifications preliminaires...
net session >nul 2>&1
if %errorLevel% == 0 (
    echo ATTENTION: Ne pas executer en mode administrateur
    pause
    exit /b 1
)

REM Vérification Python 3.10 existant
py -3.10 --version >nul 2>&1
if errorlevel 1 (
    echo Python 3.10 est requis. Telechargez-le depuis:
    echo https://www.python.org/downloads/release/python-3109/
    pause
    exit /b 1
)

REM Désactivation de l'environnement virtuel si actif
if defined VIRTUAL_ENV (
    echo Desactivation de l'environnement virtuel actif...
    deactivate
)

REM Nettoyage complet de l'environnement
set "INCLUDE="
set "LIB="
set "PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem"

REM Configuration Visual Studio
echo Configuration de Visual Studio...
set "VS_PATH=C:\Program Files\Microsoft Visual Studio\2022\Community"
if not exist "%VS_PATH%\VC\Tools\MSVC" (
    echo Visual Studio 2022 Community est requis.
    pause
    exit /b 1
)

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
call "%VS_PATH%\VC\Auxiliary\Build\vcvars64.bat"

REM Création de l'environnement virtuel
echo Creation de l'environnement virtuel...
if exist venv_py310 rmdir /s /q venv_py310
py -3.10 -m venv venv_py310
call .\venv_py310\Scripts\activate.bat

REM Installation séquentielle (ordre crucial)
echo Installation des dependances de base...
python -m pip install --upgrade pip setuptools wheel
python -m pip install Cython --no-cache-dir

echo Installation de numpy specifique...
pip install numpy==1.22.0 --no-cache-dir --only-binary :all:

echo Installation de PyTorch...
pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu117 --only-binary :all:

echo Installation des dependances TTS...
for %%p in (
    "librosa==0.10.0"
    "soundfile==0.12.1"
    "scipy==1.11.4"
    "tensorboard==2.14.1"
    "Unidecode==1.3.7"
    "tqdm==4.65.0"
) do (
    echo Installing %%p...
    pip install %%p --only-binary :all:
)

echo Installation de TTS...
pip uninstall TTS -y
pip install TTS==0.17.6 --only-binary :all: --no-deps
if errorlevel 1 (
    echo Tentative alternative TTS...
    pip install TTS==0.17.6 --no-deps --no-cache-dir
    if errorlevel 1 (
        echo Installation version stable TTS...
        pip install TTS==0.15.2 --no-deps
    )
)

echo Installation de PyQt6...
pip install PyQt6==6.5.2 PyQt6-Qt6==6.5.2 PyQt6-sip==13.5.2 --no-cache-dir

REM Vérification finale
echo.
echo Verification de l'installation...
python -c "import numpy; print('numpy', numpy.__version__)" 2>nul && ^
python -c "import torch; print('torch', torch.__version__)" 2>nul && ^
python -c "import TTS; print('TTS OK')" 2>nul && ^
python -c "from PyQt6.QtWidgets import QApplication; print('PyQt6 OK')" 2>nul

if errorlevel 1 (
    echo.
    echo ATTENTION: Installation incomplete
    echo Consultez TROUBLESHOOTING.md pour les solutions
) else (
    echo.
    echo Installation reussie!
    echo Pour utiliser:
    echo 1. call .\venv_py310\Scripts\activate.bat
    echo 2. python Simple_TTS_GUI.py
)

pause
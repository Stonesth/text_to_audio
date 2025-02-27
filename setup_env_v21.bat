REM filepath: /c:/Users/JF30LB/Projects/python/Projects/text_to_audio/setup_env_v21.bat
@echo off
chcp 1252
setlocal enabledelayedexpansion

REM Sauvegarder le chemin système original
set "ORIGINAL_PATH=%PATH%"

REM Vérifications préliminaires
echo Verifications preliminaires...
net session >nul 2>&1
if %errorLevel% == 0 (
    echo ATTENTION: Ne pas executer en mode administrateur
    pause
    exit /b 1
)

REM Trouver Python 3.10
set "PYTHON_PATH="
set "PYTHON_CMD="

REM Vérifier les emplacements possibles de Python 3.10
for %%p in (
    "C:\Python310"
    "%LOCALAPPDATA%\Programs\Python\Python310"
    "C:\Program Files\Python310"
    "%USERPROFILE%\AppData\Local\Programs\Python\Python310"
) do (
    if exist "%%~p\python.exe" (
        set "PYTHON_PATH=%%~p"
        set "PYTHON_CMD=%%~p\python.exe"
        goto found_python
    )
)

REM Vérifier avec py launcher
py -3.10 --version >nul 2>&1
if not errorlevel 1 (
    for /f "delims=" %%i in ('py -3.10 -c "import sys; print(sys.prefix)"') do set "PYTHON_PATH=%%i"
    set "PYTHON_CMD=py -3.10"
    goto found_python
)

echo Python 3.10 n'est pas trouve. Installation requise.
pause
exit /b 1

:found_python
echo Python 3.10 trouve dans %PYTHON_PATH%

REM Configuration de Visual Studio
echo Configuration de Visual Studio...
set "VS_PATH=C:\Program Files\Microsoft Visual Studio\2022\Community"
if not exist "%VS_PATH%\VC\Tools\MSVC" (
    echo Visual Studio 2022 Community est requis.
    pause
    exit /b 1
)

REM Nettoyage et configuration de l'environnement
set "INCLUDE="
set "LIB="
set "PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem"
set "PATH=%PYTHON_PATH%;%PYTHON_PATH%\Scripts;%PATH%"

REM Configuration des chemins Visual Studio
set "MSVC_PATH=%VS_PATH%\VC\Tools\MSVC"
for /f "delims=" %%i in ('dir /b /ad "%MSVC_PATH%"') do set "MSVC_VERSION=%%i"
set "MSVC_FULL=%MSVC_PATH%\%MSVC_VERSION%"
set "SDK_PATH=C:\Program Files (x86)\Windows Kits\10"
set "SDK_VER=10.0.22621.0"

REM Configuration des includes sans duplication
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

REM Appeler vcvarsall.bat et restaurer le chemin Python
call "%VS_PATH%\VC\Auxiliary\Build\vcvars64.bat"
set "PATH=%PYTHON_PATH%;%PYTHON_PATH%\Scripts;%PATH%"

REM Création de l'environnement virtuel
echo Creation de l'environnement virtuel...
if exist venv_py310 rmdir /s /q venv_py310
%PYTHON_CMD% -m venv venv_py310
call .\venv_py310\Scripts\activate.bat

REM Installation des dépendances
echo Installation des dependances de base...
%PYTHON_CMD% -m pip install --upgrade pip setuptools wheel
%PYTHON_CMD% -m pip install Cython --no-cache-dir

echo Installation de numpy...
%PYTHON_CMD% -m pip install numpy==1.22.0 --no-cache-dir --only-binary :all:

echo Installation de PyTorch...
%PYTHON_CMD% -m pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu117 --only-binary :all:

REM Installation des dépendances TTS
for %%p in (
    "librosa==0.10.0"
    "soundfile==0.12.1"
    "scipy==1.11.4"
    "tensorboard==2.14.1"
    "Unidecode==1.3.7"
    "tqdm==4.65.0"
) do (
    echo Installing %%p...
    %PYTHON_CMD% -m pip install %%p --only-binary :all:
)

echo Installation de TTS...
%PYTHON_CMD% -m pip uninstall TTS -y
%PYTHON_CMD% -m pip install TTS==0.17.6 --only-binary :all: --no-deps
if errorlevel 1 (
    echo Tentative alternative TTS...
    %PYTHON_CMD% -m pip install TTS==0.17.6 --no-deps --no-cache-dir
    if errorlevel 1 (
        echo Installation version stable TTS...
        %PYTHON_CMD% -m pip install TTS==0.15.2 --no-deps
    )
)

echo Installation de PyQt6...
%PYTHON_CMD% -m pip install PyQt6==6.5.2 PyQt6-Qt6==6.5.2 PyQt6-sip==13.5.2 --no-cache-dir

echo.
echo Verification de l'installation...
%PYTHON_CMD% -c "import numpy; print('numpy', numpy.__version__)" 2>nul && ^
%PYTHON_CMD% -c "import torch; print('torch', torch.__version__)" 2>nul && ^
%PYTHON_CMD% -c "import TTS; print('TTS OK')" 2>nul && ^
%PYTHON_CMD% -c "from PyQt6.QtWidgets import QApplication; print('PyQt6 OK')" 2>nul

if errorlevel 1 (
    echo.
    echo ATTENTION: Installation incomplete
    echo Consultez TROUBLESHOOTING.md pour les solutions
) else (
    echo.
    echo Installation reussie!
    echo Pour utiliser:
    echo call .\venv_py310\Scripts\activate.bat
    echo python Simple_TTS_GUI.py
)

pause
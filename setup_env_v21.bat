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

REM Vérification précise des composants requis
reg query "HKLM\SOFTWARE\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 >nul || (
    echo Installation du SDK Windows 10...
    curl -L -o "%TEMP%\winsdksetup.exe" https://go.microsoft.com/fwlink/p/?LinkID=2033908
    "%TEMP%\winsdksetup.exe" /quiet /norestart
)

REM Configuration précise des chemins SDK
set "WindowsSdkDir=C:\Program Files (x86)\Windows Kits\10"
set "WindowsSdkVerBinPath=%WindowsSdkDir%\bin\10.0.19041.0\x64"
set "PATH=%WindowsSdkVerBinPath%;%PATH%"

REM Vérification des redistribuables Visual C++
echo Vérification des redistribuables Visual C++...
reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" /v Version | find "v14" >nul || (
    echo Installation des redistribuables VS 2015-2022...
    curl -L -o "%TEMP%\vc_redist.x64.exe" https://aka.ms/vs/17/release/vc_redist.x64.exe
    "%TEMP%\vc_redist.x64.exe" /install /quiet /norestart
)

REM Vérification des en-têtes système Windows
echo Vérification des en-têtes système Windows...
if not exist "%ProgramFiles(x86)%\Windows Kits\10\Include\10.0.19041.0\um\windows.h" (
    echo Installation des en-têtes système manquants...
    winget install --id Microsoft.WindowsSDK --version 10.0.19041.0 --silent
    if %errorlevel% neq 0 (
        echo Erreur lors de l'installation des en-têtes système
        exit /b 1
    )
    echo Installation terminée
) else (
    echo Les en-têtes système sont déjà installés
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

REM Configuration des includes sans duplication
set "INCLUDE=%MSVC_FULL%\include"
set "INCLUDE=%INCLUDE%;%VS_PATH%\VC\Auxiliary\VS\include"
set "INCLUDE=%INCLUDE%;%MSVC_FULL%\ATLMFC\include"
set "INCLUDE=%INCLUDE%;%WindowsSdkDir%\Include\10.0.19041.0\ucrt"
set "INCLUDE=%INCLUDE%;%WindowsSdkDir%\Include\10.0.19041.0\um"
set "INCLUDE=%INCLUDE%;%WindowsSdkDir%\Include\10.0.19041.0\shared"

REM Configuration des bibliothèques
set "LIB=%MSVC_FULL%\lib\x64"
set "LIB=%LIB%;%MSVC_FULL%\ATLMFC\lib\x64"
set "LIB=%LIB%;%WindowsSdkDir%\Lib\10.0.19041.0\ucrt\x64"
set "LIB=%LIB%;%WindowsSdkDir%\Lib\10.0.19041.0\um\x64"

REM Configuration de l'environnement de build
set DISTUTILS_USE_SDK=1
set MSSdk=1
set "CL=/MP"

REM Appeler vcvarsall.bat et restaurer le chemin Python
call "%VS_PATH%\VC\Auxiliary\Build\vcvars64.bat"
set "PATH=%PYTHON_PATH%;%PYTHON_PATH%\Scripts;%PATH%"

REM Installation des dépendances système
curl -L -o "%TEMP%\vc_redist.x64.exe" https://aka.ms/vs/17/release/vc_redist.x64.exe
"%TEMP%\vc_redist.x64.exe" /quiet /norestart

REM Installation spécifique de numpy compatible
%PYTHON_CMD% -m pip install "numpy==1.23.5" --only-binary=:all: --no-cache-dir

REM Installation des dépendances Python
%PYTHON_CMD% -m pip install --upgrade pip
%PYTHON_CMD% -m pip install Cython
%PYTHON_CMD% -m pip install torch==2.1.0+cpu -f https://download.pytorch.org/whl/torch_stable.html
%PYTHON_CMD% -m pip install TTS --no-deps --no-cache-dir
%PYTHON_CMD% -c "import os, site; print('Répertoires Python:', site.getsitepackages())"
%PYTHON_CMD% -m pip install PyQt6==6.4.2
%PYTHON_CMD% -m pip install pyinstaller==6.3.0

REM Création de l'environnement virtuel
echo Creation de l'environnement virtuel...
if exist venv_py310 rmdir /s /q venv_py310
%PYTHON_CMD% -m venv venv_py310
call .\venv_py310\Scripts\activate.bat

REM Installation des dépendances
echo Installation des dependances de base...
%PYTHON_CMD% -m pip install --upgrade pip setuptools wheel

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
@echo off
chcp 1252
setlocal enabledelayedexpansion

echo Verification de Python 3.10...
python --version 2>&1 | findstr /C:"Python 3.10" >nul
if errorlevel 1 (
    echo Python 3.10 est requis. Veuillez l'installer depuis:
    echo https://www.python.org/downloads/release/python-3109/
    pause
    exit /b 1
)

echo Configuration de l'environnement de build...
set DISTUTILS_USE_SDK=1
set MSSdk=1
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"

echo Creation de l'environnement virtuel...
if exist venv_py310 rmdir /s /q venv_py310
python -m venv venv_py310
call .\venv_py310\Scripts\activate.bat

echo Installation des dependances...
python -m pip install --upgrade pip wheel setuptools
pip install numpy==1.24.3 --only-binary :all:
pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu117
pip install TTS==0.17.6
pip install PyQt6

echo.
echo Installation terminee!
echo Pour tester, executez:
echo call .\venv_py310\Scripts\activate.bat
echo python Simple_TTS_GUI.py
echo.
pause

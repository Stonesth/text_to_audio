@echo off
setlocal enabledelayedexpansion

echo Creation de l'environnement virtuel Python...
if exist venv_py311 rmdir /s /q venv_py311
python -m venv venv_py311
call .\venv_py311\Scripts\activate.bat

echo Installation des dependances de base...
python -m pip install --upgrade pip
python -m pip install --upgrade setuptools wheel
python -m pip install Cython numpy

echo Installation de PyTorch...
pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu117

echo Installation de TTS pre-compilé...
pip install https://github.com/rhasspy/matplotlib-windows/releases/download/v3.3.4/TTS-0.17.6-cp311-cp311-win_amd64.whl

echo Installation de PyQt6...
pip install PyQt6

echo.
echo Installation terminee! Pour tester, executez:
echo call .\venv_py311\Scripts\activate.bat
echo python Simple_TTS_GUI.py
echo.
pause

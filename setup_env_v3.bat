@echo off
chcp 1252
setlocal enabledelayedexpansion

echo Installation de l'environnement...
if exist venv_py311 rmdir /s /q venv_py311
python -m venv venv_py311
call .\venv_py311\Scripts\activate.bat

echo Installation des dependances de base...
python -m pip install --upgrade pip
python -m pip install --upgrade setuptools wheel

echo Installation de NumPy precompile...
pip install numpy==1.24.3 --only-binary :all:

echo Installation de PyTorch...
pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu117

echo Installation de TTS precompile...
pip install --only-binary :all: TTS==0.15.2

echo Installation de PyQt6...
pip install PyQt6

echo.
echo Installation terminee!
echo Pour tester, executez:
echo call .\venv_py311\Scripts\activate.bat
echo python Simple_TTS_GUI.py
echo.
pause

REM filepath: /c:/Users/JF30LB/Projects/python/Projects/text_to_audio/setup_env_v16.bat
@echo off
chcp 1252
setlocal enabledelayedexpansion

REM Vérification de Python 3.10
// ...existing Python check code...

REM Installation des dépendances essentielles d'abord
echo Installation des dependances de base...
python -m pip install --upgrade pip setuptools wheel
python -m pip install Cython

REM Installation de numpy spécifique (version requise pour TTS)
echo Installation de numpy...
pip uninstall numpy -y
pip install numpy==1.22.0 --no-cache-dir

REM Installation de PyTorch avant TTS
echo Installation de PyTorch...
pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu117

REM Installation des dépendances TTS dans l'ordre
echo Installation des pre-requis TTS...
pip install librosa==0.10.0
pip install soundfile==0.12.1
pip install Unidecode==1.3.7
pip install tqdm>=4.65.0
pip install scipy>=1.11.4
pip install tensorboard==2.14.1
pip install coqpit>=0.0.16
pip install mecab-python3==1.0.8

echo Installation de TTS...
pip uninstall TTS -y
pip install TTS==0.17.6
if errorlevel 1 (
    echo Tentative alternative d'installation TTS...
    pip install --no-cache-dir TTS==0.17.6
    if errorlevel 1 (
        echo Deuxieme tentative avec --no-deps...
        pip install TTS==0.17.6 --no-deps
        if errorlevel 1 (
            echo Installation de la derniere version stable de TTS...
            pip install TTS==0.15.2
        )
    )
)

echo Installation de PyQt6...
pip uninstall PyQt6 PyQt6-Qt6 PyQt6-sip -y
pip install PyQt6==6.5.2 PyQt6-Qt6==6.5.2 PyQt6-sip==13.5.2 --no-cache-dir

echo.
echo Installation terminee!
echo Pour tester, executez:
echo call .\venv_py310\Scripts\activate.bat
echo python Simple_TTS_GUI.py
echo.
pause
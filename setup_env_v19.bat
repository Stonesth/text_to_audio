REM filepath: /c:/Users/JF30LB/Projects/python/Projects/text_to_audio/setup_env_v19.bat
@echo off
chcp 1252
setlocal enabledelayedexpansion

REM Vérification administrative
net session >nul 2>&1
if %errorLevel% == 0 (
    echo ATTENTION: Ne pas executer en mode administrateur
    echo Relancez sans droits administrateur
    pause
    exit /b 1
)

REM Vérification environnement virtuel actif
python -c "import sys; sys.exit(0 if hasattr(sys, 'real_prefix') or hasattr(sys, 'base_prefix') and sys.base_prefix != sys.prefix else 1)"
if errorlevel 1 (
    echo Aucun environnement virtuel actif, on peut continuer...
) else (
    echo Pour eviter les conflits, desactivez d'abord votre environnement virtuel avec 'deactivate'
    pause
    exit /b 1
)

REM ... rest of setup_env_v18.bat code ...

REM Vérification finale plus complète
echo.
echo Verification finale de l'installation...
python -c "import numpy; print('numpy', numpy.__version__)" 2>nul
python -c "import torch; print('torch', torch.__version__)" 2>nul
python -c "import TTS; print('TTS version OK')" 2>nul
python -c "from PyQt6.QtWidgets import QApplication; print('PyQt6 OK')" 2>nul

if errorlevel 1 (
    echo.
    echo ATTENTION: Certains packages ne sont pas correctement installes
    echo Verifiez les erreurs ci-dessus
    echo Pour plus d'aide, consultez le fichier TROUBLESHOOTING.md
) else (
    echo.
    echo Installation reussie! Tous les packages sont correctement installes
    echo.
    echo Pour utiliser l'environnement:
    echo 1. call .\venv_py310\Scripts\activate.bat
    echo 2. python Simple_TTS_GUI.py
)

pause
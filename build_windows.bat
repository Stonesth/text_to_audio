@echo off
echo Compilation de Simple_TTS_GUI pour Windows

:: Créer et activer un environnement virtuel
echo Création de l'environnement virtuel...
python -m venv venv_build
call venv_build\Scripts\activate.bat

:: Nettoyer les anciens fichiers de compilation
echo Nettoyage des fichiers temporaires...
rd /s /q build 2>nul
rd /s /q dist 2>nul

:: Installer les dépendances nécessaires
echo Installation des dépendances...
pip install -U pip
pip install pyinstaller
pip install PyQt6
pip install torch torchaudio
pip install TTS

:: Créer un fichier spec temporaire adapté à l'environnement actuel
echo Création du fichier spec temporaire...

:: Compiler l'application
echo Compilation de l'application...
pyinstaller --name="Simple_TTS_GUI" ^
            --onefile ^
            --debug ^
            --console ^
            --add-data "venv_build\Lib\site-packages\TTS\VERSION;TTS" ^
            --add-data "venv_build\Lib\site-packages\trainer\VERSION;trainer" ^
            --add-data "pytorch_2_6_patch.py;." ^
            --hidden-import PyQt6.QtWidgets ^
            --hidden-import PyQt6.QtCore ^
            --hidden-import PyQt6.QtGui ^
            --hidden-import PyQt6.uic ^
            --hidden-import PyQt6.sip ^
            --hidden-import sip ^
            --hidden-import torch ^
            --hidden-import torch._C ^
            --hidden-import torch.serialization ^
            --hidden-import torch.nn ^
            --hidden-import torch.nn.functional ^
            --hidden-import torchaudio ^
            --hidden-import TTS ^
            --hidden-import trainer ^
            --collect-all PyQt6 ^
            --runtime-hook torch_patch.py ^
            --runtime-hook tts_patch.py ^
            --runtime-hook pyqt_patch.py ^
            Simple_TTS_GUI.py

if %ERRORLEVEL% NEQ 0 (
    echo Erreur lors de la compilation
    exit /b %ERRORLEVEL%
)

echo Compilation terminée avec succès
echo L'exécutable se trouve dans le dossier dist

:: Copier les fichiers nécessaires dans le dossier dist
echo Copie des fichiers additionnels...
xcopy /y style_nn.qss dist\
xcopy /y README.md dist\ 2>nul
xcopy /y LICENSE dist\ 2>nul

:: Désactiver l'environnement virtuel
deactivate

echo Build terminé

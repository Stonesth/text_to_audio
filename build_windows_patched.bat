@echo off
echo Compilation de Simple TTS GUI (version patchee)

:: Definir le chemin vers Python 3.10
set PYTHON_PATH="C:\Users\JF30LB\Projects\python\Projects\text_to_audio\venv_py310\Scripts\python.exe"

:: Verifier que Python 3.10 est disponible
echo Verification de Python 3.10...
%PYTHON_PATH% --version
if errorlevel 1 (
    echo ERREUR: Python 3.10 n'a pas ete trouve au chemin specifie.
    echo Veuillez modifier la variable PYTHON_PATH dans ce script pour pointer vers votre installation Python 3.10.
    pause
    exit /b 1
)

:: Installer PyInstaller si necessaire
echo Installation de PyInstaller dans l'environnement virtuel...
%PYTHON_PATH% -m pip install pyinstaller
if errorlevel 1 (
    echo ERREUR: Impossible d'installer PyInstaller.
    echo Verifiez votre connexion Internet et les permissions d'installation.
    pause
    exit /b 1
)

:: Definir les variables d'environnement
set PYTHONPATH=%PYTHONPATH%;%CD%
set PYSIMPLEGUI_VERBOSE=1

:: Definir les chemins relatifs aux fichiers principaux
set MAIN_SCRIPT=launcher_with_patches.py
set SPEC_FILE=Simple_TTS_GUI_patched.spec

:: Creer le fichier .spec personnalise
echo Generation du fichier .spec: %SPEC_FILE%

:: Ecrire la commande dans un fichier temporaire et l'executer pour eviter les problemes de carets
echo %PYTHON_PATH% -m PyInstaller --name Simple_TTS_GUI_patched --onefile --icon="./assets/icons/icon.ico" --add-data="./assets;assets/" --add-data="./pytorch_2_6_patch.py;." --add-data="./models;models/" --hidden-import=pyaudio --hidden-import=PyQt6 --hidden-import=PyQt6.sip --hidden-import=torch --hidden-import=torchaudio --hidden-import=torchaudio.functional.filtering --hidden-import=pysbd --hidden-import=numba --hidden-import=numba.core %MAIN_SCRIPT% > temp_cmd.bat

call temp_cmd.bat

:: Supprimer le fichier temporaire
del temp_cmd.bat

:: Modifier le fichier .spec pour inclure les hooks
echo Modification de %SPEC_FILE% pour inclure les hooks de patch

:: Compiler avec le fichier .spec modifie
echo Compilation avec %SPEC_FILE%
%PYTHON_PATH% -m PyInstaller %SPEC_FILE%

if errorlevel 1 (
    echo La compilation a echoue !
    pause
    exit /b 1
)

echo Compilation terminee avec succes !
echo L'executable se trouve dans le dossier dist/
pause

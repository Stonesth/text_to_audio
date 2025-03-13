@echo off
echo Compilation de Simple TTS GUI (version patchee)

:: Definir les variables d'environnement
set PYTHONPATH=%PYTHONPATH%;%CD%
set PYSIMPLEGUI_VERBOSE=1

:: Definir les chemins relatifs aux fichiers principaux
set MAIN_SCRIPT=launcher_with_patches.py
set SPEC_FILE=Simple_TTS_GUI_patched.spec

:: Creer le fichier .spec personnalise
echo Generating .spec file: %SPEC_FILE%
pyinstaller --name Simple_TTS_GUI_patched ^^
    --onefile ^^
    --icon="./assets/icons/icon.ico" ^^
    --add-data="./assets;assets/" ^^
    --add-data="./pytorch_2_6_patch.py;." ^^
    --add-data="./models;models/" ^^
    --hidden-import=pyaudio ^^
    --hidden-import=PyQt6 ^^
    --hidden-import=PyQt6.sip ^^
    --hidden-import=torch ^^
    --hidden-import=torchaudio ^^
    --hidden-import=torchaudio.functional.filtering ^^
    --hidden-import=pysbd ^^
    --hidden-import=numba ^^
    --hidden-import=numba.core ^^
    %MAIN_SCRIPT%

:: Modifier le fichier .spec pour inclure les hooks
echo Modifying %SPEC_FILE% to include patch hooks

:: Compiler avec le fichier .spec modifie
echo Building with %SPEC_FILE%
pyinstaller %SPEC_FILE%

if errorlevel 1 (
    echo La compilation a echoue !
    pause
    exit /b 1
)

echo Compilation terminee avec succes !
echo L'executable se trouve dans le dossier dist/
pause

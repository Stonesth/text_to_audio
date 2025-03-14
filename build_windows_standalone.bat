@echo off
echo Création de l'exécutable Windows autonome...

:: Vérifier que l'environnement virtuel existe
if not exist "venv_py310\Scripts\python.exe" (
    echo ERREUR: L'environnement virtuel venv_py310 n'existe pas
    echo Veuillez d'abord créer et activer l'environnement virtuel
    pause
    exit /b 1
)

:: Installer PyInstaller si nécessaire
echo Installation de PyInstaller...
"venv_py310\Scripts\python.exe" -m pip install pyinstaller
if errorlevel 1 (
    echo ERREUR: Impossible d'installer PyInstaller
    pause
    exit /b 1
)

:: Créer l'exécutable
echo Création de l'exécutable...
"venv_py310\Scripts\python.exe" -m PyInstaller --onefile --noconsole ^
    --name "Simple_TTS_GUI" ^
    --add-data="venv_py310\Lib\site-packages\TTS\VERSION;TTS" ^
    --hidden-import=PyQt6 ^
    --hidden-import=PyQt6.sip ^
    --hidden-import=torch ^
    --hidden-import=torchaudio ^
    --hidden-import=pysbd ^
    --hidden-import=numba ^
    Simple_TTS_GUI.py

if errorlevel 1 (
    echo La création de l'exécutable a échoué
    pause
    exit /b 1
)

echo Création terminée avec succès!
echo L'exécutable se trouve dans le dossier dist/
pause

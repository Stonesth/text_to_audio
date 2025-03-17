@echo off
setlocal enabledelayedexpansion

:: Supprimer le dossier dist et mettre un message d'avertissement
if exist "%~dp0dist" (
    echo AVERTISSEMENT: Le dossier dist existe déjà et sera supprimé
    rmdir /s /q "%~dp0dist"
)

:: Configuration des fichiers de journalisation
set "LOG_DIR=%~dp0logs"
set "BUILD_LOG=%LOG_DIR%\build_exec.log"
set "BUILD_ERROR=%LOG_DIR%\build_exec_error.log"

:: Créer le répertoire de logs s'il n'existe pas
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: Effacer les fichiers de log existants
echo === RAPPORT DE COMPILATION PYINSTALLER === > "%BUILD_LOG%"
echo === ERREURS DE COMPILATION PYINSTALLER === > "%BUILD_ERROR%"

:: Obtenir la date et l'heure pour l'horodatage
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list') do set datetime=%%I
set TIMESTAMP=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2% %datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%

echo [%TIMESTAMP%] ===== COMPILATION DE L'EXÉCUTABLE =====
echo [%TIMESTAMP%] ===== COMPILATION DE L'EXÉCUTABLE ===== >> "%BUILD_LOG%"

:: Vérifier que l'environnement virtuel est activé
if not defined VIRTUAL_ENV (
    echo ERREUR: Environnement virtuel non activé >> "%BUILD_ERROR%"
    echo ERREUR: Environnement virtuel non activé
    echo Exécutez d'abord verify_env.bat
    exit /b 1
)

:: Obtenir nouvel horodatage
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list') do set datetime=%%I
set TIMESTAMP=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2% %datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%

:: Vérifier que les hooks existent
echo [%TIMESTAMP%] CHECKPOINT 1 - Vérification des hooks...
echo [%TIMESTAMP%] CHECKPOINT 1 - Vérification des hooks... >> "%BUILD_LOG%"

set "HOOKS_DIR=%~dp0hooks"
if not exist "%HOOKS_DIR%\hook-torch.py" (
    echo ERREUR: Les hooks n'ont pas été créés >> "%BUILD_ERROR%"
    echo ERREUR: Les hooks n'ont pas été créés
    echo Exécutez d'abord create_hooks.bat
    exit /b 1
) else (
    for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list') do set datetime=%%I
    set TIMESTAMP=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2% %datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%
    echo [%TIMESTAMP%]   Hooks trouvés avec succès dans %HOOKS_DIR%
    echo [%TIMESTAMP%]   Hooks trouvés avec succès dans %HOOKS_DIR% >> "%BUILD_LOG%"
)

:: Capturer les variables d'environnement importantes
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list') do set datetime=%%I
set TIMESTAMP=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2% %datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%
echo [%TIMESTAMP%] CHECKPOINT 2 - Capture des variables d'environnement...
echo [%TIMESTAMP%] CHECKPOINT 2 - Capture des variables d'environnement... >> "%BUILD_LOG%"

echo [%TIMESTAMP%]   Environnement virtuel: %VIRTUAL_ENV%
echo [%TIMESTAMP%]   Environnement virtuel: %VIRTUAL_ENV% >> "%BUILD_LOG%"
echo PYTHONPATH: %PYTHONPATH% >> "%BUILD_LOG%"
echo PATH: %PATH% >> "%BUILD_LOG%"
echo [%TIMESTAMP%]   Répertoire courant: %CD%
echo [%TIMESTAMP%]   Répertoire courant: %CD% >> "%BUILD_LOG%"

:: Construire le fichier spec et compiler l'exécutable
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list') do set datetime=%%I
set TIMESTAMP=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2% %datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%
echo [%TIMESTAMP%] CHECKPOINT 3 - Création du fichier spec et compilation de l'exécutable...
echo [%TIMESTAMP%] CHECKPOINT 3 - Création du fichier spec et compilation de l'exécutable... >> "%BUILD_LOG%"

:: Générer le fichier spec avec des options de débogage
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list') do set datetime=%%I
set TIMESTAMP=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2% %datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%
echo [%TIMESTAMP%]   Exécution de la commande PyInstaller...
echo [%TIMESTAMP%]   Exécution de la commande PyInstaller... >> "%BUILD_LOG%"

:: Vérifier que le fichier existe avant de continuer
if not exist "Simple_TTS_GUI.py" (
    echo ERREUR: Le fichier Simple_TTS_GUI.py n'existe pas dans le répertoire actuel >> "%BUILD_ERROR%"
    echo ERREUR: Le fichier Simple_TTS_GUI.py n'existe pas dans le répertoire actuel
    echo Répertoire actuel: %CD% >> "%BUILD_ERROR%"
    echo Contenu du répertoire: >> "%BUILD_ERROR%"
    dir *.py >> "%BUILD_ERROR%"
    dir *.py
    exit /b 1
) else (
    for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list') do set datetime=%%I
    set TIMESTAMP=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2% %datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%
    echo [%TIMESTAMP%]   Fichier Simple_TTS_GUI.py trouvé avec succès
    echo [%TIMESTAMP%]   Fichier Simple_TTS_GUI.py trouvé avec succès >> "%BUILD_LOG%"
)

:: Assurez-vous que le nom du script est le dernier argument de PyInstaller
echo Chemin complet du script: %~dp0Simple_TTS_GUI.py >> "%BUILD_LOG%"

:: Utiliser le chemin absolu du fichier Python et la syntaxe sans caractères spéciaux
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list') do set datetime=%%I
set TIMESTAMP=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2% %datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%
echo [%TIMESTAMP%]   Lancement de PyInstaller pour créer l'exécutable...
echo [%TIMESTAMP%]   Lancement de PyInstaller pour créer l'exécutable... >> "%BUILD_LOG%"
echo Cette étape peut prendre plusieurs minutes, veuillez patienter...

:: Exécuter PyInstaller directement avec toutes les options nécessaires
pyinstaller --name=Simple_TTS_GUI --noconsole --additional-hooks-dir="%HOOKS_DIR%" --log-level=DEBUG "%~dp0Simple_TTS_GUI.py" -y > "%TEMP%\pyinstaller_build.txt" 2>&1
set BUILD_RESULT=%ERRORLEVEL%

type "%TEMP%\pyinstaller_build.txt" >> "%BUILD_LOG%"
type "%TEMP%\pyinstaller_build.txt"
del "%TEMP%\pyinstaller_build.txt"

if %BUILD_RESULT% NEQ 0 (
    echo ERREUR: La compilation a échoué (code %BUILD_RESULT%) >> "%BUILD_ERROR%"
    echo ERREUR: La compilation a échoué (code %BUILD_RESULT%)
    echo Consultez les fichiers logs pour plus de détails.
    exit /b 1
) else (
    for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list') do set datetime=%%I
    set TIMESTAMP=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2% %datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%
    echo [%TIMESTAMP%]   Compilation réussie
    echo [%TIMESTAMP%]   Compilation réussie >> "%BUILD_LOG%"
)

:: Vérifier l'existence de l'exécutable
if not exist "dist\Simple_TTS_GUI\Simple_TTS_GUI.exe" (
    echo ERREUR: L'exécutable n'a pas été créé >> "%BUILD_ERROR%"
    echo ERREUR: L'exécutable n'a pas été créé
    echo Consultez les fichiers logs pour plus de détails.
    exit /b 1
) else (
    for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list') do set datetime=%%I
    set TIMESTAMP=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2% %datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%
    echo [%TIMESTAMP%]   L'exécutable a été créé avec succès
    echo [%TIMESTAMP%]   L'exécutable a été créé avec succès >> "%BUILD_LOG%"
)

echo.
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list') do set datetime=%%I
set TIMESTAMP=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2% %datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%
echo [%TIMESTAMP%] ===== COMPILATION TERMINÉE AVEC SUCCÈS =====
echo [%TIMESTAMP%] ===== COMPILATION TERMINÉE AVEC SUCCÈS ===== >> "%BUILD_LOG%"
echo L'exécutable a été créé avec succès: %~dp0dist\Simple_TTS_GUI\Simple_TTS_GUI.exe
echo Vous pouvez maintenant exécuter l'application depuis le répertoire dist\Simple_TTS_GUI
echo.

endlocal

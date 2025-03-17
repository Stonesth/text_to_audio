@echo off
setlocal enabledelayedexpansion

:: Configuration des fichiers de journalisation
set "LOG_DIR=%~dp0logs"
set "BUILD_LOG=%LOG_DIR%\build_exec.log"
set "BUILD_ERROR=%LOG_DIR%\build_exec_error.log"

:: Créer le répertoire de logs s'il n'existe pas
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: Effacer les fichiers de log existants
echo === RAPPORT DE COMPILATION PYINSTALLER === > "%BUILD_LOG%"
echo === ERREURS DE COMPILATION PYINSTALLER === > "%BUILD_ERROR%"

echo ===== COMPILATION DE L'EXÉCUTABLE =====
echo ===== COMPILATION DE L'EXÉCUTABLE ===== >> "%BUILD_LOG%"

:: Vérifier que l'environnement virtuel est activé
if not defined VIRTUAL_ENV (
    echo ERREUR: Environnement virtuel non activé >> "%BUILD_ERROR%"
    echo ERREUR: Environnement virtuel non activé
    echo Exécutez d'abord verify_env.bat
    exit /b 1
)

:: Vérifier que les hooks existent
echo CHECKPOINT 1 - Vérification des hooks... >> "%BUILD_LOG%"
echo CHECKPOINT 1 - Vérification des hooks...

set "HOOKS_DIR=%~dp0hooks"
if not exist "%HOOKS_DIR%\hook-torch.py" (
    echo ERREUR: Les hooks n'ont pas été créés >> "%BUILD_ERROR%"
    echo ERREUR: Les hooks n'ont pas été créés
    echo Exécutez d'abord create_hooks.bat
    exit /b 1
)

:: Capturer les variables d'environnement importantes
echo CHECKPOINT 2 - Capture des variables d'environnement... >> "%BUILD_LOG%"
echo CHECKPOINT 2 - Capture des variables d'environnement...

echo Environnement virtuel: %VIRTUAL_ENV% >> "%BUILD_LOG%"
echo PYTHONPATH: %PYTHONPATH% >> "%BUILD_LOG%"
echo PATH: %PATH% >> "%BUILD_LOG%"
echo Répertoire courant: %CD% >> "%BUILD_LOG%"

:: Construire le fichier spec
echo CHECKPOINT 3 - Création du fichier spec... >> "%BUILD_LOG%"
echo CHECKPOINT 3 - Création du fichier spec...

:: Générer le fichier spec avec des options de débogage
echo Exécution de la commande: pyinstaller --name="Simple_TTS_GUI" --noconsole --additional-hooks-dir="%HOOKS_DIR%" --paths="%~dp0" --paths="%VIRTUAL_ENV%\Lib\site-packages" "Simple_TTS_GUI.py" --log-level=DEBUG >> "%BUILD_LOG%"

:: Vérifier que le fichier existe avant de continuer
if not exist "Simple_TTS_GUI.py" (
    echo ERREUR: Le fichier Simple_TTS_GUI.py n'existe pas dans le répertoire actuel >> "%BUILD_ERROR%"
    echo ERREUR: Le fichier Simple_TTS_GUI.py n'existe pas dans le répertoire actuel
    echo Répertoire actuel: %CD% >> "%BUILD_ERROR%"
    echo Contenu du répertoire: >> "%BUILD_ERROR%"
    dir *.py >> "%BUILD_ERROR%"
    dir *.py
    exit /b 1
)

pyinstaller --name="Simple_TTS_GUI" --noconsole --additional-hooks-dir="%HOOKS_DIR%" --paths="%~dp0" --paths="%VIRTUAL_ENV%\Lib\site-packages" "Simple_TTS_GUI.py" --log-level=DEBUG > "%TEMP%\pyinstaller_spec.txt" 2>&1

if %ERRORLEVEL% NEQ 0 (
    echo ERREUR: Échec de création du fichier spec >> "%BUILD_ERROR%"
    echo ERREUR: Échec de création du fichier spec
    type "%TEMP%\pyinstaller_spec.txt" >> "%BUILD_ERROR%"
    type "%TEMP%\pyinstaller_spec.txt"
    del "%TEMP%\pyinstaller_spec.txt"
    exit /b 1
)
type "%TEMP%\pyinstaller_spec.txt" >> "%BUILD_LOG%"
del "%TEMP%\pyinstaller_spec.txt"

:: Vérifier que le fichier spec existe
if not exist "Simple_TTS_GUI.spec" (
    echo ERREUR: Le fichier spec n'a pas été créé >> "%BUILD_ERROR%"
    echo ERREUR: Le fichier spec n'a pas été créé
    exit /b 1
)

:: Modifier le fichier spec pour ajouter la gestion d'erreurs
echo CHECKPOINT 4 - Ajout de la gestion d'erreurs au fichier spec... >> "%BUILD_LOG%"
echo CHECKPOINT 4 - Ajout de la gestion d'erreurs au fichier spec...

:: Créer un fichier temporaire avec les modifications
echo import os, sys, traceback > "%TEMP%\spec_header.txt"
echo # Redirection des erreurs vers un fichier >> "%TEMP%\spec_header.txt"
echo error_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'logs', 'build_exec_error.log') >> "%TEMP%\spec_header.txt"
echo. >> "%TEMP%\spec_header.txt"
echo try: >> "%TEMP%\spec_header.txt"

echo except Exception as e: > "%TEMP%\spec_footer.txt"
echo     with open(error_file, 'a') as f: >> "%TEMP%\spec_footer.txt"
echo         f.write("\n\nERREUR CRITIQUE DANS LE FICHIER SPEC:\n") >> "%TEMP%\spec_footer.txt"
echo         f.write(str(e) + "\n") >> "%TEMP%\spec_footer.txt"
echo         f.write(traceback.format_exc()) >> "%TEMP%\spec_footer.txt"
echo     print("\nERREUR CRITIQUE DANS LE FICHIER SPEC") >> "%TEMP%\spec_footer.txt"
echo     print(str(e)) >> "%TEMP%\spec_footer.txt"
echo     print("Détails dans", error_file) >> "%TEMP%\spec_footer.txt"
echo     sys.exit(1) >> "%TEMP%\spec_footer.txt"

:: Combiner les fichiers
type "%TEMP%\spec_header.txt" > "%TEMP%\Simple_TTS_GUI.spec.new"
type "Simple_TTS_GUI.spec" >> "%TEMP%\Simple_TTS_GUI.spec.new"
type "%TEMP%\spec_footer.txt" >> "%TEMP%\Simple_TTS_GUI.spec.new"

:: Remplacer le fichier spec original
move /y "%TEMP%\Simple_TTS_GUI.spec.new" "Simple_TTS_GUI.spec" > nul
del "%TEMP%\spec_header.txt" "%TEMP%\spec_footer.txt"

echo Fichier spec modifié avec gestion d'erreurs >> "%BUILD_LOG%"

:: Compiler l'exécutable
echo CHECKPOINT 5 - Compilation de l'exécutable... >> "%BUILD_LOG%"
echo CHECKPOINT 5 - Compilation de l'exécutable...

pyinstaller --clean "Simple_TTS_GUI.spec" --log-level=DEBUG > "%TEMP%\pyinstaller_build.txt" 2>&1
set BUILD_RESULT=%ERRORLEVEL%

type "%TEMP%\pyinstaller_build.txt" >> "%BUILD_LOG%"
type "%TEMP%\pyinstaller_build.txt"
del "%TEMP%\pyinstaller_build.txt"

if %BUILD_RESULT% NEQ 0 (
    echo ERREUR: La compilation a échoué (code %BUILD_RESULT%) >> "%BUILD_ERROR%"
    echo ERREUR: La compilation a échoué (code %BUILD_RESULT%)
    echo Consultez les fichiers logs pour plus de détails.
    exit /b 1
)

:: Vérifier l'existence de l'exécutable
if not exist "dist\Simple_TTS_GUI\Simple_TTS_GUI.exe" (
    echo ERREUR: L'exécutable n'a pas été créé >> "%BUILD_ERROR%"
    echo ERREUR: L'exécutable n'a pas été créé
    echo Consultez les fichiers logs pour plus de détails.
    exit /b 1
)

echo.
echo ===== COMPILATION TERMINÉE AVEC SUCCÈS =====
echo ===== COMPILATION TERMINÉE AVEC SUCCÈS ===== >> "%BUILD_LOG%"
echo L'exécutable a été créé avec succès: %~dp0dist\Simple_TTS_GUI\Simple_TTS_GUI.exe
echo Vous pouvez maintenant exécuter l'application depuis le répertoire dist\Simple_TTS_GUI
echo.

endlocal

@echo off
setlocal enabledelayedexpansion

:: Configuration des fichiers de journalisation
set "LOG_DIR=%~dp0logs"
set "VERIFY_LOG=%LOG_DIR%\verify_env.log"
set "VERIFY_ERROR=%LOG_DIR%\verify_env_error.log"

:: Créer le répertoire de logs s'il n'existe pas
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: Effacer les fichiers de log existants
echo === RAPPORT DE VÉRIFICATION DE L'ENVIRONNEMENT === > "%VERIFY_LOG%"
echo === ERREURS DE VÉRIFICATION === > "%VERIFY_ERROR%"

echo ===== VÉRIFICATION DE L'ENVIRONNEMENT PYTHON =====
echo ===== VÉRIFICATION DE L'ENVIRONNEMENT PYTHON ===== >> "%VERIFY_LOG%"

:: CHECKPOINT 1 - Version Python
echo CHECKPOINT 1 - Vérification de la version Python...
echo CHECKPOINT 1 - Vérification de la version Python... >> "%VERIFY_LOG%"
python --version > "%TEMP%\python_version.txt" 2>&1
set /p PYTHON_VERSION=<"%TEMP%\python_version.txt"
type "%TEMP%\python_version.txt" >> "%VERIFY_LOG%"
del "%TEMP%\python_version.txt"

echo Version détectée: %PYTHON_VERSION% >> "%VERIFY_LOG%"
echo Version détectée: %PYTHON_VERSION%

echo %PYTHON_VERSION% | findstr "3.10" > nul
if %ERRORLEVEL% NEQ 0 (
    echo AVERTISSEMENT: Version Python non recommandée. Python 3.10 est recommandé. >> "%VERIFY_ERROR%"
    echo AVERTISSEMENT: Version Python non recommandée. Python 3.10 est recommandé.
    echo Continuer quand même? (O/N)
    set /p CONTINUE=
    if /i not "%CONTINUE%"=="O" (
        echo Opération annulée par l'utilisateur. >> "%VERIFY_LOG%"
        echo Opération annulée.
        exit /b 1
    )
)

:: CHECKPOINT 2 - Vérification de l'environnement virtuel
echo.
echo CHECKPOINT 2 - Vérification de l'environnement virtuel...
echo CHECKPOINT 2 - Vérification de l'environnement virtuel... >> "%VERIFY_LOG%"

set "VENV_PATH=%~dp0venv_py310"
echo Chemin environnement virtuel: %VENV_PATH% >> "%VERIFY_LOG%"
echo Chemin environnement virtuel: %VENV_PATH%

if not exist "%VENV_PATH%" (
    echo ERREUR: Environnement virtuel venv_py310 non trouvé >> "%VERIFY_ERROR%"
    echo ERREUR: Environnement virtuel non trouvé en %VENV_PATH%
    echo Veuillez créer l'environnement virtuel avec: python -m venv venv_py310
    exit /b 1
)

if not exist "%VENV_PATH%\Scripts\activate.bat" (
    echo ERREUR: Script d'activation non trouvé en %VENV_PATH%\Scripts\activate.bat >> "%VERIFY_ERROR%"
    echo ERREUR: Script d'activation non trouvé
    exit /b 1
)

:: Activation de l'environnement virtuel avec capture d'erreurs explicite
echo Tentative d'activation de l'environnement virtuel... >> "%VERIFY_LOG%"
echo Tentative d'activation de l'environnement virtuel...

:: Redirection complète de la sortie pour diagnostiquer le problème
echo.>>"%VERIFY_LOG%"
echo Commande exécutée: call "%VENV_PATH%\Scripts\activate.bat" >>"%VERIFY_LOG%"

:: Exécution avec redirection explicite des erreurs et de la sortie standard
call "%VENV_PATH%\Scripts\activate.bat" >"%TEMP%\venv_activation_out.txt" 2>"%TEMP%\venv_activation_err.txt"
set ACTIVATION_RESULT=%ERRORLEVEL%

:: Capture et journalisation des sorties
echo Code de retour: %ACTIVATION_RESULT% >>"%VERIFY_LOG%"
echo ---Sortie standard--- >>"%VERIFY_LOG%"
type "%TEMP%\venv_activation_out.txt" >>"%VERIFY_LOG%"
echo ---Erreurs--- >>"%VERIFY_LOG%"
type "%TEMP%\venv_activation_err.txt" >>"%VERIFY_LOG%"

del "%TEMP%\venv_activation_out.txt" "%TEMP%\venv_activation_err.txt"

if %ACTIVATION_RESULT% NEQ 0 (
    echo ERREUR: Échec d'activation de l'environnement virtuel >> "%VERIFY_ERROR%"
    echo ERREUR: Échec d'activation de l'environnement virtuel
    exit /b 1
)

if not defined VIRTUAL_ENV (
    echo ERREUR: Variable VIRTUAL_ENV non définie après activation >> "%VERIFY_ERROR%"
    echo ERREUR: Environnement virtuel non activé correctement
    exit /b 1
)

echo Environnement virtuel activé: %VIRTUAL_ENV% >> "%VERIFY_LOG%"
echo Environnement virtuel activé: %VIRTUAL_ENV%

:: CHECKPOINT 3 - Vérification des modules
echo.
echo CHECKPOINT 3 - Vérification des modules nécessaires...
echo CHECKPOINT 3 - Vérification des modules nécessaires... >> "%VERIFY_LOG%"

:: Script de vérification des modules
echo import sys, os, platform > "%TEMP%\check_modules.py"
echo from datetime import datetime >> "%TEMP%\check_modules.py"
echo print(f"Date et heure: {datetime.now()}") >> "%TEMP%\check_modules.py"
echo print(f"Python: {sys.version}") >> "%TEMP%\check_modules.py"
echo print(f"Environnement virtuel: {os.environ.get('VIRTUAL_ENV', 'Non défini')}") >> "%TEMP%\check_modules.py"
echo print(f"Plateforme: {platform.platform()}") >> "%TEMP%\check_modules.py"
echo. >> "%TEMP%\check_modules.py"
echo modules_requis = ['PyInstaller', 'PyQt6', 'PyQt6.sip', 'torch', 'TTS'] >> "%TEMP%\check_modules.py"
echo print("\nTest des modules requis:") >> "%TEMP%\check_modules.py"
echo erreurs = False >> "%TEMP%\check_modules.py"
echo. >> "%TEMP%\check_modules.py"
echo for module in modules_requis: >> "%TEMP%\check_modules.py"
echo     try: >> "%TEMP%\check_modules.py"
echo         exec(f"import {module}") >> "%TEMP%\check_modules.py"
echo         module_base = module.split('.')[0] >> "%TEMP%\check_modules.py"
echo         base_module = sys.modules[module_base] >> "%TEMP%\check_modules.py"
echo         version = getattr(base_module, '__version__', 'Inconnue') >> "%TEMP%\check_modules.py"
echo         path = getattr(base_module, '__file__', 'Inconnu') >> "%TEMP%\check_modules.py"
echo         print(f"  {module}: OK") >> "%TEMP%\check_modules.py"
echo         print(f"    Version: {version}") >> "%TEMP%\check_modules.py"
echo         print(f"    Chemin: {path}") >> "%TEMP%\check_modules.py"
echo     except Exception as e: >> "%TEMP%\check_modules.py"
echo         print(f"  {module}: ERREUR - {str(e)}") >> "%TEMP%\check_modules.py"
echo         erreurs = True >> "%TEMP%\check_modules.py"
echo. >> "%TEMP%\check_modules.py"
echo if erreurs: >> "%TEMP%\check_modules.py"
echo     print("\nDes erreurs ont été détectées avec les modules requis.") >> "%TEMP%\check_modules.py"
echo     print("\nChemin d'importation Python:") >> "%TEMP%\check_modules.py"
echo     for p in sys.path: >> "%TEMP%\check_modules.py"
echo         print(f"  {p}") >> "%TEMP%\check_modules.py"
echo     sys.exit(1) >> "%TEMP%\check_modules.py"
echo else: >> "%TEMP%\check_modules.py"
echo     print("\nTous les modules requis sont disponibles.") >> "%TEMP%\check_modules.py"
echo     sys.exit(0) >> "%TEMP%\check_modules.py"

:: Exécuter le script de vérification
python "%TEMP%\check_modules.py" > "%TEMP%\modules_check.txt" 2>&1
set MODULE_CHECK=%ERRORLEVEL%

type "%TEMP%\modules_check.txt" >> "%VERIFY_LOG%"
type "%TEMP%\modules_check.txt"
del "%TEMP%\check_modules.py"
del "%TEMP%\modules_check.txt"

if %MODULE_CHECK% NEQ 0 (
    echo ERREUR: Problèmes détectés avec les modules requis >> "%VERIFY_ERROR%"
    echo ERREUR: Problèmes détectés avec les modules requis
    echo Veuillez installer les modules manquants ou corriger les problèmes
    exit /b 1
)

:: CHECKPOINT 4 - Vérification de PyInstaller
echo.
echo CHECKPOINT 4 - Vérification de PyInstaller...
echo CHECKPOINT 4 - Vérification de PyInstaller... >> "%VERIFY_LOG%"

pip show pyinstaller > "%TEMP%\pyinstaller_info.txt" 2>&1
type "%TEMP%\pyinstaller_info.txt" >> "%VERIFY_LOG%"
type "%TEMP%\pyinstaller_info.txt"
del "%TEMP%\pyinstaller_info.txt"

where pyinstaller > "%TEMP%\pyinstaller_path.txt" 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERREUR: PyInstaller non trouvé dans le PATH >> "%VERIFY_ERROR%"
    echo ERREUR: PyInstaller non trouvé dans le PATH
    echo Veuillez installer PyInstaller: pip install pyinstaller
    exit /b 1
)
type "%TEMP%\pyinstaller_path.txt" >> "%VERIFY_LOG%"
echo PyInstaller est disponible: > nul
type "%TEMP%\pyinstaller_path.txt"
del "%TEMP%\pyinstaller_path.txt"

echo.
echo ===== VÉRIFICATION TERMINÉE AVEC SUCCÈS =====
echo ===== VÉRIFICATION TERMINÉE AVEC SUCCÈS ===== >> "%VERIFY_LOG%"
echo Tous les contrôles ont réussi. Vous pouvez maintenant exécuter create_hooks.bat
echo.

endlocal

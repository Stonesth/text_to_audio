@echo off
chcp 1252 > nul
setlocal enabledelayedexpansion

echo ===== MISE A JOUR DE NUMPY =====
echo Script de mise à jour de NumPy pour résoudre les incompatibilités avec PyTorch
echo Date et heure: %DATE% %TIME%
echo ==============================

REM Configuration de la journalisation
if not exist "logs" mkdir logs
set "LOG_FILE=%~dp0logs\update_numpy_log.txt"

REM Initialisation du fichier de log
echo ===== DEBUT MISE A JOUR NUMPY %DATE% %TIME% ===== > "!LOG_FILE!"

REM Fonction de journalisation
:log
echo [%DATE% %TIME%] [%~1] %~2 >> "!LOG_FILE!"
if "%~1"=="ERROR" (
    echo [ERREUR] %~2
) else if "%~1"=="WARNING" (
    echo [AVERTISSEMENT] %~2
) else if "%~1"=="SUCCESS" (
    echo [SUCCÈS] %~2
) else (
    echo [INFO] %~2
)
exit /b

REM Fonction d'exécution de commande avec journalisation
:exec_and_log
echo [%DATE% %TIME%] [COMMANDE] %~1 >> "!LOG_FILE!"
echo Exécution: %~1
%~1 >> "!LOG_FILE!" 2>&1
if !ERRORLEVEL! neq 0 (
    call :log ERROR "Échec de la commande: %~1"
    call :log ERROR "Code d'erreur: !ERRORLEVEL!"
) else (
    call :log SUCCESS "%~2 réussi"
)
exit /b !ERRORLEVEL!

REM Vérification de Python
call :log INFO "Vérification de l'installation Python..."
where python > nul 2>&1
if !ERRORLEVEL! neq 0 (
    call :log ERROR "Python n'est pas installé ou n'est pas dans le PATH"
    echo Python n'est pas installé ou n'est pas dans le PATH.
    echo Veuillez installer Python ou vérifier votre PATH.
    pause
    exit /b 1
)

REM Affichage de la version de Python
for /f "tokens=*" %%i in ('python --version 2^>^&1') do (
    set PYTHON_VERSION=%%i
)
call :log INFO "Version Python détectée: !PYTHON_VERSION!"
echo Version Python détectée: !PYTHON_VERSION!

REM Vérification de l'environnement virtuel
python -c "import sys; print('Environnement virtuel: ' + (sys.prefix if hasattr(sys, 'real_prefix') or sys.prefix != sys.base_prefix else 'Non'))" > "%TEMP%\venv_check.txt"
set /p VENV_STATUS=<"%TEMP%\venv_check.txt"
del "%TEMP%\venv_check.txt"
call :log INFO "!VENV_STATUS!"
echo !VENV_STATUS!

REM Vérification de la version actuelle de NumPy
call :log INFO "Vérification de la version actuelle de NumPy..."
python -c "import numpy; print('Version NumPy actuelle:', numpy.__version__)" > "%TEMP%\numpy_version.txt" 2>&1
if !ERRORLEVEL! neq 0 (
    call :log WARNING "NumPy n'est pas installé ou ne peut pas être importé"
    echo NumPy n'est pas installé ou ne peut pas être importé.
    set CURRENT_NUMPY_VERSION=Non installé
) else (
    set /p CURRENT_NUMPY_VERSION=<"%TEMP%\numpy_version.txt"
)
del "%TEMP%\numpy_version.txt" 2>nul
call :log INFO "!CURRENT_NUMPY_VERSION!"
echo !CURRENT_NUMPY_VERSION!

REM Mise à jour de NumPy
echo.
echo ==============================
echo Mise à jour de NumPy vers la version 1.24.3...
echo Cette version est compatible avec PyTorch et devrait résoudre les avertissements.
echo ==============================
echo.

REM Demande de confirmation
set /p CONFIRM=Voulez-vous continuer avec la mise à jour? (O/N): 
if /i "!CONFIRM!" neq "O" (
    call :log INFO "Mise à jour annulée par l'utilisateur"
    echo Mise à jour annulée.
    pause
    exit /b 0
)

REM Mise à jour de pip
call :log INFO "Mise à jour de pip..."
call :exec_and_log "python -m pip install --upgrade pip --no-cache-dir" "Mise à jour de pip"

REM Installation de NumPy 1.24.3
call :log INFO "Installation de NumPy 1.24.3..."
call :exec_and_log "python -m pip install numpy==1.24.3 --no-cache-dir" "Installation de NumPy 1.24.3"
if !ERRORLEVEL! neq 0 (
    call :log ERROR "Échec de l'installation de NumPy 1.24.3"
    echo.
    echo Échec de l'installation de NumPy 1.24.3.
    echo Veuillez vérifier les logs pour plus de détails: !LOG_FILE!
    pause
    exit /b 1
)

REM Vérification de la nouvelle version de NumPy
call :log INFO "Vérification de la nouvelle version de NumPy..."
python -c "import numpy; print('Nouvelle version NumPy:', numpy.__version__)" > "%TEMP%\numpy_new_version.txt" 2>&1
if !ERRORLEVEL! neq 0 (
    call :log ERROR "Impossible de vérifier la nouvelle version de NumPy"
    echo Impossible de vérifier la nouvelle version de NumPy.
) else (
    set /p NEW_NUMPY_VERSION=<"%TEMP%\numpy_new_version.txt"
    call :log SUCCESS "!NEW_NUMPY_VERSION!"
    echo !NEW_NUMPY_VERSION!
)
del "%TEMP%\numpy_new_version.txt" 2>nul

REM Fin du script
echo.
echo ==============================
echo Mise à jour terminée avec succès!
echo Vous pouvez maintenant lancer l'application sans les avertissements NumPy.
echo ==============================
echo.
call :log INFO "Mise à jour NumPy terminée"

pause
exit /b 0

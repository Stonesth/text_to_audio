@echo off
chcp 1252 > nul
setlocal enabledelayedexpansion

REM Configuration de la journalisation
if not exist "logs" mkdir logs
set "LOG_FILE=logs\setup_env_log.txt"
set "LOG_LEVEL=DEBUG"
set "DEBUG_MODE=0"

REM Initialisation du fichier de log
echo ===== DEBUT INSTALLATION %DATE% %TIME% ===== > "!LOG_FILE!"

REM ========== DÉBUT DU SCRIPT PRINCIPAL ==========

REM Gestion des paramètres
set "NO_REGISTRY=0"

for %%a in (%*) do (
    if "%%a"=="--no-registry" (
        set "NO_REGISTRY=1"
    )
    if "%%a"=="--debug" (
        set "DEBUG_MODE=1"
        set "LOG_LEVEL=DEBUG"
    )
)

if "%NO_REGISTRY%"=="1" (
    call :log INFO "[MODE SANS REGISTRE] Les modifications système seront désactivées"
)

if "%DEBUG_MODE%"=="1" (
    call :log INFO "Mode debug activé - Fichier log: !LOG_FILE!"
)

REM Sauvegarder le chemin système original
set "ORIGINAL_PATH=%PATH%"
call :log DEBUG "PATH initial: !PATH!"

REM Configuration des chemins sécurisés
call :log DEBUG "Configuration des chemins sécurisés"
set "PROGRAM_FILES=%ProgramFiles%"
if not defined PROGRAM_FILES set "PROGRAM_FILES=C:\Program Files"
set "PROGRAM_FILES_X86=%ProgramFiles(x86)%"
if not defined PROGRAM_FILES_X86 set "PROGRAM_FILES_X86=C:\Program Files (x86)"
call :log DEBUG "PROGRAM_FILES: !PROGRAM_FILES!"
call :log DEBUG "PROGRAM_FILES_X86: !PROGRAM_FILES_X86!"

REM Vérifications préliminaires
call :log INFO "Vérifications préliminaires..."
net session >nul 2>&1
if %errorLevel% == 0 (
    call :log ERROR "ATTENTION: Ne pas exécuter en mode administrateur"
    pause
    exit /b 1
)

REM Vérification de Python
call :log INFO "Vérification de Python..."
set "PYTHON_FOUND=0"

REM Recherche dans le répertoire des programmes
if exist "%PROGRAM_FILES%\Python310\python.exe" (
    set "PYTHON_PATH=%PROGRAM_FILES%\Python310"
    set "PYTHON_CMD=%PYTHON_PATH%\python.exe"
    set "PYTHON_FOUND=1"
    call :log INFO "Python trouvé dans !PYTHON_PATH!"
    call :exec_and_log ""!PYTHON_CMD!" --version" "Version Python"
)

REM Recherche dans le répertoire des programmes (x86)
if %PYTHON_FOUND% equ 0 (
    if exist "%PROGRAM_FILES_X86%\Python310\python.exe" (
        set "PYTHON_PATH=%PROGRAM_FILES_X86%\Python310"
        set "PYTHON_CMD=%PYTHON_PATH%\python.exe"
        set "PYTHON_FOUND=1"
        call :log INFO "Python trouvé dans !PYTHON_PATH!"
        call :exec_and_log ""!PYTHON_CMD!" --version" "Version Python"
    )
)

REM Recherche dans le répertoire utilisateur
if %PYTHON_FOUND% equ 0 (
    if exist "%LOCALAPPDATA%\Programs\Python\Python310\python.exe" (
        set "PYTHON_PATH=%LOCALAPPDATA%\Programs\Python\Python310"
        set "PYTHON_CMD=%PYTHON_PATH%\python.exe"
        set "PYTHON_FOUND=1"
        call :log INFO "Python trouvé dans !PYTHON_PATH!"
        call :exec_and_log ""!PYTHON_CMD!" --version" "Version Python"
    )
)

REM Recherche dans le PATH
if %PYTHON_FOUND% equ 0 (
    call :log INFO "Recherche de Python dans le PATH..."
    where python >nul 2>&1
    if %errorlevel% equ 0 (
        for /f "tokens=*" %%i in ('where python') do (
            set "PYTHON_CMD=%%i"
            for %%j in ("!PYTHON_CMD!") do set "PYTHON_PATH=%%~dpj"
            set "PYTHON_PATH=!PYTHON_PATH:~0,-1!"
            set "PYTHON_FOUND=1"
            call :log INFO "Python trouvé dans !PYTHON_PATH!"
            call :exec_and_log ""!PYTHON_CMD!" --version" "Version Python"
            goto :python_found
        )
    )
)

:python_found
if %PYTHON_FOUND% equ 0 (
    call :log ERROR "Python 3.10 non trouvé. Veuillez l'installer depuis https://www.python.org/downloads/"
    pause
    exit /b 1
)

REM Vérification de Visual Studio
call :log INFO "Vérification de Visual Studio..."
set "VS_FOUND=0"

REM Recherche de Visual Studio 2022
if exist "%PROGRAM_FILES%\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe" (
    set "VS_PATH=%PROGRAM_FILES%\Microsoft Visual Studio\2022\Community"
    set "VS_FOUND=1"
    call :log INFO "Visual Studio 2022 trouvé dans !VS_PATH!"
    call :exec_and_log "dir "!VS_PATH!\VC\Tools\MSVC" /b" "Versions MSVC disponibles"
)

REM Recherche de Visual Studio 2019
if %VS_FOUND% equ 0 (
    if exist "%PROGRAM_FILES%\Microsoft Visual Studio\2019\Community\Common7\IDE\devenv.exe" (
        set "VS_PATH=%PROGRAM_FILES%\Microsoft Visual Studio\2019\Community"
        set "VS_FOUND=1"
        call :log INFO "Visual Studio 2019 trouvé dans !VS_PATH!"
        call :exec_and_log "dir "!VS_PATH!\VC\Tools\MSVC" /b" "Versions MSVC disponibles"
    )
)

if %VS_FOUND% equ 0 (
    call :log WARNING "Visual Studio non trouvé. L'installation pourrait échouer."
    call :log INFO "Installation de Visual Studio Build Tools..."
    if not defined NO_REGISTRY (
        call :exec_and_log "winget install Microsoft.VisualStudio.2022.BuildTools --silent --override "--wait --quiet --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"" "Installation VS Build Tools"
    ) else (
        call :log INFO "Téléchargement manuel de Visual Studio Build Tools..."
        call :exec_and_log "curl -L -o "%TEMP%\vs_buildtools.exe" https://aka.ms/vs/17/release/vs_buildtools.exe" "Téléchargement VS Build Tools"
        call :exec_and_log ""%TEMP%\vs_buildtools.exe" --quiet --wait --norestart --nocache --installPath "%PROGRAM_FILES%\Microsoft Visual Studio\2022\BuildTools" --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended" "Installation VS Build Tools"
    )
)

REM Section Visual Studio modifiée
call :log DEBUG "Chemin Visual Studio: !VS_PATH!"

REM Configuration des chemins Visual Studio
if exist "!VS_PATH!\VC\Auxiliary\Build\vcvarsall.bat" (
    call :log INFO "Fichier vcvarsall.bat trouvé dans !VS_PATH!"
    call :exec_and_log "dir "!VS_PATH!\VC\Tools\MSVC" /b" "Versions MSVC disponibles"
    
    REM Trouver la dernière version de MSVC
    for /f "tokens=*" %%v in ('dir "!VS_PATH!\VC\Tools\MSVC" /b /ad /o-n') do (
        set "MSVC_VERSION=%%v"
        goto :found_msvc
    )
    
    :found_msvc
    call :log INFO "Version MSVC trouvée: !MSVC_VERSION!"
    set "MSVC_PATH=!VS_PATH!\VC\Tools\MSVC\!MSVC_VERSION!"
    call :log DEBUG "Chemin MSVC: !MSVC_PATH!"
    
    REM Configuration des variables d'environnement Visual Studio
    call :log INFO "Configuration des variables d'environnement Visual Studio..."
    call "!VS_PATH!\VC\Auxiliary\Build\vcvarsall.bat" x64 > "!LOG_FILE!.vs_vars" 2>&1
    type "!LOG_FILE!.vs_vars" >> "!LOG_FILE!"
    echo [%DATE% %TIME%] [COMMAND] Configuration vcvarsall - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"
) else (
    call :log WARNING "Fichier vcvarsall.bat non trouvé. Les variables d'environnement Visual Studio ne seront pas configurées."
)

REM Vérifications précise des composants requis
if not defined NO_REGISTRY (
    reg query "HKLM\SOFTWARE\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10 >nul 2>&1 || (
        call :log INFO "Installation du SDK Windows 10..."
        curl -L -o "%TEMP%\winsdksetup.exe" https://go.microsoft.com/fwlink/p/?LinkID=2033908
        "%TEMP%\winsdksetup.exe" /quiet /norestart
    )
) else (
    call :log INFO "Vérification du SDK Windows 10 ignorée en mode sans registre"
    if not exist "%PROGRAM_FILES_X86%\Windows Kits\10" (
        call :log INFO "Installation du SDK Windows 10..."
        curl -L -o "%TEMP%\winsdksetup.exe" https://go.microsoft.com/fwlink/p/?LinkID=2033908
        "%TEMP%\winsdksetup.exe" /quiet /norestart
    )
)

REM Configuration précise des chemins SDK
call :log DEBUG "Configuration des chemins SDK Windows"
set "WindowsSdkDir=%PROGRAM_FILES_X86%\Windows Kits\10"
set "WindowsSdkVerBinPath=%WindowsSdkDir%\bin\10.0.19041.0\x64"
set "PATH=%WindowsSdkVerBinPath%;%PATH%"
call :log DEBUG "WindowsSdkDir: %WindowsSdkDir%"
call :log DEBUG "WindowsSdkVerBinPath: %WindowsSdkVerBinPath%"

REM Vérification des redistribuables Visual C++
call :log INFO "Vérification des redistribuables VC++..."
if not exist "%PROGRAM_FILES_X86%\Microsoft Visual C++ Redistributable for Visual Studio 2022" (
    call :log INFO "Installation des redistribuables VC++..."
    call :exec_and_log "curl -L -o "%TEMP%\vc_redist.x64.exe" https://aka.ms/vs/17/release/vc_redist.x64.exe" "Téléchargement VC++ Redist"
    call :exec_and_log ""%TEMP%\vc_redist.x64.exe" /quiet /norestart" "Installation VC++ Redist"
) else (
    call :log INFO "Les redistribuables VC++ sont déjà installés"
)

REM Vérification des en-têtes système Windows
call :log INFO "Vérification des en-têtes système Windows..."
if not exist "%PROGRAM_FILES_X86%\Windows Kits\10\Include\10.0.19041.0\um\windows.h" (
    call :log INFO "Installation des en-têtes système manquants..."
    if not defined NO_REGISTRY (
        call :exec_and_log "winget install --id Microsoft.WindowsSDK --version 10.0.19041.0 --silent" "Installation SDK Windows via winget"
    ) else (
        call :log INFO "Téléchargement manuel du SDK Windows..."
        call :exec_and_log "curl -L -o "%TEMP%\winsdksetup.exe" https://go.microsoft.com/fwlink/p/?LinkID=2033908" "Téléchargement SDK Windows"
        call :exec_and_log ""%TEMP%\winsdksetup.exe" /quiet /norestart" "Installation SDK Windows"
    )
    if %errorlevel% neq 0 (
        call :log ERROR "Erreur lors de l'installation des en-têtes système"
        exit /b 1
    )
    call :log INFO "Installation terminée"
) else (
    call :log INFO "Les en-têtes système sont déjà installés"
)

REM Détection du SDK Windows 10
set "SDK_ROOT=%PROGRAM_FILES_X86%\Windows Kits\10"
if exist "!SDK_ROOT!" (
    call :log INFO "SDK Windows 10 trouvé dans !SDK_ROOT!"
    dir "!SDK_ROOT!\Include" /b >> "!LOG_FILE!" 2>&1
    echo [%DATE% %TIME%] [COMMAND] Versions SDK disponibles - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"
) else (
    call :log WARNING "SDK Windows 10 non trouvé"
)

REM Installation des dépendances système
REM curl -L -o "%TEMP%\vc_redist.x64.exe" https://aka.ms/vs/17/release/vc_redist.x64.exe
REM "%TEMP%\vc_redist.x64.exe" /quiet /norestart

REM Nettoyage et configuration de l'environnement
call :log DEBUG "Configuration de l'environnement de développement"
set "INCLUDE="
set "LIB="
set "PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem"
set "PATH=%PYTHON_PATH%;%PYTHON_PATH%\Scripts;%PATH%"
set "VS_PATH=%PROGRAM_FILES%\Microsoft Visual Studio\2022\Community"
set "MSVC_VERSION="

REM Trouver la version MSVC
call :log DEBUG "Recherche de la version MSVC"
for /d %%i in ("%VS_PATH%\VC\Tools\MSVC\*") do (
    set "MSVC_VERSION=%%~nxi"
    call :log DEBUG "Version MSVC trouvée: %%~nxi"
)

REM Configuration des chemins Visual Studio
set "MSVC_PATH=%VS_PATH%\VC\Tools\MSVC"
for /f "delims=" %%i in ('dir /b /ad "%MSVC_PATH%"') do set "MSVC_VERSION=%%i"
set "MSVC_FULL=%MSVC_PATH%\%MSVC_VERSION%"

REM Configuration des includes sans duplication
set "INCLUDE=%MSVC_FULL%\include"
set "INCLUDE=%INCLUDE%;%VS_PATH%\VC\Auxiliary\VS\include"
set "INCLUDE=%INCLUDE%;%MSVC_FULL%\ATLMFC\include"
set "INCLUDE=%INCLUDE%;%WindowsSdkDir%\Include\10.0.19041.0\ucrt"
set "INCLUDE=%INCLUDE%;%WindowsSdkDir%\Include\10.0.19041.0\um"
set "INCLUDE=%INCLUDE%;%WindowsSdkDir%\Include\10.0.19041.0\shared"

REM Configuration des bibliothèques
set "LIB=%MSVC_FULL%\lib\x64"
set "LIB=%LIB%;%MSVC_FULL%\ATLMFC\lib\x64"
set "LIB=%LIB%;%WindowsSdkDir%\Lib\10.0.19041.0\ucrt\x64"
set "LIB=%LIB%;%WindowsSdkDir%\Lib\10.0.19041.0\um\x64"

REM Configuration de l'environnement de build
set DISTUTILS_USE_SDK=1
set MSSdk=1
set "CL=/MP"

REM Appeler vcvarsall.bat et restaurer le chemin Python
call :log DEBUG "Appel de vcvarsall.bat"
if exist "!VS_PATH!\VC\Auxiliary\Build\vcvars64.bat" (
    call :log DEBUG "Exécution de !VS_PATH!\VC\Auxiliary\Build\vcvars64.bat"
    call "!VS_PATH!\VC\Auxiliary\Build\vcvars64.bat" > "!LOG_FILE!.vs_vars64" 2>&1
    type "!LOG_FILE!.vs_vars64" >> "!LOG_FILE!"
    echo [%DATE% %TIME%] [COMMAND] Configuration vcvars64 - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"
) else (
    call :log WARNING "[AVERTISSEMENT] Fichier vcvars64.bat non trouvé"
    call :log DEBUG "Chemin recherché: !VS_PATH!\VC\Auxiliary\Build\vcvars64.bat"
)
set "PATH=!PYTHON_PATH!;!PYTHON_PATH!\Scripts;%PATH%"
call :log DEBUG "PATH après configuration: !PATH!"

REM Installation des dépendances système
REM curl -L -o "%TEMP%\vc_redist.x64.exe" https://aka.ms/vs/17/release/vc_redist.x64.exe
REM "%TEMP%\vc_redist.x64.exe" /quiet /norestart

REM Fonction pour exécuter une commande et enregistrer sa sortie dans le fichier de log
:exec_and_log
set "CMD_TO_RUN=%~1"
set "LOG_PREFIX=%~2"
call :log DEBUG "Exécution: !CMD_TO_RUN!"
echo [%DATE% %TIME%] [COMMAND] !LOG_PREFIX! - Début d'exécution >> "!LOG_FILE!"
!CMD_TO_RUN! >> "!LOG_FILE!" 2>&1
set LAST_ERROR=%ERRORLEVEL%
echo [%DATE% %TIME%] [COMMAND] !LOG_PREFIX! - Fin d'exécution (code: !LAST_ERROR!) >> "!LOG_FILE!"
exit /b !LAST_ERROR!

REM Création de l'environnement virtuel
call :log INFO "Création de l'environnement virtuel..."
call :log DEBUG "Suppression de l'environnement virtuel existant si présent"
if exist venv_py310 rmdir /s /q venv_py310
call :log DEBUG "Création d'un nouvel environnement virtuel avec !PYTHON_CMD!"
"!PYTHON_CMD!" -m venv venv_py310 >> "!LOG_FILE!" 2>&1
echo [%DATE% %TIME%] [COMMAND] Création environnement virtuel - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"

REM Activation de l'environnement virtuel
call :log INFO "Activation de l'environnement virtuel..."
call "venv_py310\Scripts\activate.bat"
call :log DEBUG "Vérification de l'activation"
"!PYTHON_CMD!" -c "import sys; print('Environnement virtuel actif:', sys.prefix)" >> "!LOG_FILE!" 2>&1
echo [%DATE% %TIME%] [COMMAND] Vérification environnement - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"

REM Installation des dépendances de base
call :log INFO "Installation des dépendances de base..."
"!PYTHON_CMD!" -m pip install --upgrade pip setuptools wheel >> "!LOG_FILE!" 2>&1
echo [%DATE% %TIME%] [COMMAND] Installation pip/setuptools/wheel - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"

REM Installation des dépendances TTS
call :log INFO "Installation des dépendances principales..."
"!PYTHON_CMD!" -m pip install numpy==1.24.3 --no-cache-dir >> "!LOG_FILE!" 2>&1
echo [%DATE% %TIME%] [COMMAND] Installation numpy - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"

"!PYTHON_CMD!" -m pip install torch==2.1.0+cpu --index-url https://download.pytorch.org/whl/cpu --no-cache-dir >> "!LOG_FILE!" 2>&1
echo [%DATE% %TIME%] [COMMAND] Installation torch - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"

"!PYTHON_CMD!" -m pip install tqdm==4.65.0 --no-cache-dir >> "!LOG_FILE!" 2>&1
echo [%DATE% %TIME%] [COMMAND] Installation tqdm - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"

REM Installation de TTS avec toutes les dépendances
call :log INFO "Installation de TTS..."
"!PYTHON_CMD!" -m pip install TTS --no-cache-dir >> "!LOG_FILE!" 2>&1
echo [%DATE% %TIME%] [COMMAND] Installation TTS - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"

REM Installation de PyQt6
call :log INFO "Installation de PyQt6..."
"!PYTHON_CMD!" -m pip install PyQt6==6.4.2 --no-cache-dir >> "!LOG_FILE!" 2>&1
echo [%DATE% %TIME%] [COMMAND] Installation PyQt6 - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"

REM Installation de pyinstaller
call :log INFO "Installation de pyinstaller..."
"!PYTHON_CMD!" -m pip install pyinstaller==6.3.0 --no-cache-dir >> "!LOG_FILE!" 2>&1
echo [%DATE% %TIME%] [COMMAND] Installation pyinstaller - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"

REM Vérification de l'installation
call :log INFO "Vérification de l'installation..."
set VERIFICATION_ERROR=0

"!PYTHON_CMD!" -c "import numpy; print('numpy', numpy.__version__)" >> "!LOG_FILE!" 2>&1
set NUMPY_ERROR=%ERRORLEVEL%
echo [%DATE% %TIME%] [COMMAND] Vérification numpy - Fin d'exécution (code: !NUMPY_ERROR!) >> "!LOG_FILE!"
if !NUMPY_ERROR! neq 0 set VERIFICATION_ERROR=1

"!PYTHON_CMD!" -c "import torch; print('torch', torch.__version__)" >> "!LOG_FILE!" 2>&1
set TORCH_ERROR=%ERRORLEVEL%
echo [%DATE% %TIME%] [COMMAND] Vérification torch - Fin d'exécution (code: !TORCH_ERROR!) >> "!LOG_FILE!"
if !TORCH_ERROR! neq 0 set VERIFICATION_ERROR=1

"!PYTHON_CMD!" -c "import TTS; print('TTS OK')" >> "!LOG_FILE!" 2>&1
set TTS_ERROR=%ERRORLEVEL%
echo [%DATE% %TIME%] [COMMAND] Vérification TTS - Fin d'exécution (code: !TTS_ERROR!) >> "!LOG_FILE!"
if !TTS_ERROR! neq 0 set VERIFICATION_ERROR=1

"!PYTHON_CMD!" -c "from PyQt6.QtWidgets import QApplication; print('PyQt6 OK')" >> "!LOG_FILE!" 2>&1
set PYQT_ERROR=%ERRORLEVEL%
echo [%DATE% %TIME%] [COMMAND] Vérification PyQt6 - Fin d'exécution (code: !PYQT_ERROR!) >> "!LOG_FILE!"
if !PYQT_ERROR! neq 0 set VERIFICATION_ERROR=1

if !VERIFICATION_ERROR! equ 1 (
    call :log ERROR "ATTENTION: Installation incomplète"
    call :log INFO "Consultez TROUBLESHOOTING.md pour les solutions"
) else (
    call :log INFO "Installation réussie!"
    call :log INFO "Pour utiliser:"
    call :log INFO "call .\venv_py310\Scripts\activate.bat"
    call :log INFO "python Simple_TTS_GUI.py"
)

REM Mise à jour finale du PATH
call :log DEBUG "Mise à jour finale du PATH"
call :log DEBUG "PATH actuel: !PATH!"
if not defined NO_REGISTRY (
    call :log DEBUG "Tentative de mise à jour du PATH système avec setx"
    setx PATH "!PATH!" /M >nul 2>&1 || (
        call :log WARNING "[AVERTISSEMENT] Impossible de mettre à jour le PATH système"
        call :log INFO "Ajoutez manuellement ces chemins à votre PATH :"
        call :log INFO "!PYTHON_PATH!"
        call :log INFO "!VS_PATH!\VC\Tools\MSVC\!MSVC_VERSION!\bin\Hostx64\x64"
    )
) else (
    call :log INFO "Configuration manuelle requise :"
    call :log INFO "Ajoutez ces chemins à votre PATH :"
    call :log INFO "!PYTHON_PATH!"
    call :log INFO "!VS_PATH!\VC\Tools\MSVC\!MSVC_VERSION!\bin\Hostx64\x64"
)

call :log INFO "Installation terminée"
call :log INFO "Fichier log disponible: !LOG_FILE!"
call :log DEBUG "PATH final: !PATH!"
pause
goto :EOF

REM ========== FONCTIONS ==========
:log
set "LOG_TYPE=%~1"
set "LOG_MESSAGE=%~2"
set "LOG_LINE=[%DATE% %TIME%] [%LOG_TYPE%] %LOG_MESSAGE%"

REM Écriture dans le fichier log
echo !LOG_LINE! >> "!LOG_FILE!"

REM Affichage selon le niveau de verbosité
if "%LOG_TYPE%"=="ERROR" (
    echo !LOG_MESSAGE!
    goto :eof
)
if "%LOG_TYPE%"=="WARNING" (
    echo !LOG_MESSAGE!
    goto :eof
)
if "%LOG_TYPE%"=="INFO" (
    echo !LOG_MESSAGE!
    goto :eof
)
if "%LOG_TYPE%"=="DEBUG" (
    if "%LOG_LEVEL%"=="DEBUG" (
        echo !LOG_MESSAGE!
    )
    goto :eof
)
goto :eof
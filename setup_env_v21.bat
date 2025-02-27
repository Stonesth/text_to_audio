@echo off
setlocal EnableDelayedExpansion

REM ===== Configuration initiale =====
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

REM Vérification des arguments
set NO_REGISTRY=0
set DEBUG=0

:parse_args
if "%1"=="" goto :end_parse_args
if "%1"=="--no-registry" (
    set NO_REGISTRY=1
    shift
    goto :parse_args
)
if "%1"=="--debug" (
    set DEBUG=1
    shift
    goto :parse_args
)
:end_parse_args

REM Création du dossier logs s'il n'existe pas
if not exist "logs" mkdir logs
set "LOG_FILE=%SCRIPT_DIR%logs\setup_env_log.txt"

REM Initialisation du fichier de log
echo ===== DEBUT INSTALLATION %DATE% %TIME% ===== > "!LOG_FILE!"

if %NO_REGISTRY% equ 1 (
    call :log INFO "[MODE SANS REGISTRE] Les modifications système seront désactivées"
)

if %DEBUG% equ 1 (
    call :log INFO "Mode debug activé - Fichier log: !LOG_FILE!"
    call :log DEBUG "PATH initial: %PATH%"
)

REM Configuration de la journalisation
set "LOG_LEVEL=DEBUG"

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
    "!PYTHON_CMD!" --version >> "!LOG_FILE!" 2>&1
    echo [%DATE% %TIME%] [COMMAND] Version Python - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"
)

REM Recherche dans le répertoire des programmes (x86)
if %PYTHON_FOUND% equ 0 (
    if exist "%PROGRAM_FILES_X86%\Python310\python.exe" (
        set "PYTHON_PATH=%PROGRAM_FILES_X86%\Python310"
        set "PYTHON_CMD=%PYTHON_PATH%\python.exe"
        set "PYTHON_FOUND=1"
        call :log INFO "Python trouvé dans !PYTHON_PATH!"
        "!PYTHON_CMD!" --version >> "!LOG_FILE!" 2>&1
        echo [%DATE% %TIME%] [COMMAND] Version Python - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"
    )
)

REM Recherche dans le répertoire utilisateur
if %PYTHON_FOUND% equ 0 (
    if exist "%LOCALAPPDATA%\Programs\Python\Python310\python.exe" (
        set "PYTHON_PATH=%LOCALAPPDATA%\Programs\Python\Python310"
        set "PYTHON_CMD=%PYTHON_PATH%\python.exe"
        set "PYTHON_FOUND=1"
        call :log INFO "Python trouvé dans !PYTHON_PATH!"
        "!PYTHON_CMD!" --version >> "!LOG_FILE!" 2>&1
        echo [%DATE% %TIME%] [COMMAND] Version Python - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"
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
            "!PYTHON_CMD!" --version >> "!LOG_FILE!" 2>&1
            echo [%DATE% %TIME%] [COMMAND] Version Python - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"
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
    dir "!VS_PATH!\VC\Tools\MSVC" /b >> "!LOG_FILE!" 2>&1
    echo [%DATE% %TIME%] [COMMAND] Versions MSVC disponibles - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"
)

REM Recherche de Visual Studio 2019
if %VS_FOUND% equ 0 (
    if exist "%PROGRAM_FILES%\Microsoft Visual Studio\2019\Community\Common7\IDE\devenv.exe" (
        set "VS_PATH=%PROGRAM_FILES%\Microsoft Visual Studio\2019\Community"
        set "VS_FOUND=1"
        call :log INFO "Visual Studio 2019 trouvé dans !VS_PATH!"
        dir "!VS_PATH!\VC\Tools\MSVC" /b >> "!LOG_FILE!" 2>&1
        echo [%DATE% %TIME%] [COMMAND] Versions MSVC disponibles - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"
    )
)

if %VS_FOUND% equ 0 (
    call :log WARNING "Visual Studio non trouvé. L'installation pourrait échouer."
    call :log INFO "Installation de Visual Studio Build Tools..."
    if not defined NO_REGISTRY (
        call :log INFO "Installation VS Build Tools..."
        call "!VS_PATH!\VC\Auxiliary\Build\vcvarsall.bat" x64 > "!LOG_FILE!.vs_vars" 2>&1
        type "!LOG_FILE!.vs_vars" >> "!LOG_FILE!"
        echo [%DATE% %TIME%] [COMMAND] Configuration vcvarsall - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"
    ) else (
        call :log INFO "Téléchargement manuel de Visual Studio Build Tools..."
        call :log INFO "Installation VS Build Tools..."
        call "!VS_PATH!\VC\Auxiliary\Build\vcvarsall.bat" x64 > "!LOG_FILE!.vs_vars" 2>&1
        type "!LOG_FILE!.vs_vars" >> "!LOG_FILE!"
        echo [%DATE% %TIME%] [COMMAND] Configuration vcvarsall - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"
    )
)

REM Section Visual Studio modifiée
call :log DEBUG "Chemin Visual Studio: !VS_PATH!"

REM Configuration des chemins Visual Studio
if exist "!VS_PATH!\VC\Auxiliary\Build\vcvarsall.bat" (
    call :log INFO "Fichier vcvarsall.bat trouvé dans !VS_PATH!"
    dir "!VS_PATH!\VC\Tools\MSVC" /b >> "!LOG_FILE!" 2>&1
    echo [%DATE% %TIME%] [COMMAND] Versions MSVC disponibles - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"
    
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
        curl -L -o "%TEMP%\winsdksetup.exe" https://go.microsoft.com/fwlink/p/?LinkID=2033908 >> "!LOG_FILE!" 2>&1
        echo [%DATE% %TIME%] [COMMAND] Téléchargement SDK Windows - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"
        "%TEMP%\winsdksetup.exe" /quiet /norestart >> "!LOG_FILE!" 2>&1
        echo [%DATE% %TIME%] [COMMAND] Installation SDK Windows - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"
    )
) else (
    call :log INFO "Vérification du SDK Windows 10 ignorée en mode sans registre"
    if not exist "%PROGRAM_FILES_X86%\Windows Kits\10" (
        call :log INFO "Installation du SDK Windows 10..."
        curl -L -o "%TEMP%\winsdksetup.exe" https://go.microsoft.com/fwlink/p/?LinkID=2033908 >> "!LOG_FILE!" 2>&1
        echo [%DATE% %TIME%] [COMMAND] Téléchargement SDK Windows - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"
        "%TEMP%\winsdksetup.exe" /quiet /norestart >> "!LOG_FILE!" 2>&1
        echo [%DATE% %TIME%] [COMMAND] Installation SDK Windows - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"
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
    curl -L -o "%TEMP%\vc_redist.x64.exe" https://aka.ms/vs/17/release/vc_redist.x64.exe >> "!LOG_FILE!" 2>&1
    echo [%DATE% %TIME%] [COMMAND] Téléchargement VC++ Redist - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"
    "%TEMP%\vc_redist.x64.exe" /quiet /norestart >> "!LOG_FILE!" 2>&1
    echo [%DATE% %TIME%] [COMMAND] Installation VC++ Redist - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"
) else (
    call :log INFO "Les redistribuables VC++ sont déjà installés"
)

REM Vérification des en-têtes système Windows
call :log INFO "Vérification des en-têtes système Windows..."
if not exist "%PROGRAM_FILES_X86%\Windows Kits\10\Include\10.0.19041.0\um\windows.h" (
    call :log INFO "Installation des en-têtes système manquants..."
    if not defined NO_REGISTRY (
        call :log INFO "Installation SDK Windows via winget..."
    ) else (
        call :log INFO "Téléchargement manuel du SDK Windows..."
        call :log INFO "Installation SDK Windows..."
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

REM Fonction pour exécuter une commande et enregistrer sa sortie dans le fichier de log
:exec_and_log
set "CMD=%~1"
set "DESC=%~2"

call :log COMMAND "%DESC% - Début d'exécution"
%CMD% >> "!LOG_FILE!" 2>&1
set "ERROR_CODE=%ERRORLEVEL%"
call :log COMMAND "%DESC% - Fin d'exécution (code: %ERROR_CODE%)"

if %ERROR_CODE% neq 0 (
    call :log ERROR "Erreur lors de l'exécution de la commande: %DESC% (code: %ERROR_CODE%)"
)

exit /b %ERROR_CODE%

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

REM Vérification du SDK Windows 10
if not defined NO_REGISTRY (
    call :log INFO "Vérification du SDK Windows 10..."
    
    REM Vérifier si le SDK Windows 10 est installé
    if exist "%PROGRAM_FILES_X86%\Windows Kits\10" (
        call :log INFO "SDK Windows 10 trouvé dans %PROGRAM_FILES_X86%\Windows Kits\10"
        dir "%PROGRAM_FILES_X86%\Windows Kits\10\Include" /b >> "!LOG_FILE!" 2>&1
        echo [%DATE% %TIME%] [COMMAND] Versions SDK disponibles - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"
    ) else (
        call :log WARNING "SDK Windows 10 non trouvé"
        call :log INFO "Installation du SDK Windows 10..."
        
        REM Télécharger et installer le SDK Windows 10
        curl -L -o "%TEMP%\winsdksetup.exe" https://go.microsoft.com/fwlink/p/?LinkID=2033908 >> "!LOG_FILE!" 2>&1
        echo [%DATE% %TIME%] [COMMAND] Téléchargement SDK Windows - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"
        
        "%TEMP%\winsdksetup.exe" /quiet /norestart /features OptionId.WindowsDesktopDebuggers OptionId.WindowsSoftwareDevelopmentKit >> "!LOG_FILE!" 2>&1
        echo [%DATE% %TIME%] [COMMAND] Installation SDK Windows - Fin d'exécution (code: %ERRORLEVEL%) >> "!LOG_FILE!"
    )
) else (
    call :log INFO "Vérification du SDK Windows 10 ignorée en mode sans registre"
)

REM Création de l'environnement virtuel
call :log INFO "Création de l'environnement virtuel..."
call :log DEBUG "Suppression de l'environnement virtuel existant si présent"
if exist venv_py310 rmdir /s /q venv_py310
call :log DEBUG "Création d'un nouvel environnement virtuel avec !PYTHON_CMD!"
call :exec_and_log ""!PYTHON_CMD!" -m venv venv_py310" "Création environnement virtuel"

REM Activation de l'environnement virtuel
call :log INFO "Activation de l'environnement virtuel..."
call venv_py310\Scripts\activate.bat
set "PYTHON_CMD=venv_py310\Scripts\python.exe"
call :log DEBUG "Vérification de l'activation"
call :exec_and_log ""!PYTHON_CMD!" -c "import sys; print('Environnement virtuel actif:', sys.prefix)"" "Vérification environnement"

REM Installation des dépendances de base
call :log INFO "Installation des dépendances de base..."
call :exec_and_log ""!PYTHON_CMD!" -m pip install --upgrade pip setuptools wheel" "Installation pip/setuptools/wheel"

REM Installation des dépendances TTS
call :log INFO "Installation des dépendances principales..."

REM Installation de numpy
call :log INFO "Installation de numpy..."
call :exec_and_log ""!PYTHON_CMD!" -m pip install numpy==1.24.3 --no-cache-dir" "Installation numpy"
set NUMPY_INSTALL_ERROR=%ERRORLEVEL%

REM Installation de torch
call :log INFO "Installation de torch..."
call :exec_and_log ""!PYTHON_CMD!" -m pip install torch==2.1.0+cpu --index-url https://download.pytorch.org/whl/cpu --no-cache-dir" "Installation torch"
set TORCH_INSTALL_ERROR=%ERRORLEVEL%

REM Installation de tqdm
call :log INFO "Installation de tqdm..."
call :exec_and_log ""!PYTHON_CMD!" -m pip install tqdm==4.65.0 --no-cache-dir" "Installation tqdm"
set TQDM_INSTALL_ERROR=%ERRORLEVEL%

REM Installation de TTS avec toutes les dépendances
call :log INFO "Installation de TTS..."
call :exec_and_log ""!PYTHON_CMD!" -m pip install TTS --no-cache-dir" "Installation TTS"
set TTS_INSTALL_ERROR=%ERRORLEVEL%

REM Installation de PyQt6
call :log INFO "Installation de PyQt6..."
call :exec_and_log ""!PYTHON_CMD!" -m pip install PyQt6==6.4.2 --no-cache-dir" "Installation PyQt6"
set PYQT_INSTALL_ERROR=%ERRORLEVEL%

REM Installation de pyinstaller
call :log INFO "Installation de pyinstaller..."
call :exec_and_log ""!PYTHON_CMD!" -m pip install pyinstaller==6.3.0 --no-cache-dir" "Installation pyinstaller"
set PYINSTALLER_INSTALL_ERROR=%ERRORLEVEL%

REM Vérification de l'installation
call :log INFO "Vérification de l'installation..."
set VERIFICATION_ERROR=0

REM Vérification de numpy
call :exec_and_log ""!PYTHON_CMD!" -c "import numpy; print('numpy', numpy.__version__)"" "Vérification numpy"
set NUMPY_ERROR=%ERRORLEVEL%
if !NUMPY_ERROR! neq 0 (
    set VERIFICATION_ERROR=1
    call :log ERROR "Erreur lors de la vérification de numpy"
)

REM Vérification de torch
call :exec_and_log ""!PYTHON_CMD!" -c "import torch; print('torch', torch.__version__)"" "Vérification torch"
set TORCH_ERROR=%ERRORLEVEL%
if !TORCH_ERROR! neq 0 (
    set VERIFICATION_ERROR=1
    call :log ERROR "Erreur lors de la vérification de torch"
)

REM Vérification de TTS
call :exec_and_log ""!PYTHON_CMD!" -c "import TTS; print('TTS OK')"" "Vérification TTS"
set TTS_ERROR=%ERRORLEVEL%
if !TTS_ERROR! neq 0 (
    set VERIFICATION_ERROR=1
    call :log ERROR "Erreur lors de la vérification de TTS"
)

REM Vérification de PyQt6
call :exec_and_log ""!PYTHON_CMD!" -c "from PyQt6.QtWidgets import QApplication; print('PyQt6 OK')"" "Vérification PyQt6"
set PYQT_ERROR=%ERRORLEVEL%
if !PYQT_ERROR! neq 0 (
    set VERIFICATION_ERROR=1
    call :log ERROR "Erreur lors de la vérification de PyQt6"
)

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
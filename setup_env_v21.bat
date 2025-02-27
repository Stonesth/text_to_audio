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

REM Trouver Python 3.10
call :log INFO "Recherche de Python 3.10..."
set PYTHON_PATH=
set PYTHON_CMD=

REM Vérifier dans Program Files
if exist "%PROGRAM_FILES%\Python310\python.exe" (
    set "PYTHON_PATH=%PROGRAM_FILES%\Python310"
    set "PYTHON_CMD=%PROGRAM_FILES%\Python310\python.exe"
    call :log DEBUG "Chemin Python trouvé: !PYTHON_PATH!"
    call :log DEBUG "Commande Python: !PYTHON_CMD!"
    goto :found_python
)

REM Vérifier dans Program Files (x86)
if exist "%PROGRAM_FILES_X86%\Python310\python.exe" (
    set "PYTHON_PATH=%PROGRAM_FILES_X86%\Python310"
    set "PYTHON_CMD=%PROGRAM_FILES_X86%\Python310\python.exe"
    call :log DEBUG "Chemin Python trouvé: !PYTHON_PATH!"
    call :log DEBUG "Commande Python: !PYTHON_CMD!"
    goto :found_python
)

REM Vérifier avec py launcher
call :log DEBUG "Vérification avec py launcher..."
py -3.10 --version >nul 2>&1
if not errorlevel 1 (
    for /f "delims=" %%i in ('py -3.10 -c "import sys; print(sys.prefix)"') do set "PYTHON_PATH=%%i"
    set "PYTHON_CMD=py -3.10"
    call :log INFO "Python 3.10 trouvé via py launcher: !PYTHON_PATH!"
    goto :found_python
)

call :log WARNING "Python 3.10 n'est pas trouvé. Tentative d'installation automatique..."
curl -L -o "%TEMP%\python-3.10-installer.exe" https://www.python.org/ftp/python/3.10.11/python-3.10.11-amd64.exe
if exist "%TEMP%\python-3.10-installer.exe" (
    call :log INFO "Installation silencieuse de Python 3.10..."
    start /wait "" "%TEMP%\python-3.10-installer.exe" /quiet InstallAllUsers=1 PrependPath=1 Include_launcher=0 Include_test=0
    set "PYTHON_PATH=C:\Python310"
    set "PYTHON_CMD=C:\Python310\python.exe"
    if exist "%PYTHON_CMD%" (
        call :log INFO "Vérification de la version installée..."
        "%PYTHON_CMD%" --version
        if %errorlevel% equ 0 (
            call :log INFO "Python 3.10 installé avec succès"
            goto :found_python
        )
    )
    call :log ERROR "Échec de l'installation automatique"
    pause
    exit /b 1
)

call :log ERROR "Python 3.10 n'est pas trouvé. Installation requise."
pause
exit /b 1

:found_python
call :log INFO "Python 3.10 trouvé dans !PYTHON_PATH!"
call :log DEBUG "Chemin Python: !PYTHON_PATH!"
call :log DEBUG "Commande Python: !PYTHON_CMD!"
call :log DEBUG "PATH après détection de Python: !PATH!"

REM Section Visual Studio modifiée
set "VS_PATH=%PROGRAM_FILES%\Microsoft Visual Studio\2022\Community"
if not exist "%VS_PATH%\VC\Tools\MSVC" (
    if not defined NO_REGISTRY (
        call :log INFO "Installation des outils de build..."
        curl -L -o "%TEMP%\vs_buildtools.exe" https://aka.ms/vs/17/release/vs_buildtools.exe
        start /wait "" "%TEMP%\vs_buildtools.exe" --quiet --norestart --wait --add Microsoft.VisualStudio.Workload.VCTools
    ) else (
        call :log WARNING "Installez manuellement Visual Studio Build Tools 2022"
    )
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
call :log INFO "Vérification des redistribuables Visual C++..."
if not defined NO_REGISTRY (
    reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" /v Version >nul 2>&1 || (
        call :log INFO "Installation des redistribuables VS 2015-2022..."
        curl -L -o "%TEMP%\vc_redist.x64.exe" https://aka.ms/vs/17/release/vc_redist.x64.exe
        "%TEMP%\vc_redist.x64.exe" /install /quiet /norestart
    )
) else (
    call :log INFO "Vérification des redistribuables Visual C++ ignorée en mode sans registre"
    call :log INFO "Installation des redistribuables VS 2015-2022..."
    curl -L -o "%TEMP%\vc_redist.x64.exe" https://aka.ms/vs/17/release/vc_redist.x64.exe
    "%TEMP%\vc_redist.x64.exe" /install /quiet /norestart
)

REM Vérification des en-têtes système Windows
call :log INFO "Vérification des en-têtes système Windows..."
if not exist "%PROGRAM_FILES_X86%\Windows Kits\10\Include\10.0.19041.0\um\windows.h" (
    call :log INFO "Installation des en-têtes système manquants..."
    if not defined NO_REGISTRY (
        winget install --id Microsoft.WindowsSDK --version 10.0.19041.0 --silent
    ) else (
        call :log INFO "Téléchargement manuel du SDK Windows..."
        curl -L -o "%TEMP%\winsdksetup.exe" https://go.microsoft.com/fwlink/p/?LinkID=2033908
        "%TEMP%\winsdksetup.exe" /quiet /norestart
    )
    if %errorlevel% neq 0 (
        call :log ERROR "Erreur lors de l'installation des en-têtes système"
        exit /b 1
    )
    call :log INFO "Installation terminée"
) else (
    call :log INFO "Les en-têtes système sont déjà installés"
)

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
if exist "%VS_PATH%\VC\Auxiliary\Build\vcvars64.bat" (
    call :log DEBUG "Exécution de %VS_PATH%\VC\Auxiliary\Build\vcvars64.bat"
    call "%VS_PATH%\VC\Auxiliary\Build\vcvars64.bat"
) else (
    call :log WARNING "[AVERTISSEMENT] Fichier vcvars64.bat non trouvé"
    call :log DEBUG "Chemin recherché: %VS_PATH%\VC\Auxiliary\Build\vcvars64.bat"
)
set "PATH=%PYTHON_PATH%;%PYTHON_PATH%\Scripts;%PATH%"

REM Installation des dépendances système
curl -L -o "%TEMP%\vc_redist.x64.exe" https://aka.ms/vs/17/release/vc_redist.x64.exe
"%TEMP%\vc_redist.x64.exe" /quiet /norestart

REM Création de l'environnement virtuel
call :log INFO "Création de l'environnement virtuel..."
call :log DEBUG "Suppression de l'environnement virtuel existant si présent"
if exist venv_py310 rmdir /s /q venv_py310
call :log DEBUG "Création d'un nouvel environnement virtuel avec !PYTHON_CMD!"
"!PYTHON_CMD!" -m venv venv_py310
call :log DEBUG "Vérification de l'existence du script d'activation"
if not exist "venv_py310\Scripts\activate.bat" (
    call :log ERROR "Échec de création de l'environnement virtuel"
    pause
    exit /b 1
)

REM Activation de l'environnement virtuel
call :log INFO "Activation de l'environnement virtuel..."
call "venv_py310\Scripts\activate.bat"
call :log DEBUG "Vérification de l'activation"
"!PYTHON_CMD!" -c "import sys; print('Environnement virtuel actif:', sys.prefix)" >> "!LOG_FILE!" 2>&1

REM Installation des dépendances de base
call :log INFO "Installation des dépendances de base..."
"!PYTHON_CMD!" -m pip install --upgrade pip setuptools wheel

REM Installation des dépendances TTS
for %%p in (
    "numpy==1.24.3"
    "torch==2.1.0+cpu" "--index-url" "https://download.pytorch.org/whl/cpu"
    "tqdm==4.65.0"
) do (
    call :log INFO "Installation de %%p..."
    "!PYTHON_CMD!" -m pip install %%p --no-cache-dir
)

REM Installation de TTS avec toutes les dépendances
call :log INFO "Installation de TTS..."
"!PYTHON_CMD!" -m pip install TTS --no-cache-dir

REM Installation de PyQt6
call :log INFO "Installation de PyQt6..."
"!PYTHON_CMD!" -m pip install PyQt6==6.4.2 --no-cache-dir

REM Installation de pyinstaller
call :log INFO "Installation de pyinstaller..."
"!PYTHON_CMD!" -m pip install pyinstaller==6.3.0 --no-cache-dir

REM Vérification de l'installation
call :log INFO "Vérification de l'installation..."
"!PYTHON_CMD!" -c "import numpy; print('numpy', numpy.__version__)" 2>nul && ^
"!PYTHON_CMD!" -c "import torch; print('torch', torch.__version__)" 2>nul && ^
"!PYTHON_CMD!" -c "import TTS; print('TTS OK')" 2>nul && ^
"!PYTHON_CMD!" -c "from PyQt6.QtWidgets import QApplication; print('PyQt6 OK')" 2>nul

if errorlevel 1 (
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
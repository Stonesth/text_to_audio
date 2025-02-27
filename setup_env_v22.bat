@echo off
chcp 1252 > nul
setlocal enabledelayedexpansion

echo ===== DEBUT DU PROGRAMME D'INSTALLATION ===== 
echo Programme d'installation de l'environnement Text-to-Audio
echo Date et heure: %DATE% %TIME%
echo ============================================

REM Configuration de la journalisation
if not exist "logs" mkdir logs
set "LOG_FILE=%~dp0logs\setup_env_log.txt"
set "LOG_LEVEL=DEBUG"

REM Initialisation du fichier de log
echo ===== DEBUT INSTALLATION %DATE% %TIME% ===== > "!LOG_FILE!"

REM Vérification des arguments
set NO_REGISTRY=0
set DEBUG=0

:parse_args
if "%1"=="" goto :end_parse_args
if "%1"=="--no-registry" (
    set NO_REGISTRY=1
    call :log INFO "[MODE SANS REGISTRE] Les modifications système seront désactivées"
    shift
    goto :parse_args
)
if "%1"=="--debug" (
    set DEBUG=1
    call :log INFO "Mode debug activé - Fichier log: !LOG_FILE!"
    call :log DEBUG "PATH initial: %PATH%"
    shift
    goto :parse_args
)
:end_parse_args

REM Vérification de Python 3.10
call :log INFO "Verification de Python 3.10..."

REM Sauvegarder le chemin Python original
for /f "tokens=*" %%p in ('where py 2^>nul') do set "PYTHON_PATH=%%~dp0"
for /f "tokens=*" %%p in ('where python 2^>nul') do set "PYTHON_EXE_PATH=%%~dp0"

REM Vérifier si py launcher peut trouver Python 3.10
call :log INFO "Verification Python 3.10 via py launcher"
call :exec_and_log "py -3.10 --version" "Vérification Python 3.10 via py launcher"
if not errorlevel 1 (
    call :log INFO "Python 3.10 trouve via py launcher"
    set "PYTHON_CMD=py -3.10"
    goto setup_vs
)

REM Vérifier dans les emplacements standard
set "PYTHON310_PATHS=C:\Python310;%LOCALAPPDATA%\Programs\Python\Python310;C:\Program Files\Python310;C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python310"
for %%p in (%PYTHON310_PATHS%) do (
    if exist "%%p\python.exe" (
        call :log INFO "Python 3.10 trouve dans %%p"
        set "PYTHON_PATH=%%p"
        set "PYTHON_CMD="%%p\python.exe""
        goto setup_vs
    )
)

call :log ERROR "Python 3.10 n'est pas trouve. Veuillez l'installer depuis:"
call :log ERROR "https://www.python.org/downloads/release/python-3109/"
pause
exit /b 1

:setup_vs
REM Configuration de Visual Studio
call :log INFO "Verification de Visual Studio..."
set "VS_PATH=C:\Program Files\Microsoft Visual Studio\2022\Community"
if not exist "%VS_PATH%\VC\Tools\MSVC" (
    call :log INFO "Installation de Visual Studio requise..."
    call :exec_and_log "curl -L -o "%TEMP%\vs_community.exe" https://aka.ms/vs/17/release/vs_community.exe" "Téléchargement Visual Studio"
    
    call :log INFO "Installation de Visual Studio avec les composants C++..."
    call :exec_and_log ""%TEMP%\vs_community.exe" --quiet --wait --norestart --nocache ^
        --add Microsoft.VisualStudio.Workload.NativeDesktop ^
        --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 ^
        --add Microsoft.VisualStudio.Component.Windows11SDK.22621 ^
        --add Microsoft.VisualStudio.Component.VC.ATL ^
        --add Microsoft.VisualStudio.Component.VC.ATLMFC" "Installation Visual Studio"
    del "%TEMP%\vs_community.exe"
)

REM Vérification des redistribuables VC++
call :log INFO "Vérification des redistribuables VC++..."
set VC_REDIST_INSTALLED=0

REM Méthode 1: Vérification basée sur les fichiers DLL avec contrôle de version
if exist "C:\Windows\System32\vcruntime140.dll" (
    call :log DEBUG "vcruntime140.dll trouvé, vérification de la version..."
    
    REM DISPLAY de la version du fichier
    call :log DEBUG "Version du fichier vcruntime140.dll:"
    powershell -Command "(Get-Item 'C:\Windows\System32\vcruntime140.dll').VersionInfo.FileVersion"
)

REM Méthode 2: Vérification de la présence d'autres DLL spécifiques à VC++ 2022
if %VC_REDIST_INSTALLED% equ 0 (
    if exist "C:\Windows\System32\msvcp140.dll" (
        if exist "C:\Windows\System32\vcruntime140_1.dll" (
            call :log DEBUG "msvcp140.dll et vcruntime140_1.dll trouvés, probablement VC++ 2022 installé"
            set VC_REDIST_INSTALLED=1
        )
    )
)

@REM REM Méthode 3: Test fonctionnel - création d'un petit programme de test
@REM if %VC_REDIST_INSTALLED% equ 1 (
@REM     call :log DEBUG "Création d'un programme de test pour vérifier les redistribuables VC++..."
    
@REM     REM Création d'un fichier source C++ temporaire
@REM     (
@REM         echo #include <iostream>
@REM         echo int main() { std::cout << "VC++ Test OK" << std::endl; return 0; }
@REM     ) > "%TEMP%\vc_test.cpp"
    
@REM     REM Tentative de compilation avec cl.exe si disponible
@REM     where cl.exe >nul 2>&1
@REM     if %ERRORLEVEL% equ 0 (
@REM         cl.exe /nologo /EHsc "%TEMP%\vc_test.cpp" /Fe:"%TEMP%\vc_test.exe" >nul 2>&1
@REM         if %ERRORLEVEL% equ 0 (
@REM             "%TEMP%\vc_test.exe" >nul 2>&1
@REM             if %ERRORLEVEL% equ 0 (
@REM                 set VC_REDIST_INSTALLED=1
@REM                 call :log DEBUG "Test de compilation et d'exécution réussi, VC++ installé"
@REM             )
@REM             del "%TEMP%\vc_test.exe" 2>nul
@REM         )
@REM         del "%TEMP%\vc_test.obj" 2>nul
@REM     )
@REM     del "%TEMP%\vc_test.cpp" 2>nul
@REM )

REM Installation si nécessaire
if %VC_REDIST_INSTALLED% equ 0 (
    call :log INFO "Installation des redistribuables VC++ 2022..."
    call :exec_and_log "curl -L -o "%TEMP%\vc_redist.x64.exe" https://aka.ms/vs/17/release/vc_redist.x64.exe" "Téléchargement VC++ Redistributable"
    call :exec_and_log ""%TEMP%\vc_redist.x64.exe" /quiet /norestart" "Installation VC++ Redistributable"
    del "%TEMP%\vc_redist.x64.exe"
) else (
    call :log INFO "Redistribuables VC++ 2022 déjà installés."
)

REM Réinitialisation des variables d'environnement
set "INCLUDE="
set "LIB="
set "OLD_PATH=%PATH%"

REM Configuration des chemins Visual Studio
call :log INFO "Configuration des chemins..."
set "MSVC_PATH=%VS_PATH%\VC\Tools\MSVC"
for /f "delims=" %%i in ('dir /b /ad "%MSVC_PATH%"') do set "MSVC_VERSION=%%i"
call :log DEBUG "Version MSVC détectée: !MSVC_VERSION!"
set "MSVC_FULL=%MSVC_PATH%\%MSVC_VERSION%"
set "SDK_PATH=C:\Program Files (x86)\Windows Kits\10"
set "SDK_VER=10.0.22621.0"

REM Configuration ordonnée des includes
call :log INFO "Configuration des includes..."
set "INCLUDE=%MSVC_FULL%\include"
set "INCLUDE=%INCLUDE%;%VS_PATH%\VC\Auxiliary\VS\include"
set "INCLUDE=%INCLUDE%;%MSVC_FULL%\ATLMFC\include"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\ucrt"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\um"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\shared"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\winrt"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\cppwinrt"
call :log DEBUG "INCLUDE=%INCLUDE%"

REM Configuration des bibliothèques
call :log INFO "Configuration des bibliothèques..."
set "LIB=%MSVC_FULL%\lib\x64"
set "LIB=%LIB%;%MSVC_FULL%\ATLMFC\lib\x64"
set "LIB=%LIB%;%SDK_PATH%\Lib\%SDK_VER%\ucrt\x64"
set "LIB=%LIB%;%SDK_PATH%\Lib\%SDK_VER%\um\x64"
call :log DEBUG "LIB=%LIB%"

REM Configuration du PATH
call :log INFO "Configuration du PATH..."
set "PATH=%MSVC_FULL%\bin\HostX64\x64;%PATH%"

REM Restaurer Python dans le PATH
set "PATH=%PYTHON_PATH%;%PYTHON_PATH%\Scripts;%PATH%"
if defined PYTHON_EXE_PATH set "PATH=%PYTHON_EXE_PATH%;%PATH%"

REM Configuration de l'environnement de build
call :log INFO "Configuration de l'environnement de build..."
set DISTUTILS_USE_SDK=1
set MSSdk=1
set "CL=/MP"

REM Appel de vcvarsall.bat avec gestion d'erreur
call :log DEBUG "Appel de vcvarsall.bat"
if exist "%VS_PATH%\VC\Auxiliary\Build\vcvars64.bat" (
    call "%VS_PATH%\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1
    if !ERRORLEVEL! neq 0 (
        call :log WARNING "Erreur lors de l'appel de vcvars64.bat, tentative alternative..."
        call :exec_and_log "call "%VS_PATH%\VC\Auxiliary\Build\vcvarsall.bat" x64" "Configuration vcvarsall x64"
    ) else (
        call :log DEBUG "vcvars64.bat exécuté avec succès"
    )
) else (
    call :log WARNING "vcvars64.bat non trouvé, tentative avec vcvarsall.bat..."
    call :exec_and_log "call "%VS_PATH%\VC\Auxiliary\Build\vcvarsall.bat" x64" "Configuration vcvarsall x64"
)

REM S'assurer que Python est toujours accessible
call :log INFO "Vérification de Python après configuration de l'environnement..."
set "PATH=%PYTHON_PATH%;%PYTHON_PATH%\Scripts;%PATH%"
if defined PYTHON_EXE_PATH set "PATH=%PYTHON_EXE_PATH%;%PATH%"

REM Création de l'environnement virtuel
call :log INFO "Creation de l'environnement virtuel..."
if exist venv_py310 rmdir /s /q venv_py310
call :exec_and_log "%PYTHON_CMD% -m venv venv_py310" "Création environnement virtuel"
call .\venv_py310\Scripts\activate.bat
call :log DEBUG "Environnement virtuel activé"

@REM REM Vérification de l'activation
@REM call :log INFO "Vérification de l'environnement virtuel..."
@REM @REM call :exec_and_log "python -c "import sys; print('Python:', sys.version); print('Prefix:', sys.prefix)"" "Vérification environnement Python"
@REM call :exec_and_log 'python -c "print('Bonjour, monde !')' " "Vérification environnement Python"

REM Installation des dépendances de base
call :log INFO "Installation des dependances de base..."
call :exec_and_log "python -m pip install --upgrade pip setuptools wheel --no-cache-dir" "Installation pip/setuptools/wheel"

REM Vérification des dépendances avant installation
call :log INFO "Vérification des dépendances requises..."
call :exec_and_log "python -m pip install Cython --no-cache-dir" "Installation Cython"

REM Installation séquentielle des packages
call :log INFO "Installation des packages principaux..."
call :exec_and_log "pip install numpy==1.22.0 --only-binary :all: --no-cache-dir" "Installation numpy"

REM Amélioration de l'installation de PyTorch avec gestion des timeout
call :log INFO "Installation de PyTorch avec gestion des timeout..."
set MAX_RETRY=3
set RETRY_COUNT=0

:retry_torch_install
set /a RETRY_COUNT+=1
call :log INFO "Tentative d'installation de PyTorch (%RETRY_COUNT%/%MAX_RETRY%)..."
call :exec_and_log "pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cpu --only-binary :all: --no-cache-dir --timeout 300" "Installation torch"
if !ERRORLEVEL! neq 0 (
    if %RETRY_COUNT% lss %MAX_RETRY% (
        call :log WARNING "Échec de l'installation de PyTorch, nouvelle tentative dans 5 secondes..."
        timeout /t 5 /nobreak > nul
        goto :retry_torch_install
    ) else (
        call :log WARNING "Échec de l'installation de PyTorch après %MAX_RETRY% tentatives, essai avec une méthode alternative..."
        call :log INFO "Téléchargement direct des fichiers wheel de PyTorch..."
        
        REM Téléchargement direct des wheels PyTorch
        call :exec_and_log "curl -L -o "%TEMP%\torch-2.0.1-cp310-cp310-win_amd64.whl" https://download.pytorch.org/whl/cpu/torch-2.0.1%%2Bcpu-cp310-cp310-win_amd64.whl" "Téléchargement wheel torch"
        call :exec_and_log "pip install "%TEMP%\torch-2.0.1-cp310-cp310-win_amd64.whl" --no-cache-dir" "Installation wheel torch"
        del "%TEMP%\torch-2.0.1-cp310-cp310-win_amd64.whl"
    )
)

call :log INFO "Installation des dependances TTS..."
call :exec_and_log "pip install librosa==0.10.0 --only-binary :all: --no-cache-dir" "Installation librosa"
call :exec_and_log "pip install soundfile==0.12.1 --only-binary :all: --no-cache-dir" "Installation soundfile"
call :exec_and_log "pip install Unidecode==1.3.7 --only-binary :all: --no-cache-dir" "Installation Unidecode"
call :exec_and_log "pip install tqdm>=4.65.0 --only-binary :all: --no-cache-dir" "Installation tqdm"

REM Vérification et configuration du SDK Windows pour rc.exe
call :log INFO "Vérification de rc.exe pour la compilation..."
set RC_FOUND=0
where rc.exe >nul 2>&1
if %ERRORLEVEL% equ 0 (
    set RC_FOUND=1
    call :log DEBUG "rc.exe trouvé dans le PATH"
) else (
    REM Recherche de rc.exe dans les emplacements standard du SDK Windows
    for /f "delims=" %%i in ('dir /b /s "%SDK_PATH%\bin\*\x64\rc.exe" 2^>nul') do (
        set "RC_PATH=%%i"
        set RC_FOUND=1
        call :log DEBUG "rc.exe trouvé: !RC_PATH!"
        set "PATH=%%~dpi;!PATH!"
    )
)

if %RC_FOUND% equ 0 (
    call :log WARNING "rc.exe non trouvé, tentative d'ajout du chemin du SDK Windows au PATH..."
    set "PATH=%PATH%;%SDK_PATH%\bin\%SDK_VER%\x64;%SDK_PATH%\bin\x64"
)

call :log INFO "Installation de TTS..."
call :exec_and_log "pip uninstall TTS -y" "Désinstallation TTS"

REM Installation des dépendances spécifiques pour TTS
call :log INFO "Installation des dépendances spécifiques pour TTS..."
call :exec_and_log "pip install packaging==23.1 --no-cache-dir" "Installation packaging"
call :exec_and_log "pip install protobuf==4.24.4 --no-cache-dir" "Installation protobuf"
call :exec_and_log "pip install pyyaml==6.0.1 --no-cache-dir" "Installation pyyaml"
call :exec_and_log "pip install tensorboard==2.14.0 --no-cache-dir" "Installation tensorboard"
call :exec_and_log "pip install coqpit==0.0.17 --no-cache-dir" "Installation coqpit"
call :exec_and_log "pip install fsspec==2023.9.2 --no-cache-dir" "Installation fsspec"
call :exec_and_log "pip install jieba==0.42.1 --no-cache-dir" "Installation jieba"
call :exec_and_log "pip install matplotlib==3.7.3 --no-cache-dir" "Installation matplotlib"
call :exec_and_log "pip install scipy==1.10.1 --no-cache-dir" "Installation scipy"

REM Tentative d'installation de TTS avec différentes versions
call :log INFO "Tentative d'installation de TTS version 0.15.2..."
call :exec_and_log "pip install TTS==0.15.2 --no-cache-dir" "Installation TTS 0.15.2"
if !ERRORLEVEL! neq 0 (
    call :log WARNING "Échec de l'installation de TTS 0.15.2, tentative avec la version 0.17.6..."
    call :exec_and_log "pip install TTS==0.17.6 --no-cache-dir" "Installation TTS 0.17.6"
    if !ERRORLEVEL! neq 0 (
        call :log WARNING "Échec de l'installation de TTS 0.17.6, tentative avec la version 0.13.0 (plus stable)..."
        call :exec_and_log "pip install TTS==0.13.0 --no-cache-dir" "Installation TTS 0.13.0"
        if !ERRORLEVEL! neq 0 (
            call :log WARNING "Échec de l'installation de TTS 0.13.0, tentative avec la dernière version..."
            
            REM Tentative d'installation avec les options de build spécifiques
            call :log INFO "Installation de TTS avec options de build spécifiques..."
            set "DISTUTILS_USE_SDK=1"
            set "MSSdk=1"
            set "CL=/MP"
            
            REM Définir explicitement le chemin vers rc.exe
            call :log DEBUG "Configuration explicite de RC_PATH pour la compilation..."
            for /f "delims=" %%i in ('dir /b /s "%SDK_PATH%\bin\*\x64\rc.exe" 2^>nul') do (
                set "RC_PATH=%%i"
                call :log DEBUG "Utilisation de rc.exe: !RC_PATH!"
                set "PATH=%%~dpi;!PATH!"
            )
            
            call :exec_and_log "pip install TTS --no-cache-dir" "Installation TTS dernière version"
            if !ERRORLEVEL! neq 0 (
                call :log ERROR "Échec de l'installation de TTS. Tentative d'installation à partir des sources..."
                
                REM Tentative d'installation à partir des sources
                call :log INFO "Téléchargement et installation de TTS à partir des sources..."
                call :exec_and_log "git clone https://github.com/coqui-ai/TTS.git %TEMP%\TTS" "Clone du dépôt TTS"
                cd %TEMP%\TTS
                call :exec_and_log "pip install -e . --no-deps" "Installation TTS depuis les sources"
                cd %~dp0
                if !ERRORLEVEL! neq 0 (
                    call :log ERROR "Échec de l'installation de TTS depuis les sources. Veuillez consulter le fichier log pour plus de détails."
                )
            )
        )
    )
)

call :log INFO "Installation de PyQt6..."
call :exec_and_log "pip uninstall PyQt6 PyQt6-Qt6 PyQt6-sip -y" "Désinstallation PyQt6"
call :exec_and_log "pip install PyQt6==6.5.2 PyQt6-Qt6==6.5.2 PyQt6-sip==13.5.2 --only-binary :all: --no-cache-dir" "Installation PyQt6"

REM Vérification finale des installations
call :log INFO "Vérification des installations..."
call :log INFO "Vérification de numpy..."
call :exec_and_log "python -c \"import numpy; print(numpy.__version__)\"" "Vérification installation numpy"
call :log INFO "Vérification de torch..."
call :exec_and_log "python -c \"import torch; print(torch.__version__)\"" "Vérification installation PyTorch"
call :log INFO "Vérification de TTS..."
call :exec_and_log "python -c \"import sys; sys.path.append('.'); import TTS; print('TTS OK')"" "Vérification TTS"
call :log INFO "Vérification de PyQt6..."
call :exec_and_log "python -c \"from PyQt6.QtWidgets import QApplication; print('PyQt6 OK')"" "Vérification PyQt6"

REM Vérification des fonctionnalités TTS
call :log INFO "Vérification des fonctionnalités TTS..."
call :exec_and_log "python -c \"import sys; sys.path.append('.'); from TTS.utils.synthesizer import Synthesizer; print('TTS Synthesizer OK')"" "Vérification TTS Synthesizer"

call :log INFO "Installation terminee!"
call :log INFO "Pour tester, executez:"
call :log INFO "call .\venv_py310\Scripts\activate.bat"
call :log INFO "python Simple_TTS_GUI.py"
call :log INFO "Fichier log disponible: !LOG_FILE!"

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
    echo [ERROR] !LOG_MESSAGE!
    goto :eof
)
if "%LOG_TYPE%"=="WARNING" (
    echo [WARNING] !LOG_MESSAGE!
    goto :eof
)
if "%LOG_TYPE%"=="INFO" (
    echo [INFO] !LOG_MESSAGE!
    goto :eof
)
if "%LOG_TYPE%"=="DEBUG" (
    if "%LOG_LEVEL%"=="DEBUG" (
        echo [DEBUG] !LOG_MESSAGE!
    )
    goto :eof
)
if "%LOG_TYPE%"=="COMMAND" (
    if "%LOG_LEVEL%"=="DEBUG" (
        echo [COMMAND] !LOG_MESSAGE!
    )
    goto :eof
)
goto :eof

REM Fonction pour exécuter une commande et enregistrer sa sortie dans le fichier de log
:exec_and_log
set "CMD=%~1"
set "DESC=%~2"

call :log COMMAND "%DESC% - Debut d'execution"
%CMD% >> "!LOG_FILE!" 2>&1
set "ERROR_CODE=%ERRORLEVEL%"
call :log COMMAND "%DESC% - Fin d'exécution (code: %ERROR_CODE%)"

if %ERROR_CODE% neq 0 (
    call :log ERROR "Erreur lors de l'exécution de la commande: %DESC% (code: %ERROR_CODE%)"
)

exit /b %ERROR_CODE%

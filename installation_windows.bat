@echo off
chcp 1252 > nul
setlocal enabledelayedexpansion

echo ===== Programme d'Installation Simple TTS ===== 
echo Date et heure: %DATE% %TIME%
echo ============================================

:: Définir le répertoire de base comme le répertoire du script
set "BASE_DIR=%~dp0"
set "INSTALL_DIR=%BASE_DIR%installation"

:: Configuration de la journalisation
if not exist "%BASE_DIR%logs" mkdir "%BASE_DIR%logs"
set "LOG_FILE=%BASE_DIR%logs\installation_log.txt"
echo ===== DEBUT INSTALLATION %DATE% %TIME% ===== > "!LOG_FILE!"

:: Lancement du programme principal
goto :main

:: Fonction de journalisation
:log
set "LEVEL=%~1"
set "MESSAGE=%~2"
echo [%LEVEL%] %MESSAGE%
echo [%LEVEL%] %MESSAGE% >> "!LOG_FILE!"
exit /b 0

:: Fonction pour exécuter des commandes avec journalisation
:exec_and_log
set "CMD=%~1"
set "DESCRIPTION=%~2"
call :log INFO "Exécution: %DESCRIPTION%"
call :log DEBUG "Commande: %CMD%"

echo %CMD% >> "!LOG_FILE!"
%CMD% >> "!LOG_FILE!" 2>&1
set "RESULT=%ERRORLEVEL%"

if %RESULT% equ 0 (
    call :log INFO "Succès: %DESCRIPTION%"
) else (
    call :log ERROR "Échec: %DESCRIPTION% (Code: %RESULT%)"
)

exit /b %RESULT%

:main
call :log INFO "Démarrage de la création de l'installateur Simple TTS"

:: Vérifier l'existence de l'environnement virtuel
if not exist "%BASE_DIR%venv_py310\Scripts\activate.bat" (
    call :log ERROR "L'environnement virtuel venv_py310 n'existe pas. Veuillez exécuter setup_env_v22.bat d'abord."
    echo Erreur: L'environnement virtuel venv_py310 n'existe pas.
    echo Veuillez exécuter setup_env_v22.bat d'abord pour créer l'environnement.
    pause
    exit /b 1
)

:: Configuration de Visual Studio (nécessaire pour la compilation)
call :log INFO "Configuration de Visual Studio..."
set "VS_PATH=C:\Program Files\Microsoft Visual Studio\2022\Community"

:: Configuration des chemins Visual Studio
call :log INFO "Configuration des chemins..."
set "MSVC_PATH=%VS_PATH%\VC\Tools\MSVC"
for /f "delims=" %%i in ('dir /b /ad "%MSVC_PATH%"') do set "MSVC_VERSION=%%i"
call :log DEBUG "Version MSVC détectée: !MSVC_VERSION!"
set "MSVC_FULL=%MSVC_PATH%\%MSVC_VERSION%"
set "SDK_PATH=C:\Program Files (x86)\Windows Kits\10"
set "SDK_VER=10.0.22621.0"

:: Configuration ordonnée des includes
call :log DEBUG "Configuration des includes..."
set "INCLUDE=%MSVC_FULL%\include"
set "INCLUDE=%INCLUDE%;%VS_PATH%\VC\Auxiliary\VS\include"
set "INCLUDE=%INCLUDE%;%MSVC_FULL%\ATLMFC\include"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\ucrt"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\um"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\shared"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\winrt"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\cppwinrt"

:: Configuration des bibliothèques
call :log DEBUG "Configuration des bibliothèques..."
set "LIB=%MSVC_FULL%\lib\x64"
set "LIB=%LIB%;%MSVC_FULL%\ATLMFC\lib\x64"
set "LIB=%LIB%;%SDK_PATH%\Lib\%SDK_VER%\ucrt\x64"
set "LIB=%LIB%;%SDK_PATH%\Lib\%SDK_VER%\um\x64"

:: Ajout du chemin rc.exe au PATH pour PyInstaller
call :log INFO "Vérification de rc.exe (Resource Compiler)..."
set RC_FOUND=0
where rc.exe >nul 2>&1
if %ERRORLEVEL% equ 0 (
    set RC_FOUND=1
    call :log DEBUG "rc.exe trouvé dans le PATH"
)

if %RC_FOUND% equ 0 (
    call :log WARNING "rc.exe non trouvé, ajout du chemin du SDK Windows au PATH..."
    set "PATH=%PATH%;%SDK_PATH%\bin\%SDK_VER%\x64;%SDK_PATH%\bin\x64"
)

:: Activer l'environnement virtuel Python 3.10
call :log INFO "Activation de l'environnement virtuel venv_py310..."
call "%BASE_DIR%venv_py310\Scripts\activate.bat"
if %ERRORLEVEL% neq 0 (
    call :log ERROR "Impossible d'activer l'environnement virtuel"
    exit /b 1
)

:: Vérifier que l'environnement est activé
call :log INFO "Vérification de l'environnement Python..."
for /f "tokens=*" %%a in ('python --version 2^>^&1') do set PYTHON_VERSION=%%a
call :log INFO "Version Python actuelle: %PYTHON_VERSION%"

:: Vérifier PyInstaller
call :log INFO "Vérification de PyInstaller..."
pip show pyinstaller >nul 2>&1
if %ERRORLEVEL% neq 0 (
    call :log INFO "Installation de PyInstaller..."
    call :exec_and_log "pip install pyinstaller" "Installation de PyInstaller"
    if %ERRORLEVEL% neq 0 (
        call :log ERROR "Échec de l'installation de PyInstaller"
        exit /b 1
    )
)

:: Vérifier PyQt6
call :log INFO "Vérification de PyQt6..."
pip show PyQt6 >nul 2>&1
if %ERRORLEVEL% neq 0 (
    call :log INFO "Installation de PyQt6..."
    call :exec_and_log "pip install PyQt6" "Installation de PyQt6"
    if %ERRORLEVEL% neq 0 (
        call :log ERROR "Échec de l'installation de PyQt6"
        exit /b 1
    )
)

:: Créer le dossier d'installation si nécessaire
if not exist "%INSTALL_DIR%" (
    call :log INFO "Création du dossier d'installation: %INSTALL_DIR%"
    mkdir "%INSTALL_DIR%" 2>nul
)

:: Créer le fichier spec pour PyInstaller avec les bons chemins et dépendances
call :log INFO "Création du fichier spec pour PyInstaller..."
(
echo # -*- mode: python -*-
echo import os
echo import importlib
echo import site
echo import sys
echo 
echo block_cipher = None
echo 
echo # Récupérer les chemins des packages
echo venv_path = os.path.dirname(os.path.dirname(sys.executable))
echo site_packages = site.getsitepackages()[0]
echo 
echo # Hidden imports spécifiques pour torch et TTS
echo hidden_imports = [
echo     'torch', 'torch.nn', 'torch.optim', 'torch.utils',
echo     'torch.distributed._shard.checkpoint.*',
echo     'torch.distributed._sharded_tensor.*',
echo     'torch.distributed._sharding_spec.*',
echo     'PyQt6', 'PyQt6.sip', 'PyQt6.QtCore', 'PyQt6.QtGui', 'PyQt6.QtWidgets',
echo     'pkg_resources.py2_warn',
echo     'TTS.tts.configs.xtts_config', 'TTS.tts.models.xtts',
echo     'TTS', 'TTS.config', 'TTS.utils', 'TTS.tts',
echo     'pytorch_2_6_patch',
echo ]
echo 
echo a = Analysis(
echo     ['Simple_TTS_GUI.py'],
echo     pathex=['%BASE_DIR%'],
echo     binaries=[],
echo     datas=[],
echo     hiddenimports=hidden_imports,
echo     hookspath=[],
echo     hooksconfig={},
echo     runtime_hooks=[],
echo     excludes=[],
echo     win_no_prefer_redirects=False,
echo     win_private_assemblies=False,
echo     cipher=block_cipher,
echo     noarchive=False,
echo )
echo 
echo # Ajouter les fichiers VERSION requis
echo tts_module_path = None
echo try:
echo     tts_module_path = os.path.dirname(importlib.import_module('TTS').__file__)
echo     a.datas += [("VERSION", os.path.join(tts_module_path, "VERSION"), "DATA")]
echo     print("Ajout du fichier VERSION de TTS")
echo except (ImportError, FileNotFoundError) as e:
echo     print(f"Erreur lors de l'ajout du fichier VERSION de TTS: {e}")
echo 
echo try:
echo     trainer_module_path = os.path.dirname(importlib.import_module('trainer').__file__)
echo     a.datas += [("trainer\VERSION", os.path.join(trainer_module_path, "VERSION"), "DATA")]
echo     print("Ajout du fichier VERSION de trainer")
echo except (ImportError, FileNotFoundError) as e:
echo     print(f"Erreur lors de l'ajout du fichier VERSION de trainer: {e}")
echo 
echo # Ajouter les modèles TTS
echo models_dir = os.path.join('%BASE_DIR%', 'models')
echo if os.path.exists(models_dir):
echo     for root, dirs, files in os.walk(models_dir):
echo         for file in files:
echo             file_path = os.path.join(root, file)
echo             rel_path = os.path.relpath(file_path, '%BASE_DIR%')
echo             a.datas += [(rel_path, file_path, 'DATA')]
echo             print(f"Ajout du fichier modèle: {rel_path}")
echo 
echo pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)
echo 
echo exe = EXE(
echo     pyz,
echo     a.scripts,
echo     a.binaries,
echo     a.zipfiles,
echo     a.datas,
echo     [],
echo     name='Simple_TTS',
echo     debug=False,
echo     bootloader_ignore_signals=False,
echo     strip=False,
echo     upx=True,
echo     upx_exclude=[],
echo     runtime_tmpdir=None,
echo     console=True,  # Mettre à True pendant le dév pour voir les erreurs
echo     disable_windowed_traceback=False,
echo     argv_emulation=False,
echo     target_arch=None,
echo     codesign_identity=None,
echo     entitlements_file=None,
echo     icon='%BASE_DIR%icons\tts_icon.ico'
echo )
) > "%BASE_DIR%Simple_TTS_GUI.spec"

:: Compiler l'application avec PyInstaller
call :log INFO "Compilation de l'application avec PyInstaller..."
cd "%BASE_DIR%"
call :exec_and_log "pyinstaller --clean --noconfirm Simple_TTS_GUI.spec" "Compilation PyInstaller"

:: Vérifier si la compilation a réussi
if not exist "%BASE_DIR%dist\Simple_TTS\Simple_TTS.exe" (
    call :log ERROR "La compilation a échoué. Veuillez consulter le fichier log pour plus de détails."
    echo Erreur: La compilation a échoué. Veuillez consulter %LOG_FILE% pour plus de détails.
    pause
    exit /b 1
)

:: Créer l'installateur avec NSIS (si disponible) ou simplement copier les fichiers
if exist "%ProgramFiles(x86)%\NSIS\makensis.exe" (
    call :log INFO "Création de l'installateur avec NSIS..."
    
    :: Créer le script NSIS
    echo !define APPNAME "Simple TTS"                   > "%BASE_DIR%installer.nsi"
    echo !define COMPANYNAME "TTS Project"            >> "%BASE_DIR%installer.nsi"
    echo !define DESCRIPTION "Application de synthèse vocale" >> "%BASE_DIR%installer.nsi"
    echo !define VERSIONMAJOR 1                      >> "%BASE_DIR%installer.nsi"
    echo !define VERSIONMINOR 0                      >> "%BASE_DIR%installer.nsi"
    echo !define VERSIONBUILD 0                      >> "%BASE_DIR%installer.nsi"
    echo                                             >> "%BASE_DIR%installer.nsi"
    echo !define HELPURL "https://github.com/Stonesth/text_to_audio" >> "%BASE_DIR%installer.nsi"
    echo !define UPDATEURL "https://github.com/Stonesth/text_to_audio" >> "%BASE_DIR%installer.nsi"
    echo !define ABOUTURL "https://github.com/Stonesth/text_to_audio" >> "%BASE_DIR%installer.nsi"
    echo                                             >> "%BASE_DIR%installer.nsi"
    echo !define INSTALLDIR "$PROGRAMFILES64\${APPNAME}" >> "%BASE_DIR%installer.nsi"
    echo !define INSTALLTYPE "SetShellVarContext all"  >> "%BASE_DIR%installer.nsi"
    echo                                             >> "%BASE_DIR%installer.nsi"
    echo !include "MUI2.nsh"                         >> "%BASE_DIR%installer.nsi"
    echo !include "FileFunc.nsh"                      >> "%BASE_DIR%installer.nsi"
    echo                                             >> "%BASE_DIR%installer.nsi"
    echo Name "${APPNAME}"                            >> "%BASE_DIR%installer.nsi"
    echo OutFile "%INSTALL_DIR%\Simple_TTS_Setup.exe" >> "%BASE_DIR%installer.nsi"
    echo InstallDir "${INSTALLDIR}"                  >> "%BASE_DIR%installer.nsi"
    echo                                             >> "%BASE_DIR%installer.nsi"
    echo !define MUI_ICON "%BASE_DIR%icons\tts_icon.ico" >> "%BASE_DIR%installer.nsi"
    echo !define MUI_UNICON "%BASE_DIR%icons\tts_icon.ico" >> "%BASE_DIR%installer.nsi"
    echo                                             >> "%BASE_DIR%installer.nsi"
    echo !insertmacro MUI_PAGE_WELCOME               >> "%BASE_DIR%installer.nsi"
    echo !insertmacro MUI_PAGE_DIRECTORY             >> "%BASE_DIR%installer.nsi"
    echo !insertmacro MUI_PAGE_INSTFILES             >> "%BASE_DIR%installer.nsi"
    echo !insertmacro MUI_PAGE_FINISH                >> "%BASE_DIR%installer.nsi"
    echo                                             >> "%BASE_DIR%installer.nsi"
    echo !insertmacro MUI_UNPAGE_WELCOME             >> "%BASE_DIR%installer.nsi"
    echo !insertmacro MUI_UNPAGE_CONFIRM             >> "%BASE_DIR%installer.nsi"
    echo !insertmacro MUI_UNPAGE_INSTFILES           >> "%BASE_DIR%installer.nsi"
    echo !insertmacro MUI_UNPAGE_FINISH              >> "%BASE_DIR%installer.nsi"
    echo                                             >> "%BASE_DIR%installer.nsi"
    echo !insertmacro MUI_LANGUAGE "French"          >> "%BASE_DIR%installer.nsi"
    echo                                             >> "%BASE_DIR%installer.nsi"
    echo Section "Simple TTS" SecDummy                >> "%BASE_DIR%installer.nsi"
    echo    SetOutPath "$INSTDIR"                    >> "%BASE_DIR%installer.nsi"
    echo    File /r "%BASE_DIR%dist\Simple_TTS\*.*"   >> "%BASE_DIR%installer.nsi"
    echo    CreateDirectory "$SMPROGRAMS\${APPNAME}"  >> "%BASE_DIR%installer.nsi"
    echo    CreateShortCut "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" "$INSTDIR\Simple_TTS.exe" "" >> "%BASE_DIR%installer.nsi"
    echo    CreateShortCut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\Simple_TTS.exe" "" >> "%BASE_DIR%installer.nsi"
    echo    WriteUninstaller "$INSTDIR\uninstall.exe" >> "%BASE_DIR%installer.nsi"
    echo    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}" >> "%BASE_DIR%installer.nsi"
    echo    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\"" >> "%BASE_DIR%installer.nsi"
    echo    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayIcon" "$\"$INSTDIR\Simple_TTS.exe$\"" >> "%BASE_DIR%installer.nsi"
    echo    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "Publisher" "${COMPANYNAME}" >> "%BASE_DIR%installer.nsi"
    echo    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "HelpLink" "${HELPURL}" >> "%BASE_DIR%installer.nsi"
    echo    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "URLUpdateInfo" "${UPDATEURL}" >> "%BASE_DIR%installer.nsi"
    echo    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "URLInfoAbout" "${ABOUTURL}" >> "%BASE_DIR%installer.nsi"
    echo    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoModify" 1 >> "%BASE_DIR%installer.nsi"
    echo    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoRepair" 1 >> "%BASE_DIR%installer.nsi"
    echo SectionEnd                                  >> "%BASE_DIR%installer.nsi"
    echo                                             >> "%BASE_DIR%installer.nsi"
    echo Section "Uninstall"                         >> "%BASE_DIR%installer.nsi"
    echo    ${INSTALLTYPE}                          >> "%BASE_DIR%installer.nsi"
    echo    RMDir /r "$INSTDIR"                      >> "%BASE_DIR%installer.nsi"
    echo    Delete "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" >> "%BASE_DIR%installer.nsi"
    echo    RMDir "$SMPROGRAMS\${APPNAME}"           >> "%BASE_DIR%installer.nsi"
    echo    Delete "$DESKTOP\${APPNAME}.lnk"         >> "%BASE_DIR%installer.nsi"
    echo    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" >> "%BASE_DIR%installer.nsi"
    echo SectionEnd                                  >> "%BASE_DIR%installer.nsi"
    
    :: Exécuter NSIS pour créer l'installateur
    call :log INFO "Exécution de NSIS pour créer l'installateur..."
    call :exec_and_log ""%ProgramFiles(x86)%\NSIS\makensis.exe" "%BASE_DIR%installer.nsi"" "Création de l'installateur NSIS"
    
    if exist "%INSTALL_DIR%\Simple_TTS_Setup.exe" (
        call :log INFO "L'installateur a été créé avec succès: %INSTALL_DIR%\Simple_TTS_Setup.exe"
        echo.
        echo L'installateur a été créé avec succès.
        echo Emplacement: %INSTALL_DIR%\Simple_TTS_Setup.exe
    ) else (
        call :log ERROR "La création de l'installateur a échoué."
        echo Erreur: La création de l'installateur a échoué. Veuillez consulter %LOG_FILE% pour plus de détails.
    )
) else (
    call :log INFO "NSIS non trouvé, création d'un package ZIP portable à la place..."
    
    :: Créer un dossier d'installation portable
    set "PORTABLE_DIR=%INSTALL_DIR%\Simple_TTS_Portable"
    if exist "%PORTABLE_DIR%" rmdir /s /q "%PORTABLE_DIR%"
    mkdir "%PORTABLE_DIR%"
    
    :: Copier les fichiers compilés
    call :log INFO "Copie des fichiers dans le dossier portable..."
    xcopy "%BASE_DIR%dist\Simple_TTS\*.*" "%PORTABLE_DIR%" /e /i /h /y
    
    :: Créer un script de lancement
    echo @echo off > "%PORTABLE_DIR%\Lancer_Simple_TTS.bat"
    echo start "" "%~dp0Simple_TTS.exe" >> "%PORTABLE_DIR%\Lancer_Simple_TTS.bat"
    
    :: Créer un fichier README
    echo Simple TTS - Application de synthèse vocale > "%PORTABLE_DIR%\README.txt"
    echo ======================================= >> "%PORTABLE_DIR%\README.txt"
    echo. >> "%PORTABLE_DIR%\README.txt"
    echo Pour lancer l'application, double-cliquez sur Lancer_Simple_TTS.bat >> "%PORTABLE_DIR%\README.txt"
    echo. >> "%PORTABLE_DIR%\README.txt"
    echo Pour plus d'informations, visitez: >> "%PORTABLE_DIR%\README.txt"
    echo https://github.com/Stonesth/text_to_audio >> "%PORTABLE_DIR%\README.txt"
    
    :: Créer une archive ZIP
    call :log INFO "Création de l'archive ZIP..."
    powershell -Command "Compress-Archive -Path '%PORTABLE_DIR%\*' -DestinationPath '%INSTALL_DIR%\Simple_TTS_Portable.zip' -Force"
    
    if exist "%INSTALL_DIR%\Simple_TTS_Portable.zip" (
        call :log INFO "L'archive portable a été créée avec succès: %INSTALL_DIR%\Simple_TTS_Portable.zip"
        echo.
        echo L'archive portable a été créée avec succès.
        echo Emplacement: %INSTALL_DIR%\Simple_TTS_Portable.zip
    ) else (
        call :log ERROR "La création de l'archive a échoué."
        echo Erreur: La création de l'archive a échoué. Veuillez consulter %LOG_FILE% pour plus de détails.
    )
)

echo.
echo L'installation est terminée. Consultez le fichier log pour plus de détails: %LOG_FILE%
pause
exit /b 0

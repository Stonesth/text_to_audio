@echo off
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

:: Activer l'environnement virtuel
call :log INFO "Activation de l'environnement virtuel venv_py310..."
call "%BASE_DIR%venv_py310\Scripts\activate.bat"

:: Vérifier PyInstaller
pip show pyinstaller >nul 2>&1
if %ERRORLEVEL% neq 0 (
    call :log INFO "Installation de PyInstaller..."
    call :exec_and_log "pip install pyinstaller" "Installation de PyInstaller"
)

:: Créer le dossier d'installation si nécessaire
if not exist "%INSTALL_DIR%" (
    call :log INFO "Création du dossier d'installation: %INSTALL_DIR%"
    mkdir "%INSTALL_DIR%" 2>nul
)

:: Créer le fichier spec pour PyInstaller
call :log INFO "Création du fichier spec pour PyInstaller..."
echo # -*- mode: python -*-                                                  > "%BASE_DIR%Simple_TTS_GUI.spec"
echo block_cipher = None                                                    >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo                                                                        >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo a = Analysis(['Simple_TTS_GUI.py'],                                     >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo              pathex=['%BASE_DIR%'],                                     >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo              binaries=[],                                               >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo              datas=[],                                                  >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo              hiddenimports=['torch.distributed._shard.checkpoint.*',    >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo                             'torch.distributed._sharded_tensor.*',      >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo                             'torch.distributed._sharding_spec.*',       >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo                             'pkg_resources.py2_warn',                   >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo                             'TTS.tts.configs.xtts_config',              >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo                             'TTS.tts.models.xtts',                      >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo                             'pytorch_2_6_patch'],                       >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo              hookspath=[],                                              >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo              runtime_hooks=[],                                          >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo              excludes=[],                                               >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo              win_no_prefer_redirects=False,                             >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo              win_private_assemblies=False,                              >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo              cipher=block_cipher,                                       >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo              noarchive=False)                                           >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo                                                                        >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo # Ajouter les fichiers VERSION requis                                  >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo tts_site_pkg = os.path.dirname(importlib.import_module('TTS').__file__) >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo a.datas += [("VERSION", os.path.join(tts_site_pkg, "VERSION"), "DATA")] >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo trainer_site_pkg = os.path.dirname(importlib.import_module('trainer').__file__) >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo a.datas += [("trainer\VERSION", os.path.join(trainer_site_pkg, "VERSION"), "DATA")] >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo                                                                        >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo # Ajouter les modèles TTS                                              >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo models_dir = os.path.join('%BASE_DIR%', 'models')                      >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo if os.path.exists(models_dir):                                         >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo     for root, dirs, files in os.walk(models_dir):                      >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo         for file in files:                                             >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo             file_path = os.path.join(root, file)                       >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo             rel_path = os.path.relpath(file_path, '%BASE_DIR%')        >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo             a.datas += [(rel_path, file_path, 'DATA')]                 >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo                                                                        >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)                  >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo                                                                        >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo exe = EXE(pyz,                                                          >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo           a.scripts,                                                    >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo           a.binaries,                                                   >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo           a.zipfiles,                                                   >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo           a.datas,                                                      >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo           [],                                                          >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo           name='Simple_TTS',                                            >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo           debug=False,                                                  >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo           bootloader_ignore_signals=False,                              >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo           strip=False,                                                  >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo           upx=True,                                                     >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo           runtime_tmpdir=None,                                          >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo           console=False,                                                >> "%BASE_DIR%Simple_TTS_GUI.spec"
echo           icon='%BASE_DIR%icons\tts_icon.ico')                         >> "%BASE_DIR%Simple_TTS_GUI.spec"

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
    echo !define INSTALLSIZE 250000                  >> "%BASE_DIR%installer.nsi"
    echo                                             >> "%BASE_DIR%installer.nsi"
    echo !include "MUI2.nsh"                         >> "%BASE_DIR%installer.nsi"
    echo                                             >> "%BASE_DIR%installer.nsi"
    echo Name "${APPNAME}"                           >> "%BASE_DIR%installer.nsi"
    echo OutFile "%BASE_DIR%Simple_TTS_Setup.exe"     >> "%BASE_DIR%installer.nsi"
    echo InstallDir "$PROGRAMFILES\${APPNAME}"       >> "%BASE_DIR%installer.nsi"
    echo InstallDirRegKey HKCU "Software\${APPNAME}" "" >> "%BASE_DIR%installer.nsi"
    echo                                             >> "%BASE_DIR%installer.nsi"
    echo !define MUI_ABORTWARNING                    >> "%BASE_DIR%installer.nsi"
    echo !define MUI_ICON "%BASE_DIR%icons\tts_icon.ico" >> "%BASE_DIR%installer.nsi"
    echo                                             >> "%BASE_DIR%installer.nsi"
    echo !insertmacro MUI_PAGE_WELCOME               >> "%BASE_DIR%installer.nsi"
    echo !insertmacro MUI_PAGE_LICENSE "%BASE_DIR%LICENSE.txt" >> "%BASE_DIR%installer.nsi"
    echo !insertmacro MUI_PAGE_DIRECTORY             >> "%BASE_DIR%installer.nsi"
    echo !insertmacro MUI_PAGE_INSTFILES             >> "%BASE_DIR%installer.nsi"
    echo !insertmacro MUI_PAGE_FINISH                >> "%BASE_DIR%installer.nsi"
    echo                                             >> "%BASE_DIR%installer.nsi"
    echo !insertmacro MUI_LANGUAGE "French"          >> "%BASE_DIR%installer.nsi"
    echo                                             >> "%BASE_DIR%installer.nsi"
    echo Section "Simple TTS" SecDummy                >> "%BASE_DIR%installer.nsi"
    echo   SetOutPath "$INSTDIR"                     >> "%BASE_DIR%installer.nsi"
    echo   File /r "%BASE_DIR%dist\Simple_TTS\*.*"   >> "%BASE_DIR%installer.nsi"
    echo   CreateDirectory "$SMPROGRAMS\${APPNAME}"  >> "%BASE_DIR%installer.nsi"
    echo   CreateShortCut "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" "$INSTDIR\Simple_TTS.exe" >> "%BASE_DIR%installer.nsi"
    echo   CreateShortCut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\Simple_TTS.exe" >> "%BASE_DIR%installer.nsi"
    echo   WriteUninstaller "$INSTDIR\uninstall.exe" >> "%BASE_DIR%installer.nsi"
    echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}" >> "%BASE_DIR%installer.nsi"
    echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\"" >> "%BASE_DIR%installer.nsi"
    echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S" >> "%BASE_DIR%installer.nsi"
    echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "InstallLocation" "$\"$INSTDIR$\"" >> "%BASE_DIR%installer.nsi"
    echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayIcon" "$\"$INSTDIR\Simple_TTS.exe$\"" >> "%BASE_DIR%installer.nsi"
    echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "Publisher" "${COMPANYNAME}" >> "%BASE_DIR%installer.nsi"
    echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "HelpLink" "${HELPURL}" >> "%BASE_DIR%installer.nsi"
    echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "URLUpdateInfo" "${UPDATEURL}" >> "%BASE_DIR%installer.nsi"
    echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "URLInfoAbout" "${ABOUTURL}" >> "%BASE_DIR%installer.nsi"
    echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayVersion" "${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}" >> "%BASE_DIR%installer.nsi"
    echo   WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "VersionMajor" ${VERSIONMAJOR} >> "%BASE_DIR%installer.nsi"
    echo   WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "VersionMinor" ${VERSIONMINOR} >> "%BASE_DIR%installer.nsi"
    echo   WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoModify" 1 >> "%BASE_DIR%installer.nsi"
    echo   WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoRepair" 1 >> "%BASE_DIR%installer.nsi"
    echo   WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "EstimatedSize" ${INSTALLSIZE} >> "%BASE_DIR%installer.nsi"
    echo SectionEnd                                  >> "%BASE_DIR%installer.nsi"
    echo                                             >> "%BASE_DIR%installer.nsi"
    echo Section "Uninstall"                         >> "%BASE_DIR%installer.nsi"
    echo   Delete "$INSTDIR\uninstall.exe"           >> "%BASE_DIR%installer.nsi"
    echo   RMDir /r "$INSTDIR"                       >> "%BASE_DIR%installer.nsi"
    echo   Delete "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" >> "%BASE_DIR%installer.nsi"
    echo   RMDir "$SMPROGRAMS\${APPNAME}"            >> "%BASE_DIR%installer.nsi"
    echo   Delete "$DESKTOP\${APPNAME}.lnk"          >> "%BASE_DIR%installer.nsi"
    echo   DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" >> "%BASE_DIR%installer.nsi"
    echo SectionEnd                                  >> "%BASE_DIR%installer.nsi"
    
    :: Créer un fichier LICENSE fictif si nécessaire
    if not exist "%BASE_DIR%LICENSE.txt" (
        echo Licence Simple TTS                          > "%BASE_DIR%LICENSE.txt"
        echo =====================================        >> "%BASE_DIR%LICENSE.txt"
        echo                                             >> "%BASE_DIR%LICENSE.txt"
        echo Ce logiciel est distribué sous les termes de la licence MIT. >> "%BASE_DIR%LICENSE.txt"
    )
    
    :: Compiler l'installateur NSIS
    call :exec_and_log ""%ProgramFiles(x86)%\NSIS\makensis.exe" "%BASE_DIR%installer.nsi"" "Compilation de l'installateur NSIS"
    
    call :log INFO "Installateur créé: %BASE_DIR%Simple_TTS_Setup.exe"
    echo Installateur créé avec succès: %BASE_DIR%Simple_TTS_Setup.exe
) else (
    call :log INFO "NSIS non trouvé, création d'un package ZIP à la place..."
    
    :: Créer un dossier d'installation portable
    set "PORTABLE_DIR=%BASE_DIR%Simple_TTS_Portable"
    if exist "%PORTABLE_DIR%" rmdir /s /q "%PORTABLE_DIR%"
    mkdir "%PORTABLE_DIR%"
    
    :: Copier les fichiers compilés
    xcopy /y /s "%BASE_DIR%dist\Simple_TTS\*" "%PORTABLE_DIR%\"
    
    :: Créer un script de lancement
    echo @echo off                                   > "%PORTABLE_DIR%\Lancer_Simple_TTS.bat"
    echo start "" "%~dp0Simple_TTS.exe"               >> "%PORTABLE_DIR%\Lancer_Simple_TTS.bat"
    
    :: Vérifier si 7-Zip est installé
    if exist "%ProgramFiles%\7-Zip\7z.exe" (
        call :exec_and_log ""%ProgramFiles%\7-Zip\7z.exe" a -tzip "%BASE_DIR%Simple_TTS_Portable.zip" "%PORTABLE_DIR%\*"" "Création du package ZIP"
        call :log INFO "Package portable créé: %BASE_DIR%Simple_TTS_Portable.zip"
        echo Package portable créé avec succès: %BASE_DIR%Simple_TTS_Portable.zip
        
        :: Supprimer le dossier temporaire
        rmdir /s /q "%PORTABLE_DIR%"
    ) else (
        call :log INFO "7-Zip non trouvé, version portable créée dans: %PORTABLE_DIR%"
        echo Version portable créée avec succès dans: %PORTABLE_DIR%
    )
)

:: Nettoyer les fichiers temporaires
call :log INFO "Nettoyage des fichiers temporaires..."
if exist "%BASE_DIR%build" rmdir /s /q "%BASE_DIR%build"
if exist "%BASE_DIR%dist" rmdir /s /q "%BASE_DIR%dist"
if exist "%BASE_DIR%Simple_TTS_GUI.spec" del /f /q "%BASE_DIR%Simple_TTS_GUI.spec"
if exist "%BASE_DIR%installer.nsi" del /f /q "%BASE_DIR%installer.nsi"

echo ===== Installation terminée =====
echo Vous pouvez maintenant distribuer l'installateur créé à d'autres utilisateurs.
echo Ils n'auront pas besoin d'installer Python pour utiliser l'application.
pause
exit /b 0

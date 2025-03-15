@echo off
setlocal enabledelayedexpansion

echo ===== Programme d'Installation Simple TTS ===== 
echo Date et heure: %DATE% %TIME%
echo ============================================

:: Configuration de la journalisation
if not exist "logs" mkdir logs
set "LOG_FILE=%~dp0logs\installation_log.txt"
echo ===== DEBUT INSTALLATION %DATE% %TIME% ===== > "!LOG_FILE!"

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
call :log INFO "Démarrage de l'installation de Simple TTS"

:: Vérifier que Python 3.10 est installé
call :log INFO "Vérification de Python 3.10..."
where python.exe >nul 2>&1
if %ERRORLEVEL% neq 0 (
    call :log ERROR "Python n'est pas installé ou n'est pas dans le PATH."
    echo Erreur: Python 3.10 est requis mais n'a pas été trouvé.
    echo Téléchargez et installez Python 3.10 depuis https://www.python.org/downloads/release/python-3109/
    pause
    exit /b 1
)

:: Créer un dossier d'installation
set "INSTALL_DIR=%ProgramFiles%\Simple TTS"
echo Dossier d'installation: %INSTALL_DIR%

choice /C YN /M "Installer Simple TTS dans ce dossier?"
if %ERRORLEVEL% neq 1 (
    echo Installation annulée par l'utilisateur.
    exit /b 0
)

if not exist "%INSTALL_DIR%" (
    call :log INFO "Création du dossier d'installation: %INSTALL_DIR%"
    mkdir "%INSTALL_DIR%" 2>nul
    if %ERRORLEVEL% neq 0 (
        call :log ERROR "Impossible de créer le dossier d'installation. Essai avec les droits d'administrateur..."
        echo Remarque: Des droits d'administrateur sont nécessaires pour installer dans %ProgramFiles%.
        echo Redémarrez ce script en tant qu'administrateur ou choisissez un autre dossier.
        
        set /p "INSTALL_DIR=Entrez un autre chemin d'installation (ou appuyez sur Entrée pour annuler): "
        if "!INSTALL_DIR!"=="" (
            echo Installation annulée.
            exit /b 1
        )
        
        mkdir "!INSTALL_DIR!" 2>nul
        if %ERRORLEVEL% neq 0 (
            call :log ERROR "Impossible de créer le dossier d'installation: !INSTALL_DIR!"
            echo Erreur: Impossible de créer le dossier d'installation.
            pause
            exit /b 1
        )
    )
)

:: Créer un environnement virtuel temporaire pour la compilation
call :log INFO "Création d'un environnement virtuel temporaire pour la compilation..."
set "TEMP_DIR=%TEMP%\simple_tts_build"
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"
cd "%TEMP_DIR%"

call :exec_and_log "python -m venv venv" "Création de l'environnement virtuel"
call :exec_and_log "venv\Scripts\activate.bat" "Activation de l'environnement virtuel"

:: Installer les dépendances nécessaires pour la compilation
call :log INFO "Installation des dépendances pour la compilation..."
call :exec_and_log "pip install -U pip" "Mise à jour de pip"
call :exec_and_log "pip install wheel setuptools" "Installation des outils de base"
call :exec_and_log "pip install pyinstaller" "Installation de PyInstaller"

:: Installer les dépendances spécifiques à TTS
call :log INFO "Installation des dépendances spécifiques à TTS..."
call :exec_and_log "pip install numpy==1.21.0" "Installation de numpy spécifique"
call :exec_and_log "pip install torch==2.0.1 torchaudio==2.0.2" "Installation de PyTorch"
call :exec_and_log "pip install TTS==0.21.3" "Installation de TTS 0.21.3"
call :exec_and_log "pip install PyQt6" "Installation de PyQt6"

:: Copier les fichiers sources depuis le répertoire du projet
call :log INFO "Copie des fichiers sources..."
set "PROJECT_DIR=%~dp0"
xcopy /y "%PROJECT_DIR%Simple_TTS_GUI.py" "%TEMP_DIR%\"
xcopy /y "%PROJECT_DIR%Simple_TTS.py" "%TEMP_DIR%\"
xcopy /y "%PROJECT_DIR%pytorch_2_6_patch.py" "%TEMP_DIR%\"
xcopy /y "%PROJECT_DIR%*.png" "%TEMP_DIR%\\" 2>nul
xcopy /y /s "%PROJECT_DIR%models" "%TEMP_DIR%\models\" 2>nul
xcopy /y /s "%PROJECT_DIR%icons" "%TEMP_DIR%\icons\" 2>nul

:: Créer le fichier spec pour PyInstaller
call :log INFO "Création du fichier spec pour PyInstaller..."
echo # -*- mode: python -*-                                                  > "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo block_cipher = None                                                    >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo                                                                        >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo a = Analysis(['Simple_TTS_GUI.py'],                                     >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo              pathex=['%TEMP_DIR%'],                                     >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo              binaries=[],                                               >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo              datas=[],                                                  >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo              hiddenimports=['torch.distributed._shard.checkpoint.*',    >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo                             'torch.distributed._sharded_tensor.*',      >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo                             'torch.distributed._sharding_spec.*',       >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo                             'pkg_resources.py2_warn',                   >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo                             'pytorch_2_6_patch'],                       >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo              hookspath=[],                                              >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo              runtime_hooks=[],                                          >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo              excludes=[],                                               >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo              win_no_prefer_redirects=False,                             >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo              win_private_assemblies=False,                              >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo              cipher=block_cipher,                                       >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo              noarchive=False)                                           >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo                                                                        >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo a.datas += [("VERSION", "%TEMP_DIR%\venv\Lib\site-packages\TTS\VERSION", "DATA")] >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo a.datas += [("trainer\VERSION", "%TEMP_DIR%\venv\Lib\site-packages\trainer\VERSION", "DATA")] >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo                                                                        >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)                  >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo                                                                        >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo exe = EXE(pyz,                                                          >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo           a.scripts,                                                    >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo           a.binaries,                                                   >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo           a.zipfiles,                                                   >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo           a.datas,                                                      >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo           [],                                                          >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo           name='Simple_TTS',                                            >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo           debug=False,                                                  >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo           bootloader_ignore_signals=False,                              >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo           strip=False,                                                  >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo           upx=True,                                                     >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo           upx_exclude=[],                                               >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo           runtime_tmpdir=None,                                          >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo           console=False,                                                >> "%TEMP_DIR%\Simple_TTS_GUI.spec"
echo           icon='%TEMP_DIR%\icons\tts_icon.ico')                        >> "%TEMP_DIR%\Simple_TTS_GUI.spec"

:: Compiler l'application avec PyInstaller
call :log INFO "Compilation de l'application avec PyInstaller..."
cd "%TEMP_DIR%"
call :exec_and_log "pyinstaller --clean --noconfirm Simple_TTS_GUI.spec" "Compilation PyInstaller"

:: Créer l'installateur avec NSIS (si disponible) ou simplement copier les fichiers
if exist "%ProgramFiles(x86)%\NSIS\makensis.exe" (
    call :log INFO "Création de l'installateur avec NSIS..."
    
    :: Créer le script NSIS
    echo !define APPNAME "Simple TTS"                   > "%TEMP_DIR%\installer.nsi"
    echo !define COMPANYNAME "TTS Project"            >> "%TEMP_DIR%\installer.nsi"
    echo !define DESCRIPTION "Application de synthèse vocale" >> "%TEMP_DIR%\installer.nsi"
    echo !define VERSIONMAJOR 1                      >> "%TEMP_DIR%\installer.nsi"
    echo !define VERSIONMINOR 0                      >> "%TEMP_DIR%\installer.nsi"
    echo !define VERSIONBUILD 0                      >> "%TEMP_DIR%\installer.nsi"
    echo                                             >> "%TEMP_DIR%\installer.nsi"
    echo !define HELPURL "https://github.com/Stonesth/text_to_audio" >> "%TEMP_DIR%\installer.nsi"
    echo !define UPDATEURL "https://github.com/Stonesth/text_to_audio" >> "%TEMP_DIR%\installer.nsi"
    echo !define ABOUTURL "https://github.com/Stonesth/text_to_audio" >> "%TEMP_DIR%\installer.nsi"
    echo                                             >> "%TEMP_DIR%\installer.nsi"
    echo !define INSTALLSIZE 250000                  >> "%TEMP_DIR%\installer.nsi"
    echo                                             >> "%TEMP_DIR%\installer.nsi"
    echo !include "MUI2.nsh"                         >> "%TEMP_DIR%\installer.nsi"
    echo                                             >> "%TEMP_DIR%\installer.nsi"
    echo Name "${APPNAME}"                           >> "%TEMP_DIR%\installer.nsi"
    echo OutFile "Simple_TTS_Setup.exe"              >> "%TEMP_DIR%\installer.nsi"
    echo InstallDir "$PROGRAMFILES\${APPNAME}"       >> "%TEMP_DIR%\installer.nsi"
    echo InstallDirRegKey HKCU "Software\${APPNAME}" "" >> "%TEMP_DIR%\installer.nsi"
    echo                                             >> "%TEMP_DIR%\installer.nsi"
    echo !define MUI_ABORTWARNING                    >> "%TEMP_DIR%\installer.nsi"
    echo !define MUI_ICON "%TEMP_DIR%\icons\tts_icon.ico" >> "%TEMP_DIR%\installer.nsi"
    echo                                             >> "%TEMP_DIR%\installer.nsi"
    echo !insertmacro MUI_PAGE_WELCOME               >> "%TEMP_DIR%\installer.nsi"
    echo !insertmacro MUI_PAGE_LICENSE "LICENSE.txt" >> "%TEMP_DIR%\installer.nsi"
    echo !insertmacro MUI_PAGE_DIRECTORY             >> "%TEMP_DIR%\installer.nsi"
    echo !insertmacro MUI_PAGE_INSTFILES             >> "%TEMP_DIR%\installer.nsi"
    echo !insertmacro MUI_PAGE_FINISH                >> "%TEMP_DIR%\installer.nsi"
    echo                                             >> "%TEMP_DIR%\installer.nsi"
    echo !insertmacro MUI_LANGUAGE "French"          >> "%TEMP_DIR%\installer.nsi"
    echo                                             >> "%TEMP_DIR%\installer.nsi"
    echo Section "Simple TTS" SecDummy                >> "%TEMP_DIR%\installer.nsi"
    echo   SetOutPath "$INSTDIR"                     >> "%TEMP_DIR%\installer.nsi"
    echo   File /r "%TEMP_DIR%\dist\Simple_TTS\*.*"  >> "%TEMP_DIR%\installer.nsi"
    echo   CreateDirectory "$SMPROGRAMS\${APPNAME}"  >> "%TEMP_DIR%\installer.nsi"
    echo   CreateShortCut "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" "$INSTDIR\Simple_TTS.exe" >> "%TEMP_DIR%\installer.nsi"
    echo   CreateShortCut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\Simple_TTS.exe" >> "%TEMP_DIR%\installer.nsi"
    echo   WriteUninstaller "$INSTDIR\uninstall.exe" >> "%TEMP_DIR%\installer.nsi"
    echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}" >> "%TEMP_DIR%\installer.nsi"
    echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\"" >> "%TEMP_DIR%\installer.nsi"
    echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S" >> "%TEMP_DIR%\installer.nsi"
    echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "InstallLocation" "$\"$INSTDIR$\"" >> "%TEMP_DIR%\installer.nsi"
    echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayIcon" "$\"$INSTDIR\Simple_TTS.exe$\"" >> "%TEMP_DIR%\installer.nsi"
    echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "Publisher" "${COMPANYNAME}" >> "%TEMP_DIR%\installer.nsi"
    echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "HelpLink" "${HELPURL}" >> "%TEMP_DIR%\installer.nsi"
    echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "URLUpdateInfo" "${UPDATEURL}" >> "%TEMP_DIR%\installer.nsi"
    echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "URLInfoAbout" "${ABOUTURL}" >> "%TEMP_DIR%\installer.nsi"
    echo   WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayVersion" "${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}" >> "%TEMP_DIR%\installer.nsi"
    echo   WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "VersionMajor" ${VERSIONMAJOR} >> "%TEMP_DIR%\installer.nsi"
    echo   WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "VersionMinor" ${VERSIONMINOR} >> "%TEMP_DIR%\installer.nsi"
    echo   WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoModify" 1 >> "%TEMP_DIR%\installer.nsi"
    echo   WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoRepair" 1 >> "%TEMP_DIR%\installer.nsi"
    echo   WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "EstimatedSize" ${INSTALLSIZE} >> "%TEMP_DIR%\installer.nsi"
    echo SectionEnd                                  >> "%TEMP_DIR%\installer.nsi"
    echo                                             >> "%TEMP_DIR%\installer.nsi"
    echo Section "Uninstall"                         >> "%TEMP_DIR%\installer.nsi"
    echo   Delete "$INSTDIR\uninstall.exe"           >> "%TEMP_DIR%\installer.nsi"
    echo   RMDir /r "$INSTDIR"                       >> "%TEMP_DIR%\installer.nsi"
    echo   Delete "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" >> "%TEMP_DIR%\installer.nsi"
    echo   RMDir "$SMPROGRAMS\${APPNAME}"            >> "%TEMP_DIR%\installer.nsi"
    echo   Delete "$DESKTOP\${APPNAME}.lnk"          >> "%TEMP_DIR%\installer.nsi"
    echo   DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" >> "%TEMP_DIR%\installer.nsi"
    echo SectionEnd                                  >> "%TEMP_DIR%\installer.nsi"
    
    :: Créer un fichier LICENSE fictif si nécessaire
    echo Licence Simple TTS                          > "%TEMP_DIR%\LICENSE.txt"
    echo =====================================        >> "%TEMP_DIR%\LICENSE.txt"
    echo                                             >> "%TEMP_DIR%\LICENSE.txt"
    echo Ce logiciel est distribué sous les termes de la licence MIT. >> "%TEMP_DIR%\LICENSE.txt"
    
    :: Compiler l'installateur NSIS
    call :exec_and_log ""%ProgramFiles(x86)%\NSIS\makensis.exe" "%TEMP_DIR%\installer.nsi"" "Compilation de l'installateur NSIS"
    
    :: Copier l'installateur dans le dossier du projet
    copy /y "%TEMP_DIR%\Simple_TTS_Setup.exe" "%PROJECT_DIR%\Simple_TTS_Setup.exe"
    
    call :log INFO "Installateur créé: %PROJECT_DIR%\Simple_TTS_Setup.exe"
    echo Installateur créé avec succès: %PROJECT_DIR%\Simple_TTS_Setup.exe
) else (
    call :log INFO "NSIS non trouvé, création d'un package ZIP à la place..."
    
    :: Vérifier si 7-Zip est installé
    if exist "%ProgramFiles%\7-Zip\7z.exe" (
        call :exec_and_log ""%ProgramFiles%\7-Zip\7z.exe" a -tzip "%PROJECT_DIR%\Simple_TTS_Portable.zip" "%TEMP_DIR%\dist\Simple_TTS\*"" "Création du package ZIP"
        call :log INFO "Package portable créé: %PROJECT_DIR%\Simple_TTS_Portable.zip"
        echo Package portable créé avec succès: %PROJECT_DIR%\Simple_TTS_Portable.zip
    ) else (
        :: Copier les fichiers compilés dans le dossier d'installation
        call :log INFO "Copie des fichiers compilés dans le dossier d'installation..."
        xcopy /y /s "%TEMP_DIR%\dist\Simple_TTS\*" "%INSTALL_DIR%\"
        
        :: Créer un raccourci sur le bureau
        call :log INFO "Création d'un raccourci sur le bureau..."
        powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\Simple TTS.lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\Simple_TTS.exe'; $Shortcut.Save()"
        
        call :log INFO "Installation terminée: %INSTALL_DIR%"
        echo Installation terminée avec succès dans: %INSTALL_DIR%
    )
)

:: Nettoyage
call :log INFO "Nettoyage des fichiers temporaires..."
cd "%PROJECT_DIR%"
rmdir /s /q "%TEMP_DIR%"

echo ===== Installation terminée =====
pause
exit /b 0

:: Lancement du programme principal
:startup
call :main
goto :EOF

@echo off
setlocal enabledelayedexpansion

:: Configuration de la journalisation
set "LOG_FILE=%~dp0logs\build_executable_log.txt"
set "ERROR_FILE=%~dp0logs\error.txt"

:: Création du dossier de logs s'il n'existe pas
if not exist "%~dp0logs" mkdir "%~dp0logs"

:: Effacer les fichiers de log précédents
echo ===== JOURNAL DE COMPILATION PYINSTALLER ===== > "%LOG_FILE%"
echo Date et heure: %DATE% %TIME% >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

echo ===== ERREURS DE COMPILATION PYINSTALLER ===== > "%ERROR_FILE%"
echo Date et heure: %DATE% %TIME% >> "%ERROR_FILE%"
echo. >> "%ERROR_FILE%"

:: Fonction de journalisation
:log
echo %~1 >> "%LOG_FILE%"
echo %~1
goto :eof

:: Fonction d'erreur
:error
echo %~1 >> "%ERROR_FILE%"
echo %~1
goto :eof

:: Gestionnaire d'exceptions
:try
setlocal
call :log "[TRY] Début du bloc %~1"
goto :eof

:catch
if %ERRORLEVEL% neq 0 (
    call :error "[ERREUR] Échec dans le bloc %~1 avec code %ERRORLEVEL%"
    goto :end_catch
)
call :log "[OK] Bloc %~1 exécuté avec succès"
:end_catch
endlocal & set LAST_ERROR=%ERRORLEVEL%
goto :eof

echo ===== CREATION DE L'EXECUTABLE AVEC PYINSTALLER =====
echo Date et heure: %DATE% %TIME%
call :log "Démarrage du script de compilation"

:: ===== SECTION: VÉRIFICATION ENVIRONNEMENT VIRTUEL =====
call :try "VERIFICATION_ENV"

:: Vérification de l'existence de l'environnement virtuel
call :log "Vérification de l'environnement virtuel venv_py310"
if not exist ".\venv_py310\Scripts\activate.bat" (
    call :error "L'environnement virtuel venv_py310 n'existe pas"
    echo ERREUR: L'environnement virtuel venv_py310 n'existe pas.
    echo Veuillez d'abord exécuter setup_env.bat pour créer l'environnement virtuel.
    echo.
    pause
    exit /b 1
)

echo.
echo IMPORTANT: Ce script va utiliser l'environnement virtuel venv_py310.
echo Assurez-vous que toutes les dépendances sont correctement installées dans cet environnement.
echo Si vous avez besoin d'installer les dépendances, veuillez d'abord exécuter setup_env.bat.
echo.

:: Activation de l'environnement virtuel existant
echo Activation de l'environnement virtuel venv_py310...
call :log "Tentative d'activation de l'environnement virtuel"
call .\venv_py310\Scripts\activate.bat

:: Vérification de l'activation réussie
if not defined VIRTUAL_ENV (
    call :error "Impossible d'activer l'environnement virtuel venv_py310"
    echo ERREUR: Impossible d'activer l'environnement virtuel venv_py310.
    pause
    exit /b 1
)
echo Environnement virtuel activé avec succès: %VIRTUAL_ENV%
call :log "Environnement virtuel activé: %VIRTUAL_ENV%"
echo.

call :catch "VERIFICATION_ENV"
if %LAST_ERROR% neq 0 exit /b %LAST_ERROR%

:: ===== SECTION: VÉRIFICATION PYINSTALLER =====
call :try "VERIFICATION_PYINSTALLER"

:: Vérification de PyInstaller
call :log "Vérification de PyInstaller"
pip show pyinstaller > nul 2>&1
if %ERRORLEVEL% neq 0 (
    call :log "Installation de PyInstaller..."
    echo Installation de PyInstaller...
    pip install pyinstaller
    if %ERRORLEVEL% neq 0 (
        call :error "Impossible d'installer PyInstaller"
        echo ERREUR: Impossible d'installer PyInstaller
        exit /b 1
    )
)
call :log "PyInstaller est disponible"

call :catch "VERIFICATION_PYINSTALLER"
if %LAST_ERROR% neq 0 exit /b %LAST_ERROR%

:: ===== SECTION: CRÉATION DES RÉPERTOIRES =====
call :try "CREATION_REPERTOIRES"

:: Création du répertoire build s'il n'existe pas
call :log "Vérification du répertoire de build"
if not exist "build" (
    mkdir build
    call :log "Répertoire build créé"
) else (
    call :log "Répertoire build existe déjà"
)

call :catch "CREATION_REPERTOIRES"
if %LAST_ERROR% neq 0 exit /b %LAST_ERROR%

:: ===== SECTION: VÉRIFICATION ESPEAK-NG =====
call :try "VERIFICATION_ESPEAK"

:: Téléchargement du dossier espeak-ng s'il n'existe pas
call :log "Vérification du dossier espeak-ng"
if not exist "espeak-ng" (
    call :log "Le dossier espeak-ng n'existe pas, demande à l'utilisateur"
    echo Téléchargement et extraction du dossier espeak-ng...
    :: Si vous avez un fichier ZIP espeak-ng, décommentez ces lignes et ajustez le chemin
    :: powershell -Command "Invoke-WebRequest -Uri 'URL_DU_FICHIER_ZIP_ESPEAK_NG' -OutFile 'espeak-ng.zip'"
    :: powershell -Command "Expand-Archive -Path 'espeak-ng.zip' -DestinationPath '.'"
    :: del espeak-ng.zip
    
    echo ATTENTION: Veuillez placer manuellement le dossier espeak-ng dans ce répertoire.
    echo Appuyez sur une touche pour continuer une fois le dossier espeak-ng ajouté...
    pause > nul
) else (
    call :log "Le dossier espeak-ng existe"
)

call :catch "VERIFICATION_ESPEAK"
if %LAST_ERROR% neq 0 exit /b %LAST_ERROR%

:: ===== SECTION: CRÉATION DU HOOK PYTORCH =====
call :try "CREATION_HOOK_PYTORCH"

:: Création d'un hook pour PyTorch
call :log "Vérification du hook PyTorch"
if not exist "pytorch_hook.py" (
    call :log "Création du fichier pytorch_hook.py"
    echo Création du hook PyTorch...
    (
        echo from PyInstaller.utils.hooks import collect_all
        echo def hook(hook_api):
        echo     packages = [
        echo         'torch',
        echo         'torchaudio',
        echo         'TTS',
        echo     ]
        echo     for package in packages:
        echo         datas, binaries, hiddenimports = collect_all(package)
        echo         hook_api.add_datas(datas)
        echo         hook_api.add_binaries(binaries)
        echo         hook_api.add_imports(*hiddenimports)
        echo     # Ajouter les classes securisees pour PyTorch 2.6+
        echo     hook_api.add_imports('torchaudio.lib.libtorchaudio')
        echo     hook_api.add_imports('torch.lib.libtorch')
    ) > pytorch_hook.py
    call :log "Fichier pytorch_hook.py créé avec succès"
) else (
    call :log "Le fichier pytorch_hook.py existe déjà"
)

call :catch "CREATION_HOOK_PYTORCH"
if %LAST_ERROR% neq 0 exit /b %LAST_ERROR%

:: ===== SECTION: CRÉATION DU HOOK TTS =====
call :try "CREATION_HOOK_TTS"

:: Création d'un hook pour TTS
call :log "Vérification du hook TTS"
if not exist "tts_hook.py" (
    call :log "Création du fichier tts_hook.py"
    echo Création du hook TTS...
    (
        echo from PyInstaller.utils.hooks import collect_data_files, collect_all
        echo def hook(hook_api):
        echo     # Collecter tous les fichiers pour TTS
        echo     datas, binaries, hiddenimports = collect_all('TTS')
        echo     hook_api.add_datas(datas)
        echo     hook_api.add_binaries(binaries)
        echo     hook_api.add_imports(*hiddenimports)
        echo     # Ajouter explicitement les classes securisees
        echo     classes = [
        echo         'TTS.tts.configs.xtts_config.XttsConfig',
        echo         'TTS.tts.configs.shared_configs.XttsAudioConfig',
        echo         'TTS.api.Xtts',
        echo         'TTS.utils.audio.AudioProcessor',
        echo         'TTS.config.load_config',
        echo         'TTS.tts.configs.BaseTTSConfig',
        echo         'TTS.utils.audio.TorchSTFT'
        echo     ]
        echo     hook_api.add_imports(*classes)
    ) > tts_hook.py
    call :log "Fichier tts_hook.py créé avec succès"
) else (
    call :log "Le fichier tts_hook.py existe déjà"
)

call :catch "CREATION_HOOK_TTS"
if %LAST_ERROR% neq 0 exit /b %LAST_ERROR%

:: ===== SECTION: CRÉATION DU PATCH PYTORCH =====
call :try "CREATION_PATCH_PYTORCH"

:: Création du fichier patch pour PyTorch 2.6+
call :log "Vérification du patch PyTorch 2.6+"
if not exist "pytorch_2_6_patch.py" (
    call :log "Création du fichier pytorch_2_6_patch.py"
    echo Création du patch PyTorch 2.6+...
    (
        echo # Patch pour assurer la compatibilite avec PyTorch 2.6+
        echo import torch
        echo import warnings
        echo.
        echo def apply_patch():
        echo     # Applique le patch pour PyTorch 2.6+
        echo     try:
        echo         if hasattr(torch.serialization, 'add_safe_globals'):
        echo             # Classes a ajouter a la liste des classes securisees
        echo             from TTS.tts.configs.xtts_config import XttsConfig
        echo             from TTS.tts.configs.shared_configs import XttsAudioConfig
        echo             from TTS.api import Xtts
        echo             from TTS.utils.audio import AudioProcessor
        echo             from TTS.config import load_config
        echo             from TTS.tts.configs.base_tts_config import BaseTTSConfig
        echo             from TTS.utils.audio.torch_transforms import TorchSTFT
        echo.
        echo             print("Application du patch PyTorch 2.6+...")
        echo             # Ajouter toutes les classes a la liste des classes securisees
        echo             torch.serialization.add_safe_globals([XttsConfig, XttsAudioConfig, Xtts,
        echo                                                   AudioProcessor, load_config, BaseTTSConfig, TorchSTFT])
        echo             print("Patch PyTorch 2.6+ applique avec succes!")
        echo     except Exception as e:
        echo         warnings.warn("Impossible d'appliquer le patch PyTorch 2.6+: " + str(e))
        echo.
        echo # Appliquer le patch automatiquement a l'importation
        echo apply_patch()
    ) > pytorch_2_6_patch.py
    call :log "Fichier pytorch_2_6_patch.py créé avec succès"
) else (
    call :log "Le fichier pytorch_2_6_patch.py existe déjà"
)

call :catch "CREATION_PATCH_PYTORCH"
if %LAST_ERROR% neq 0 exit /b %LAST_ERROR%

:: ===== SECTION: CRÉATION DU FICHIER SPEC =====
call :try "CREATION_SPEC"

:: Création du fichier spec pour PyInstaller
call :log "Création du fichier spec PyInstaller"
echo Création du fichier spec PyInstaller...
(
    echo # -*- mode: python ; coding: utf-8 -*-
    echo import os
    echo import sys
    echo from PyInstaller.utils.hooks import collect_all, collect_data_files
    echo 
    echo block_cipher = None
    echo 
    echo # Collecter toutes les donnees necessaires pour TTS et torch
    echo tts_datas, tts_binaries, tts_hiddenimports = collect_all('TTS')
    echo torch_datas, torch_binaries, torch_hiddenimports = collect_all('torch')
    echo pyqt_datas, pyqt_binaries, pyqt_hiddenimports = collect_all('PyQt6')
    echo 
    echo # Ajouter les ressources supplementaires
    echo added_files = [
    echo     # Fichiers de style et ressources
    echo     ('style_nn.qss', '.'),
    echo     ('resources/*', 'resources'),
    echo     ('fonts/*', 'fonts'),
    echo     # Fichiers d'exemple
    echo     ('test_en.txt', '.'),
    echo     ('test_fr.txt', '.'),
    echo     # Dossier espeak-ng
    echo     ('espeak-ng/*', 'espeak-ng'),
    echo     # Patch PyTorch 2.6+
    echo     ('pytorch_2_6_patch.py', '.'),
    echo ]
    echo 
    echo # Combiner toutes les donnees
    echo all_datas = tts_datas + torch_datas + pyqt_datas + added_files
    echo all_binaries = tts_binaries + torch_binaries + pyqt_binaries
    echo all_hiddenimports = tts_hiddenimports + torch_hiddenimports + pyqt_hiddenimports + [
    echo     'PyQt6.sip',
    echo     'PyQt6.QtWidgets',
    echo     'PyQt6.QtCore',
    echo     'PyQt6.QtGui',
    echo     'TTS.tts.configs.xtts_config',
    echo     'TTS.tts.configs.shared_configs',
    echo     'TTS.api',
    echo     'TTS.utils.audio',
    echo     'TTS.config',
    echo     'TTS.tts.configs.base_tts_config',
    echo     'TTS.utils.audio.torch_transforms',
    echo     'pytorch_2_6_patch',
    echo ]
    echo 
    echo a = Analysis(
    echo     ['Simple_TTS_GUI.py'],
    echo     pathex=[os.path.abspath('.')],
    echo     binaries=all_binaries,
    echo     datas=all_datas,
    echo     hiddenimports=all_hiddenimports,
    echo     hookspath=['tts_hook.py', 'pytorch_hook.py'],
    echo     hooksconfig={},
    echo     runtime_hooks=[],
    echo     excludes=[],
    echo     win_no_prefer_redirects=False,
    echo     win_private_assemblies=False,
    echo     cipher=block_cipher,
    echo     noarchive=False,
    echo )
    echo 
    echo pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)
    echo 
    echo exe = EXE(
    echo     pyz,
    echo     a.scripts,
    echo     [],
    echo     exclude_binaries=True,
    echo     name='Simple_TTS_GUI',
    echo     debug=False,
    echo     bootloader_ignore_signals=False,
    echo     strip=False,
    echo     upx=True,
    echo     upx_exclude=[],
    echo     runtime_tmpdir=None,
    echo     console=False,
    echo     disable_windowed_traceback=False,
    echo     target_arch=None,
    echo     codesign_identity=None,
    echo     entitlements_file=None,
    echo     icon='resources/nn_logo.png',
    echo )
    echo 
    echo coll = COLLECT(
    echo     exe,
    echo     a.binaries,
    echo     a.zipfiles,
    echo     a.datas,
    echo     strip=False,
    echo     upx=True,
    echo     upx_exclude=[],
    echo     name='Simple_TTS_GUI',
    echo )
) > Simple_TTS_GUI.spec
call :log "Fichier Simple_TTS_GUI.spec créé avec succès"

call :catch "CREATION_SPEC"
if %LAST_ERROR% neq 0 exit /b %LAST_ERROR%

:: ===== SECTION: EXÉCUTION DE PYINSTALLER =====
call :try "EXECUTION_PYINSTALLER"

:: Exécution de PyInstaller
call :log "Démarrage de la compilation avec PyInstaller"
echo ===== Démarrage de la compilation avec PyInstaller =====
pyinstaller --clean Simple_TTS_GUI.spec

if %ERRORLEVEL% equ 0 (
    call :log "Compilation terminée avec succès"
    echo ===== COMPILATION TERMINÉE AVEC SUCCÈS =====
    echo L'exécutable est disponible dans le dossier: %CD%\dist\Simple_TTS_GUI
) else (
    call :error "Erreur lors de la compilation avec code %ERRORLEVEL%"
    echo ===== ERREUR LORS DE LA COMPILATION =====
    echo Veuillez vérifier les erreurs ci-dessus.
)

call :catch "EXECUTION_PYINSTALLER"
if %LAST_ERROR% neq 0 exit /b %LAST_ERROR%

:: ===== SECTION: FINALISATION =====
call :try "FINALISATION"

:: Désactivation de l'environnement virtuel
call :log "Désactivation de l'environnement virtuel"
deactivate

call :log "Script terminé"
echo Script terminé.

call :catch "FINALISATION"

pause

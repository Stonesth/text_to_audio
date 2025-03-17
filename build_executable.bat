@echo off
setlocal enabledelayedexpansion

echo ===== CREATION DE L'EXECUTABLE AVEC PYINSTALLER =====
echo Date et heure: %DATE% %TIME%

:: Vérification de l'existence de l'environnement virtuel
if not exist ".\venv_py310\Scripts\activate.bat" (
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
call .\venv_py310\Scripts\activate.bat

:: Vérification de l'activation réussie
if not defined VIRTUAL_ENV (
    echo ERREUR: Impossible d'activer l'environnement virtuel venv_py310.
    pause
    exit /b 1
)
echo Environnement virtuel activé avec succès: %VIRTUAL_ENV%
echo.

:: Vérification de PyInstaller
pip show pyinstaller > nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Installation de PyInstaller...
    pip install pyinstaller
    if %ERRORLEVEL% neq 0 (
        echo ERREUR: Impossible d'installer PyInstaller
        exit /b 1
    )
)

:: Création du répertoire build s'il n'existe pas
if not exist "build" mkdir build

:: Téléchargement du dossier espeak-ng s'il n'existe pas
if not exist "espeak-ng" (
    echo Téléchargement et extraction du dossier espeak-ng...
    :: Si vous avez un fichier ZIP espeak-ng, décommentez ces lignes et ajustez le chemin
    :: powershell -Command "Invoke-WebRequest -Uri 'URL_DU_FICHIER_ZIP_ESPEAK_NG' -OutFile 'espeak-ng.zip'"
    :: powershell -Command "Expand-Archive -Path 'espeak-ng.zip' -DestinationPath '.'"
    :: del espeak-ng.zip
    
    echo ATTENTION: Veuillez placer manuellement le dossier espeak-ng dans ce répertoire.
    echo Appuyez sur une touche pour continuer une fois le dossier espeak-ng ajouté...
    pause > nul
)

:: Création d'un hook pour PyTorch
if not exist "pytorch_hook.py" (
    echo Création du hook PyTorch...
    (
        echo from PyInstaller.utils.hooks import collect_all
        echo def hook(hook_api^):
        echo     packages = [
        echo         'torch',
        echo         'torchaudio',
        echo         'TTS',
        echo     ]
        echo     for package in packages:
        echo         datas, binaries, hiddenimports = collect_all(package^)
        echo         hook_api.add_datas(datas^)
        echo         hook_api.add_binaries(binaries^)
        echo         hook_api.add_imports(*hiddenimports^)
        echo     # Ajouter les classes sécurisées pour PyTorch 2.6+
        echo     hook_api.add_imports('torchaudio.lib.libtorchaudio')
        echo     hook_api.add_imports('torch.lib.libtorch')
    ) > pytorch_hook.py
)

:: Création d'un hook pour TTS
if not exist "tts_hook.py" (
    echo Création du hook TTS...
    (
        echo from PyInstaller.utils.hooks import collect_data_files, collect_all
        echo def hook(hook_api^):
        echo     # Collecter tous les fichiers pour TTS
        echo     datas, binaries, hiddenimports = collect_all('TTS')
        echo     hook_api.add_datas(datas^)
        echo     hook_api.add_binaries(binaries^)
        echo     hook_api.add_imports(*hiddenimports^)
        echo     # Ajouter explicitement les classes sécurisées
        echo     classes = [
        echo         'TTS.tts.configs.xtts_config.XttsConfig',
        echo         'TTS.tts.configs.shared_configs.XttsAudioConfig',
        echo         'TTS.api.Xtts',
        echo         'TTS.utils.audio.AudioProcessor',
        echo         'TTS.config.load_config',
        echo         'TTS.tts.configs.BaseTTSConfig',
        echo         'TTS.utils.audio.TorchSTFT'
        echo     ]
        echo     hook_api.add_imports(*classes^)
    ) > tts_hook.py
)

:: Création du fichier patch pour PyTorch 2.6+
if not exist "pytorch_2_6_patch.py" (
    echo Création du patch PyTorch 2.6+...
    (
        echo """Patch pour assurer la compatibilité avec PyTorch 2.6+"""
        echo import torch
        echo import warnings
        echo 
        echo def apply_patch():
        echo     """Applique le patch pour PyTorch 2.6+"""
        echo     try:
        echo         if hasattr(torch.serialization, 'add_safe_globals'):
        echo             # Classes à ajouter à la liste des classes sécurisées
        echo             from TTS.tts.configs.xtts_config import XttsConfig
        echo             from TTS.tts.configs.shared_configs import XttsAudioConfig
        echo             from TTS.api import Xtts
        echo             from TTS.utils.audio import AudioProcessor
        echo             from TTS.config import load_config
        echo             from TTS.tts.configs.base_tts_config import BaseTTSConfig
        echo             from TTS.utils.audio.torch_transforms import TorchSTFT
        echo 
        echo             print("Application du patch PyTorch 2.6+...")
        echo             # Ajouter toutes les classes à la liste des classes sécurisées
        echo             torch.serialization.add_safe_globals([XttsConfig, XttsAudioConfig, Xtts,
        echo                                                   AudioProcessor, load_config, BaseTTSConfig, TorchSTFT])
        echo             print("Patch PyTorch 2.6+ appliqué avec succès!")
        echo     except Exception as e:
        echo         warnings.warn(f"Impossible d'appliquer le patch PyTorch 2.6+: {e}")
        echo 
        echo # Appliquer le patch automatiquement à l'importation
        echo apply_patch()
    ) > pytorch_2_6_patch.py
)

:: Création du fichier spec pour PyInstaller
echo Création du fichier spec PyInstaller...
(
    echo # -*- mode: python ; coding: utf-8 -*-
    echo import os
    echo import sys
    echo from PyInstaller.utils.hooks import collect_all, collect_data_files
    echo 
    echo block_cipher = None
    echo 
    echo # Collecter toutes les données nécessaires pour TTS et torch
    echo tts_datas, tts_binaries, tts_hiddenimports = collect_all('TTS')
    echo torch_datas, torch_binaries, torch_hiddenimports = collect_all('torch')
    echo pyqt_datas, pyqt_binaries, pyqt_hiddenimports = collect_all('PyQt6')
    echo 
    echo # Ajouter les ressources supplémentaires
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
    echo # Combiner toutes les données
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

:: Exécution de PyInstaller
echo ===== Démarrage de la compilation avec PyInstaller =====
pyinstaller --clean Simple_TTS_GUI.spec

if %ERRORLEVEL% equ 0 (
    echo ===== COMPILATION TERMINÉE AVEC SUCCÈS =====
    echo L'exécutable est disponible dans le dossier: %CD%\dist\Simple_TTS_GUI
) else (
    echo ===== ERREUR LORS DE LA COMPILATION =====
    echo Veuillez vérifier les erreurs ci-dessus.
)

:: Désactivation de l'environnement virtuel
deactivate

echo Script terminé.
pause

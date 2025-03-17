@echo on
setlocal enabledelayedexpansion

:: Fichiers de journalisation
set "LOG_FILE=%~dp0logs\build_simple.txt"
set "ERROR_FILE=%~dp0logs\error_simple.txt"

:: Creation dossier de logs
if not exist "%~dp0logs" mkdir "%~dp0logs"

echo ===== JOURNAL DE COMPILATION PYINSTALLER ===== > "%LOG_FILE%"
echo Date et heure: %DATE% %TIME% >> "%LOG_FILE%"

echo ===== ERREURS DE COMPILATION PYINSTALLER ===== > "%ERROR_FILE%"
echo Date et heure: %DATE% %TIME% >> "%ERROR_FILE%"

echo ===== CREATION DE L'EXECUTABLE AVEC PYINSTALLER =====
echo Date et heure: %DATE% %TIME%
echo Demarrage du script >> "%LOG_FILE%"

:: ===== VERIFICATION ENVIRONNEMENT VIRTUEL =====

echo Verification de l'environnement virtuel venv_py310 >> "%LOG_FILE%"
if not exist ".\venv_py310\Scripts\activate.bat" (
    echo L'environnement virtuel venv_py310 n'existe pas >> "%ERROR_FILE%"
    echo ERREUR: L'environnement virtuel venv_py310 n'existe pas.
    echo Veuillez d'abord executer setup_env.bat pour creer l'environnement virtuel.
    pause
    exit /b 1
)

echo Ce script va utiliser l'environnement virtuel venv_py310.
echo Activation de l'environnement virtuel...
echo Tentative d'activation de l'environnement virtuel >> "%LOG_FILE%"
call .\venv_py310\Scripts\activate.bat

if not defined VIRTUAL_ENV (
    echo Impossible d'activer l'environnement virtuel venv_py310 >> "%ERROR_FILE%"
    echo ERREUR: Impossible d'activer l'environnement virtuel venv_py310.
    pause
    exit /b 1
)
echo Environnement virtuel active avec succes: %VIRTUAL_ENV%
echo Environnement virtuel active: %VIRTUAL_ENV% >> "%LOG_FILE%"

:: ===== VERIFICATION PYINSTALLER =====

echo Verification de PyInstaller >> "%LOG_FILE%"
pip show pyinstaller > nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Installation de PyInstaller... >> "%LOG_FILE%"
    echo Installation de PyInstaller...
    pip install pyinstaller
    if %ERRORLEVEL% neq 0 (
        echo Impossible d'installer PyInstaller >> "%ERROR_FILE%"
        echo ERREUR: Impossible d'installer PyInstaller
        exit /b 1
    )
)
echo PyInstaller est disponible >> "%LOG_FILE%"

:: ===== CREATION DES FICHIERS PYTHON =====
echo Creation des fichiers Python (hooks et patch) >> "%LOG_FILE%"

:: Creation du hook PyTorch
del /f /q pytorch_hook.py 2>nul
echo Creation du hook PyTorch...
@(
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
echo     # Ajouter les imports specifiques
echo     hook_api.add_imports('torchaudio.lib.libtorchaudio')
echo     hook_api.add_imports('torch.lib.libtorch')
) > pytorch_hook.py
echo Hook PyTorch cree avec succes >> "%LOG_FILE%"

:: Creation du hook TTS
del /f /q tts_hook.py 2>nul
echo Creation du hook TTS...
@(
echo from PyInstaller.utils.hooks import collect_data_files, collect_all
echo def hook(hook_api):
echo     # Collecter tous les fichiers pour TTS
echo     datas, binaries, hiddenimports = collect_all('TTS')
echo     hook_api.add_datas(datas)
echo     hook_api.add_binaries(binaries)
echo     hook_api.add_imports(*hiddenimports)
echo     # Ajouter explicitement les classes necessaires
echo     classes = [
echo         'TTS.tts.configs.xtts_config.XttsConfig',
echo         'TTS.tts.configs.shared_configs.XttsAudioConfig',
echo         'TTS.api.Xtts',
echo         'TTS.utils.audio.AudioProcessor',
echo         'TTS.config.load_config',
echo         'TTS.tts.configs.base_tts_config.BaseTTSConfig',
echo         'TTS.utils.audio.torch_transforms.TorchSTFT'
echo     ]
echo     hook_api.add_imports(*classes)
) > tts_hook.py
echo Hook TTS cree avec succes >> "%LOG_FILE%"

:: Creation du patch PyTorch 2.6+
del /f /q pytorch_2_6_patch.py 2>nul
echo Creation du patch PyTorch 2.6+...
@(
echo # Patch pour assurer la compatibilite avec PyTorch 2.6+
echo import torch
echo import warnings
echo 
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
echo 
echo             print("Application du patch PyTorch 2.6+...")
echo             # Ajouter toutes les classes a la liste des classes securisees
echo             torch.serialization.add_safe_globals([XttsConfig, XttsAudioConfig, Xtts,
echo                                                   AudioProcessor, load_config, BaseTTSConfig, TorchSTFT])
echo             print("Patch PyTorch 2.6+ applique avec succes!")
echo     except Exception as e:
echo         warnings.warn("Impossible d'appliquer le patch PyTorch 2.6+: " + str(e))
echo 
echo # Appliquer le patch automatiquement a l'importation
echo apply_patch()
) > pytorch_2_6_patch.py
echo Patch PyTorch 2.6+ cree avec succes >> "%LOG_FILE%"

:: ===== CREATION DU FICHIER SPEC =====

echo Creation du fichier spec PyInstaller... >> "%LOG_FILE%"

echo # -*- mode: python ; coding: utf-8 -*- > Simple_TTS_GUI.spec
echo import os >> Simple_TTS_GUI.spec
echo import sys >> Simple_TTS_GUI.spec
echo from PyInstaller.utils.hooks import collect_all, collect_data_files >> Simple_TTS_GUI.spec
echo. >> Simple_TTS_GUI.spec
echo block_cipher = None >> Simple_TTS_GUI.spec
echo. >> Simple_TTS_GUI.spec
echo tts_datas, tts_binaries, tts_hiddenimports = collect_all('TTS') >> Simple_TTS_GUI.spec
echo torch_datas, torch_binaries, torch_hiddenimports = collect_all('torch') >> Simple_TTS_GUI.spec
echo pyqt_datas, pyqt_binaries, pyqt_hiddenimports = collect_all('PyQt6') >> Simple_TTS_GUI.spec
echo. >> Simple_TTS_GUI.spec
echo added_files = [ >> Simple_TTS_GUI.spec
echo     ('style_nn.qss', '.'), >> Simple_TTS_GUI.spec
echo     ('resources/*', 'resources'), >> Simple_TTS_GUI.spec
echo     ('fonts/*', 'fonts'), >> Simple_TTS_GUI.spec
echo     ('test_en.txt', '.'), >> Simple_TTS_GUI.spec
echo     ('test_fr.txt', '.'), >> Simple_TTS_GUI.spec
echo     ('espeak-ng/*', 'espeak-ng'), >> Simple_TTS_GUI.spec
echo     ('pytorch_2_6_patch.py', '.'), >> Simple_TTS_GUI.spec
echo ] >> Simple_TTS_GUI.spec
echo. >> Simple_TTS_GUI.spec
echo all_datas = tts_datas + torch_datas + pyqt_datas + added_files >> Simple_TTS_GUI.spec
echo all_binaries = tts_binaries + torch_binaries + pyqt_binaries >> Simple_TTS_GUI.spec
echo all_hiddenimports = tts_hiddenimports + torch_hiddenimports + pyqt_hiddenimports + [ >> Simple_TTS_GUI.spec
echo     'PyQt6.sip', >> Simple_TTS_GUI.spec
echo     'PyQt6.QtWidgets', >> Simple_TTS_GUI.spec
echo     'PyQt6.QtCore', >> Simple_TTS_GUI.spec
echo     'PyQt6.QtGui', >> Simple_TTS_GUI.spec
echo     'TTS.tts.configs.xtts_config', >> Simple_TTS_GUI.spec
echo     'TTS.tts.configs.shared_configs', >> Simple_TTS_GUI.spec
echo     'TTS.api', >> Simple_TTS_GUI.spec
echo     'TTS.utils.audio', >> Simple_TTS_GUI.spec
echo     'TTS.config', >> Simple_TTS_GUI.spec
echo     'TTS.tts.configs.base_tts_config', >> Simple_TTS_GUI.spec
echo     'TTS.utils.audio.torch_transforms', >> Simple_TTS_GUI.spec
echo     'pytorch_2_6_patch', >> Simple_TTS_GUI.spec
echo ] >> Simple_TTS_GUI.spec
echo. >> Simple_TTS_GUI.spec
echo a = Analysis( >> Simple_TTS_GUI.spec
echo     ['Simple_TTS_GUI.py'], >> Simple_TTS_GUI.spec
echo     pathex=[os.path.abspath('.')], >> Simple_TTS_GUI.spec
echo     binaries=all_binaries, >> Simple_TTS_GUI.spec
echo     datas=all_datas, >> Simple_TTS_GUI.spec
echo     hiddenimports=all_hiddenimports, >> Simple_TTS_GUI.spec
echo     hookspath=['.'], >> Simple_TTS_GUI.spec
echo     hooksconfig={}, >> Simple_TTS_GUI.spec
echo     runtime_hooks=[], >> Simple_TTS_GUI.spec
echo     excludes=[], >> Simple_TTS_GUI.spec
echo     win_no_prefer_redirects=False, >> Simple_TTS_GUI.spec
echo     win_private_assemblies=False, >> Simple_TTS_GUI.spec
echo     cipher=block_cipher, >> Simple_TTS_GUI.spec
echo     noarchive=False, >> Simple_TTS_GUI.spec
echo ) >> Simple_TTS_GUI.spec
echo. >> Simple_TTS_GUI.spec
echo pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher) >> Simple_TTS_GUI.spec
echo. >> Simple_TTS_GUI.spec
echo exe = EXE( >> Simple_TTS_GUI.spec
echo     pyz, >> Simple_TTS_GUI.spec
echo     a.scripts, >> Simple_TTS_GUI.spec
echo     [], >> Simple_TTS_GUI.spec
echo     exclude_binaries=True, >> Simple_TTS_GUI.spec
echo     name='Simple_TTS_GUI', >> Simple_TTS_GUI.spec
echo     debug=False, >> Simple_TTS_GUI.spec
echo     bootloader_ignore_signals=False, >> Simple_TTS_GUI.spec
echo     strip=False, >> Simple_TTS_GUI.spec
echo     upx=True, >> Simple_TTS_GUI.spec
echo     upx_exclude=[], >> Simple_TTS_GUI.spec
echo     runtime_tmpdir=None, >> Simple_TTS_GUI.spec
echo     console=True, >> Simple_TTS_GUI.spec
echo     disable_windowed_traceback=False, >> Simple_TTS_GUI.spec
echo     target_arch=None, >> Simple_TTS_GUI.spec
echo     codesign_identity=None, >> Simple_TTS_GUI.spec
echo     entitlements_file=None, >> Simple_TTS_GUI.spec
echo     icon='resources/nn_logo.png', >> Simple_TTS_GUI.spec
echo ) >> Simple_TTS_GUI.spec
echo. >> Simple_TTS_GUI.spec
echo coll = COLLECT( >> Simple_TTS_GUI.spec
echo     exe, >> Simple_TTS_GUI.spec
echo     a.binaries, >> Simple_TTS_GUI.spec
echo     a.zipfiles, >> Simple_TTS_GUI.spec
echo     a.datas, >> Simple_TTS_GUI.spec
echo     strip=False, >> Simple_TTS_GUI.spec
echo     upx=True, >> Simple_TTS_GUI.spec
echo     upx_exclude=[], >> Simple_TTS_GUI.spec
echo     name='Simple_TTS_GUI', >> Simple_TTS_GUI.spec
echo ) >> Simple_TTS_GUI.spec

:: ===== EXECUTION DE PYINSTALLER =====

echo Demarrage de la compilation avec PyInstaller >> "%LOG_FILE%"
echo ===== Demarrage de la compilation avec PyInstaller =====
pyinstaller --clean Simple_TTS_GUI.spec

if %ERRORLEVEL% equ 0 (
    echo Compilation terminee avec succes >> "%LOG_FILE%"
    echo ===== COMPILATION TERMINEE AVEC SUCCES =====
    echo L'executable est disponible dans le dossier: %CD%\dist\Simple_TTS_GUI
) else (
    echo Erreur lors de la compilation avec code %ERRORLEVEL% >> "%ERROR_FILE%"
    echo ===== ERREUR LORS DE LA COMPILATION =====
    echo Veuillez verifier les erreurs ci-dessus.
)

:: Desactivation de l'environnement virtuel
echo Desactivation de l'environnement virtuel >> "%LOG_FILE%"
deactivate

echo Script termine >> "%LOG_FILE%"
echo Script termine.

pause

@echo off
setlocal enabledelayedexpansion

:: Configuration des fichiers de journalisation
set "LOG_DIR=%~dp0logs"
set "HOOK_LOG=%LOG_DIR%\create_hooks.log"
set "HOOK_ERROR=%LOG_DIR%\create_hooks_error.log"

:: Créer le répertoire de logs s'il n'existe pas
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: Effacer les fichiers de log existants
echo === RAPPORT DE CRÉATION DES HOOKS === > "%HOOK_LOG%"
echo === ERREURS DE CRÉATION DES HOOKS === > "%HOOK_ERROR%"

echo ===== CRÉATION DES HOOKS PYINSTALLER =====
echo ===== CRÉATION DES HOOKS PYINSTALLER ===== >> "%HOOK_LOG%"

:: Vérifier que l'environnement virtuel est activé
if not defined VIRTUAL_ENV (
    echo ERREUR: Environnement virtuel non activé >> "%HOOK_ERROR%"
    echo ERREUR: Environnement virtuel non activé
    echo Exécutez d'abord verify_env.bat
    exit /b 1
)

:: CHECKPOINT 1 - Création du répertoire hooks
echo.
echo CHECKPOINT 1 - Création du répertoire hooks...
echo CHECKPOINT 1 - Création du répertoire hooks... >> "%HOOK_LOG%"

set "HOOKS_DIR=%~dp0hooks"
if not exist "%HOOKS_DIR%" mkdir "%HOOKS_DIR%"
echo Répertoire hooks créé/vérifié: %HOOKS_DIR% >> "%HOOK_LOG%"
echo Répertoire hooks: %HOOKS_DIR%

:: CHECKPOINT 2 - Création du hook pour torch
echo.
echo CHECKPOINT 2 - Création du hook pour torch...
echo CHECKPOINT 2 - Création du hook pour torch... >> "%HOOK_LOG%"

echo # Hook pour PyTorch > "%HOOKS_DIR%\hook-torch.py"
echo from PyInstaller.utils.hooks import collect_all >> "%HOOKS_DIR%\hook-torch.py"
echo. >> "%HOOKS_DIR%\hook-torch.py"
echo # Collecte de tous les packages liés à torch >> "%HOOKS_DIR%\hook-torch.py"
echo datas, binaries, hiddenimports = collect_all('torch') >> "%HOOKS_DIR%\hook-torch.py"
echo. >> "%HOOKS_DIR%\hook-torch.py"
echo # Ajouter des imports supplémentaires >> "%HOOKS_DIR%\hook-torch.py"
echo hiddenimports += [ >> "%HOOKS_DIR%\hook-torch.py"
echo     'torch', >> "%HOOKS_DIR%\hook-torch.py"
echo     'torch.nn', >> "%HOOKS_DIR%\hook-torch.py"
echo     'torch.nn.functional', >> "%HOOKS_DIR%\hook-torch.py"
echo     'torch.utils', >> "%HOOKS_DIR%\hook-torch.py"
echo     'torch.utils.data', >> "%HOOKS_DIR%\hook-torch.py"
echo     'torch.serialization', >> "%HOOKS_DIR%\hook-torch.py"
echo     'torch.audio', >> "%HOOKS_DIR%\hook-torch.py"
echo     'torchvision', >> "%HOOKS_DIR%\hook-torch.py"
echo     'torchaudio', >> "%HOOKS_DIR%\hook-torch.py"
echo ] >> "%HOOKS_DIR%\hook-torch.py"

echo Hook torch créé: %HOOKS_DIR%\hook-torch.py >> "%HOOK_LOG%"
echo Hook torch créé

:: CHECKPOINT 3 - Création du hook pour TTS
echo.
echo CHECKPOINT 3 - Création du hook pour TTS...
echo CHECKPOINT 3 - Création du hook pour TTS... >> "%HOOK_LOG%"

echo # Hook pour TTS > "%HOOKS_DIR%\hook-TTS.py"
echo from PyInstaller.utils.hooks import collect_all >> "%HOOKS_DIR%\hook-TTS.py"
echo. >> "%HOOKS_DIR%\hook-TTS.py"
echo # Collecte de tous les packages liés à TTS >> "%HOOKS_DIR%\hook-TTS.py"
echo datas, binaries, hiddenimports = collect_all('TTS') >> "%HOOKS_DIR%\hook-TTS.py"
echo. >> "%HOOKS_DIR%\hook-TTS.py"
echo # Ajouter des imports supplémentaires >> "%HOOKS_DIR%\hook-TTS.py"
echo hiddenimports += [ >> "%HOOKS_DIR%\hook-TTS.py"
echo     'TTS', >> "%HOOKS_DIR%\hook-TTS.py"
echo     'TTS.utils', >> "%HOOKS_DIR%\hook-TTS.py"
echo     'TTS.utils.audio', >> "%HOOKS_DIR%\hook-TTS.py"
echo     'TTS.tts', >> "%HOOKS_DIR%\hook-TTS.py"
echo     'TTS.tts.models', >> "%HOOKS_DIR%\hook-TTS.py"
echo     'TTS.tts.utils', >> "%HOOKS_DIR%\hook-TTS.py"
echo     'TTS.tts.configs', >> "%HOOKS_DIR%\hook-TTS.py"
echo ] >> "%HOOKS_DIR%\hook-TTS.py"

echo Hook TTS créé: %HOOKS_DIR%\hook-TTS.py >> "%HOOK_LOG%"
echo Hook TTS créé

:: CHECKPOINT 4 - Création du hook pour PyQt6
echo.
echo CHECKPOINT 4 - Création du hook pour PyQt6...
echo CHECKPOINT 4 - Création du hook pour PyQt6... >> "%HOOK_LOG%"

echo # Hook pour PyQt6 > "%HOOKS_DIR%\hook-PyQt6.py"
echo from PyInstaller.utils.hooks import collect_all, collect_submodules >> "%HOOKS_DIR%\hook-PyQt6.py"
echo. >> "%HOOKS_DIR%\hook-PyQt6.py"
echo # Collecte de tous les packages liés à PyQt6 >> "%HOOKS_DIR%\hook-PyQt6.py"
echo datas, binaries, hiddenimports = collect_all('PyQt6') >> "%HOOKS_DIR%\hook-PyQt6.py"
echo. >> "%HOOKS_DIR%\hook-PyQt6.py"
echo # Ajouter spécifiquement PyQt6.sip qui pose souvent problème >> "%HOOKS_DIR%\hook-PyQt6.py"
echo hiddenimports += [ >> "%HOOKS_DIR%\hook-PyQt6.py"
echo     'PyQt6', >> "%HOOKS_DIR%\hook-PyQt6.py"
echo     'PyQt6.sip', >> "%HOOKS_DIR%\hook-PyQt6.py"
echo     'PyQt6.QtCore', >> "%HOOKS_DIR%\hook-PyQt6.py"
echo     'PyQt6.QtGui', >> "%HOOKS_DIR%\hook-PyQt6.py"
echo     'PyQt6.QtWidgets', >> "%HOOKS_DIR%\hook-PyQt6.py"
echo     'PyQt6.uic', >> "%HOOKS_DIR%\hook-PyQt6.py"
echo ] >> "%HOOKS_DIR%\hook-PyQt6.py"
echo. >> "%HOOKS_DIR%\hook-PyQt6.py"
echo # Collecte explicite des sous-modules PyQt6.sip >> "%HOOKS_DIR%\hook-PyQt6.py"
echo sip_modules = collect_submodules('PyQt6.sip') >> "%HOOKS_DIR%\hook-PyQt6.py"
echo hiddenimports += sip_modules >> "%HOOKS_DIR%\hook-PyQt6.py"

echo Hook PyQt6 créé: %HOOKS_DIR%\hook-PyQt6.py >> "%HOOK_LOG%"
echo Hook PyQt6 créé

:: CHECKPOINT 5 - Création du patch PyTorch 2.6
echo.
echo CHECKPOINT 5 - Création du patch PyTorch 2.6...
echo CHECKPOINT 5 - Création du patch PyTorch 2.6... >> "%HOOK_LOG%"

echo # Patch pour PyTorch 2.6+ > "%~dp0pytorch_2_6_patch.py"
echo """Patch pour assurer la compatibilité avec PyTorch 2.6+ qui utilise weights_only=True par défaut""" >> "%~dp0pytorch_2_6_patch.py"
echo import sys >> "%~dp0pytorch_2_6_patch.py"
echo import torch >> "%~dp0pytorch_2_6_patch.py"
echo import importlib >> "%~dp0pytorch_2_6_patch.py"
echo import logging >> "%~dp0pytorch_2_6_patch.py"
echo. >> "%~dp0pytorch_2_6_patch.py"
echo logger = logging.getLogger(__name__) >> "%~dp0pytorch_2_6_patch.py"
echo. >> "%~dp0pytorch_2_6_patch.py"
echo def apply_patch(): >> "%~dp0pytorch_2_6_patch.py"
echo     """Applique le patch pour PyTorch 2.6+""" >> "%~dp0pytorch_2_6_patch.py"
echo     try: >> "%~dp0pytorch_2_6_patch.py"
echo         if hasattr(torch.serialization, 'add_safe_globals'): >> "%~dp0pytorch_2_6_patch.py"
echo             logger.info("Application du patch PyTorch 2.6+ pour XTTS") >> "%~dp0pytorch_2_6_patch.py"
echo. >> "%~dp0pytorch_2_6_patch.py"
echo             # Liste des classes à ajouter à safe_globals >> "%~dp0pytorch_2_6_patch.py"
echo             classes_to_add = [ >> "%~dp0pytorch_2_6_patch.py"
echo                 ('TTS.tts.configs.xtts_config', 'XttsConfig'), >> "%~dp0pytorch_2_6_patch.py"
echo                 ('TTS.tts.configs.xtts_config', 'XttsAudioConfig'), >> "%~dp0pytorch_2_6_patch.py"
echo                 ('TTS.tts.models.xtts', 'Xtts'), >> "%~dp0pytorch_2_6_patch.py"
echo                 ('TTS.utils.audio.processor', 'AudioProcessor'), >> "%~dp0pytorch_2_6_patch.py"
echo                 ('TTS.config', 'load_config'), >> "%~dp0pytorch_2_6_patch.py"
echo                 ('TTS.tts.configs.shared_configs', 'BaseTTSConfig'), >> "%~dp0pytorch_2_6_patch.py"
echo                 ('TTS.utils.audio', 'TorchSTFT'), >> "%~dp0pytorch_2_6_patch.py"
echo             ] >> "%~dp0pytorch_2_6_patch.py"
echo. >> "%~dp0pytorch_2_6_patch.py"
echo             # Importer et ajouter chaque classe >> "%~dp0pytorch_2_6_patch.py"
echo             for module_path, class_name in classes_to_add: >> "%~dp0pytorch_2_6_patch.py"
echo                 try: >> "%~dp0pytorch_2_6_patch.py"
echo                     module = importlib.import_module(module_path) >> "%~dp0pytorch_2_6_patch.py"
echo                     cls = getattr(module, class_name) >> "%~dp0pytorch_2_6_patch.py"
echo                     torch.serialization.add_safe_globals([(f"{module_path}.{class_name}", cls)]) >> "%~dp0pytorch_2_6_patch.py"
echo                     logger.info(f"Ajouté {module_path}.{class_name} à safe_globals") >> "%~dp0pytorch_2_6_patch.py"
echo                 except Exception as e: >> "%~dp0pytorch_2_6_patch.py"
echo                     logger.warning(f"Impossible d'ajouter {module_path}.{class_name}: {e}") >> "%~dp0pytorch_2_6_patch.py"
echo. >> "%~dp0pytorch_2_6_patch.py"
echo             return True >> "%~dp0pytorch_2_6_patch.py"
echo         else: >> "%~dp0pytorch_2_6_patch.py"
echo             logger.info("PyTorch < 2.6 détecté, pas besoin de patch") >> "%~dp0pytorch_2_6_patch.py"
echo             return False >> "%~dp0pytorch_2_6_patch.py"
echo     except Exception as e: >> "%~dp0pytorch_2_6_patch.py"
echo         logger.error(f"Erreur lors de l'application du patch PyTorch: {e}") >> "%~dp0pytorch_2_6_patch.py"
echo         return False >> "%~dp0pytorch_2_6_patch.py"
echo. >> "%~dp0pytorch_2_6_patch.py"
echo if __name__ == "__main__": >> "%~dp0pytorch_2_6_patch.py"
echo     logging.basicConfig(level=logging.INFO) >> "%~dp0pytorch_2_6_patch.py"
echo     apply_patch() >> "%~dp0pytorch_2_6_patch.py"

echo Patch PyTorch 2.6 créé: %~dp0pytorch_2_6_patch.py >> "%HOOK_LOG%"
echo Patch PyTorch 2.6 créé

:: Vérifier le fonctionnement du patch
echo.
echo Test du patch PyTorch...
echo Test du patch PyTorch... >> "%HOOK_LOG%"

python "%~dp0pytorch_2_6_patch.py" > "%TEMP%\patch_test.txt" 2>&1
set PATCH_TEST=%ERRORLEVEL%
type "%TEMP%\patch_test.txt" >> "%HOOK_LOG%"
type "%TEMP%\patch_test.txt"
del "%TEMP%\patch_test.txt"

if %PATCH_TEST% NEQ 0 (
    echo AVERTISSEMENT: Le test du patch PyTorch a échoué >> "%HOOK_ERROR%"
    echo AVERTISSEMENT: Le test du patch PyTorch a échoué
    echo Cela pourrait causer des problèmes avec les modèles XTTS
    echo Continuer quand même? (O/N)
    set /p CONTINUE=
    if /i not "%CONTINUE%"=="O" (
        echo Opération annulée par l'utilisateur >> "%HOOK_LOG%"
        echo Opération annulée.
        exit /b 1
    )
)

:: CHECKPOINT 6 - Création du hook pour trainer
echo.
echo CHECKPOINT 6 - Création du hook pour trainer...
echo CHECKPOINT 6 - Création du hook pour trainer... >> "%HOOK_LOG%"

echo # Fichier hook-trainer.py pour PyInstaller > "%HOOKS_DIR%\hook-trainer.py"
echo from PyInstaller.utils.hooks import collect_all, collect_data_files >> "%HOOKS_DIR%\hook-trainer.py"
echo from pathlib import Path >> "%HOOKS_DIR%\hook-trainer.py"
echo import os >> "%HOOKS_DIR%\hook-trainer.py"
echo. >> "%HOOKS_DIR%\hook-trainer.py"
echo # Collecter tous les modules, les packages et les données >> "%HOOKS_DIR%\hook-trainer.py"
echo datas, binaries, hiddenimports = collect_all('trainer') >> "%HOOKS_DIR%\hook-trainer.py"
echo. >> "%HOOKS_DIR%\hook-trainer.py"
echo # Ajouter explicitement le fichier VERSION >> "%HOOKS_DIR%\hook-trainer.py"
echo trainer_path = os.path.dirname(__file__) >> "%HOOKS_DIR%\hook-trainer.py"
echo version_path = Path(trainer_path).parent / 'VERSION_trainer' >> "%HOOKS_DIR%\hook-trainer.py"
echo. >> "%HOOKS_DIR%\hook-trainer.py"
echo # Créer un fichier VERSION temporaire s'il n'existe pas >> "%HOOKS_DIR%\hook-trainer.py"
echo if not version_path.exists(): >> "%HOOKS_DIR%\hook-trainer.py"
echo     with open(version_path, 'w') as f: >> "%HOOKS_DIR%\hook-trainer.py"
echo         f.write('0.0.36') >> "%HOOKS_DIR%\hook-trainer.py"
echo. >> "%HOOKS_DIR%\hook-trainer.py"
echo # Ajouter le fichier VERSION au package trainer >> "%HOOKS_DIR%\hook-trainer.py"
echo datas.append((str(version_path), 'trainer')) >> "%HOOKS_DIR%\hook-trainer.py"
echo. >> "%HOOKS_DIR%\hook-trainer.py"
echo # S'assurer que tous les imports nécessaires sont présents >> "%HOOKS_DIR%\hook-trainer.py"
echo hiddenimports.extend([ >> "%HOOKS_DIR%\hook-trainer.py"
echo     'trainer.trainer', >> "%HOOKS_DIR%\hook-trainer.py"
echo     'trainer.io', >> "%HOOKS_DIR%\hook-trainer.py"
echo     'trainer.logging', >> "%HOOKS_DIR%\hook-trainer.py"
echo     'trainer.callback', >> "%HOOKS_DIR%\hook-trainer.py"
echo ]) >> "%HOOKS_DIR%\hook-trainer.py"

echo Hook trainer créé: %HOOKS_DIR%\hook-trainer.py >> "%HOOK_LOG%"
echo Hook trainer créé

echo.
echo ===== CRÉATION DES HOOKS TERMINÉE =====
echo ===== CRÉATION DES HOOKS TERMINÉE ===== >> "%HOOK_LOG%"
echo Tous les hooks et patches ont été créés avec succès.
echo Vous pouvez maintenant exécuter build_exec.bat
echo.

endlocal

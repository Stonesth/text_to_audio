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


:: CHECKPOINT 5 - Création du hook pour trainer
echo.
echo CHECKPOINT 5 - Création du hook pour trainer...
echo CHECKPOINT 5 - Création du hook pour trainer... >> "%HOOK_LOG%"

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

@REM :: CHECKPOINT 6 - Création du patch PyTorch 2.6
@REM echo.
@REM echo CHECKPOINT 6 - Création du patch PyTorch 2.6...
@REM echo CHECKPOINT 6 - Création du patch PyTorch 2.6... >> "%HOOK_LOG%"

@REM echo # Patch pour PyTorch 2.6+ > "%~dp0pytorch_2_6_patch.py"
@REM echo """Patch pour assurer la compatibilité avec PyTorch 2.6+ qui utilise weights_only=True par défaut""" >> "%~dp0pytorch_2_6_patch.py"
@REM echo import sys >> "%~dp0pytorch_2_6_patch.py"
@REM echo import torch >> "%~dp0pytorch_2_6_patch.py"
@REM echo import importlib >> "%~dp0pytorch_2_6_patch.py"
@REM echo import logging >> "%~dp0pytorch_2_6_patch.py"
@REM echo. >> "%~dp0pytorch_2_6_patch.py"
@REM echo logger = logging.getLogger(__name__) >> "%~dp0pytorch_2_6_patch.py"
@REM echo. >> "%~dp0pytorch_2_6_patch.py"
@REM echo def apply_patch(): >> "%~dp0pytorch_2_6_patch.py"
@REM echo     """Applique le patch pour PyTorch 2.6+""" >> "%~dp0pytorch_2_6_patch.py"
@REM echo     try: >> "%~dp0pytorch_2_6_patch.py"
@REM echo         if hasattr(torch.serialization, 'add_safe_globals'): >> "%~dp0pytorch_2_6_patch.py"
@REM echo             logger.info("Application du patch PyTorch 2.6+ pour XTTS") >> "%~dp0pytorch_2_6_patch.py"
@REM echo. >> "%~dp0pytorch_2_6_patch.py"
@REM echo             # Liste des classes à ajouter à safe_globals >> "%~dp0pytorch_2_6_patch.py"
@REM echo             classes_to_add = [ >> "%~dp0pytorch_2_6_patch.py"
@REM echo                 ('TTS.tts.configs.xtts_config', 'XttsConfig'), >> "%~dp0pytorch_2_6_patch.py"
@REM echo                 ('TTS.tts.configs.xtts_config', 'XttsAudioConfig'), >> "%~dp0pytorch_2_6_patch.py"
@REM echo                 ('TTS.tts.models.xtts', 'Xtts'), >> "%~dp0pytorch_2_6_patch.py"
@REM echo                 ('TTS.utils.audio.processor', 'AudioProcessor'), >> "%~dp0pytorch_2_6_patch.py"
@REM echo                 ('TTS.config', 'load_config'), >> "%~dp0pytorch_2_6_patch.py"
@REM echo                 ('TTS.tts.configs.shared_configs', 'BaseTTSConfig'), >> "%~dp0pytorch_2_6_patch.py"
@REM echo                 ('TTS.utils.audio', 'TorchSTFT'), >> "%~dp0pytorch_2_6_patch.py"
@REM echo             ] >> "%~dp0pytorch_2_6_patch.py"
@REM echo. >> "%~dp0pytorch_2_6_patch.py"
@REM echo             # Importer et ajouter chaque classe >> "%~dp0pytorch_2_6_patch.py"
@REM echo             for module_path, class_name in classes_to_add: >> "%~dp0pytorch_2_6_patch.py"
@REM echo                 try: >> "%~dp0pytorch_2_6_patch.py"
@REM echo                     module = importlib.import_module(module_path) >> "%~dp0pytorch_2_6_patch.py"
@REM echo                     cls = getattr(module, class_name) >> "%~dp0pytorch_2_6_patch.py"
@REM echo                     torch.serialization.add_safe_globals([(f"{module_path}.{class_name}", cls)]) >> "%~dp0pytorch_2_6_patch.py"
@REM echo                     logger.info(f"Ajouté {module_path}.{class_name} à safe_globals") >> "%~dp0pytorch_2_6_patch.py"
@REM echo                 except Exception as e: >> "%~dp0pytorch_2_6_patch.py"
@REM echo                     logger.warning(f"Impossible d'ajouter {module_path}.{class_name}: {e}") >> "%~dp0pytorch_2_6_patch.py"
@REM echo. >> "%~dp0pytorch_2_6_patch.py"
@REM echo             return True >> "%~dp0pytorch_2_6_patch.py"
@REM echo         else: >> "%~dp0pytorch_2_6_patch.py"
@REM echo             logger.info("PyTorch < 2.6 détecté, pas besoin de patch") >> "%~dp0pytorch_2_6_patch.py"
@REM echo             return False >> "%~dp0pytorch_2_6_patch.py"
@REM echo     except Exception as e: >> "%~dp0pytorch_2_6_patch.py"
@REM echo         logger.error(f"Erreur lors de l'application du patch PyTorch: {e}") >> "%~dp0pytorch_2_6_patch.py"
@REM echo         return False >> "%~dp0pytorch_2_6_patch.py"
@REM echo. >> "%~dp0pytorch_2_6_patch.py"
@REM echo if __name__ == "__main__": >> "%~dp0pytorch_2_6_patch.py"
@REM echo     logging.basicConfig(level=logging.INFO) >> "%~dp0pytorch_2_6_patch.py"
@REM echo     apply_patch() >> "%~dp0pytorch_2_6_patch.py"

@REM echo Patch PyTorch 2.6 créé: %~dp0pytorch_2_6_patch.py >> "%HOOK_LOG%"
@REM echo Patch PyTorch 2.6 créé

@REM :: Vérifier le fonctionnement du patch
@REM echo.
@REM echo Test du patch PyTorch...
@REM echo Test du patch PyTorch... >> "%HOOK_LOG%"

@REM python "%~dp0pytorch_2_6_patch.py" > "%TEMP%\patch_test.txt" 2>&1
@REM set PATCH_TEST=%ERRORLEVEL%
@REM type "%TEMP%\patch_test.txt" >> "%HOOK_LOG%"
@REM type "%TEMP%\patch_test.txt"
@REM del "%TEMP%\patch_test.txt"

@REM if %PATCH_TEST% NEQ 0 (
@REM     echo AVERTISSEMENT: Le test du patch PyTorch a échoué >> "%HOOK_ERROR%"
@REM     echo AVERTISSEMENT: Le test du patch PyTorch a échoué
@REM     echo Cela pourrait causer des problèmes avec les modèles XTTS
@REM     echo Continuer quand même? (O/N)
@REM     set /p CONTINUE=
@REM     if /i not "%CONTINUE%"=="O" (
@REM         echo Opération annulée par l'utilisateur >> "%HOOK_LOG%"
@REM         echo Opération annulée.
@REM         exit /b 1
@REM     )
@REM )

:: CHECKPOINT 7 - Création du hook pour inflect
echo.
echo CHECKPOINT 7 - Création du hook pour inflect...
echo CHECKPOINT 7 - Création du hook pour inflect... >> "%HOOK_LOG%"

echo # Fichier hook-inflect.py pour PyInstaller > "%HOOKS_DIR%\hook-inflect.py"
echo from PyInstaller.utils.hooks import collect_all, collect_submodules >> "%HOOKS_DIR%\hook-inflect.py"
echo import os >> "%HOOKS_DIR%\hook-inflect.py"
echo import sys >> "%HOOKS_DIR%\hook-inflect.py"
echo. >> "%HOOKS_DIR%\hook-inflect.py"
echo # Collecter tous les modules et sous-modules >> "%HOOKS_DIR%\hook-inflect.py"
echo datas, binaries, hiddenimports = collect_all('inflect') >> "%HOOKS_DIR%\hook-inflect.py"
echo. >> "%HOOKS_DIR%\hook-inflect.py"
echo # Ajouter typeguard et ses sous-modules >> "%HOOKS_DIR%\hook-inflect.py"
echo hiddenimports.extend(collect_submodules('typeguard')) >> "%HOOKS_DIR%\hook-inflect.py"
echo. >> "%HOOKS_DIR%\hook-inflect.py"
echo # Créer un fichier d'environnement pour désactiver les vérifications typeguard >> "%HOOKS_DIR%\hook-inflect.py"
echo typeguard_env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'typeguard_env.py') >> "%HOOKS_DIR%\hook-inflect.py"
echo with open(typeguard_env_path, 'w') as f: >> "%HOOKS_DIR%\hook-inflect.py"
echo     f.write('import os\nos.environ["TYPEGUARD_DISABLE"] = "1"\n') >> "%HOOKS_DIR%\hook-inflect.py"
echo. >> "%HOOKS_DIR%\hook-inflect.py"
echo # Ajouter le fichier d'environnement aux données >> "%HOOKS_DIR%\hook-inflect.py"
echo datas.append((typeguard_env_path, '.')) >> "%HOOKS_DIR%\hook-inflect.py"

echo Hook inflect créé: %HOOKS_DIR%\hook-inflect.py >> "%HOOK_LOG%"
echo Hook inflect créé

:: CHECKPOINT 8 - Création du fichier d'environnement typeguard_env.py
echo.
echo CHECKPOINT 8 - Création du fichier d'environnement typeguard_env.py...
echo CHECKPOINT 8 - Création du fichier d'environnement typeguard_env.py... >> "%HOOK_LOG%"

echo import os > "%~dp0typeguard_env.py"
echo os.environ["TYPEGUARD_DISABLE"] = "1" >> "%~dp0typeguard_env.py"

echo Fichier d'environnement typeguard créé: %~dp0typeguard_env.py >> "%HOOK_LOG%"
echo Fichier d'environnement typeguard créé

:: CHECKPOINT 9 - Création du hook pour jamo
echo.
echo CHECKPOINT 9 - Création du hook pour jamo...
echo CHECKPOINT 9 - Création du hook pour jamo... >> "%HOOK_LOG%"

echo # Fichier hook-jamo.py pour PyInstaller > "%HOOKS_DIR%\hook-jamo.py"
echo from PyInstaller.utils.hooks import collect_data_files, copy_metadata >> "%HOOKS_DIR%\hook-jamo.py"
echo import os >> "%HOOKS_DIR%\hook-jamo.py"
echo import sys >> "%HOOKS_DIR%\hook-jamo.py"
echo import jamo >> "%HOOKS_DIR%\hook-jamo.py"
echo import shutil >> "%HOOKS_DIR%\hook-jamo.py"
echo. >> "%HOOKS_DIR%\hook-jamo.py"
echo # Collecter tous les fichiers de données >> "%HOOKS_DIR%\hook-jamo.py"
echo datas = collect_data_files('jamo') >> "%HOOKS_DIR%\hook-jamo.py"
echo. >> "%HOOKS_DIR%\hook-jamo.py"
echo # Ajouter explicitement les fichiers JSON de données >> "%HOOKS_DIR%\hook-jamo.py"
echo jamo_path = os.path.dirname(jamo.__file__) >> "%HOOKS_DIR%\hook-jamo.py"
echo data_dir = os.path.join(jamo_path, 'data') >> "%HOOKS_DIR%\hook-jamo.py"
echo. >> "%HOOKS_DIR%\hook-jamo.py"
echo # S'assurer que tous les fichiers JSON sont inclus >> "%HOOKS_DIR%\hook-jamo.py"
echo for file in os.listdir(data_dir): >> "%HOOKS_DIR%\hook-jamo.py"
echo     if file.endswith('.json'): >> "%HOOKS_DIR%\hook-jamo.py"
echo         source_file = os.path.join(data_dir, file) >> "%HOOKS_DIR%\hook-jamo.py"
echo         datas.append((source_file, os.path.join('jamo', 'data'))) >> "%HOOKS_DIR%\hook-jamo.py"
echo         print(f"Ajout du fichier {file} au package jamo") >> "%HOOKS_DIR%\hook-jamo.py"

echo Hook jamo créé: %HOOKS_DIR%\hook-jamo.py >> "%HOOK_LOG%"
echo Hook jamo créé

echo.
echo ===== TOUTES LES OPÉRATIONS SONT TERMINÉES =====
echo ===== TOUTES LES OPÉRATIONS SONT TERMINÉES ===== >> "%HOOK_LOG%"

echo.
echo Utilisez build_exec.bat pour lancer la compilation avec PyInstaller
echo.
echo Terminé.

endlocal

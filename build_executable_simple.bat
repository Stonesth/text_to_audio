@echo on
setlocal enabledelayedexpansion

:: ===== CONFIGURATION DES LOGS =====
set "LOG_FILE=%~dp0logs\build_simple.txt"
set "ERROR_FILE=%~dp0logs\error_simple.txt"
set "DEBUG_FILE=%~dp0logs\debug_simple.txt"

:: Creation dossier de logs
if not exist "%~dp0logs" mkdir "%~dp0logs"

echo ===== JOURNAL DE COMPILATION PYINSTALLER ===== > "%LOG_FILE%"
echo Date et heure: %DATE% %TIME% >> "%LOG_FILE%"

echo ===== ERREURS DE COMPILATION PYINSTALLER ===== > "%ERROR_FILE%"
echo Date et heure: %DATE% %TIME% >> "%ERROR_FILE%"

echo ===== DEBUG DETAILLE DE LA COMPILATION ===== > "%DEBUG_FILE%"
echo Date et heure: %DATE% %TIME% >> "%DEBUG_FILE%"

echo ===== CREATION DE L'EXECUTABLE AVEC PYINSTALLER =====
echo Date et heure: %DATE% %TIME%
echo Demarrage du script >> "%LOG_FILE%"

:: ===== VERIFICATION DE LA VERSION PYTHON =====
echo Verification de la version Python >> "%LOG_FILE%"
echo Verification de la version Python...

:: Capturer la version de Python
python --version > "%TEMP%\python_version.txt" 2>&1
set /p PYTHON_VERSION=<"%TEMP%\python_version.txt"
del "%TEMP%\python_version.txt"

echo Version Python detectee: %PYTHON_VERSION% >> "%LOG_FILE%"
echo Version Python detectee: %PYTHON_VERSION% >> "%DEBUG_FILE%"
echo Version Python detectee: %PYTHON_VERSION%

:: Verifier si c'est Python 3.10
echo %PYTHON_VERSION% | findstr "3.10" > nul
if %ERRORLEVEL% neq 0 (
    echo AVERTISSEMENT: La version Python detectee n'est pas 3.10 >> "%ERROR_FILE%"
    echo AVERTISSEMENT: La version Python detectee n'est pas 3.10
    echo AVERTISSEMENT: La version Python detectee n'est pas 3.10 >> "%DEBUG_FILE%"
    echo Il est recommande d'utiliser Python 3.10 pour garantir la compatibilite.
    echo Voulez-vous continuer quand meme? (O/N)
    set /p CONTINUE=
    if /i "%CONTINUE%" neq "O" (
        echo Compilation annulee par l'utilisateur >> "%LOG_FILE%"
        echo Compilation annulee.
        exit /b 1
    )
    echo L'utilisateur a choisi de continuer avec Python %PYTHON_VERSION% >> "%LOG_FILE%"
    echo Poursuite avec Python %PYTHON_VERSION% >> "%DEBUG_FILE%"
)

:: ===== VERIFICATION ENVIRONNEMENT VIRTUEL =====

echo Verification de l'environnement virtuel venv_py310 >> "%LOG_FILE%"
echo Verification de l'environnement virtuel venv_py310 >> "%DEBUG_FILE%"

:: Forcer l'activation de l'environnement virtuel même si déjà activé
echo Forcage de l'activation de l'environnement virtuel... >> "%DEBUG_FILE%"

:: Déterminer le chemin absolu de l'environnement virtuel
set "VENV_PATH=%~dp0venv_py310"
echo Chemin absolu de l'environnement virtuel: %VENV_PATH% >> "%DEBUG_FILE%"

:: Vérifier si le répertoire existe
if not exist "%VENV_PATH%" (
    echo ERREUR: L'environnement virtuel n'existe pas au chemin %VENV_PATH% >> "%ERROR_FILE%"
    echo ERREUR: L'environnement virtuel n'existe pas au chemin %VENV_PATH% >> "%DEBUG_FILE%"
    echo ERREUR: L'environnement virtuel n'existe pas.
    echo Veuillez créer un environnement virtuel avec la commande:
    echo python -m venv venv_py310
    exit /b 1
)

:: Tester l'activation avec redirection explicite des erreurs
echo Test d'activation avec redirection des erreurs... >> "%DEBUG_FILE%"
call "%VENV_PATH%\Scripts\activate.bat" > "%TEMP%\venv_activation.txt" 2>&1
set ACTIVATION_CODE=%ERRORLEVEL%

:: Vérifier si l'activation a réussi
type "%TEMP%\venv_activation.txt" >> "%DEBUG_FILE%"
echo Code de retour de l'activation: %ACTIVATION_CODE% >> "%DEBUG_FILE%"

if %ACTIVATION_CODE% neq 0 (
    echo ERREUR: Impossible d'activer l'environnement virtuel (code %ACTIVATION_CODE%) >> "%ERROR_FILE%"
    echo ERREUR: Impossible d'activer l'environnement virtuel (code %ACTIVATION_CODE%) >> "%DEBUG_FILE%"
    type "%TEMP%\venv_activation.txt" >> "%ERROR_FILE%"
    echo ERREUR: Impossible d'activer l'environnement virtuel
    echo Veuillez vérifier que l'environnement virtuel est correctement configuré
    exit /b 1
)
del "%TEMP%\venv_activation.txt"

if not defined VIRTUAL_ENV (
    echo Impossible d'activer l'environnement virtuel venv_py310 >> "%ERROR_FILE%"
    echo Impossible d'activer l'environnement virtuel venv_py310 >> "%DEBUG_FILE%"
    echo ERREUR: Impossible d'activer l'environnement virtuel venv_py310.
    pause
    exit /b 1
)
echo Environnement virtuel active avec succes: %VIRTUAL_ENV%
echo Environnement virtuel active: %VIRTUAL_ENV% >> "%LOG_FILE%"
echo Environnement virtuel active: %VIRTUAL_ENV% >> "%DEBUG_FILE%"

:: ===== VERIFICATION PYINSTALLER =====

echo Verification de PyInstaller >> "%LOG_FILE%"
echo Verification de PyInstaller >> "%DEBUG_FILE%"
pip show pyinstaller > "%TEMP%\pyinstaller_info.txt" 2>&1
type "%TEMP%\pyinstaller_info.txt" >> "%DEBUG_FILE%"
del "%TEMP%\pyinstaller_info.txt"

pip show pyinstaller > nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Installation de PyInstaller... >> "%LOG_FILE%"
    echo Installation de PyInstaller... >> "%DEBUG_FILE%"
    echo Installation de PyInstaller...
    pip install pyinstaller > "%TEMP%\pip_install.txt" 2>&1
    type "%TEMP%\pip_install.txt" >> "%DEBUG_FILE%"
    del "%TEMP%\pip_install.txt"
    
    if %ERRORLEVEL% neq 0 (
        echo Impossible d'installer PyInstaller >> "%ERROR_FILE%"
        echo Impossible d'installer PyInstaller >> "%DEBUG_FILE%"
        echo ERREUR: Impossible d'installer PyInstaller
        exit /b 1
    )
)
echo PyInstaller est disponible >> "%LOG_FILE%"
echo PyInstaller est disponible >> "%DEBUG_FILE%"

:: ===== CREATION DES FICHIERS PYTHON =====
echo Creation des fichiers Python (hooks et patch) >> "%LOG_FILE%"
echo Creation des fichiers Python (hooks et patch) >> "%DEBUG_FILE%"

:: Creation du hook PyTorch
del /f /q pytorch_hook.py 2>nul
echo Creation du hook PyTorch... >> "%DEBUG_FILE%"
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
echo Hook PyTorch cree avec succes >> "%DEBUG_FILE%"
if exist pytorch_hook.py echo Verification: Hook PyTorch existe bien dans %CD% >> "%DEBUG_FILE%"

:: Creation du hook TTS
del /f /q tts_hook.py 2>nul
echo Creation du hook TTS... >> "%DEBUG_FILE%"
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
echo         'TTS.utils.audio.torch_transforms.TorchSTFT',
echo         'PyQt6.sip'
echo     ]
echo     hook_api.add_imports(*classes)
) > tts_hook.py
echo Hook TTS cree avec succes >> "%LOG_FILE%"
echo Hook TTS cree avec succes >> "%DEBUG_FILE%"
if exist tts_hook.py echo Verification: Hook TTS existe bien dans %CD% >> "%DEBUG_FILE%"

:: Creation du patch PyTorch 2.6+
del /f /q pytorch_2_6_patch.py 2>nul
echo Creation du patch PyTorch 2.6+... >> "%DEBUG_FILE%"
echo Creation du patch PyTorch 2.6+...
@(
echo # Patch pour assurer la compatibilite avec PyTorch 2.6+
echo import torch
echo import warnings
echo import sys
echo 
echo def apply_patch():
echo     # Afficher la version de PyTorch
echo     print(f"Version de PyTorch: {torch.__version__}")
echo     print(f"Version de Python: {sys.version}")
echo     # Applique le patch pour PyTorch 2.6+
echo     try:
echo         if hasattr(torch.serialization, 'add_safe_globals'):
echo             # Classes a ajouter a la liste des classes securisees
echo             print("PyTorch 2.6+ detecte, application du patch de securite...")
echo             from TTS.tts.configs.xtts_config import XttsConfig
echo             from TTS.tts.configs.shared_configs import XttsAudioConfig
echo             from TTS.api import Xtts
echo             from TTS.utils.audio import AudioProcessor
echo             from TTS.config import load_config
echo             from TTS.tts.configs.base_tts_config import BaseTTSConfig
echo             from TTS.utils.audio.torch_transforms import TorchSTFT
echo 
echo             classes_securisees = [XttsConfig, XttsAudioConfig, Xtts,
echo                                 AudioProcessor, load_config, BaseTTSConfig, TorchSTFT]
echo 
echo             print(f"Classes a securiser: {len(classes_securisees)}")
echo             for idx, cls in enumerate(classes_securisees):
echo                 print(f"  {idx+1}. {cls.__name__}")
echo 
echo             # Ajouter toutes les classes a la liste des classes securisees
echo             torch.serialization.add_safe_globals(classes_securisees)
echo             print("Patch PyTorch 2.6+ applique avec succes!")
echo         else:
echo             print("PyTorch version < 2.6 detecte, patch non necessaire")
echo     except Exception as e:
echo         warnings.warn(f"Impossible d'appliquer le patch PyTorch 2.6+: {str(e)}")
echo         import traceback
echo         traceback.print_exc()
echo 
echo # Appliquer le patch automatiquement a l'importation
echo apply_patch()
) > pytorch_2_6_patch.py
echo Patch PyTorch 2.6+ cree avec succes >> "%LOG_FILE%"
echo Patch PyTorch 2.6+ cree avec succes >> "%DEBUG_FILE%"
if exist pytorch_2_6_patch.py echo Verification: Patch PyTorch existe bien dans %CD% >> "%DEBUG_FILE%"

:: ===== VERIFICATION DES IMPORTATIONS APRÈS HOOKS =====
echo Verification des importations apres creation des hooks... >> "%DEBUG_FILE%"
echo ===== TEST IMPORTATION HOOKS ET PATCH ===== > "%TEMP%\import_test.txt"

:: Créer un script temporaire pour tester les importations
echo import sys > "%TEMP%\test_imports.py"
echo print("Python: " + sys.version) >> "%TEMP%\test_imports.py"
echo print("\nChemin d'importation:") >> "%TEMP%\test_imports.py"
echo for path in sys.path: >> "%TEMP%\test_imports.py"
echo     print(f"  - {path}") >> "%TEMP%\test_imports.py"
echo. >> "%TEMP%\test_imports.py"

:: Test des imports clés
echo print("\nTest des imports cles:") >> "%TEMP%\test_imports.py"
echo modules_a_tester = ['PyQt6', 'PyQt6.sip', 'torch', 'TTS', 'pytorch_2_6_patch'] >> "%TEMP%\test_imports.py"
echo for module_name in modules_a_tester: >> "%TEMP%\test_imports.py"
echo     try: >> "%TEMP%\test_imports.py"
echo         exec(f"import {module_name}") >> "%TEMP%\test_imports.py"
echo         module = eval(module_name.split('.')[0]) >> "%TEMP%\test_imports.py"
echo         version = getattr(module, '__version__', 'Inconnue') >> "%TEMP%\test_imports.py"
echo         filepath = getattr(module, '__file__', 'Inconnu') >> "%TEMP%\test_imports.py"
echo         print(f"  {module_name}: OK") >> "%TEMP%\test_imports.py"
echo         print(f"    Version: {version}") >> "%TEMP%\test_imports.py"
echo         print(f"    Chemin: {filepath}") >> "%TEMP%\test_imports.py"
echo     except Exception as e: >> "%TEMP%\test_imports.py"
echo         print(f"  {module_name}: ERREUR - {str(e)}") >> "%TEMP%\test_imports.py"
echo         import traceback >> "%TEMP%\test_imports.py"
echo         traceback.print_exc() >> "%TEMP%\test_imports.py"

:: Vérifier specifiquement pour torch.serialization.add_safe_globals
echo. >> "%TEMP%\test_imports.py"
echo print("\nVerification de torch.serialization.add_safe_globals:") >> "%TEMP%\test_imports.py"
echo try: >> "%TEMP%\test_imports.py"
echo     import torch >> "%TEMP%\test_imports.py"
echo     if hasattr(torch.serialization, 'add_safe_globals'): >> "%TEMP%\test_imports.py"
echo         print("  add_safe_globals est disponible") >> "%TEMP%\test_imports.py"
echo     else: >> "%TEMP%\test_imports.py"
echo         print("  add_safe_globals n'est PAS disponible") >> "%TEMP%\test_imports.py"
echo except Exception as e: >> "%TEMP%\test_imports.py"
echo     print(f"  ERREUR lors de la verification: {str(e)}") >> "%TEMP%\test_imports.py"

:: Exécuter le script de test et capturer la sortie
python "%TEMP%\test_imports.py" > "%TEMP%\import_test.txt" 2>&1
type "%TEMP%\import_test.txt" >> "%DEBUG_FILE%"
echo Resultat du test d'importation: %ERRORLEVEL% >> "%DEBUG_FILE%"
del "%TEMP%\test_imports.py"
del "%TEMP%\import_test.txt"

:: ===== CREATION DU FICHIER SPEC =====
echo Creation du fichier spec PyInstaller... >> "%LOG_FILE%"
echo Creation du fichier spec PyInstaller... >> "%DEBUG_FILE%"

:: Tester l'importation des modules avant de créer le spec
echo Verification des imports Python importants... >> "%DEBUG_FILE%"
python -c "import sys; print(f'Python: {sys.version}'); import torch; print(f'PyTorch: {torch.__version__}'); import PyQt6; print('PyQt6 importe avec succes'); import PyQt6.sip; print('PyQt6.sip importe avec succes'); import TTS; print(f'TTS version: {TTS.__version__}')" >> "%DEBUG_FILE%" 2>&1
echo Resultat des tests d'importation: %ERRORLEVEL% >> "%DEBUG_FILE%"

echo # -*- mode: python ; coding: utf-8 -*- > Simple_TTS_GUI.spec
echo import os >> Simple_TTS_GUI.spec
echo import sys >> Simple_TTS_GUI.spec
echo from PyInstaller.utils.hooks import collect_all, collect_data_files >> Simple_TTS_GUI.spec
echo. >> Simple_TTS_GUI.spec
echo # Journal de debug >> Simple_TTS_GUI.spec
echo with open('%~dp0logs\debug_simple.txt', 'a') as debug_file: >> Simple_TTS_GUI.spec
echo     debug_file.write('Creation du fichier spec en cours...\n') >> Simple_TTS_GUI.spec
echo     debug_file.write(f'Chemin absolu: {os.path.abspath(".")}\n') >> Simple_TTS_GUI.spec
echo. >> Simple_TTS_GUI.spec
echo block_cipher = None >> Simple_TTS_GUI.spec
echo. >> Simple_TTS_GUI.spec
echo # Collecte des donnees >> Simple_TTS_GUI.spec
echo with open('%~dp0logs\debug_simple.txt', 'a') as debug_file: >> Simple_TTS_GUI.spec
echo     debug_file.write('Collecte des donnees de packages...\n') >> Simple_TTS_GUI.spec
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
echo     ('pytorch_hook.py', '.'), >> Simple_TTS_GUI.spec
echo     ('tts_hook.py', '.'), >> Simple_TTS_GUI.spec
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
echo # Journaliser les hiddenimports >> Simple_TTS_GUI.spec
echo with open('%~dp0logs\debug_simple.txt', 'a') as debug_file: >> Simple_TTS_GUI.spec
echo     debug_file.write('Liste des imports caches:\n') >> Simple_TTS_GUI.spec
echo     for imp in all_hiddenimports: >> Simple_TTS_GUI.spec
echo         debug_file.write(f'  - {imp}\n') >> Simple_TTS_GUI.spec
echo. >> Simple_TTS_GUI.spec
echo # Gestionnaire d'erreur global >> Simple_TTS_GUI.spec
echo import sys >> Simple_TTS_GUI.spec
echo original_excepthook = sys.excepthook >> Simple_TTS_GUI.spec
echo def custom_excepthook(exctype, value, traceback): >> Simple_TTS_GUI.spec
echo     with open('%~dp0logs\error_simple.txt', 'a') as err_file: >> Simple_TTS_GUI.spec
echo         err_file.write(f"\n\n===== ERREUR CRITIQUE DANS LE SPEC =====\n") >> Simple_TTS_GUI.spec
echo         err_file.write(f"Type: {exctype}\n") >> Simple_TTS_GUI.spec
echo         err_file.write(f"Valeur: {value}\n") >> Simple_TTS_GUI.spec
echo         import traceback as tb >> Simple_TTS_GUI.spec
echo         tb.print_exc(file=err_file) >> Simple_TTS_GUI.spec
echo     # Appel au gestionnaire d'origine >> Simple_TTS_GUI.spec
echo     original_excepthook(exctype, value, traceback) >> Simple_TTS_GUI.spec
echo sys.excepthook = custom_excepthook >> Simple_TTS_GUI.spec
echo. >> Simple_TTS_GUI.spec
echo try: # Envelopper tout le code dans un bloc try-except global >> Simple_TTS_GUI.spec
echo     a = Analysis( >> Simple_TTS_GUI.spec
echo         ['Simple_TTS_GUI.py'], >> Simple_TTS_GUI.spec
echo         pathex=[os.path.abspath('.')], >> Simple_TTS_GUI.spec
echo         binaries=all_binaries, >> Simple_TTS_GUI.spec
echo         datas=all_datas, >> Simple_TTS_GUI.spec
echo         hiddenimports=all_hiddenimports, >> Simple_TTS_GUI.spec
echo         hookspath=['.'], >> Simple_TTS_GUI.spec
echo         hooksconfig={}, >> Simple_TTS_GUI.spec
echo         runtime_hooks=[], >> Simple_TTS_GUI.spec
echo         excludes=[], >> Simple_TTS_GUI.spec
echo         win_no_prefer_redirects=False, >> Simple_TTS_GUI.spec
echo         win_private_assemblies=False, >> Simple_TTS_GUI.spec
echo         cipher=block_cipher, >> Simple_TTS_GUI.spec
echo         noarchive=False, >> Simple_TTS_GUI.spec
echo     ) >> Simple_TTS_GUI.spec
echo. >> Simple_TTS_GUI.spec
echo     # Log fin de l'analyse >> Simple_TTS_GUI.spec
echo     with open('%~dp0logs\debug_simple.txt', 'a') as debug_file: >> Simple_TTS_GUI.spec
echo         debug_file.write('Analyse terminee\n') >> Simple_TTS_GUI.spec
echo. >> Simple_TTS_GUI.spec
echo     pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher) >> Simple_TTS_GUI.spec
echo. >> Simple_TTS_GUI.spec
echo     exe = EXE( >> Simple_TTS_GUI.spec
echo         pyz, >> Simple_TTS_GUI.spec
echo         a.scripts, >> Simple_TTS_GUI.spec
echo         [], >> Simple_TTS_GUI.spec
echo         exclude_binaries=True, >> Simple_TTS_GUI.spec
echo         name='Simple_TTS_GUI', >> Simple_TTS_GUI.spec
echo         debug=True, >> Simple_TTS_GUI.spec
echo         bootloader_ignore_signals=False, >> Simple_TTS_GUI.spec
echo         strip=False, >> Simple_TTS_GUI.spec
echo         upx=True, >> Simple_TTS_GUI.spec
echo         upx_exclude=[], >> Simple_TTS_GUI.spec
echo         runtime_tmpdir=None, >> Simple_TTS_GUI.spec
echo         console=True, >> Simple_TTS_GUI.spec
echo         disable_windowed_traceback=False, >> Simple_TTS_GUI.spec
echo         target_arch=None, >> Simple_TTS_GUI.spec
echo         codesign_identity=None, >> Simple_TTS_GUI.spec
echo         entitlements_file=None, >> Simple_TTS_GUI.spec
echo         icon='resources/nn_logo.png', >> Simple_TTS_GUI.spec
echo     ) >> Simple_TTS_GUI.spec
echo. >> Simple_TTS_GUI.spec
echo     coll = COLLECT( >> Simple_TTS_GUI.spec
echo         exe, >> Simple_TTS_GUI.spec
echo         a.binaries, >> Simple_TTS_GUI.spec
echo         a.zipfiles, >> Simple_TTS_GUI.spec
echo         a.datas, >> Simple_TTS_GUI.spec
echo         strip=False, >> Simple_TTS_GUI.spec
echo         upx=True, >> Simple_TTS_GUI.spec
echo         upx_exclude=[], >> Simple_TTS_GUI.spec
echo         name='Simple_TTS_GUI', >> Simple_TTS_GUI.spec
echo     ) >> Simple_TTS_GUI.spec
echo except Exception as e: >> Simple_TTS_GUI.spec
echo     with open('%~dp0logs\error_simple.txt', 'a') as err_file: >> Simple_TTS_GUI.spec
echo         err_file.write(f"\n\n===== ERREUR CRITIQUE DANS LE SPEC =====\n") >> Simple_TTS_GUI.spec
echo         err_file.write(f"Type: {type(e)}\n") >> Simple_TTS_GUI.spec
echo         err_file.write(f"Valeur: {str(e)}\n") >> Simple_TTS_GUI.spec
echo         import traceback as tb >> Simple_TTS_GUI.spec
echo         tb.print_exc(file=err_file) >> Simple_TTS_GUI.spec
echo. >> Simple_TTS_GUI.spec

echo Fichier Simple_TTS_GUI.spec cree avec succes >> "%LOG_FILE%"
echo Fichier Simple_TTS_GUI.spec cree avec succes >> "%DEBUG_FILE%"
if exist Simple_TTS_GUI.spec echo Verification: Simple_TTS_GUI.spec existe bien dans %CD% >> "%DEBUG_FILE%"

:: ===== EXECUTION DE PYINSTALLER =====

echo Demarrage de la compilation avec PyInstaller >> "%LOG_FILE%"
echo Demarrage de la compilation avec PyInstaller >> "%DEBUG_FILE%"
echo ===== Demarrage de la compilation avec PyInstaller =====

:: Execution avec journalisation detaillee
echo Execution de PyInstaller avec le fichier spec... >> "%DEBUG_FILE%"
echo. > "%TEMP%\pyinstaller_output.txt"
echo ===== DEBUT EXECUTION PYINSTALLER ===== >> "%TEMP%\pyinstaller_output.txt"

:: Capturer l'environnement avant l'exécution
echo ENVIRONNEMENT D'EXECUTION: >> "%TEMP%\pyinstaller_output.txt"
echo Repertoire courant: %CD% >> "%TEMP%\pyinstaller_output.txt"
echo PATH: %PATH% >> "%TEMP%\pyinstaller_output.txt"
echo PYTHONPATH: %PYTHONPATH% >> "%TEMP%\pyinstaller_output.txt"
echo. >> "%TEMP%\pyinstaller_output.txt"

:: Vérifier le contenu du fichier spec avant exécution
echo CONTENU DU FICHIER SPEC: >> "%TEMP%\pyinstaller_output.txt"
type Simple_TTS_GUI.spec >> "%TEMP%\pyinstaller_output.txt"
echo. >> "%TEMP%\pyinstaller_output.txt"

:: Vérifier que les hooks existe bien
if exist pytorch_hook.py echo HOOK PYTORCH EXISTE >> "%TEMP%\pyinstaller_output.txt"
if exist tts_hook.py echo HOOK TTS EXISTE >> "%TEMP%\pyinstaller_output.txt"
if exist pytorch_2_6_patch.py echo PATCH PYTORCH EXISTE >> "%TEMP%\pyinstaller_output.txt"
echo. >> "%TEMP%\pyinstaller_output.txt"

:: Demander à Python de lister tous les modules importables
echo MODULES IMPORTABLES: >> "%TEMP%\pyinstaller_output.txt"
python -c "help('modules')" >> "%TEMP%\pyinstaller_output.txt" 2>&1
echo. >> "%TEMP%\pyinstaller_output.txt"

echo ===== EXECUTION PYINSTALLER PROPREMENT DITE ===== >> "%TEMP%\pyinstaller_output.txt"
pyinstaller --clean Simple_TTS_GUI.spec >> "%TEMP%\pyinstaller_output.txt" 2>&1
set PYINSTALLER_EXIT_CODE=%ERRORLEVEL%
echo ===== FIN EXECUTION PYINSTALLER (Code: %PYINSTALLER_EXIT_CODE%) ===== >> "%TEMP%\pyinstaller_output.txt"

:: Enregistrer la sortie de PyInstaller dans les fichiers de log
type "%TEMP%\pyinstaller_output.txt" >> "%DEBUG_FILE%"
if %PYINSTALLER_EXIT_CODE% neq 0 (
    echo ERREUR PYINSTALLER DETECTEE: >> "%ERROR_FILE%"
    type "%TEMP%\pyinstaller_output.txt" >> "%ERROR_FILE%"
)
del "%TEMP%\pyinstaller_output.txt"

if %PYINSTALLER_EXIT_CODE% equ 0 (
    echo Compilation terminee avec succes >> "%LOG_FILE%"
    echo Compilation terminee avec succes >> "%DEBUG_FILE%"
    echo ===== COMPILATION TERMINEE AVEC SUCCES =====
    echo L'executable est disponible dans le dossier: %CD%\dist\Simple_TTS_GUI
) else (
    echo Erreur lors de la compilation avec code %PYINSTALLER_EXIT_CODE% >> "%ERROR_FILE%"
    echo Erreur lors de la compilation avec code %PYINSTALLER_EXIT_CODE% >> "%DEBUG_FILE%"
    echo ===== ERREUR LORS DE LA COMPILATION =====
    echo Veuillez verifier les erreurs dans le fichier %ERROR_FILE%
    echo Un journal detaille est disponible dans %DEBUG_FILE%
)

:: ===== VERIFICATION DE L'EXECUTABLE =====
if %PYINSTALLER_EXIT_CODE% equ 0 (
    echo Verification de l'executable cree... >> "%DEBUG_FILE%"
    if exist "%CD%\dist\Simple_TTS_GUI\Simple_TTS_GUI.exe" (
        echo Executable trouve avec succes >> "%DEBUG_FILE%"
        echo Taille de l'executable: >> "%DEBUG_FILE%"
        dir "%CD%\dist\Simple_TTS_GUI\Simple_TTS_GUI.exe" >> "%DEBUG_FILE%"
    ) else (
        echo Executable non trouve dans le repertoire dist >> "%ERROR_FILE%"
        echo Executable non trouve dans le repertoire dist >> "%DEBUG_FILE%"
        echo ERREUR: Executable non trouve dans le repertoire dist
    )
)

:: Desactivation de l'environnement virtuel
echo Desactivation de l'environnement virtuel >> "%LOG_FILE%"
echo Desactivation de l'environnement virtuel >> "%DEBUG_FILE%"
deactivate

echo Script termine >> "%LOG_FILE%"
echo Script termine >> "%DEBUG_FILE%"
echo Script termine.
echo Consultez les fichiers de log pour plus d'informations:
echo - Journal principal: %LOG_FILE%
echo - Journal des erreurs: %ERROR_FILE%
echo - Journal detaille: %DEBUG_FILE%

pause

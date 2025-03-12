@echo off
echo Compilation de Simple_TTS_GUI pour Windows

:: Nettoyer les anciens fichiers de compilation
echo Nettoyage des fichiers temporaires...
rd /s /q build 2>nul
rd /s /q dist 2>nul

:: Utiliser l'environnement virtuel existant
echo Activation de l'environnement virtuel existant...
call venv_py310\Scripts\activate.bat

:: Installer PyInstaller dans l'environnement existant si nu00e9cessaire
echo Installation de PyInstaller...
pip install pyinstaller

:: Cru00e9er les fichiers de patch
echo Pru00e9paration des fichiers de patch...

:: Compiler l'application en utilisant les chemins de l'environnement virtuel existant
echo Compilation de l'application...
pyinstaller --name="Simple_TTS_GUI" ^
            --onefile ^
            --debug=all ^
            --console ^
            --add-data "venv_py310\Lib\site-packages\TTS\VERSION;TTS" ^
            --add-data "venv_py310\Lib\site-packages\trainer\VERSION;trainer" ^
            --add-data "venv_py310\Lib\site-packages\gruut\VERSION;gruut" ^
            --add-data "venv_py310\Lib\site-packages\jamo\data\*.json;jamo\data" ^
            --add-data "venv_py310\Lib\site-packages\transformers\VERSION;transformers" ^
            --add-data "pytorch_2_6_patch.py;." ^
            --add-data "torchaudio_patch.py;." ^
            --add-data "style_nn.qss;." ^
            --hidden-import PyQt6.QtWidgets ^
            --hidden-import PyQt6.QtCore ^
            --hidden-import PyQt6.QtGui ^
            --hidden-import PyQt6.uic ^
            --hidden-import PyQt6.sip ^
            --hidden-import sip ^
            --hidden-import torch ^
            --hidden-import torch._C ^
            --hidden-import torch.serialization ^
            --hidden-import torch.nn ^
            --hidden-import torch.nn.functional ^
            --hidden-import torchaudio ^
            --hidden-import torchaudio.functional ^
            --hidden-import torchaudio.functional.filtering ^
            --hidden-import transformers ^
            --hidden-import transformers.utils ^
            --hidden-import transformers.utils.generic ^
            --hidden-import transformers.utils.import_utils ^
            --hidden-import gruut ^
            --hidden-import jamo ^
            --hidden-import TTS ^
            --hidden-import TTS.api ^
            --hidden-import TTS.tts.configs.xtts_config ^
            --hidden-import TTS.tts.models.xtts ^
            --hidden-import TTS.tts.utils.text.phonemizers.gruut_wrapper ^
            --hidden-import TTS.tts.utils.text.phonemizers.ko_kr_phonemizer ^
            --hidden-import TTS.tts.utils.text.korean.phonemizer ^
            --hidden-import TTS.tts.layers.tortoise.diffusion_decoder ^
            --hidden-import TTS.tts.layers.tortoise.arch_utils ^
            --hidden-import trainer ^
            --collect-all PyQt6 ^
            --collect-all TTS ^
            --collect-all torch ^
            --collect-all numpy ^
            --collect-all librosa ^
            --collect-all torchaudio ^
            --collect-all gruut ^
            --collect-all jamo ^
            --collect-all transformers ^
            --runtime-hook torch_patch.py ^
            --runtime-hook tts_patch.py ^
            --runtime-hook pyqt_patch.py ^
            --runtime-hook torchaudio_patch.py ^
            --runtime-hook torchaudio_spec_patch.py ^
            --runtime-hook gruut_patch.py ^
            --runtime-hook jamo_patch.py ^
            debug_launcher.py

if %ERRORLEVEL% NEQ 0 (
    echo Erreur lors de la compilation
    exit /b %ERRORLEVEL%
)

echo Compilation terminu00e9e avec succu00e8s
echo L'exu00e9cutable se trouve dans le dossier dist

:: Copier les fichiers nu00e9cessaires dans le dossier dist
echo Copie des fichiers additionnels...
xcopy /y style_nn.qss dist\
xcopy /y README.md dist\ 2>nul
xcopy /y LICENSE dist\ 2>nul

:: Du00e9sactiver l'environnement virtuel
deactivate

echo Build terminu00e9

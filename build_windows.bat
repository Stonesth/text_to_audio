@echo off
echo Compilation de Simple_TTS_GUI pour Windows

:: Nettoyer les anciens fichiers de compilation
echo Nettoyage des fichiers temporaires...
rd /s /q build 2>nul
rd /s /q dist 2>nul

:: Utiliser l'environnement virtuel existant
echo Activation de l'environnement virtuel existant...
call venv_py310\Scripts\activate.bat

:: Installer PyInstaller dans l'environnement existant si nécessaire
echo Installation de PyInstaller...
pip install pyinstaller

:: Créer un fichier de debug pour capturer les erreurs
echo import sys > debug_launcher.py
echo import traceback >> debug_launcher.py
echo. >> debug_launcher.py
echo try: >> debug_launcher.py
echo     from Simple_TTS_GUI import * >> debug_launcher.py
echo     if __name__ == '__main__': >> debug_launcher.py
echo         app = QApplication(sys.argv) >> debug_launcher.py
echo         window = MainWindow() >> debug_launcher.py
echo         sys.exit(app.exec()) >> debug_launcher.py
echo except Exception as e: >> debug_launcher.py
echo     with open('error_detailed.log', 'w') as f: >> debug_launcher.py
echo         f.write(f"Exception: {str(e)}\n") >> debug_launcher.py
echo         f.write(traceback.format_exc()) >> debug_launcher.py
echo     print(f"Une erreur s'est produite: {str(e)}") >> debug_launcher.py
echo     print(traceback.format_exc()) >> debug_launcher.py
echo     sys.exit(1) >> debug_launcher.py

:: Compiler l'application en utilisant les chemins de l'environnement virtuel existant
echo Compilation de l'application...
pyinstaller --name="Simple_TTS_GUI" ^
            --onefile ^
            --debug=all ^
            --console ^
            --add-data "venv_py310\Lib\site-packages\TTS\VERSION;TTS" ^
            --add-data "venv_py310\Lib\site-packages\trainer\VERSION;trainer" ^
            --add-data "pytorch_2_6_patch.py;." ^
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
            --hidden-import TTS ^
            --hidden-import TTS.api ^
            --hidden-import TTS.tts.configs.xtts_config ^
            --hidden-import trainer ^
            --collect-all PyQt6 ^
            --collect-all TTS ^
            --collect-all torch ^
            --collect-all numpy ^
            --collect-all librosa ^
            --runtime-hook torch_patch.py ^
            --runtime-hook tts_patch.py ^
            --runtime-hook pyqt_patch.py ^
            debug_launcher.py

if %ERRORLEVEL% NEQ 0 (
    echo Erreur lors de la compilation
    exit /b %ERRORLEVEL%
)

echo Compilation terminée avec succès
echo L'exécutable se trouve dans le dossier dist

:: Copier les fichiers nécessaires dans le dossier dist
echo Copie des fichiers additionnels...
xcopy /y style_nn.qss dist\
xcopy /y README.md dist\ 2>nul
xcopy /y LICENSE dist\ 2>nul

:: Désactiver l'environnement virtuel
deactivate

echo Build terminé

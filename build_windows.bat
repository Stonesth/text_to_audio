@echo off
echo Création de l'environnement virtuel pour la compilation...
python -m venv venv_build
call venv_build\Scripts\activate.bat

echo Installation des dépendances...
pip install -r requirements_build.txt

echo Nettoyage des anciens fichiers...
rmdir /s /q dist build
del /f /q *.spec

echo Compilation avec PyInstaller...
pyinstaller --name="Simple_TTS" ^
            --windowed ^
            --onefile ^
            --add-data "venv_build\Lib\site-packages\TTS\VERSION;TTS" ^
            --add-data "venv_build\Lib\site-packages\TTS\config;TTS\config" ^
            --add-data "venv_build\Lib\site-packages\TTS\utils;TTS\utils" ^
            --hidden-import="scipy.special.cython_special" ^
            --collect-all PyQt6 ^
            --collect-all PyQt6.QtGui ^
            Simple_TTS_GUI.py

echo Création du package de distribution...
cd dist
mkdir Simple_TTS
copy Simple_TTS.exe Simple_TTS\
copy ..\test_*.txt Simple_TTS\
copy ..\README.txt Simple_TTS\

echo Création du fichier ZIP...
powershell Compress-Archive -Path Simple_TTS -DestinationPath Simple_TTS_Windows.zip -Force
rmdir /s /q Simple_TTS

echo Nettoyage final...
cd ..
rmdir /s /q build
del /f /q *.spec
deactivate
rmdir /s /q venv_build

echo Compilation terminée ! Le fichier se trouve dans dist/Simple_TTS_Windows.zip

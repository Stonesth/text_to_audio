@echo off
echo Création de l'environnement virtuel pour la compilation...
python -m venv venv_build
call venv_build\Scripts\activate.bat

echo Installation des dépendances...
pip install -r requirements_build.txt

echo Compilation avec PyInstaller...
pyinstaller --name="Simple_TTS" ^
            --windowed ^
            --onefile ^
            --add-data "venv_build\Lib\site-packages\TTS\VERSION;TTS" ^
            --add-data "venv_build\Lib\site-packages\TTS\config;TTS\config" ^
            --add-data "venv_build\Lib\site-packages\TTS\utils;TTS\utils" ^
            --hidden-import="scipy.special.cython_special" ^
            Simple_TTS_GUI.py

echo Nettoyage...
deactivate
rmdir /s /q venv_build build
del *.spec

echo Création du dossier de distribution...
mkdir dist\Simple_TTS
move dist\Simple_TTS.exe dist\Simple_TTS\
copy test_fr.txt dist\Simple_TTS\
copy test_en.txt dist\Simple_TTS\

echo Création du fichier README...
echo Simple TTS - Application de synthèse vocale > dist\Simple_TTS\README.txt
echo. >> dist\Simple_TTS\README.txt
echo Instructions d'installation : >> dist\Simple_TTS\README.txt
echo 1. Décompressez l'archive >> dist\Simple_TTS\README.txt
echo 2. Double-cliquez sur Simple_TTS.exe pour lancer l'application >> dist\Simple_TTS\README.txt
echo. >> dist\Simple_TTS\README.txt
echo Note : Lors du premier lancement, l'application téléchargera automatiquement les modèles nécessaires. >> dist\Simple_TTS\README.txt

cd dist
powershell Compress-Archive -Path Simple_TTS -DestinationPath Simple_TTS_Windows.zip
cd ..

echo Compilation terminée ! L'application se trouve dans dist\Simple_TTS_Windows.zip

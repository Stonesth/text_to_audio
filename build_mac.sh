#!/bin/bash

# Création d'un environnement virtuel pour la compilation
python3 -m venv venv_build
source venv_build/bin/activate

# Installation des dépendances
pip install -r requirements_build.txt

# Nettoyage des anciens fichiers
rm -rf dist build *.spec

# Compilation avec PyInstaller
pyinstaller --name="Simple_TTS" \
            --windowed \
            --onefile \
            --add-data "venv_build/lib/python3.11/site-packages/TTS/VERSION:TTS" \
            --add-data "venv_build/lib/python3.11/site-packages/TTS/config:TTS/config" \
            --add-data "venv_build/lib/python3.11/site-packages/TTS/utils:TTS/utils" \
            --hidden-import="scipy.special.cython_special" \
            --collect-all PyQt6 \
            --collect-all PyQt6.QtGui \
            Simple_TTS_GUI.py

# Nettoyage
deactivate
rm -rf venv_build build *.spec

# Création du dossier de distribution
rm -rf dist/Simple_TTS
mkdir -p dist/Simple_TTS
mv dist/Simple_TTS.app dist/Simple_TTS/
cp test_fr.txt test_en.txt dist/Simple_TTS/

# Création d'un fichier README
cat > dist/Simple_TTS/README.txt << EOL
Simple TTS - Application de synthèse vocale

Instructions d'installation :
1. Décompressez l'archive
2. Double-cliquez sur Simple_TTS.app pour lancer l'application

Note : Lors du premier lancement, l'application téléchargera automatiquement les modèles nécessaires.
EOL

# Création de l'archive
cd dist
rm -f Simple_TTS_Mac.zip
zip -r Simple_TTS_Mac.zip Simple_TTS
cd ..

echo "Compilation terminée ! L'application se trouve dans dist/Simple_TTS_Mac.zip"

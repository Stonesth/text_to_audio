# Fichier hook-jamo.py pour PyInstaller 
from PyInstaller.utils.hooks import collect_data_files, copy_metadata 
import os 
import sys 
import jamo 
import shutil 
 
# Collecter tous les fichiers de données 
datas = collect_data_files('jamo') 
 
# Ajouter explicitement les fichiers JSON de données 
jamo_path = os.path.dirname(jamo.__file__) 
data_dir = os.path.join(jamo_path, 'data') 
 
# S'assurer que tous les fichiers JSON sont inclus 
for file in os.listdir(data_dir): 
    if file.endswith('.json'): 
        source_file = os.path.join(data_dir, file) 
        datas.append((source_file, os.path.join('jamo', 'data'))) 
        print(f"Ajout du fichier {file} au package jamo") 

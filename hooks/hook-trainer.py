# Fichier hook-trainer.py pour PyInstaller 
from PyInstaller.utils.hooks import collect_all, collect_data_files 
from pathlib import Path 
import os 
 
# Collecter tous les modules, les packages et les données 
datas, binaries, hiddenimports = collect_all('trainer') 
 
# Ajouter explicitement le fichier VERSION 
trainer_path = os.path.dirname(__file__) 
version_path = Path(trainer_path).parent / 'VERSION_trainer' 
 
# Créer un fichier VERSION temporaire s'il n'existe pas 
if not version_path.exists(): 
    with open(version_path, 'w') as f: 
        f.write('0.0.36') 
 
# Ajouter le fichier VERSION au package trainer 
datas.append((str(version_path), 'trainer')) 
 
# S'assurer que tous les imports nécessaires sont présents 
hiddenimports.extend([ 
    'trainer.trainer', 
    'trainer.io', 
    'trainer.logging', 
    'trainer.callback', 
]) 

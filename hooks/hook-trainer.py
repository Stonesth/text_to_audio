# Fichier hook-trainer.py pour PyInstaller
# Ce hook assure que les fichiers du package trainer sont correctement inclus

from PyInstaller.utils.hooks import collect_all, collect_data_files
from pathlib import Path
import os
import sys

# Collecter tous les modules, les packages et les données
datas, binaries, hiddenimports = collect_all('trainer')

# Créer un fichier VERSION temporaire dans le répertoire courant
version_content = "0.0.36"
current_dir = os.path.dirname(os.path.abspath("__file__"))
project_root = os.path.dirname(current_dir) if "hooks" in current_dir else current_dir

# Vérifier si le fichier VERSION existe dans le module trainer
try:
    import trainer
    trainer_dir = os.path.dirname(trainer.__file__)
    version_path = os.path.join(trainer_dir, "VERSION")
    
    if os.path.exists(version_path):
        # Si le fichier existe, l'ajouter aux données
        datas.append((version_path, "trainer"))
        print(f"Fichier VERSION trouvé dans {version_path}")
    else:
        # Si le fichier n'existe pas dans le module, le créer localement
        local_version = os.path.join(project_root, "trainer", "VERSION")
        os.makedirs(os.path.dirname(local_version), exist_ok=True)
        
        with open(local_version, 'w') as f:
            f.write(version_content)
        
        # Ajouter le fichier local aux données
        datas.append((local_version, "trainer"))
        print(f"Fichier VERSION créé dans {local_version}")

except ImportError:
    # Si le module trainer n'est pas importable, créer le fichier localement
    local_version = os.path.join(project_root, "trainer", "VERSION")
    os.makedirs(os.path.dirname(local_version), exist_ok=True)
    
    with open(local_version, 'w') as f:
        f.write(version_content)
    
    # Ajouter le fichier local aux données
    datas.append((local_version, "trainer"))
    print(f"Fichier VERSION créé dans {local_version} (trainer non importable)")

# S'assurer que tous les imports nécessaires sont présents
hiddenimports.extend([
    'trainer',
    'trainer.trainer',
    'trainer.io',
    'trainer.logging',
    'trainer.callback',
])

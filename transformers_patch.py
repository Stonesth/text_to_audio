# Patch pour transformers lors de l'exu00e9cution avec PyInstaller

import os
import sys

try:
    # Vu00e9rifier si nous sommes dans un environnement PyInstaller
    if hasattr(sys, '_MEIPASS'):
        print("Application du patch transformers...")
        
        # Cru00e9er le ru00e9pertoire transformers s'il n'existe pas
        transformers_dir = os.path.join(sys._MEIPASS, 'transformers')
        if not os.path.exists(transformers_dir):
            os.makedirs(transformers_dir)
            print(f"Ru00e9pertoire transformers cru00e9u00e9: {transformers_dir}")
        
        # Cru00e9er le fichier VERSION s'il n'existe pas
        version_file = os.path.join(transformers_dir, 'VERSION')
        if not os.path.exists(version_file):
            with open(version_file, 'w') as f:
                f.write('4.30.0')
            print(f"Fichier VERSION cru00e9u00e9 pour transformers")
        
        print("Patch transformers appliquu00e9 avec succu00e8s")
except Exception as e:
    print(f"Erreur lors de l'application du patch transformers: {e}")

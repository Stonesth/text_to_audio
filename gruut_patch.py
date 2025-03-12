# Patch pour gruut lors de l'exécution avec PyInstaller

import os
import sys

try:
    # Vérifier si nous sommes dans un environnement PyInstaller
    if hasattr(sys, '_MEIPASS'):
        print("Application du patch gruut...")
        
        # Créer le répertoire gruut s'il n'existe pas
        gruut_dir = os.path.join(sys._MEIPASS, 'gruut')
        if not os.path.exists(gruut_dir):
            os.makedirs(gruut_dir)
            print(f"Répertoire gruut créé: {gruut_dir}")
        
        # Créer le fichier VERSION s'il n'existe pas
        version_file = os.path.join(gruut_dir, 'VERSION')
        if not os.path.exists(version_file):
            with open(version_file, 'w') as f:
                f.write('0.0.0')
            print(f"Fichier VERSION créé pour gruut")
        
        print("Patch gruut appliqué avec succès")
except Exception as e:
    print(f"Erreur lors de l'application du patch gruut: {e}")

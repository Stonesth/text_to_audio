# Patch pour jamo lors de l'exécution avec PyInstaller

import os
import sys
import json

try:
    # Vérifier si nous sommes dans un environnement PyInstaller
    if hasattr(sys, '_MEIPASS'):
        print("Application du patch jamo...")
        
        # Créer le répertoire jamo/data s'il n'existe pas
        jamo_data_dir = os.path.join(sys._MEIPASS, 'jamo', 'data')
        if not os.path.exists(jamo_data_dir):
            os.makedirs(jamo_data_dir)
            print(f"Répertoire jamo/data créé: {jamo_data_dir}")
        
        # Créer les fichiers JSON nécessaires
        files_to_create = [
            "U+11xx.json",
            "U+31xx.json",
            "U+A9xx.json",
            "U+D7xx.json"
        ]
        
        for filename in files_to_create:
            file_path = os.path.join(jamo_data_dir, filename)
            if not os.path.exists(file_path):
                # Créer un fichier JSON vide ou avec une structure minimale
                with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump({}, f)
                print(f"Fichier créé: {file_path}")
        
        print("Patch jamo appliqué avec succès")
except Exception as e:
    print(f"Erreur lors de l'application du patch jamo: {e}")

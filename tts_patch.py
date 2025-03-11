# Patch pour TTS lors de l'exu00e9cution avec PyInstaller

import os
import sys

# Cru00e9er les fichiers VERSION pour TTS et trainer si nu00e9cessaires
try:
    # Vu00e9rifier si nous sommes dans un environnement PyInstaller
    if hasattr(sys, '_MEIPASS'):
        # Chemins pour les ru00e9pertoires TTS et trainer
        tts_dir = os.path.join(sys._MEIPASS, 'TTS')
        trainer_dir = os.path.join(sys._MEIPASS, 'trainer')
        
        # Cru00e9er les ru00e9pertoires s'ils n'existent pas
        if not os.path.exists(tts_dir):
            os.makedirs(tts_dir)
        if not os.path.exists(trainer_dir):
            os.makedirs(trainer_dir)
        
        # Cru00e9er les fichiers VERSION s'ils n'existent pas
        tts_version = os.path.join(tts_dir, 'VERSION')
        trainer_version = os.path.join(trainer_dir, 'VERSION')
        
        if not os.path.exists(tts_version):
            with open(tts_version, 'w') as f:
                f.write('0.0.0')
            print(f"Fichier VERSION cru00e9u00e9 pour TTS")
        
        if not os.path.exists(trainer_version):
            with open(trainer_version, 'w') as f:
                f.write('0.0.0')
            print(f"Fichier VERSION cru00e9u00e9 pour trainer")
            
        print("Patch TTS appliquu00e9 avec succu00e8s")
except Exception as e:
    print(f"Erreur lors de l'application du patch TTS: {e}")

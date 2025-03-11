import TTS
import os

# Chemin vers le fichier VERSION
version_file = os.path.join(os.path.dirname(TTS.__file__), 'VERSION')
print(version_file)
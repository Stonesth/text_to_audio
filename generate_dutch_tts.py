import sys
import torch
from TTS.api import TTS
import ssl
import urllib3

# Désactiver les avertissements SSL
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
ssl._create_default_https_context = ssl._create_unverified_context

def generate_dutch_tts(text, output_file, use_cuda=True):
    # Configuration du device
    device = "cuda" if torch.cuda.is_available() and use_cuda else "cpu"
    
    # Nom du modèle néerlandais
    model_name = "tts_models/nl/css10/vits"
    
    # Initialisation du modèle TTS
    tts = TTS(model_name).to(device)
    
    # Génération de l'audio
    tts.tts_to_file(text=text, file_path=output_file)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python generate_dutch_tts.py <text> <output_file>")
        sys.exit(1)
    
    text = sys.argv[1]
    output_file = sys.argv[2]
    
    generate_dutch_tts(text, output_file)

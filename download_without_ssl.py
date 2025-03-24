import requests
import urllib3
import os
from tqdm import tqdm

# Désactiver les avertissements SSL
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
print("⚠️ ATTENTION: Vérification SSL désactivée pour ce téléchargement uniquement")

# URL du modèle néerlandais CSS10 VITS
url = "https://coqui.gateway.scarf.sh/tts_models--nl--css10--vits.zip"

# Nom du fichier local
filename = "tts_models--nl--css10--vits.zip"

# Créer le dossier de destination si nécessaire
os.makedirs(os.path.dirname(filename) if os.path.dirname(filename) else '.', exist_ok=True)

try:
    print(f"Téléchargement du modèle néerlandais depuis {url}...")
    
    # Télécharger avec une barre de progression
    response = requests.get(url, stream=True, verify=False)
    response.raise_for_status()  # Vérifier si le téléchargement a réussi
    
    # Taille totale en octets
    total_size = int(response.headers.get('content-length', 0))
    block_size = 1024  # 1 Kibibyte
    
    # Créer une barre de progression
    with open(filename, 'wb') as f, tqdm(
            desc=filename,
            total=total_size,
            unit='iB',
            unit_scale=True,
            unit_divisor=1024,
        ) as bar:
            for data in response.iter_content(block_size):
                size = f.write(data)
                bar.update(size)
    
    print(f"\n✅ Téléchargement terminé! Fichier sauvegardé sous: {os.path.abspath(filename)}")
    print("\nPour charger ce modèle dans Simple_TTS:")
    print("python simple_TTS.py --model_name tts_models/nl/css10/vits")

except Exception as e:
    print(f"\n❌ Erreur de téléchargement: {e}")
    print("Veuillez vérifier votre connexion internet et réessayer.")
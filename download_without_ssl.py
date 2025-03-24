import os
import sys
import urllib3
import warnings
from tqdm import tqdm

# Désactiver les avertissements SSL et warnings généraux
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
warnings.filterwarnings("ignore")
os.environ["PYTHONWARNINGS"] = "ignore"
print("\u26a0ufe0f ATTENTION: Vérification SSL désactivée pour ce téléchargement uniquement")

# Modèle à télécharger
model_name = "tts_models/nl/css10/vits"
print(f"\nTéléchargement du modèle néerlandais: {model_name}")

try:
    # S'assurer que tous les paquets nécessaires sont installés
    import pkg_resources
    required_packages = ['TTS']
    for package in required_packages:
        try:
            pkg_resources.get_distribution(package)
        except pkg_resources.DistributionNotFound:
            print(f"\nInstallation du package requis: {package}...")
            import subprocess
            subprocess.check_call([sys.executable, "-m", "pip", "install", package])
    
    # Import après avoir vérifié l'installation
    from TTS.utils.manage import ModelManager
    
    # Désactiver la vérification SSL pour la bibliothèque TTS
    import ssl
    if hasattr(ssl, '_create_unverified_context'):
        ssl._create_default_https_context = ssl._create_unverified_context
    
    # Utiliser le gestionnaire de modèles de TTS pour télécharger le modèle
    model_manager = ModelManager()
    
    # Afficher l'URL du modèle
    model_path, config_path, model_item = model_manager.download_model(model_name)
    
    print(f"\u2705 Téléchargement terminé avec succès!")
    print(f"\nChemin du modèle: {model_path}")
    print(f"Chemin de la configuration: {config_path}")
    
    print("\nPour utiliser ce modèle dans Simple_TTS:")
    print(f"python simple_TTS.py --model_name {model_name}")

except Exception as e:
    print(f"\u274c Erreur: {e}")
    print("\nSolution alternative: téléchargement manuel")
    print("1. Ouvrez un terminal avec l'environnement Python activé")
    print("2. Exécutez la commande:")
    print("   python -m TTS.bin.download_model --model_name tts_models/nl/css10/vits")
import os
import shutil
import sys
import site
import tempfile
from pathlib import Path

def find_unidic_lite_dir():
    """Trouve le répertoire unidic_lite dans les packages installés."""
    try:
        # Essayer d'importer unidic_lite pour vérifier son existence
        import unidic_lite
        return os.path.dirname(unidic_lite.__file__)
    except ImportError:
        # Si unidic_lite n'est pas installé, essayer de le localiser dans les répertoires site-packages
        for site_dir in site.getsitepackages():
            unidic_path = os.path.join(site_dir, 'unidic_lite')
            if os.path.exists(unidic_path):
                return unidic_path
        
        # Vérifier dans le répertoire site-packages de l'utilisateur
        user_site = site.getusersitepackages()
        unidic_path = os.path.join(user_site, 'unidic_lite')
        if os.path.exists(unidic_path):
            return unidic_path
    
    return None

def extract_unidic_files(dest_dir):
    """Extrait les fichiers unidic_lite vers le répertoire de destination."""
    unidic_dir = find_unidic_lite_dir()
    if not unidic_dir:
        print("❌ ERREUR: Impossible de trouver le package unidic_lite.")
        print("Veuillez l'installer avec: pip install unidic-lite")
        return False
    
    print(f"📦 Package unidic_lite trouvé dans: {unidic_dir}")
    
    # S'assurer que le répertoire de destination existe
    os.makedirs(dest_dir, exist_ok=True)
    
    # Dossier dicdir dans le package unidic_lite
    source_dicdir = os.path.join(unidic_dir, 'dicdir')
    if not os.path.exists(source_dicdir):
        print(f"❌ ERREUR: Répertoire dicdir non trouvé dans {unidic_dir}")
        return False
    
    # Copier tous les fichiers de dicdir
    try:
        for filename in os.listdir(source_dicdir):
            source_file = os.path.join(source_dicdir, filename)
            dest_file = os.path.join(dest_dir, filename)
            
            if os.path.isfile(source_file):
                shutil.copy2(source_file, dest_file)
                print(f"✅ Copié: {filename}")
        
        print(f"\n🎉 Extraction réussie! Tous les fichiers unidic_lite ont été copiés dans {dest_dir}")
        return True
    except Exception as e:
        print(f"❌ ERREUR lors de la copie: {e}")
        return False

if __name__ == "__main__":
    # Destination par défaut (utilisée dans le script de build)
    default_dest = os.path.join(os.getcwd(), "dist", "Simple_TTS_GUI", "_internal", "unidic_lite", "dicdir")
    
    # Permettre la spécification d'un répertoire de destination personnalisé
    dest_dir = sys.argv[1] if len(sys.argv) > 1 else default_dest
    
    print(f"🔍 Extraction des fichiers unidic_lite vers {dest_dir}")
    success = extract_unidic_files(dest_dir)
    
    sys.exit(0 if success else 1)

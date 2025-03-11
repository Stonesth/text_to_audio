# Script pour vu00e9rifier l'installation de PyQt6.sip

import sys
import os

def check_pyqt6_sip():
    print("=== Vu00e9rification de PyQt6.sip ===")
    
    # Vu00e9rifier si PyQt6 est installu00e9
    try:
        import PyQt6
        print(f"PyQt6 est installu00e9: {PyQt6.__version__}")
        print(f"Chemin de PyQt6: {PyQt6.__file__}")
    except ImportError as e:
        print(f"Erreur lors de l'importation de PyQt6: {e}")
        return
    
    # Vu00e9rifier si PyQt6.sip est disponible
    try:
        from PyQt6 import sip
        print(f"PyQt6.sip est disponible")
        print(f"Version de sip: {sip.SIP_VERSION_STR}")
    except ImportError as e:
        print(f"Erreur lors de l'importation de PyQt6.sip: {e}")
        
        # Vu00e9rifier si le module sip de base est disponible
        try:
            import sip
            print(f"Module sip de base disponible: {sip.SIP_VERSION_STR}")
        except ImportError as e2:
            print(f"Module sip de base non disponible: {e2}")
    
    # Vu00e9rifier les fichiers .pyd de PyQt6
    pyqt6_path = os.path.dirname(PyQt6.__file__)
    print(f"\nFichiers .pyd dans {pyqt6_path}:")
    pyd_files = [f for f in os.listdir(pyqt6_path) if f.endswith('.pyd')]
    for pyd in pyd_files:
        print(f"  - {pyd}")
    
    # Vu00e9rifier si _sip.pyd existe
    sip_pyd = os.path.join(pyqt6_path, '_sip.pyd')
    if os.path.exists(sip_pyd):
        print(f"\n_sip.pyd existe: {sip_pyd}")
    else:
        print(f"\n_sip.pyd n'existe pas dans {pyqt6_path}")
        # Chercher _sip.pyd ailleurs
        for path in sys.path:
            potential_path = os.path.join(path, 'PyQt6', '_sip.pyd')
            if os.path.exists(potential_path):
                print(f"_sip.pyd trouvé à: {potential_path}")
    
    # Vu00e9rifier le module sip
    try:
        import sip
        print(f"\nModule sip:")
        print(f"  Version: {sip.SIP_VERSION_STR}")
        print(f"  Chemin: {sip.__file__}")
    except ImportError as e:
        print(f"\nModule sip non disponible: {e}")
    
    print("\nSuggestions pour résoudre les problèmes:")
    print("1. Réinstaller PyQt6: pip install PyQt6 --force-reinstall")
    print("2. Installer PyQt6-sip explicitement: pip install PyQt6-sip")
    print("3. Vérifier que le fichier _sip.pyd est correctement inclus dans le fichier .spec")

if __name__ == "__main__":
    check_pyqt6_sip()

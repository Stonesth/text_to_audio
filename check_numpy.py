import numpy
import sys
import platform
import subprocess
import os


def check_numpy_version():
    print("=== Vérification de NumPy ===")
    print(f"Version de NumPy installée: {numpy.__version__}")
    print(f"Chemin de NumPy: {numpy.__file__}")
    
    # Vérifier si la version est compatible avec PyTorch
    version_parts = [int(x) for x in numpy.__version__.split('.')]
    major, minor = version_parts[0], version_parts[1]
    
    if major < 1 or (major == 1 and minor < 20):
        print("\n⚠️ AVERTISSEMENT: Votre version de NumPy est trop ancienne pour PyTorch récent.")
        print("Cela peut causer des avertissements ou des erreurs comme:")
        print("'module compiled against API version 0x10 but this version of numpy is 0xf'")
        
        print("\nSolution recommandée:")
        print("1. Mettez à jour NumPy avec la commande suivante:")
        print("   pip install --upgrade numpy")
        print("   ou")
        print("   pip install numpy==1.24.3")
        
        # Proposer une mise à jour automatique
        if input("\nVoulez-vous mettre à jour NumPy maintenant? (o/n): ").lower() == 'o':
            try:
                python_exe = sys.executable
                print(f"\nMise à jour de NumPy avec {python_exe}...")
                
                # Utiliser subprocess pour exécuter pip
                cmd = [python_exe, "-m", "pip", "install", "--upgrade", "numpy==1.24.3", "--no-cache-dir"]
                subprocess.check_call(cmd)
                
                print("\n✅ NumPy a été mis à jour. Veuillez redémarrer votre application.")
                print("Si vous utilisez un environnement virtuel, assurez-vous de l'activer avant de lancer l'application.")
            except Exception as e:
                print(f"\n❌ Erreur lors de la mise à jour: {str(e)}")
                print("Veuillez essayer de mettre à jour manuellement avec la commande:")
                print("pip install --upgrade numpy==1.24.3 --no-cache-dir")
    else:
        print("\n✅ Votre version de NumPy devrait être compatible avec PyTorch.")

if __name__ == "__main__":
    check_numpy_version()
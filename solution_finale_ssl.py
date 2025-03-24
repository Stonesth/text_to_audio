#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
SOLUTION RADICALE POUR LES PROBLÈMES DE CERTIFICATS SSL

Ce script propose trois méthodes différentes pour résoudre définitivement
les problèmes de certificats SSL en environnement Python.

Utilisation :
    python solution_finale_ssl.py [méthode]
    
    méthode : 1, 2 ou 3 (défaut: toutes les méthodes)
              1 = Patch temporaire (session courante)
              2 = Patch permanent via sitecustomize
              3 = Désactivation des vérifications (à utiliser en dernier recours)
"""

import os
import sys
import site
import certifi
import ssl
import urllib3
import shutil
import importlib


def méthode_1_patch_temporaire():
    """Applique un patch temporaire pour la session Python courante."""
    print("\n[MÉTHODE 1] Application du patch temporaire...")
    
    # Obtenir le chemin du bundle de certificats
    cert_bundle = certifi.where()
    print(f"Bundle de certificats: {cert_bundle}")
    
    # Configurer les variables d'environnement
    os.environ['SSL_CERT_FILE'] = cert_bundle
    os.environ['REQUESTS_CA_BUNDLE'] = cert_bundle 
    os.environ['CURL_CA_BUNDLE'] = cert_bundle
    
    print("Variables d'environnement configurées pour cette session.")
    return True


def méthode_2_patch_permanent():
    """Crée un patch permanent via sitecustomize.py"""
    print("\n[MÉTHODE 2] Installation du patch permanent...")
    
    # Trouver le répertoire site-packages
    try:
        site_packages = site.getsitepackages()[0]
        print(f"Répertoire site-packages: {site_packages}")
    except Exception as e:
        print(f"Erreur lors de la localisation de site-packages: {e}")
        return False
    
    # Obtenir le chemin du bundle de certificats
    cert_bundle = certifi.where()
    print(f"Bundle de certificats: {cert_bundle}")
    
    # Créer sitecustomize.py
    sitecustomize_path = os.path.join(site_packages, "sitecustomize.py")
    backup_path = sitecustomize_path + ".backup"
    
    # Faire une sauvegarde si le fichier existe déjà
    if os.path.exists(sitecustomize_path) and not os.path.exists(backup_path):
        shutil.copy2(sitecustomize_path, backup_path)
        print(f"Sauvegarde créée: {backup_path}")
    
    # Remplacer les backslashes par des forward slashes pour éviter les problèmes d'échappement
    cert_bundle_safe = cert_bundle.replace('\\', '/')
    
    # Écrire le contenu de sitecustomize.py
    with open(sitecustomize_path, 'w') as f:
        f.write(f'''"""
Configuration automatique des certificats SSL pour Python
Ce fichier a été créé automatiquement par solution_finale_ssl.py
"""

import os
import sys
import ssl

# Configurer les variables d'environnement SSL
os.environ["SSL_CERT_FILE"] = r"{cert_bundle_safe}"
os.environ["REQUESTS_CA_BUNDLE"] = r"{cert_bundle_safe}"
os.environ["CURL_CA_BUNDLE"] = r"{cert_bundle_safe}"

# Configurer urllib et requests dès leur importation
try:
    import urllib3
    urllib3.disable_warnings()
except ImportError:
    pass

try:
    import requests.packages.urllib3
    requests.packages.urllib3.disable_warnings()
except ImportError:
    pass
''')

    print(f"Fichier sitecustomize.py créé avec succès: {sitecustomize_path}")
    print("Ce fichier sera chargé automatiquement à chaque démarrage de Python.")
    return True


def méthode_3_désactiver_vérification():
    """Désactive complètement la vérification des certificats SSL."""
    print("\n[MÉTHODE 3] Désactivation des vérifications SSL...")
    print("ATTENTION: Cette méthode est à utiliser en dernier recours uniquement!")
    print("Elle désactive les vérifications de sécurité SSL, ce qui peut présenter des risques.")
    
    # Désactiver les vérifications de certificats
    # 1. Pour urllib3
    try:
        urllib3.disable_warnings()
        print("Avertissements urllib3 désactivés.")
    except:
        print("Impossible de désactiver les avertissements urllib3.")
    
    # 2. Pour le module ssl standard
    try:
        ssl._create_default_https_context = ssl._create_unverified_context
        print("Vérification SSL désactivée pour le module ssl.")
    except:
        print("Impossible de désactiver les vérifications pour le module ssl.")
    
    # 3. Pour requests si disponible
    try:
        import requests
        requests.packages.urllib3.disable_warnings()
        print("Avertissements requests désactivés.")
    except:
        print("Module requests non disponible ou impossible de désactiver les avertissements.")
    
    # Créer un fichier de désactivation permanente
    try:
        site_packages = site.getsitepackages()[0]
        disable_path = os.path.join(site_packages, "ssl_no_verify.pth")
        
        with open(disable_path, 'w') as f:
            f.write('''import ssl
ssl._create_default_https_context = ssl._create_unverified_context

try:
    import urllib3
    urllib3.disable_warnings()
except:
    pass

try:
    import requests.packages.urllib3
    requests.packages.urllib3.disable_warnings()
except:
    pass
''')
        
        print(f"Fichier de désactivation permanent créé: {disable_path}")
    except Exception as e:
        print(f"Impossible de créer le fichier de désactivation permanent: {e}")
    
    return True


def tester_configuration():
    """Teste si la configuration SSL fonctionne correctement."""
    print("\n[TEST] Vérification de la configuration SSL...")
    
    # 1. Test avec urllib
    try:
        import urllib.request
        response = urllib.request.urlopen('https://www.google.com')
        print("✓ Test urllib.request: SUCCÈS")
    except Exception as e:
        print(f"✗ Test urllib.request: ÉCHEC - {e}")
    
    # 2. Test avec requests si disponible
    try:
        import requests
        response = requests.get('https://www.google.com')
        print("✓ Test requests: SUCCÈS")
    except ImportError:
        print("! Module requests non installé, test ignoré.")
    except Exception as e:
        print(f"✗ Test requests: ÉCHEC - {e}")
    
    print("\nSi les tests ont échoué, essayez de redémarrer Python ou votre terminal.")


def main():
    """Fonction principale du script."""
    print("=" * 70)
    print("SOLUTION FINALE POUR LES PROBLÈMES DE CERTIFICATS SSL PYTHON")
    print("=" * 70)
    
    # Déterminer quelles méthodes appliquer
    methodes = []
    if len(sys.argv) > 1:
        try:
            methode = int(sys.argv[1])
            if 1 <= methode <= 3:
                methodes = [methode]
            else:
                print("Méthode invalide. Utilisation des méthodes 1 et 2 par défaut.")
                methodes = [1, 2]
        except:
            print("Argument invalide. Utilisation des méthodes 1 et 2 par défaut.")
            methodes = [1, 2]
    else:
        # Par défaut, appliquer les méthodes 1 et 2
        methodes = [1, 2]
    
    # Appliquer les méthodes sélectionnées
    if 1 in methodes:
        méthode_1_patch_temporaire()
    
    if 2 in methodes:
        méthode_2_patch_permanent()
    
    if 3 in methodes:
        méthode_3_désactiver_vérification()
    
    # Tester la configuration
    tester_configuration()
    
    print("\n" + "=" * 70)
    print("CONFIGURATION SSL TERMINÉE")
    print("=" * 70)
    print("\nSi vous rencontrez encore des problèmes:")
    print("1. Redémarrez votre terminal et Python")
    print("2. Essayez d'exécuter ce script avec la méthode 3 (python solution_finale_ssl.py 3)")
    print("   ATTENTION: La méthode 3 désactive les vérifications de sécurité SSL!")
    print("\nBonne chance!")


if __name__ == "__main__":
    main()

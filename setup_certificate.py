#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import site
import shutil
import certifi


def setup_certificate(cert_path):
    """
    Configure le certificat SSL pour Python en utilisant une approche robuste
    qui fonctionne sur Windows sans problu00e8mes d'u00e9chappement.
    
    Args:
        cert_path: Chemin vers le certificat u00e0 installer
    """
    # Vu00e9rifier que le certificat existe
    if not os.path.exists(cert_path):
        print(f"[ERREUR] Le certificat n'existe pas : {cert_path}")
        return False
    
    # Lire le contenu du certificat
    try:
        with open(cert_path, 'r') as cert_file:
            custom_cert_content = cert_file.read()
            print(f"Certificat lu avec succu00e8s: {len(custom_cert_content)} octets")
    except Exception as e:
        print(f"[ERREUR] Impossible de lire le certificat: {e}")
        return False
    
    # Obtenir le chemin du bundle de certificats
    try:
        certifi_path = certifi.where()
        print(f"Bundle de certificats trouvu00e9: {certifi_path}")
    except Exception as e:
        print(f"[ERREUR] Impossible de localiser le bundle de certificats: {e}")
        return False
    
    # Cru00e9er une sauvegarde
    backup_path = certifi_path + ".bak"
    if not os.path.exists(backup_path):
        try:
            shutil.copy2(certifi_path, backup_path)
            print(f"Sauvegarde cru00e9u00e9e: {backup_path}")
        except Exception as e:
            print(f"[AVERTISSEMENT] Impossible de cru00e9er une sauvegarde: {e}")
    
    # Vu00e9rifier si le certificat est du00e9ju00e0 dans le bundle
    try:
        with open(certifi_path, 'r') as cert_bundle:
            bundle_content = cert_bundle.read()
            if custom_cert_content in bundle_content:
                print("Le certificat est du00e9ju00e0 dans le bundle. Aucune modification nu00e9cessaire.")
                is_already_installed = True
            else:
                is_already_installed = False
    except Exception as e:
        print(f"[ERREUR] Impossible de lire le bundle: {e}")
        return False
    
    # Ajouter le certificat au bundle si nu00e9cessaire
    if not is_already_installed:
        try:
            with open(certifi_path, 'a') as cert_bundle:
                cert_bundle.write('\n')
                cert_bundle.write(custom_cert_content)
            print("Certificat ajoutu00e9 au bundle avec succu00e8s.")
        except Exception as e:
            print(f"[ERREUR] Impossible d'ajouter le certificat au bundle: {e}")
            return False
    
    # Mu00e9thode 1: Configuration via fichier sitecustomize.py
    try:
        site_packages = site.getsitepackages()[0]
        print(f"Site-packages: {site_packages}")
        
        sitecustomize_path = os.path.join(site_packages, "sitecustomize.py")
        print(f"Cru00e9ation du fichier sitecustomize.py: {sitecustomize_path}")
        
        with open(sitecustomize_path, 'w') as f:
            f.write("""# Configuration automatique pour les certificats SSL
# Ce fichier est gu00e9nu00e9ru00e9 automatiquement, ne pas modifier manuellement

import os
import sys

# Du00e9finition des variables d'environnement SSL
try:
    cert_path = r""""
            f.write(certifi_path.replace('\\', '\\\\'))
            f.write(""""""
    
    if os.path.exists(cert_path):
        os.environ['SSL_CERT_FILE'] = cert_path
        os.environ['REQUESTS_CA_BUNDLE'] = cert_path
        os.environ['CURL_CA_BUNDLE'] = cert_path
except Exception:
    pass
""")
        print("Fichier sitecustomize.py cru00e9u00e9 avec succu00e8s.")
    except Exception as e:
        print(f"[AVERTISSEMENT] Impossible de cru00e9er sitecustomize.py: {e}")
    
    # Mu00e9thode 2: Configuration via variables d'environnement du systu00e8me
    try:
        if sys.platform == 'win32':
            # Cru00e9er un script bat pour configurer les variables d'environnement
            env_bat_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "set_ssl_env.bat")
            with open(env_bat_path, 'w') as f:
                f.write('@echo off\n')
                f.write('echo Configuration des variables d\'environnement SSL...\n')
                f.write(f'setx SSL_CERT_FILE "{certifi_path}"\n')
                f.write(f'setx REQUESTS_CA_BUNDLE "{certifi_path}"\n')
                f.write(f'setx CURL_CA_BUNDLE "{certifi_path}"\n')
                f.write('echo Configuration des variables d\'environnement terminu00e9e.\n')
                f.write('pause\n')
            print(f"Script batch cru00e9u00e9: {env_bat_path}")
            print("Exu00e9cutez ce script en tant qu'administrateur pour configurer les variables d'environnement systu00e8me.")
    except Exception as e:
        print(f"[AVERTISSEMENT] Impossible de cru00e9er le script d'environnement: {e}")
    
    return True


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python setup_certificate.py <chemin_vers_certificat>")
        sys.exit(1)
    
    cert_path = sys.argv[1]
    success = setup_certificate(cert_path)
    
    if success:
        print("\n====== CONFIGURATION SSL TERMINu00c9E AVEC SUCCu00c8S ======")
        print("Python devrait maintenant utiliser votre certificat pour les connexions SSL.")
        print("\nPour tester la configuration, exu00e9cutez:")
        print("  python -c \"import requests; print(requests.get('https://httpbin.org/get').json())\"")
    else:
        print("\n====== u00c9CHEC DE LA CONFIGURATION SSL ======")
        print("Veuillez vu00e9rifier les erreurs ci-dessus et ru00e9essayer.")
        sys.exit(1)

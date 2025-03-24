#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import site
import shutil
import certifi


def install_certificate(cert_path):
    """
    Installe un certificat SSL personnalisé dans l'environnement Python actif
    en l'ajoutant au bundle de certificats de certifi.
    
    Args:
        cert_path (str): Chemin vers le fichier de certificat à installer
    """
    if not os.path.exists(cert_path):
        print(f"[ERREUR] Le certificat n'existe pas : {cert_path}")
        return False
        
    # Obtenir le chemin du bundle de certificats certifi
    certifi_path = certifi.where()
    print(f"Bundle de certificats certifi trouvé à : {certifi_path}")
    
    # Créer une sauvegarde du bundle original
    backup_path = certifi_path + ".backup"
    if not os.path.exists(backup_path):
        print(f"Création d'une sauvegarde à : {backup_path}")
        shutil.copy2(certifi_path, backup_path)
    
    # Lire le contenu du certificat personnalisé
    with open(cert_path, 'r') as cert_file:
        custom_cert_content = cert_file.read()
    
    # Vérifier si le certificat est déjà installé
    with open(certifi_path, 'r') as cert_bundle:
        bundle_content = cert_bundle.read()
        
    if custom_cert_content in bundle_content:
        print("Le certificat est déjà installé dans le bundle.")
        return True
    
    # Ajouter le certificat au bundle
    with open(certifi_path, 'a') as cert_bundle:
        cert_bundle.write('\n')
        cert_bundle.write(custom_cert_content)
    
    print("Certificat installé avec succès dans le bundle certifi.")
    
    # Configurer les variables d'environnement Python
    pip_path = os.path.join(os.path.dirname(sys.executable), "pip")
    site_packages = site.getsitepackages()[0]
    print(f"Dossier site-packages : {site_packages}")
    
    # Créer un fichier .pth pour ajouter les variables d'environnement
    env_pth_path = os.path.join(site_packages, "ssl_cert_env.pth")
    with open(env_pth_path, 'w') as env_file:
        env_file.write(f"import os; os.environ['SSL_CERT_FILE'] = '{certifi_path}'\n")
        env_file.write(f"import os; os.environ['REQUESTS_CA_BUNDLE'] = '{certifi_path}'\n")
        env_file.write(f"import os; os.environ['CURL_CA_BUNDLE'] = '{certifi_path}'\n")
    
    print(f"Variables d'environnement permanentes configurées dans : {env_pth_path}")
    return True


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python install_cert.py <chemin_vers_certificat>")
        sys.exit(1)
    
    cert_path = sys.argv[1]
    success = install_certificate(cert_path)
    
    if success:
        print("\nConfiguration terminée. Python utilisera maintenant ce certificat.")
        print("Pour vérifier, exécutez: python -c \"import requests; print(requests.get('https://httpbin.org/get').json())\"")
    else:
        print("\nLa configuration a échoué. Veuillez vérifier les erreurs ci-dessus.")
        sys.exit(1)

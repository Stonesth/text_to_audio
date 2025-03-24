import os, certifi, requests 
cert_path = certifi.where() 
print(f"Chemin du bundle de certificats: {cert_path}") 
os.environ['SSL_CERT_FILE'] = cert_path 
os.environ['REQUESTS_CA_BUNDLE'] = cert_path 
os.environ['CURL_CA_BUNDLE'] = cert_path 
print("Variables d'environnement configurées pour cette session.") 
try: 
    import urllib.request 
    response = urllib.request.urlopen('https://www.google.com') 
    print("01 - Test de connexion SSL réussi!") 
    response = requests.get('https://www.google.com', verify=certifi.where()) 
    print("02 - Test de connexion SSL réussi!") 
except Exception as e: 
    print(f"Erreur lors du test de connexion: {e}") 

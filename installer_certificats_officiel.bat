@echo off
setlocal

echo ===== INSTALLATION OFFICIELLE DES CERTIFICATS PYTHON =====
echo.

:: Activer l'environnement virtuel
echo Activation de l'environnement virtuel Python...
call .\venv_py310\Scripts\activate.bat

:: Installer/mettre à jour le package certifi
echo Installation/mise à jour du package certifi...
pip install --upgrade pip
pip install --upgrade certifi

:: Exécuter le script équivalent au Install Certificates.command
echo Exécution du script d'installation des certificats...
python -m pip install --upgrade certifi

:: Créer et exécuter un script Python pour configurer les variables d'environnement
echo import os, certifi, requests > setup_cert_env.py
echo cert_path = certifi.where() >> setup_cert_env.py
echo print(f"Chemin du bundle de certificats: {cert_path}") >> setup_cert_env.py
echo os.environ['SSL_CERT_FILE'] = cert_path >> setup_cert_env.py
echo os.environ['REQUESTS_CA_BUNDLE'] = cert_path >> setup_cert_env.py
echo os.environ['CURL_CA_BUNDLE'] = cert_path >> setup_cert_env.py
echo print("Variables d'environnement configurées pour cette session.") >> setup_cert_env.py
echo try: >> setup_cert_env.py
echo     import urllib.request >> setup_cert_env.py
echo     response = urllib.request.urlopen('https://www.google.com') >> setup_cert_env.py
echo     print("01 - Test de connexion SSL réussi!") >> setup_cert_env.py
echo     response = requests.get('https://www.google.com', verify=certifi.where()) >> setup_cert_env.py
echo     print("02 - Test de connexion SSL réussi!") >> setup_cert_env.py
echo except Exception as e: >> setup_cert_env.py
echo     print(f"Erreur lors du test de connexion: {e}") >> setup_cert_env.py

python setup_cert_env.py

:: Configurer les variables d'environnement systu00e8me
for /f "tokens=*" %%a in ('python -c "import certifi; print(certifi.where())"') do set CERT_PATH=%%a
echo Définition des variables d'environnement systu00e8me...
setx SSL_CERT_FILE "%CERT_PATH%"
setx REQUESTS_CA_BUNDLE "%CERT_PATH%"
setx CURL_CA_BUNDLE "%CERT_PATH%"

echo.
echo Installation terminée. Les certificats SSL ont été mis à jour.
echo.

pause

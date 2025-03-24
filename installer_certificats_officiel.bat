@echo off
setlocal

echo ===== INSTALLATION OFFICIELLE DES CERTIFICATS PYTHON =====
echo.

:: Activer l'environnement virtuel
echo Activation de l'environnement virtuel Python...
call .\venv_py310\Scripts\activate.bat

:: Installer/mettre u00e0 jour le package certifi
echo Installation/mise u00e0 jour du package certifi...
pip install --upgrade pip
pip install --upgrade certifi

:: Exu00e9cuter le script u00e9quivalent au Install Certificates.command
echo Exu00e9cution du script d'installation des certificats...
python -m pip install --upgrade certifi

:: Cru00e9er et exu00e9cuter un script Python pour configurer les variables d'environnement
echo import os, certifi > setup_cert_env.py
echo cert_path = certifi.where() >> setup_cert_env.py
echo print(f"Chemin du bundle de certificats: {cert_path}") >> setup_cert_env.py
echo os.environ['SSL_CERT_FILE'] = cert_path >> setup_cert_env.py
echo os.environ['REQUESTS_CA_BUNDLE'] = cert_path >> setup_cert_env.py
echo os.environ['CURL_CA_BUNDLE'] = cert_path >> setup_cert_env.py
echo print("Variables d'environnement configuru00e9es pour cette session.") >> setup_cert_env.py
echo try: >> setup_cert_env.py
echo     import urllib.request >> setup_cert_env.py
echo     response = urllib.request.urlopen('https://www.google.com') >> setup_cert_env.py
echo     print("Test de connexion SSL ru00e9ussi!") >> setup_cert_env.py
echo except Exception as e: >> setup_cert_env.py
echo     print(f"Erreur lors du test de connexion: {e}") >> setup_cert_env.py

python setup_cert_env.py

:: Configurer les variables d'environnement systu00e8me
for /f "tokens=*" %%a in ('python -c "import certifi; print(certifi.where())"') do set CERT_PATH=%%a
echo Du00e9finition des variables d'environnement systu00e8me...
setx SSL_CERT_FILE "%CERT_PATH%"
setx REQUESTS_CA_BUNDLE "%CERT_PATH%"
setx CURL_CA_BUNDLE "%CERT_PATH%"

echo.
echo Installation terminu00e9e. Les certificats SSL ont u00e9tu00e9 mis u00e0 jour.
echo.

pause

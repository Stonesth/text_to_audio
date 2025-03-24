@echo off
setlocal

echo ===== CONFIGURATION SSL SIMPLE ET DIRECTE =====
echo.

:: Chemins
set CERT_PATH=C:\Users\JF30LB\OneDrive - NN\Documents\JIRA\2025\NN-Decryption-Forward-Trust.crt

:: Vérifier que le certificat existe
if not exist "%CERT_PATH%" (
    echo [ERREUR] Certificat introuvable : %CERT_PATH%
    echo Veuillez vérifier le chemin et réessayer.
    pause
    exit /b 1
)

:: Activer l'environnement virtuel
echo Activation de l'environnement virtuel...
call .\venv_py310\Scripts\activate.bat

:: Installer ou mettre à jour certifi
echo Installation/mise à jour de certifi...
pip install --upgrade certifi

:: Localiser le bundle certifi
echo Recherche du bundle de certificats...
for /f "tokens=*" %%a in ('python -c "import certifi; print(certifi.where())"') do set CERTIFI_PATH=%%a
echo Bundle trouvé : %CERTIFI_PATH%

:: Créer une sauvegarde
if not exist "%CERTIFI_PATH%.backup" (
    echo Création d'une sauvegarde...
    copy "%CERTIFI_PATH%" "%CERTIFI_PATH%.backup" >nul
)

:: Ajouter le certificat directement
echo Ajout du certificat au bundle...
type "%CERT_PATH%" >> "%CERTIFI_PATH%"

:: Créer un script Python simple pour vérifier
echo import requests > test_ssl.py
echo try: >> test_ssl.py
echo     response = requests.get('https://httpbin.org/get') >> test_ssl.py
echo     print('SUCCESS: La connexion SSL fonctionne!') >> test_ssl.py
echo     print(response.json()) >> test_ssl.py
echo except Exception as e: >> test_ssl.py
echo     print('ERREUR:', e) >> test_ssl.py

:: Définir les variables d'environnement pour cette session
set SSL_CERT_FILE=%CERTIFI_PATH%
set REQUESTS_CA_BUNDLE=%CERTIFI_PATH%
set CURL_CA_BUNDLE=%CERTIFI_PATH%

:: Définir les variables d'environnement system-wide (administrateur requis)
echo Définition des variables d'environnement système...
setx SSL_CERT_FILE "%CERTIFI_PATH%"
setx REQUESTS_CA_BUNDLE "%CERTIFI_PATH%"
setx CURL_CA_BUNDLE "%CERTIFI_PATH%"

:: Tester la configuration
echo.
echo Test de la configuration SSL...
python test_ssl.py

echo.
echo Configuration terminée !
echo Si le test a échoué, essayez de redémarrer votre terminal et réexécutez le test:
echo   python test_ssl.py
echo.

pause

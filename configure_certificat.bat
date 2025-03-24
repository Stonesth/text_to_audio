@echo off
echo ===== CONFIGURATION DU CERTIFICAT SSL POUR PYTHON =====
echo.

:: Chemin vers le certificat
set CERT_PATH=C:\Users\JF30LB\OneDrive - NN\Documents\JIRA\2025\NN-Decryption-Forward-Trust.crt

:: Vu00e9rifie que le certificat existe
if not exist "%CERT_PATH%" (
    echo [ERREUR] Le certificat n'a pas u00e9tu00e9 trouvu00e9 u00e0 l'emplacement : %CERT_PATH%
    echo Veuillez vu00e9rifier le chemin du certificat et ru00e9essayer.
    pause
    exit /b 1
)

:: Activation de l'environnement virtuel
echo Activation de l'environnement virtuel Python...
call .\venv_py310\Scripts\activate.bat

:: Configuration des variables d'environnement pour la session actuelle
echo Configuration temporaire des variables d'environnement SSL...
set "SSL_CERT_FILE=%CERT_PATH%"
set "REQUESTS_CA_BUNDLE=%CERT_PATH%"
set "CURL_CA_BUNDLE=%CERT_PATH%"

:: Installer pip si nu00e9cessaire et certifi
echo Installation/mise u00e0 jour de certifi...
pip install --upgrade certifi

:: Lancer le nouveau script Python pour configurer de maniu00e8re permanente
echo Configuration permanente du certificat SSL...
python setup_certificate.py "%CERT_PATH%"

echo.
echo Configuration terminu00e9e !
echo.
echo Vous pouvez maintenant fermer cette fenu00eatre et lancer votre application Python.
echo.

pause

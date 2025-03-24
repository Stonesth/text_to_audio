@echo off
echo Installation du certificat pour l'environnement Python...

:: Chemin vers le certificat
set CERT_PATH=C:\Users\JF30LB\OneDrive - NN\Documents\JIRA\2025\NN-Decryption-Forward-Trust.crt

:: Vérifie que le certificat existe
if not exist "%CERT_PATH%" (
    echo [ERREUR] Le certificat n'a pas été trouvé à l'emplacement : %CERT_PATH%
    echo Veuillez vérifier le chemin du certificat et réessayer.
    exit /b 1
)

:: Activation de l'environnement virtuel
echo Activation de l'environnement virtuel Python...
call .\venv_py310\Scripts\activate.bat

:: Configuration des variables d'environnement pour la session actuelle
echo Configuration des variables d'environnement SSL...
set SSL_CERT_FILE=%CERT_PATH%
set REQUESTS_CA_BUNDLE=%CERT_PATH%
set CURL_CA_BUNDLE=%CERT_PATH%

:: Lancer le script Python pour installer le certificat de manière permanente
echo Installation permanente du certificat...
python install_cert.py "%CERT_PATH%"

echo.
echo Configuration terminée avec succès !
echo Vous pouvez maintenant utiliser Python avec le certificat personnalisé.
echo.

:: Maintenir l'environnement actif pour l'utilisation
cmd /k

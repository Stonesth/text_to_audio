@echo off
REM filepath: /c:/Users/JF30LB/Projects/python/Projects/text_to_audio/certificat.bat
setlocal enabledelayedexpansion

REM Installation du certificat dans l'environnement Python local
echo Installation du certificat SSL...
set "CERT_FILE=%~dp0certificat\INSIM Root CA2.crt"
set "PYTHON_LIB=%~dp0venv_py310\Lib\site-packages\pip\_vendor\certifi"
set "PYTHON_CERTIFI=%~dp0venv_py310\Lib\site-packages\certifi"

REM Vérifier et créer les dossiers si nécessaire
if not exist "%PYTHON_LIB%" mkdir "%PYTHON_LIB%"
if not exist "%PYTHON_CERTIFI%" mkdir "%PYTHON_CERTIFI%"

REM Copier le certificat aux deux emplacements
if exist "%CERT_FILE%" (
    type "%CERT_FILE%" >> "%PYTHON_LIB%\cacert.pem"
    type "%CERT_FILE%" >> "%PYTHON_CERTIFI%\cacert.pem"
    echo Certificat installe avec succes.
) else (
    echo Certificat non trouve : %CERT_FILE%
    exit /b 1
)

REM Configuration des variables d'environnement SSL_CERT_FILE
set "SSL_CERT_FILE=%PYTHON_CERTIFI%\cacert.pem"
set "REQUESTS_CA_BUNDLE=%PYTHON_CERTIFI%\cacert.pem"
set "CURL_CA_BUNDLE=%PYTHON_CERTIFI%\cacert.pem"

endlocal
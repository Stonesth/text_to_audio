@echo off
setlocal enabledelayedexpansion

:: Configuration du script de signature
set "APP_NAME=Simple_TTS_GUI"
set "EXE_PATH=%~dp0dist\%APP_NAME%\%APP_NAME%.exe"
set "CERTIFICATE_NAME=YOUR_CERTIFICATE_NAME_2"

:: Configuration des fichiers de journalisation
set "LOG_DIR=%~dp0logs"
set "SIGN_LOG=%LOG_DIR%\sign_exec.log"
set "SIGN_ERROR=%LOG_DIR%\sign_exec_error.log"

:: Vérifier que les répertoires de journalisation existent
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: Obtenir la date et l'heure pour l'horodatage des journaux
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list') do set datetime=%%I
set TIMESTAMP=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2% %datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%

:: En-têate des fichiers journaux
echo. > "%SIGN_LOG%"
echo ===== Début de la signature de l'exécutable %APP_NAME%.exe ===== > "%SIGN_LOG%"
echo [%TIMESTAMP%] Démarrage du processus de signature >> "%SIGN_LOG%"

echo ===== Outil de signature pour Simple_TTS_GUI =====
echo [%TIMESTAMP%] Démarrage du processus de signature

:: Vérifier l'existence de l'exécutable
if not exist "%EXE_PATH%" (
    echo ERREUR: L'exécutable %APP_NAME%.exe n'existe pas dans le répertoire dist\%APP_NAME% >> "%SIGN_ERROR%"
    echo ERREUR: L'exécutable %APP_NAME%.exe n'existe pas dans le répertoire dist\%APP_NAME%
    echo Veuillez exécuter build_exec.bat en premier pour créer l'exécutable.
    exit /b 1
)

:: Recherche de l'outil SignTool dans le SDK Windows
echo [%TIMESTAMP%] Recherche de l'outil SignTool... >> "%SIGN_LOG%"
echo Recherche de l'outil SignTool...

set "SIGNTOOL_PATH="

:: echo de SIGNTOOL_PATH
echo [%TIMESTAMP%] SIGNTOOL_PATH: %SIGNTOOL_PATH% >> "%SIGN_LOG%"
echo SIGNTOOL_PATH: %SIGNTOOL_PATH%

:: Chemins possibles pour SignTool.exe (de la version la plus récente ê0 la plus ancienne)
set "SDK_PATHS="C:\Progra~2\WI3CF2~1\10\bin\10.0.22621.0\x64" "C:\Progra~2\WI3CF2~1\10\bin\10.0.22000.0\x64" "C:\Progra~2\WI3CF2~1\10\bin\10.0.19041.0\x64" "C:\Progra~2\WI3CF2~1\10\bin\x64""

:: echo de SDK_PATHS
echo [%TIMESTAMP%] SDK_PATHS: %SDK_PATHS% >> "%SIGN_LOG%"
echo SDK_PATHS: %SDK_PATHS%

:: Recherche de SignTool.exe dans les chemins possibles
echo [%TIMESTAMP%] Recherche de SignTool.exe dans les chemins possibles... >> "%SIGN_LOG%"
echo Recherche de SignTool.exe dans les chemins possibles...

for %%P in (%SDK_PATHS%) do (

    :: echo de P
    echo [%TIMESTAMP%] P: %%P >> "%SIGN_LOG%"
    echo P: %%P

    if exist "%%P\signtool.exe" (
        set "SIGNTOOL_PATH=%%P\signtool.exe"
        goto :found_signtool
    )
)

:: Si SignTool n'est pas trouvé
echo ERREUR: SignTool.exe n'a pas été trouvé. Veuillez installer le SDK Windows. >> "%SIGN_ERROR%"
echo ERREUR: SignTool.exe n'a pas été trouvé. Veuillez installer le SDK Windows.
echo Vous pouvez télécharger le SDK Windows ê0 partir de: https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/
exit /b 1

:found_signtool
echo [%TIMESTAMP%] SignTool trouvé: %SIGNTOOL_PATH% >> "%SIGN_LOG%"
echo SignTool trouvé: %SIGNTOOL_PATH%

:: Vérifier la présence du certificat
echo [%TIMESTAMP%] Vérification du certificat... >> "%SIGN_LOG%"
echo Vérification du certificat...

:: Ce bloc peut êatre adapté en fonction de la méthode de stockage du certificat
if "%CERTIFICATE_NAME%"=="YOUR_CERTIFICATE_NAME" (
    echo AVERTISSEMENT: Vous devez configurer le nom de votre certificat dans ce script >> "%SIGN_LOG%"
    echo AVERTISSEMENT: Vous devez configurer le nom de votre certificat dans ce script
    echo Modifiez la variable CERTIFICATE_NAME dans sign_executable.bat
    
    echo Voulez-vous continuer avec un certificat auto-signé pour les tests ? (O/N)
    set /p CONTINUE=
    if /i not "!CONTINUE!"=="O" (
        echo Opération annulée par l'utilisateur >> "%SIGN_LOG%"
        echo Opération annulée.
        exit /b 1
    )
    
    :: Option pour utiliser un certificat auto-signé pour les tests
    echo [%TIMESTAMP%] Génération d'un certificat auto-signé pour les tests... >> "%SIGN_LOG%"
    echo Génération d'un certificat auto-signé pour les tests...
    
    :: Générer un certificat auto-signé (makecert doit êatre installé)
    echo Ceci nécessite makecert.exe du SDK Windows. Si vous n'avez pas ce fichier, veuillez annuler et configurer un certificat valide.
    echo Appuyez sur une touche pour continuer ou CTRL+C pour annuler...
    pause > nul
    
    if not exist "%~dp0temp" mkdir "%~dp0temp"
    
    where makecert > nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo ERREUR: makecert.exe n'est pas disponible. Impossible de créer un certificat auto-signé. >> "%SIGN_ERROR%"
        echo ERREUR: makecert.exe n'est pas disponible. Impossible de créer un certificat auto-signé.
        exit /b 1
    )
    
    makecert -r -pe -n "CN=Simple_TTS_GUI_SelfSigned" -ss MY -sr CurrentUser -a sha256 -cy authority -sky signature "%~dp0temp\Simple_TTS_GUI_SelfSigned.cer"
    set "CERTIFICATE_NAME=Simple_TTS_GUI_SelfSigned"
    echo [%TIMESTAMP%] Certificat auto-signé %CERTIFICATE_NAME% généré >> "%SIGN_LOG%"
    echo Certificat auto-signé %CERTIFICATE_NAME% généré
    echo AVERTISSEMENT: Ce certificat n'est valide que pour les tests locaux!
    echo Les utilisateurs verront toujours des avertissements de sécurité avec ce certificat
) else (
    echo [%TIMESTAMP%] Certificat %CERTIFICATE_NAME% trouvé >> "%SIGN_LOG%"
    echo Certificat %CERTIFICATE_NAME% trouvé
)

:: Procéder à la signature
echo [%TIMESTAMP%] Signature de l'exécutable %APP_NAME%.exe... >> "%SIGN_LOG%"
echo Signature de l'exécutable %APP_NAME%.exe...

:: Commande de signature avec timestamp
"%SIGNTOOL_PATH%" sign /a /n "%CERTIFICATE_NAME%" /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 "%EXE_PATH%" > "%TEMP%\signtool_output.txt" 2>&1
set SIGN_RESULT=%ERRORLEVEL%

:: Afficher la sortie de SignTool
type "%TEMP%\signtool_output.txt"
type "%TEMP%\signtool_output.txt" >> "%SIGN_LOG%"

if %SIGN_RESULT% NEQ 0 (
    echo ERREUR: La signature de l'exécutable a échoué >> "%SIGN_ERROR%"
    echo ERREUR: La signature de l'exécutable a échoué
    exit /b 1
) else (
    echo [%TIMESTAMP%] L'exécutable %APP_NAME%.exe a été signé avec succê8s >> "%SIGN_LOG%"
    echo L'exécutable %APP_NAME%.exe a été signé avec succê8s!
)

:: Vérifier la signature
echo [%TIMESTAMP%] Vérification de la signature... >> "%SIGN_LOG%"
echo Vérification de la signature...

"%SIGNTOOL_PATH%" verify /pa "%EXE_PATH%" > "%TEMP%\verify_output.txt" 2>&1
set VERIFY_RESULT=%ERRORLEVEL%

:: Afficher la sortie de vérification
type "%TEMP%\verify_output.txt"
type "%TEMP%\verify_output.txt" >> "%SIGN_LOG%"

if %VERIFY_RESULT% NEQ 0 (
    echo AVERTISSEMENT: La vérification de la signature a échoué >> "%SIGN_ERROR%"
    echo AVERTISSEMENT: La vérification de la signature a échoué
) else (
    echo [%TIMESTAMP%] La signature de l'exécutable a été vérifiée avec succê8s >> "%SIGN_LOG%"
    echo La signature de l'exécutable a été vérifiée avec succê8s
)

echo.
echo ===== Processus de signature terminé =====
echo [%TIMESTAMP%] Processus de signature terminé >> "%SIGN_LOG%"
echo ===== Processus de signature terminé ===== >> "%SIGN_LOG%"

:: Supprimer les fichiers temporaires
del "%TEMP%\signtool_output.txt" 2>nul
del "%TEMP%\verify_output.txt" 2>nul

endlocal

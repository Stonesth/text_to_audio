@echo off
setlocal enabledelayedexpansion

:: Configuration du script de signature
set "APP_NAME=Simple_TTS_GUI"
set "EXE_PATH=%~dp0dist\%APP_NAME%\%APP_NAME%.exe"
set "CERTIFICATE_NAME=YOUR_CERTIFICATE_NAME"

:: Configuration des fichiers de journalisation
set "LOG_DIR=%~dp0logs"
set "SIGN_LOG=%LOG_DIR%\sign_exec.log"
set "SIGN_ERROR=%LOG_DIR%\sign_exec_error.log"

:: Vu00e9rifier que les ru00e9pertoires de journalisation existent
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: Obtenir la date et l'heure pour l'horodatage des journaux
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list') do set datetime=%%I
set TIMESTAMP=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2% %datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%

:: En-tu00eate des fichiers journaux
echo. > "%SIGN_LOG%"
echo ===== Du00e9but de la signature de l'exu00e9cutable %APP_NAME%.exe ===== > "%SIGN_LOG%"
echo [%TIMESTAMP%] Du00e9marrage du processus de signature >> "%SIGN_LOG%"

echo ===== Outil de signature pour Simple_TTS_GUI =====
echo [%TIMESTAMP%] Du00e9marrage du processus de signature

:: Vu00e9rifier l'existence de l'exu00e9cutable
if not exist "%EXE_PATH%" (
    echo ERREUR: L'exu00e9cutable %APP_NAME%.exe n'existe pas dans le ru00e9pertoire dist\%APP_NAME% >> "%SIGN_ERROR%"
    echo ERREUR: L'exu00e9cutable %APP_NAME%.exe n'existe pas dans le ru00e9pertoire dist\%APP_NAME%
    echo Veuillez exu00e9cuter build_exec.bat en premier pour cru00e9er l'exu00e9cutable.
    exit /b 1
)

:: Recherche de l'outil SignTool dans le SDK Windows
echo [%TIMESTAMP%] Recherche de l'outil SignTool... >> "%SIGN_LOG%"
echo Recherche de l'outil SignTool...

set "SIGNTOOL_PATH="

:: Chemins possibles pour SignTool.exe (de la version la plus ru00e9cente u00e0 la plus ancienne)
set "SDK_PATHS=C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x64 C:\Program Files (x86)\Windows Kits\10\bin\10.0.22000.0\x64 C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64 C:\Program Files (x86)\Windows Kits\10\bin\x64"

for %%P in (%SDK_PATHS%) do (
    if exist "%%P\signtool.exe" (
        set "SIGNTOOL_PATH=%%P\signtool.exe"
        goto :found_signtool
    )
)

:: Si SignTool n'est pas trouvu00e9
echo ERREUR: SignTool.exe n'a pas u00e9tu00e9 trouvu00e9. Veuillez installer le SDK Windows. >> "%SIGN_ERROR%"
echo ERREUR: SignTool.exe n'a pas u00e9tu00e9 trouvu00e9. Veuillez installer le SDK Windows.
echo Vous pouvez tu00e9lu00e9charger le SDK Windows u00e0 partir de: https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/
exit /b 1

:found_signtool
echo [%TIMESTAMP%] SignTool trouvu00e9: %SIGNTOOL_PATH% >> "%SIGN_LOG%"
echo SignTool trouvu00e9: %SIGNTOOL_PATH%

:: Vu00e9rifier la pru00e9sence du certificat
echo [%TIMESTAMP%] Vu00e9rification du certificat... >> "%SIGN_LOG%"
echo Vu00e9rification du certificat...

:: Ce bloc peut u00eatre adaptu00e9 en fonction de la mu00e9thode de stockage du certificat
if "%CERTIFICATE_NAME%"=="YOUR_CERTIFICATE_NAME" (
    echo AVERTISSEMENT: Vous devez configurer le nom de votre certificat dans ce script >> "%SIGN_LOG%"
    echo AVERTISSEMENT: Vous devez configurer le nom de votre certificat dans ce script
    echo Modifiez la variable CERTIFICATE_NAME dans sign_executable.bat
    
    echo Voulez-vous continuer avec un certificat auto-signu00e9 pour les tests ? (O/N)
    set /p CONTINUE=
    if /i not "!CONTINUE!"=="O" (
        echo Opu00e9ration annulu00e9e par l'utilisateur >> "%SIGN_LOG%"
        echo Opu00e9ration annulu00e9e.
        exit /b 1
    )
    
    :: Option pour utiliser un certificat auto-signu00e9 pour les tests
    echo [%TIMESTAMP%] Gu00e9nu00e9ration d'un certificat auto-signu00e9 pour les tests... >> "%SIGN_LOG%"
    echo Gu00e9nu00e9ration d'un certificat auto-signu00e9 pour les tests...
    
    :: Gu00e9nu00e9rer un certificat auto-signu00e9 (makecert doit u00eatre installu00e9)
    echo Ceci nu00e9cessite makecert.exe du SDK Windows. Si vous n'avez pas ce fichier, veuillez annuler et configurer un certificat valide.
    echo Appuyez sur une touche pour continuer ou CTRL+C pour annuler...
    pause > nul
    
    if not exist "%~dp0temp" mkdir "%~dp0temp"
    
    where makecert > nul 2>&1
    if %ERRORLEVEL% NEQ 0 (
        echo ERREUR: makecert.exe n'est pas disponible. Impossible de cru00e9er un certificat auto-signu00e9. >> "%SIGN_ERROR%"
        echo ERREUR: makecert.exe n'est pas disponible. Impossible de cru00e9er un certificat auto-signu00e9.
        exit /b 1
    )
    
    makecert -r -pe -n "CN=Simple_TTS_GUI_SelfSigned" -ss MY -sr CurrentUser -a sha256 -cy authority -sky signature "%~dp0temp\Simple_TTS_GUI_SelfSigned.cer"
    set "CERTIFICATE_NAME=Simple_TTS_GUI_SelfSigned"
    echo [%TIMESTAMP%] Certificat auto-signu00e9 %CERTIFICATE_NAME% gu00e9nu00e9ru00e9 >> "%SIGN_LOG%"
    echo Certificat auto-signu00e9 %CERTIFICATE_NAME% gu00e9nu00e9ru00e9
    echo AVERTISSEMENT: Ce certificat n'est valide que pour les tests locaux!
    echo Les utilisateurs verront toujours des avertissements de su00e9curitu00e9 avec ce certificat
)

:: Procu00e9der u00e0 la signature
echo [%TIMESTAMP%] Signature de l'exu00e9cutable %APP_NAME%.exe... >> "%SIGN_LOG%"
echo Signature de l'exu00e9cutable %APP_NAME%.exe...

:: Commande de signature avec timestamp
"%SIGNTOOL_PATH%" sign /a /n "%CERTIFICATE_NAME%" /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 "%EXE_PATH%" > "%TEMP%\signtool_output.txt" 2>&1
set SIGN_RESULT=%ERRORLEVEL%

:: Afficher la sortie de SignTool
type "%TEMP%\signtool_output.txt"
type "%TEMP%\signtool_output.txt" >> "%SIGN_LOG%"

if %SIGN_RESULT% NEQ 0 (
    echo ERREUR: La signature de l'exu00e9cutable a u00e9chouu00e9 >> "%SIGN_ERROR%"
    echo ERREUR: La signature de l'exu00e9cutable a u00e9chouu00e9
    exit /b 1
) else (
    echo [%TIMESTAMP%] L'exu00e9cutable %APP_NAME%.exe a u00e9tu00e9 signu00e9 avec succu00e8s >> "%SIGN_LOG%"
    echo L'exu00e9cutable %APP_NAME%.exe a u00e9tu00e9 signu00e9 avec succu00e8s!
)

:: Vu00e9rifier la signature
echo [%TIMESTAMP%] Vu00e9rification de la signature... >> "%SIGN_LOG%"
echo Vu00e9rification de la signature...

"%SIGNTOOL_PATH%" verify /pa "%EXE_PATH%" > "%TEMP%\verify_output.txt" 2>&1
set VERIFY_RESULT=%ERRORLEVEL%

:: Afficher la sortie de vu00e9rification
type "%TEMP%\verify_output.txt"
type "%TEMP%\verify_output.txt" >> "%SIGN_LOG%"

if %VERIFY_RESULT% NEQ 0 (
    echo AVERTISSEMENT: La vu00e9rification de la signature a u00e9chouu00e9 >> "%SIGN_ERROR%"
    echo AVERTISSEMENT: La vu00e9rification de la signature a u00e9chouu00e9
) else (
    echo [%TIMESTAMP%] La signature de l'exu00e9cutable a u00e9tu00e9 vu00e9rifiu00e9e avec succu00e8s >> "%SIGN_LOG%"
    echo La signature de l'exu00e9cutable a u00e9tu00e9 vu00e9rifiu00e9e avec succu00e8s
)

echo.
echo ===== Processus de signature terminu00e9 =====
echo [%TIMESTAMP%] Processus de signature terminu00e9 >> "%SIGN_LOG%"
echo ===== Processus de signature terminu00e9 ===== >> "%SIGN_LOG%"

:: Supprimer les fichiers temporaires
del "%TEMP%\signtool_output.txt" 2>nul
del "%TEMP%\verify_output.txt" 2>nul

endlocal

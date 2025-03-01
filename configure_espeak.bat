REM filepath: /c:/Users/JF30LB/Projects/python/Projects/text_to_audio/configure_espeak.bat
@echo off
setlocal EnableDelayedExpansion

REM Recherche d'eSpeak NG dans les dossiers Program Files
set "FOUND="
for %%p in ("%ProgramFiles%" "%ProgramFiles(x86)%") do (
    for %%f in ("eSpeak NG") do (
        if exist "%%~p\%%~f" (
            set "ESPEAK_PATH=%%~p\%%~f"
            set "FOUND=1"
            goto :found
        )
    )
)

:found
if not defined FOUND (
    echo eSpeak non trouve. Veuillez l'installer d'abord.
    exit /b 1
)

REM Sauvegarder le PATH actuel
set "OLD_PATH=%PATH%"

REM Ajouter eSpeak au PATH sans dupliquer
echo Ajout de !ESPEAK_PATH! au PATH...
REM Utiliser une variable temporaire pour le nouveau PATH
set "NEW_PATH=!ESPEAK_PATH!"

REM Ajouter les autres chemins du PATH s'ils sont différents de eSpeak
for %%i in ("%OLD_PATH:;=" "%") do (
    if "%%~i" NEQ "" if "%%~i" NEQ "!ESPEAK_PATH!" (
        set "NEW_PATH=!NEW_PATH!;%%~i"
    )
)

REM Mettre à jour le PATH utilisateur de façon permanente
setx PATH "!NEW_PATH!"

REM Mettre à jour le PATH pour la session courante
set "PATH=!NEW_PATH!"

echo.
echo Configuration terminee. Redemarrez l'application.
echo.
echo ===== Test eSpeak-NG =====
echo.
espeak-ng --version
echo.
echo ===== Verification du PATH =====
echo.
echo PATH actuel:
echo !PATH!
echo.
echo ============================
echo.
echo Appuyez sur une touche pour fermer...
pause > nul
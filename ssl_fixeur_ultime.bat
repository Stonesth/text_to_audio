@echo off
setlocal enabledelayedexpansion

echo ===== FIXEUR ULTIME DE CERTIFICAT SSL POUR PYTHON =====
echo.

:: Activer l'environnement virtuel
echo Activation de l'environnement virtuel Python...
call .\venv_py310\Scripts\activate.bat

:: Exu00e9cuter le script Python de solution finale
echo Exu00e9cution de la solution finale SSL...
python solution_finale_ssl.py

echo.
echo Configuration terminu00e9e!
echo.
echo Si vous rencontrez encore des problu00e8mes, redu00e9marrez votre terminal et ru00e9essayez avec :
echo python solution_finale_ssl.py 3
echo.
echo ATTENTION: L'option 3 du00e9sactive complu00e8tement les vu00e9rifications SSL 
echo et ne doit u00eatre utilisu00e9e qu'en dernier recours!
echo.

pause

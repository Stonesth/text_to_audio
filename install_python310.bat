@echo off
chcp 1252
setlocal enabledelayedexpansion

echo Verification de Python 3.10...
py -3.10 --version 2>nul
if not errorlevel 1 (
    echo Python 3.10 est deja installe
    goto end
)

echo Installation de Python 3.10.9...
echo Telechargement...
curl -L -o "%TEMP%\python3.10.exe" https://www.python.org/ftp/python/3.10.9/python-3.10.9-amd64.exe

echo Installation...
"%TEMP%\python3.10.exe" /quiet InstallAllUsers=0 PrependPath=0 Include_test=0 Include_pip=1 Include_launcher=1
del "%TEMP%\python3.10.exe"

echo Creation des commandes de raccourci...
echo @echo off > use_python310.bat
echo set PATH=%%LOCALAPPDATA%%\Programs\Python\Python310;%%LOCALAPPDATA%%\Programs\Python\Python310\Scripts;%%PATH%% >> use_python310.bat
echo @echo Python 3.10 est maintenant actif >> use_python310.bat
echo @echo Pour verifier : python --version >> use_python310.bat

echo.
echo Installation terminee!
echo Pour utiliser Python 3.10:
echo 1. Executez "use_python310.bat"
echo 2. OU utilisez directement "py -3.10" pour les commandes Python
echo.
echo Exemple:
echo py -3.10 -m venv venv_py310
echo.
:end
pause

@echo off
echo Compilation de Simple_TTS_GUI pour Windows

:: Nettoyer les anciens fichiers de compilation
echo Nettoyage des fichiers temporaires...
rd /s /q build 2>nul
rd /s /q dist 2>nul

:: Installer les dépendances nécessaires pour PyInstaller
echo Installation des dépendances...
pip install pyinstaller

:: Compiler l'application avec notre fichier spec
echo Compilation de l'application...
pyinstaller Simple_TTS_GUI.spec

if %ERRORLEVEL% NEQ 0 (
    echo Erreur lors de la compilation
    exit /b %ERRORLEVEL%
)

echo Compilation terminée avec succès
echo L'exécutable se trouve dans le dossier dist

:: Copier les fichiers nécessaires dans le dossier dist
echo Copie des fichiers additionnels...
xcopy /y style_nn.qss dist\
xcopy /y README.md dist\ 2>nul
xcopy /y LICENSE dist\ 2>nul

echo Build terminé

# Journal des erreurs et solutions

## 1. PyQt6 non installé
**Erreur :**
```
ModuleNotFoundError: No module named 'PyQt6'
```
**Solution :**
- Ajout de PyQt6 aux dépendances de base dans setup_env.bat
- `pip install PyQt6`

## 2. Cython manquant
**Erreur :**
```
ModuleNotFoundError: No module named 'Cython'
```
**Solution :**
- Installation de Cython avant TTS
- `python -m pip install Cython`

## 3. io.h manquant
**Erreur :**
```
fatal error C1083: Cannot open include file: 'io.h': No such file or directory
```
**Solution :**
- Ajout des chemins du SDK Windows
- Configuration des variables d'environnement pour inclure UCRT

## 4. basetsd.h manquant (Erreur actuelle)
**Erreur :**
```
fatal error C1083: Cannot open include file: 'basetsd.h': No such file or directory
```
**Solutions tentées :**
1. Configuration des variables d'environnement Windows SDK
2. Installation des composants Windows SDK supplémentaires
3. Ajout des chemins vers les en-têtes système

**Solutions proposées à tester :**
1. Essayer d'installer une version précompilée :
```bash
pip install https://github.com/rhasspy/matplotlib-windows/releases/download/v3.3.4/TTS-0.17.6-cp311-cp311-win_amd64.whl
```

2. Installer Visual Studio Community Edition complet au lieu des Build Tools :
```batch
# Télécharger et installer Visual Studio Community 2022
# Sélectionner "Développement Desktop en C++"
```

3. Essayer une version plus ancienne de TTS :
```bash
pip install TTS==0.17.6
```

## 5. Erreur 404 lors du téléchargement de TTS précompilé
**Erreur :**
```
ERROR: HTTP error 404 while getting https://github.com/rhasspy/matplotlib-windows/releases/download/v3.3.4/TTS-0.17.6-cp311-cp311-win_amd64.whl
```

**Solutions proposées :**
1. Utiliser une version plus récente de TTS précompilée :
```bash
pip install https://github.com/rhasspy/matplotlib-windows/releases/download/v3.3.4/TTS-0.21.1-cp311-cp311-win_amd64.whl
```

2. Si cela ne fonctionne pas, essayer l'installation depuis PyPI avec une version spécifique :
```bash
pip install TTS==0.21.1
```

3. Alternative avec une version plus stable :
```bash
# Installer d'abord les dépendances
pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu117
pip install TTS==0.15.2
```

## 6. Version TTS 0.8.0 introuvable
**Erreur :**
```
ERROR: Could not find a version that satisfies the requirement TTS==0.8.0
ERROR: No matching distribution found for TTS==0.8.0
```

**Solution :**
Utiliser une version plus récente et stable de TTS. Les versions disponibles vont de 0.15.0 à 0.22.0.
Recommandation : utiliser la version 0.15.2 qui est stable et compatible avec PyTorch 2.0.1 :
```bash
pip install TTS==0.15.2
```

## 7. Erreur de compilation NumPy (kernel32.lib manquant)
**Erreur :**
```
LINK : fatal error LNK1104: cannot open file 'kernel32.lib'
RuntimeError: Broken toolchain: cannot link a simple C program.
```

**Analyse :**
Cette erreur indique que les outils de build Windows ne sont pas correctement configurés. Le fichier kernel32.lib est une bibliothèque Windows essentielle qui devrait être disponible via le SDK Windows.

**Solutions :**
1. Installer une version précompilée de NumPy :
```bash
pip uninstall numpy
pip install numpy==1.24.3 --only-binary :all:
```

2. Configurer correctement Visual Studio Build Tools :
```batch
# Ouvrir un terminal en tant qu'administrateur et exécuter :
"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
set DISTUTILS_USE_SDK=1
set MSSdk=1
```

3. Alternative - Utiliser une version précompilée de TTS :
```bash
# Désinstaller les versions existantes
pip uninstall TTS numpy
# Installer les versions précompilées
pip install numpy --only-binary :all:
pip install TTS==0.15.2 --no-build-isolation --only-binary :all:
```

## 8. Erreur cl.exe lors de la compilation de TTS
**Erreur :**
```
error: command 'cl.exe' failed: None
```

**Analyse :**
Cette erreur indique que le compilateur C++ (cl.exe) n'est pas correctement installé ou configuré. Visual Studio Build Tools ne suffit pas, il faut la version complète de Visual Studio Community.

**Solutions :**
1. Installer Visual Studio Community 2022 avec les composants C++ :
```batch
# Télécharger Visual Studio Community 2022
curl -L -o "%TEMP%\vs_community.exe" https://aka.ms/vs/17/release/vs_community.exe

# Installer avec les composants nécessaires
"%TEMP%\vs_community.exe" --quiet --wait --norestart --nocache ^
    --add Microsoft.VisualStudio.Workload.NativeDesktop ^
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 ^
    --add Microsoft.VisualStudio.Component.Windows11SDK.22621
```

2. Configurer l'environnement de build :
```batch
set DISTUTILS_USE_SDK=1
set MSSdk=1
set "CL=/MP"
call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
```

3. Installer TTS avec les bons paramètres :
```batch
pip install TTS==0.17.6 --no-cache-dir
```

**Note importante :** Cette solution nécessite aussi Python 3.10 pour une meilleure compatibilité.

## 9. Erreur cl.exe avec Python 3.10
**Erreur :**
```
error: command 'cl.exe' failed: None
[while building 'TTS.tts.utils.monotonic_align.core' extension]
```

**Analyse :**
Cette erreur survient même avec Visual Studio Community installé et Python 3.10. Le problème semble lié à la configuration des chemins des includes C++.

**Solutions à tester :**
1. Configurer explicitement les chemins des includes de Visual Studio :
```batch
set INCLUDE=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\include;%INCLUDE%
set LIB=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.43.34808\lib\x64;%LIB%
```

2. Installer une version précompilée spécifique à Python 3.10 :
```bash
pip install --only-binary :all: TTS
```

3. Utiliser la méthode d'installation alternative :
```bash
# Désinstaller TTS si déjà installé
pip uninstall TTS
# Installer d'abord les dépendances
pip install numpy torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu117
# Installer TTS sans les dépendances
pip install TTS --no-deps
```

## 10. Conflit de dépendances avec numpy
**Erreur :**
```
ERROR: Cannot install requirements.txt because these package versions have conflicting dependencies.
The conflict is caused by:
    The user requested numpy>=1.24.3
    tts requires numpy==1.22.0 for Python 3.10
    librosa 0.10.1 depends on numpy!=1.22.0
    ...and many other conflicts
```

**Analyse :**
Il y a un conflit majeur de versions entre les différentes dépendances :
- TTS requiert numpy==1.22.0 pour Python 3.10
- Librosa refuse numpy 1.22.0
- D'autres packages ont des contraintes de version différentes

**Solutions :**
1. Installation séquentielle avec versions fixes :
```bash
pip uninstall numpy TTS librosa -y
pip install numpy==1.22.0
pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2
pip install TTS==0.17.6 --no-deps
```

2. Utiliser un environnement virtuel propre avec des versions spécifiques :
```batch
python -m venv venv_py310_clean
call .\venv_py310_clean\Scripts\activate.bat
pip install numpy==1.22.0
pip install TTS==0.17.6
```

3. Modifier le fichier requirements.txt pour fixer les versions :
```text
numpy==1.22.0
torch==2.0.1
torchaudio==2.0.2
librosa==0.10.0
TTS==0.17.6
```

**Important :** 
- Pour Python 3.10, il faut absolument utiliser numpy==1.22.0
- Installer les packages un par un plutôt qu'en groupe
- Éviter l'installation depuis requirements.txt qui cause des conflits

## 11. Erreur de compilation TTS avec cl.exe sous Python 3.10
**Erreur :**
```
building 'TTS.tts.utils.monotonic_align.core' extension
error: command 'cl.exe' failed: None
ERROR: Failed building wheel for TTS
```

**Analyse :**
Cette erreur se produit lors de la compilation de l'extension C de TTS, même avec Visual Studio Community et Python 3.10 correctement installés. Le problème est lié à une incompatibilité entre les chemins d'inclusion et la configuration du compilateur.

**Solutions :**
1. Installation sans compilation des extensions :
```bash
pip uninstall TTS -y
pip install TTS==0.17.6 --only-binary :all:
```

2. Installation avec compilation manuelle :
```batch
REM Configuration des chemins d'inclusion
set "VS_PATH=C:\Program Files\Microsoft Visual Studio\2022\Community"
set "MSVC_PATH=%VS_PATH%\VC\Tools\MSVC\14.43.34808"
set "SDK_PATH=C:\Program Files (x86)\Windows Kits\10"
set "SDK_VER=10.0.22621.0"

REM Installation de TTS avec numpy spécifique
pip install numpy==1.22.0
pip install TTS==0.17.6 --no-deps
```

3. Installation des composants précompilés :
```bash
pip install wheel
pip download TTS==0.17.6
pip install TTS-0.17.6-cp310-cp310-win_amd64.whl
```

**Important :**
- Assurez-vous que numpy==1.22.0 est installé avant TTS
- Utilisez `--no-deps` pour éviter les conflits de dépendances
- Si la compilation échoue, essayez l'installation de packages précompilés

## 12. Erreur DLL PyQt6 sous Windows
**Erreur :**
```
ImportError: DLL load failed while importing QtCore: La procédure spécifiée est introuvable.
```

**Analyse :**
Cette erreur survient sur Windows lorsque les DLL de Qt ne sont pas correctement installées ou accessibles. C'est souvent lié à une installation incomplète ou à des versions incompatibles.

**Solutions :**
1. Réinstallation complète de PyQt6 avec toutes les dépendances :
```bash
pip uninstall PyQt6 PyQt6-Qt6 PyQt6-sip -y
pip install PyQt6==6.5.2 PyQt6-Qt6==6.5.2 PyQt6-sip==13.5.2
```

2. Installation des Visual C++ Redistributables :
```batch
# Télécharger et installer Visual C++ Redistributable
curl -L -o "%TEMP%\vc_redist.x64.exe" https://aka.ms/vs/17/release/vc_redist.x64.exe
"%TEMP%\vc_redist.x64.exe" /quiet /norestart
```

3. Installation alternative de PyQt6 :
```bash
pip install --no-cache-dir PyQt6==6.5.2
```

**Important :**
- Ne pas mélanger les versions de PyQt6 entre Windows et MAC
- S'assurer que toutes les dépendances systèmes sont installées
- Vérifier la compatibilité avec Python 3.10

## 13. Erreur de compilation avec chemins d'inclusion multiples
**Erreur :**
```
cl.exe /c /nologo /O2 /W3 /GL /DNDEBUG /MD ... multiple include paths ... /TcTTS/tts/utils/monotonic_align/core.c
error: command 'cl.exe' failed: None
ERROR: Failed building wheel for TTS
```

**Analyse :**
L'erreur survient malgré la présence de tous les chemins d'inclusion nécessaires. Le problème semble être lié à la duplication des chemins d'inclusion et à l'ordre de leur déclaration.

**Solutions :**
1. Nettoyage et réorganisation des variables d'environnement :
```batch
REM Réinitialiser les variables
set "INCLUDE="
set "LIB="

REM Configurer dans l'ordre correct
set "VS_PATH=C:\Program Files\Microsoft Visual Studio\2022\Community"
set "MSVC_PATH=%VS_PATH%\VC\Tools\MSVC\14.43.34808"
set "SDK_PATH=C:\Program Files (x86)\Windows Kits\10"
set "SDK_VER=10.0.22621.0"

REM Ajouter les chemins dans l'ordre de priorité
set "INCLUDE=%MSVC_PATH%\include;%MSVC_PATH%\ATLMFC\include;%VS_PATH%\VC\Auxiliary\VS\include"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\ucrt"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\um"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\shared"

set "LIB=%MSVC_PATH%\lib\x64;%MSVC_PATH%\ATLMFC\lib\x64"
set "LIB=%LIB%;%SDK_PATH%\Lib\%SDK_VER%\ucrt\x64"
set "LIB=%LIB%;%SDK_PATH%\Lib\%SDK_VER%\um\x64"
```

2. Installation en mode binaire uniquement :
```bash
pip uninstall TTS -y
pip install TTS --only-binary :all: --no-deps
pip install -r requirements_minimal.txt
```

3. Installation des dépendances dans l'ordre strict :
```batch
REM Installation séquentielle
pip install numpy==1.22.0 --only-binary :all:
pip install torch==2.0.1 --only-binary :all:
pip install TTS==0.17.6 --no-deps
```

**Important :**
- Éviter les chemins d'inclusion dupliqués
- Maintenir l'ordre correct des includes
- S'assurer que numpy est installé avant TTS
- Utiliser des versions binaires quand possible

## 14. Erreur de duplication des chemins d'inclusion Visual Studio
**Erreur :**
```
cl.exe /c /nologo /O2 /W3 /GL /DNDEBUG /MD [chemins d'inclusion dupliqués] /TcTTS/tts/utils/monotonic_align/core.c
error: command 'cl.exe' failed: None
```

**Analyse :**
Les chemins d'inclusion sont dupliqués dans la commande de compilation, ce qui peut causer des conflits. On voit notamment :
- Duplication des chemins MSVC
- Chemins d'inclusion redondants
- Ordre incorrect des includes

**Solutions :**
1. Nettoyer complètement les variables d'environnement avant configuration :
```batch
REM Réinitialisation complète
set "INCLUDE="
set "LIB="
set "PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem"

REM Configuration systématique
set "VS_PATH=C:\Program Files\Microsoft Visual Studio\2022\Community"
set "MSVC_PATH=%VS_PATH%\VC\Tools\MSVC\14.43.34808"
set "SDK_PATH=C:\Program Files (x86)\Windows Kits\10"
set "SDK_VER=10.0.22621.0"

REM Configuration ordonnée des includes
set "INCLUDE=%MSVC_PATH%\include"
set "INCLUDE=%INCLUDE%;%VS_PATH%\VC\Auxiliary\VS\include"
set "INCLUDE=%INCLUDE%;%MSVC_PATH%\ATLMFC\include"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\ucrt"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\um"
set "INCLUDE=%INCLUDE%;%SDK_PATH%\Include\%SDK_VER%\shared"

REM Configuration des bibliothèques
set "LIB=%MSVC_PATH%\lib\x64"
set "LIB=%LIB%;%MSVC_PATH%\ATLMFC\lib\x64"
set "LIB=%LIB%;%SDK_PATH%\Lib\%SDK_VER%\ucrt\x64"
set "LIB=%LIB%;%SDK_PATH%\Lib\%SDK_VER%\um\x64"

REM Configuration du PATH
set "PATH=%MSVC_PATH%\bin\HostX64\x64;%PATH%"
```

2. Installation alternative sans compilation :
```bash
pip install TTS --no-deps --only-binary :all:
```

3. Installation des dépendances dans l'ordre strict :
```bash
pip install numpy==1.22.0 --only-binary :all:
pip install torch==2.0.1 --only-binary :all:
pip install TTS==0.17.6 --no-deps
```

**Important :**
- Réinitialiser complètement l'environnement avant la configuration
- Éviter toute duplication dans les chemins d'inclusion
- Maintenir un ordre cohérent des includes
- Préférer les versions binaires quand possible

## 15. Erreur de chemin avec espaces dans Program Files
**Erreur :**
```
'C:\Program' n'est pas reconnu en tant que commande interne
ou externe, un programme exécutable ou un fichier de commandes.
```

**Analyse :**
Cette erreur se produit lorsque Windows tente d'exécuter des commandes avec des chemins contenant des espaces sans guillemets. Le chemin "C:\Program Files" est interprété comme deux parties distinctes : "C:\Program" et "Files".

**Solutions :**
1. Utiliser des guillemets pour les chemins avec espaces :
```batch
REM Au lieu de
set PYTHON_CMD=C:\Program Files\Python310\python.exe

REM Utiliser
set "PYTHON_CMD=%ProgramFiles%\Python310\python.exe"
set "PYTHON_PATH=%ProgramFiles%\Python310"
```

2. Utiliser des variables d'environnement Windows :
```batch
REM Configuration des chemins
set "PROG_FILES=%ProgramFiles%"
set "PYTHON_PATH=%PROG_FILES%\Python310"
set "PYTHON_EXE=%PYTHON_PATH%\python.exe"

REM Utilisation
"%PYTHON_EXE%" -m pip install ...
```

3. Alternative avec chemins courts :
```batch
REM Obtenir le chemin court pour Program Files
for %%i in ("%ProgramFiles%") do set "PROGFILES_SHORT=%%~si"
set "PYTHON_PATH=%PROGFILES_SHORT%\Python310"
```

**Exemple de configuration complète :**
```batch
@echo off
setlocal enabledelayedexpansion

REM Configuration des chemins avec gestion des espaces
set "PROG_FILES=%ProgramFiles%"
set "PYTHON_PATH=%PROG_FILES%\Python310"
set "PYTHON_EXE=%PYTHON_PATH%\python.exe"

REM Vérification de Python
if exist "%PYTHON_EXE%" (
    REM Utilisation avec guillemets
    "%PYTHON_EXE%" -m pip install ...
) else (
    echo Python non trouve dans "%PYTHON_PATH%"
    exit /b 1
)
```

**Important :**
- Toujours utiliser des guillemets pour les chemins contenant des espaces
- Préférer les variables d'environnement Windows (%ProgramFiles%, etc.)
- Vérifier l'existence des chemins avant utilisation
- Utiliser setlocal enabledelayedexpansion pour la manipulation des variables

## Problèmes connus restants
- Problèmes de compilation avec les dépendances qui nécessitent une compilation (NumPy, TTS)
- Nécessité d'avoir Visual Studio Community 2022 complet
- Versions spécifiques requises : Python 3.10 et TTS 0.17.6
- Erreurs de compilation persistantes même avec l'environnement correctement configuré
- Conflits de versions entre les dépendances, particulièrement avec numpy
- La compilation de l'extension C de TTS échoue même avec l'environnement correctement configuré

### Erreur : Modification du Registre désactivée
**Solution :**
1. Exécuter le script sans droits administrateur
2. Utiliser cette commande alternative :
```bash
setup_env_v21.bat --no-registry
```

## Problèmes de registre Windows

### Erreur : Accès registre bloqué
**Solution :**
- Exécutez le script avec l'option :
  ```batch
  setup_env_v21.bat --no-registry
  ```
- Configurez manuellement le PATH système avec :
  ```
  C:\Python310
  C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\<version>\bin\Hostx64\x64
  ```
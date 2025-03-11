# Guide de Compilation avec PyInstaller

## Préparation pour la compilation sous Windows

Ce guide vous aidera à compiler correctement l'application Simple_TTS_GUI sous Windows en évitant les erreurs courantes comme `ModuleNotFoundError: No module named 'PyQt6.QtWidgets'` ou `ModuleNotFoundError: No module named 'PyQt6.sip'`.

### Étape 1: Préparer l'environnement

1. Assurez-vous que votre environnement virtuel est activé :
   ```
   venv_py310\Scripts\activate
   ```

2. Vérifiez que PyQt6 est correctement installé :
   ```
   pip show PyQt6
   ```

3. Installez ou réinstallez PyQt6 et PyQt6-sip :
   ```
   pip install PyQt6==6.4.0 PyQt6-sip --force-reinstall
   ```

4. Vérifiez l'installation de PyQt6.sip avec le script de diagnostic :
   ```
   python check_sip.py
   ```

### Étape 2: Installer PyInstaller

```
pip install pyinstaller
```

### Étape 3: Compiler l'application

Utilisez la commande suivante pour compiler l'application avec le fichier .spec modifié :

```
pyinstaller --clean Simple_TTS_GUI.spec
```

L'option `--clean` permet de nettoyer les fichiers temporaires des compilations précédentes.

### Étape 4: Vérification des fichiers compilés

Après la compilation, vérifiez que les fichiers suivants sont présents dans le dossier `dist\Simple_TTS_GUI` :

1. Le fichier exécutable `Simple_TTS_GUI.exe`
2. Les dossiers `PyQt6`, `PyQt6/Qt6/bin`, `PyQt6/Qt6/plugins`
3. Les fichiers `.pyd` de PyQt6 dans le dossier `PyQt6`, notamment `_sip.pyd`

### Problèmes courants et solutions

#### 1. Module PyQt6.QtWidgets introuvable

Si vous obtenez l'erreur `ModuleNotFoundError: No module named 'PyQt6.QtWidgets'`, cela signifie que PyInstaller n'a pas correctement inclus les modules PyQt6 dans l'exécutable.

**Solution** : 
- Utilisez le fichier `Simple_TTS_GUI.spec` modifié qui inclut explicitement tous les modules et fichiers binaires nécessaires.
- Vérifiez que le hook personnalisé `pyinstaller_hook-PyQt6.py` est présent dans le même dossier que votre fichier .spec.

#### 2. Module PyQt6.sip introuvable

Si vous obtenez l'erreur `ModuleNotFoundError: No module named 'PyQt6.sip'`, cela signifie que le module d'interface Python/C++ de PyQt6 n'est pas correctement inclus.

**Solution** :
- Installez explicitement PyQt6-sip : `pip install PyQt6-sip`
- Assurez-vous que le fichier `_sip.pyd` est inclus dans le fichier .spec
- Vérifiez que les modules `PyQt6.sip` et `sip` sont dans la liste des hiddenimports

#### 3. Erreurs liées aux DLL manquantes

Si vous obtenez des erreurs concernant des DLL manquantes au lancement de l'application, assurez-vous que :

1. Les fichiers DLL de Qt6 sont correctement inclus dans le dossier `PyQt6/Qt6/bin`
2. Les plugins Qt6 sont correctement inclus dans le dossier `PyQt6/Qt6/plugins`

#### 4. Débogage des erreurs

Si l'application ne se lance pas correctement :

1. Modifiez le fichier .spec pour activer la console et le mode debug :
   ```python
   debug=True,
   console=True,
   ```
2. Recompilez l'application
3. Exécutez l'application depuis une invite de commande pour voir les messages d'erreur

### Conseils supplémentaires

1. **Chemins absolus** : Assurez-vous que les chemins dans le fichier .spec correspondent à votre environnement.

2. **Versions compatibles** : Utilisez des versions compatibles de PyQt6 et PyInstaller. Par exemple :
   - PyQt6 6.4.0
   - PyQt6-sip 13.4.0
   - PyInstaller 5.13.0

3. **Fichiers de ressources** : Si votre application utilise des fichiers de ressources (images, styles, etc.), assurez-vous qu'ils sont inclus dans la section `datas` du fichier .spec.

4. **Tests progressifs** : Testez d'abord une version simplifiée de votre application pour identifier les problèmes spécifiques.

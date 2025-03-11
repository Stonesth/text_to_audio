# Guide de Compilation avec PyInstaller

## Préparation pour la compilation sous Windows

Ce guide vous aidera à compiler correctement l'application Simple_TTS_GUI sous Windows en évitant les erreurs courantes comme `ModuleNotFoundError: No module named 'PyQt6.QtWidgets'`.

### u00c9tape 1: Préparer l'environnement

1. Assurez-vous que votre environnement virtuel est activé :
   ```
   venv_py310\Scripts\activate
   ```

2. Vérifiez que PyQt6 est correctement installé :
   ```
   pip show PyQt6
   ```

3. Si nécessaire, réinstallez PyQt6 :
   ```
   pip install PyQt6==6.4.0 --force-reinstall
   ```

### u00c9tape 2: Installer PyInstaller

```
pip install pyinstaller
```

### u00c9tape 3: Compiler l'application

Utilisez la commande suivante pour compiler l'application avec le fichier .spec modifié :

```
pyinstaller --clean Simple_TTS_GUI.spec
```

L'option `--clean` permet de nettoyer les fichiers temporaires des compilations précédentes.

### u00c9tape 4: Vérification des fichiers compilés

Apru00e8s la compilation, vérifiez que les fichiers suivants sont présents dans le dossier `dist\Simple_TTS_GUI` :

1. Le fichier exécutable `Simple_TTS_GUI.exe`
2. Les dossiers `PyQt6`, `PyQt6/Qt6/bin`, `PyQt6/Qt6/plugins`
3. Les fichiers `.pyd` de PyQt6 dans le dossier `PyQt6`

### Problu00e8mes courants et solutions

#### 1. Module PyQt6.QtWidgets introuvable

Si vous obtenez l'erreur `ModuleNotFoundError: No module named 'PyQt6.QtWidgets'`, cela signifie que PyInstaller n'a pas correctement inclus les modules PyQt6 dans l'exécutable.

**Solution** : 
- Utilisez le fichier `Simple_TTS_GUI.spec` modifié qui inclut explicitement tous les modules et fichiers binaires nécessaires.
- Vérifiez que le hook personnalisé `pyinstaller_hook-PyQt6.py` est présent dans le mu00eame dossier que votre fichier .spec.

#### 2. Erreurs liées aux DLL manquantes

Si vous obtenez des erreurs concernant des DLL manquantes au lancement de l'application, assurez-vous que :

1. Les fichiers DLL de Qt6 sont correctement inclus dans le dossier `PyQt6/Qt6/bin`
2. Les plugins Qt6 sont correctement inclus dans le dossier `PyQt6/Qt6/plugins`

#### 3. Débogage des erreurs

Si l'application ne se lance pas correctement :

1. Modifiez le fichier .spec pour activer la console (`console=True`)
2. Recompilez l'application
3. Exécutez l'application depuis une invite de commande pour voir les messages d'erreur

### Conseils supplémentaires

1. **Chemins absolus** : Assurez-vous que les chemins dans le fichier .spec correspondent à votre environnement.

2. **Versions compatibles** : Utilisez des versions compatibles de PyQt6 et PyInstaller. Par exemple :
   - PyQt6 6.4.0
   - PyInstaller 5.13.0

3. **Fichiers de ressources** : Si votre application utilise des fichiers de ressources (images, styles, etc.), assurez-vous qu'ils sont inclus dans la section `datas` du fichier .spec.

4. **Tests progressifs** : Testez d'abord une version simplifiée de votre application pour identifier les problu00e8mes spécifiques.

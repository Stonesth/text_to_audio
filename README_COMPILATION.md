# Guide de Compilation avec PyInstaller

## Pru00e9paration pour la compilation sous Windows

Ce guide vous aidera u00e0 compiler correctement l'application Simple_TTS_GUI sous Windows en u00e9vitant les erreurs courantes comme `ModuleNotFoundError: No module named 'PyQt6.QtWidgets'`.

### u00c9tape 1: Pru00e9parer l'environnement

1. Assurez-vous que votre environnement virtuel est activu00e9 :
   ```
   venv_py310\Scripts\activate
   ```

2. Vu00e9rifiez que PyQt6 est correctement installu00e9 :
   ```
   pip show PyQt6
   ```

3. Si nu00e9cessaire, ru00e9installez PyQt6 :
   ```
   pip install PyQt6==6.4.0 --force-reinstall
   ```

### u00c9tape 2: Installer PyInstaller

```
pip install pyinstaller
```

### u00c9tape 3: Compiler l'application

Utilisez la commande suivante pour compiler l'application avec le fichier .spec modifiu00e9 :

```
pyinstaller --clean Simple_TTS_GUI.spec
```

L'option `--clean` permet de nettoyer les fichiers temporaires des compilations pru00e9cu00e9dentes.

### u00c9tape 4: Vu00e9rification des fichiers compilu00e9s

Apru00e8s la compilation, vu00e9rifiez que les fichiers suivants sont pru00e9sents dans le dossier `dist\Simple_TTS_GUI` :

1. Le fichier exu00e9cutable `Simple_TTS_GUI.exe`
2. Les dossiers `PyQt6`, `PyQt6/Qt6/bin`, `PyQt6/Qt6/plugins`
3. Les fichiers `.pyd` de PyQt6 dans le dossier `PyQt6`

### Problu00e8mes courants et solutions

#### 1. Module PyQt6.QtWidgets introuvable

Si vous obtenez l'erreur `ModuleNotFoundError: No module named 'PyQt6.QtWidgets'`, cela signifie que PyInstaller n'a pas correctement inclus les modules PyQt6 dans l'exu00e9cutable.

**Solution** : 
- Utilisez le fichier `Simple_TTS_GUI.spec` modifiu00e9 qui inclut explicitement tous les modules et fichiers binaires nu00e9cessaires.
- Vu00e9rifiez que le hook personnalisu00e9 `pyinstaller_hook-PyQt6.py` est pru00e9sent dans le mu00eame dossier que votre fichier .spec.

#### 2. Erreurs liu00e9es aux DLL manquantes

Si vous obtenez des erreurs concernant des DLL manquantes au lancement de l'application, assurez-vous que :

1. Les fichiers DLL de Qt6 sont correctement inclus dans le dossier `PyQt6/Qt6/bin`
2. Les plugins Qt6 sont correctement inclus dans le dossier `PyQt6/Qt6/plugins`

#### 3. Du00e9bogage des erreurs

Si l'application ne se lance pas correctement :

1. Modifiez le fichier .spec pour activer la console (`console=True`)
2. Recompilez l'application
3. Exu00e9cutez l'application depuis une invite de commande pour voir les messages d'erreur

### Conseils supplu00e9mentaires

1. **Chemins absolus** : Assurez-vous que les chemins dans le fichier .spec correspondent u00e0 votre environnement.

2. **Versions compatibles** : Utilisez des versions compatibles de PyQt6 et PyInstaller. Par exemple :
   - PyQt6 6.4.0
   - PyInstaller 5.13.0

3. **Fichiers de ressources** : Si votre application utilise des fichiers de ressources (images, styles, etc.), assurez-vous qu'ils sont inclus dans la section `datas` du fichier .spec.

4. **Tests progressifs** : Testez d'abord une version simplifiu00e9e de votre application pour identifier les problu00e8mes spu00e9cifiques.

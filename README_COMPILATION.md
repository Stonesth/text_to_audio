# Guide de compilation avec PyInstaller

## Prérequis

1. **Python 3.10** (recommandé)
2. **PyInstaller 6.x**
3. **PyQt6 6.4.0** (ou version compatible)
4. **PyQt6-sip** (nécessaire pour la compilation)
5. **Environnement virtuel** (recommandé)

## Préparation de l'environnement

### 1. Création d'un environnement virtuel

```bash
python -m venv venv_py310
venv_py310\Scripts\activate
```

### 2. Installation des dépendances

```bash
pip install --upgrade pip
pip install -r requirements.txt
pip install pyinstaller==6.12.0
```

### 3. Vérification de PyQt6-sip

Assurez-vous que PyQt6-sip est correctement installé :

```bash
pip install PyQt6-sip --force-reinstall
```

## Problèmes connus et solutions

### 1. Problème avec PyQt6.sip

Si vous rencontrez des erreurs du type `ModuleNotFoundError: No module named 'PyQt6.sip'` lors de la compilation ou de l'exécution :

- Vérifiez que le fichier `sip.cp310-win_amd64.pyd` (ou équivalent pour votre plateforme) est présent dans le répertoire de PyQt6.
- Le fichier `.spec` est configuré pour inclure automatiquement ce fichier.

### 2. Problèmes avec PyTorch JIT

Si vous rencontrez des erreurs lorsque l'exécutable essaie de charger PyTorch, notamment des erreurs liées à `torch.jit` ou `_jit_internal` :

- Une solution a été implantée dans le fichier `Simple_TTS_GUI.py` pour désactiver les fonctionnalités JIT de PyTorch qui posent problème avec PyInstaller.
- Le fichier `.spec` est configuré pour exclure les modules problématiques.

## Compilation

### 1. Utilisation du fichier .spec

Le fichier `Simple_TTS_GUI.spec` est déjà configuré avec les paramètres nécessaires. Pour compiler :

```bash
pyinstaller --clean Simple_TTS_GUI.spec
```

### 2. Vérification de l'exécutable

L'exécutable sera créé dans le dossier `dist`. Pour le tester :

```bash
cd dist
Simple_TTS_GUI.exe
```

## Résolution des problèmes

Si vous rencontrez des problèmes lors de la compilation ou de l'exécution :

1. **Vérifiez les logs** : PyInstaller génère des logs détaillés qui peuvent aider à identifier les problèmes.

2. **Utilisez le mode debug** : Le fichier `.spec` est configuré pour activer le mode debug, ce qui fournit plus d'informations en cas d'erreur.

3. **Vérifiez les dépendances manquantes** : Utilisez l'outil `check_sip.py` pour vérifier l'installation de PyQt6-sip :

```bash
python check_sip.py
```

4. **Problèmes avec PyTorch** : Si vous rencontrez des erreurs spécifiques à PyTorch, essayez d'installer une version plus ancienne :

```bash
pip uninstall torch
pip install torch==1.13.1
```

## Conseils supplémentaires

1. **Nettoyage avant compilation** : Toujours utiliser l'option `--clean` avec PyInstaller pour éviter les problèmes liés aux compilations précédentes.

2. **Vérification des hooks** : Les hooks personnalisés (`pyinstaller_hook-PyQt6.py`, `hook-torch.py`) sont essentiels pour la compilation correcte. Ne les modifiez pas sans comprendre leur fonctionnement.

3. **Mise à jour de PyInstaller** : Si vous rencontrez des problèmes persistants, essayez de mettre à jour PyInstaller vers la dernière version.

4. **Compilation sur la même plateforme** : Compilez toujours sur la même plateforme que celle où l'exécutable sera utilisé (Windows pour Windows, macOS pour macOS).

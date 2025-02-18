# Simple_TTS

Script de synthèse vocale utilisant différents modèles pour générer de l'audio en français et en anglais.

## Installation

```bash
# Créer et activer l'environnement virtuel
python3 -m venv venv_py311
source venv_py311/bin/activate

# Installer les dépendances
pip install --upgrade pip
pip install TTS
```

## Commandes disponibles

### 1. Modèles Anglais (--lang 0)

```bash
# Tacotron2-DDC (par défaut)
python Simple_TTS.py --lang 0 --en-model 0 --text-file text_en.txt --use-cuda

# Glow-TTS
python Simple_TTS.py --lang 0 --en-model 1 --text-file text_en.txt --use-cuda

# Speedy-Speech
python Simple_TTS.py --lang 0 --en-model 2 --text-file text_en.txt --use-cuda

# VITS
python Simple_TTS.py --lang 0 --en-model 3 --text-file text_en.txt --use-cuda

# Jenny
python Simple_TTS.py --lang 0 --en-model 4 --text-file text_en.txt --use-cuda
```

### 2. Modèles Français (--lang 1)

```bash
# VITS CSS10 (par défaut)
python Simple_TTS.py --lang 1 --fr-model 0 --text-file text_fr.txt --use-cuda

# Tacotron2-DDC CSS10
python Simple_TTS.py --lang 1 --fr-model 1 --text-file text_fr.txt --use-cuda

# YourTTS
python Simple_TTS.py --lang 1 --fr-model 2 --text-file text_fr.txt --use-cuda --yourtts-speaker male-en-2

# YourTTS avec speaker spécifique
python Simple_TTS.py --lang 1 --fr-model 3 --text-file text_fr.txt --use-cuda --yourtts-speaker female-en-5

# XTTS v2 (nécessite un fichier audio de référence)
python Simple_TTS.py --lang 1 --fr-model 4 --text-file text_fr.txt --use-cuda --reference-audio voice.wav
```

### 3. Voix VCTK (--lang 2)

#### Voix recommandées :
- VCTK_p232 (homme, bien)
- VCTK_p273 (femme, bien)
- VCTK_p278 (femme, bien)
- VCTK_p279 (homme, bien)
- VCTK_p304 (femme, voix préférée)

```bash
# Utilisation des voix VCTK
python Simple_TTS.py --lang 2 --en-model 3 --text-file text_en.txt --use-cuda --speaker VCTK_p304
```

### 4. Options supplémentaires

#### Vitesse de parole
```bash
# Plus lent (>1.0)
python Simple_TTS.py --lang 1 --text-file text_fr.txt --use-cuda --length-scale 1.2

# Plus rapide (<1.0)
python Simple_TTS.py --lang 1 --text-file text_fr.txt --use-cuda --length-scale 0.8
```

#### Speakers YourTTS disponibles
- male-en-2
- female-en-5
- female-pt-4
- male-pt-3

## Interface Graphique

Une interface graphique est disponible via le script `Simple_TTS_GUI.py`. Pour l'utiliser :

```bash
# Installer PyQt6
pip install PyQt6

# Lancer l'interface graphique
python Simple_TTS_GUI.py
```

L'interface graphique offre :
- Sélection de la langue
- Choix du modèle
- Sélection des voix VCTK
- Support CUDA
- Chargement de fichiers texte
- Zone de texte intégrée
- Suivi de la progression
- Sélection du dossier de sortie pour les fichiers audio générés

## Notes importantes

1. Les fichiers générés seront sauvegardés dans le dossier `story_output/`
2. Le paramètre `--use-cuda` est optionnel et n'utilise CUDA que s'il est disponible
3. Les fichiers texte doivent être encodés en UTF-8
4. Pour XTTS v2, le fichier audio de référence est obligatoire

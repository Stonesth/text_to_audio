#!/bin/bash

# Activation de l'environnement virtuel
source venv_py311/bin/activate

# Création des fichiers texte de test
echo "This is a test sentence in English. I hope you enjoy listening to all these different voices!" > test_en.txt
echo "Ceci est une phrase de test en français. J'espère que vous apprécierez d'écouter toutes ces différentes voix !" > test_fr.txt

# Création du dossier de sortie
mkdir -p story_output

echo "=== Test des modèles anglais (lang 0) ==="
# Tacotron2-DDC
echo "Test de Tacotron2-DDC en anglais..."
python Simple_TTS.py --lang 0 --en-model 0 --text-file test_en.txt --use-cuda

# Glow-TTS (désactivé - mauvaise qualité)
# echo "Test de Glow-TTS en anglais..."
# python Simple_TTS.py --lang 0 --en-model 1 --text-file test_en.txt --use-cuda

# Speedy-Speech (désactivé - mauvaise qualité)
# echo "Test de Speedy-Speech en anglais..."
# python Simple_TTS.py --lang 0 --en-model 2 --text-file test_en.txt --use-cuda

# VITS
echo "Test de VITS en anglais..."
python Simple_TTS.py --lang 0 --en-model 3 --text-file test_en.txt --use-cuda --speaker "p225"

# Jenny
echo "Test de Jenny en anglais..."
python Simple_TTS.py --lang 0 --en-model 4 --text-file test_en.txt --use-cuda

echo "=== Test des modèles français (lang 1) ==="
# VITS CSS10 (désactivé - mauvaise qualité)
# echo "Test de VITS CSS10 en français..."
# python Simple_TTS.py --lang 1 --fr-model 0 --text-file test_fr.txt --use-cuda

# Tacotron2-DDC CSS10
echo "Test de Tacotron2-DDC CSS10 en français..."
python Simple_TTS.py --lang 1 --fr-model 1 --text-file test_fr.txt --use-cuda

# YourTTS avec différents speakers
echo "Test de YourTTS en français avec voix masculine..."
python Simple_TTS.py --lang 1 --fr-model 3 --text-file test_fr.txt --use-cuda --yourtts-speaker male-en-2

echo "Test de YourTTS en français avec voix féminine..."
python Simple_TTS.py --lang 1 --fr-model 3 --text-file test_fr.txt --use-cuda --yourtts-speaker female-en-5

# XTTS v2 avec fichier audio de référence
echo "Test de XTTS v2 en français..."
python Simple_TTS.py --lang 1 --fr-model 4 --text-file test_fr.txt --use-cuda --reference-audio voice/audio.wav

echo "=== Test des voix VCTK (lang 2) ==="
# Test avec différentes voix VCTK recommandées
for voice in "p232" "p273" "p278" "p279" "p304"; do
    echo "Test de la voix VCTK ${voice}..."
    python Simple_TTS.py --lang 2 --en-model 3 --text-file test_en.txt --use-cuda --speaker "VCTK_${voice}"
done

# Note : Les tests de vitesse sont désactivés car ils utilisent VITS qui a été désactivé
# echo "=== Test des variations de vitesse ==="
# Test avec différentes vitesses
# echo "Test avec vitesse lente (1.2)..."
# python Simple_TTS.py --lang 1 --fr-model 0 --text-file test_fr.txt --use-cuda --length-scale 1.2
# mv "story_output/output_fr_vits.wav" "story_output/output_fr_vits_slow.wav"

# echo "Test avec vitesse rapide (0.8)..."
# python Simple_TTS.py --lang 1 --fr-model 0 --text-file test_fr.txt --use-cuda --length-scale 0.8
# mv "story_output/output_fr_vits.wav" "story_output/output_fr_vits_fast.wav"

echo "Tests terminés ! Vérifiez le dossier story_output pour les fichiers audio générés."

"""
Script de synthèse vocale utilisant différents modèles pour générer de l'audio en français et en anglais.
Supporte les modèles : Tacotron2, Glow-TTS, VITS, YourTTS et XTTS v2.
"""

import os
import sys
import argparse
from pathlib import Path
import datetime
import inspect

# Imports PyTorch
import torch
import torch.nn as nn
# from torch.serialization import add_safe_globals

# Imports TTS
from TTS.api import TTS
from TTS.utils.radam import RAdam
from TTS.tts.configs.shared_configs import BaseTTSConfig
from TTS.tts.configs.xtts_config import XttsConfig
from TTS.tts.models.xtts import XttsAudioConfig, Xtts, XttsArgs
from TTS.tts.models.base_tts import BaseTTS
from TTS.config.shared_configs import BaseDatasetConfig

# Imports NumPy
import numpy as np
from collections import defaultdict, OrderedDict

# # Configuration des globals sécurisés pour PyTorch 2.6
# SAFE_CLASSES = [
#     RAdam,
#     defaultdict,
#     OrderedDict,
#     np.ndarray,
#     torch.nn.Parameter,
#     torch._utils._rebuild_tensor_v2,
#     torch.Tensor,
#     dict,
#     list,
#     tuple,
#     int,
#     float,
#     str,
#     bool,
#     type(None),
#     BaseTTSConfig,
#     XttsConfig,
#     XttsAudioConfig,
#     XttsArgs,
#     Xtts,
#     np.core.multiarray.scalar,
#     np.ndarray,
#     np._globals._NoValue,
#     np.dtype,
#     np.ufunc,
#     np.generic,
#     BaseTTS,
#     nn.Module,
#     BaseDatasetConfig,
# ]
# add_safe_globals(SAFE_CLASSES)

# Configuration de base pour PyTorch
torch._C._add_docstring = lambda obj, doc: None  # Fix pour éviter les erreurs de docstring
torch.set_default_dtype(torch.float32)  # Assure la compatibilité des types


def read_text_file(file_path: str) -> str | None:
    """
    Lit le contenu d'un fichier texte.
    
    Args:
        file_path: Chemin vers le fichier texte à lire
        
    Returns:
        Le contenu du fichier ou None si une erreur survient
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            return file.read().strip()
    except FileNotFoundError:
        print(f"Erreur : Le fichier {file_path} n'existe pas.")
        return None
    except Exception as e:
        print(f"Erreur lors de la lecture du fichier : {str(e)}")
        return None

def get_parser():
    """Retourne le parseur d'arguments configuré."""
    parser = argparse.ArgumentParser(description="Générer un fichier audio à partir d'un texte")
    
    # Arguments principaux
    parser.add_argument('--lang', type=int, choices=[0, 1, 2], default=0,
                       help='Langue (0: Anglais, 1: Français, 2: Anglais avec VCTK)')
    parser.add_argument('--text-file', type=str, required=False,
                       help='Chemin vers le fichier texte à lire')
    parser.add_argument('--text', type=str, required=False,
                       help='Texte à lire')
    parser.add_argument('--output', type=str, required=False,
                       help='Chemin vers le fichier de sortie')
    parser.add_argument('--use-cuda', action='store_true',
                       help='Utiliser CUDA si disponible')
    
    # Modèles et voix
    parser.add_argument('--en-model', type=int, choices=range(5), default=0,
                       help='Modèle anglais (0: Tacotron2-DDC, 1: Glow-TTS, 2: Speedy-Speech, 3: VITS, 4: Jenny)')
    parser.add_argument('--fr-model', type=int, choices=range(5), default=0,
                       help='Modèle français (0: VITS, 1: Tacotron2-DDC, 2: YourTTS, 3: YourTTS+speaker, 4: XTTS v2)')
    
    # Options spécifiques aux modèles
    parser.add_argument('--yourtts-speaker', type=str, default='male-en-2',
                       choices=['male-en-2', 'female-en-5', 'female-pt-4', 'male-pt-3'],
                       help='Speaker pour YourTTS')
    parser.add_argument('--reference-audio', type=str,
                       help='Fichier audio de référence pour XTTS v2')
    parser.add_argument('--speaker', type=str, default='VCTK_p229',
                       help='ID du speaker pour VCTK (ex: VCTK_p229, VCTK_p304)')
    
    # Paramètres de synthèse
    parser.add_argument('--length-scale', type=float, default=1.0,
                       help='Vitesse de la parole (< 1.0 plus rapide, > 1.0 plus lent)')
    
    return parser

def get_model_name(lang: int, en_model: int = 0, fr_model: int = 0) -> str:
    """Retourne le nom du modèle en fonction de la langue choisie."""
    models = {
        0: {  # Anglais
            0: "tts_models/en/ljspeech/tacotron2-DDC",
            1: "tts_models/en/ljspeech/glow-tts",
            2: "tts_models/en/ljspeech/speedy-speech",
            3: "tts_models/en/vctk/vits",
            4: "tts_models/en/jenny/jenny"
        },
        1: {  # Français
            0: "tts_models/fr/css10/vits",
            1: "tts_models/fr/css10/tacotron2-DDC",
            2: "tts_models/multilingual/multi-dataset/your_tts",
            3: "tts_models/multilingual/multi-dataset/your_tts",
            4: "tts_models/multilingual/multi-dataset/xtts_v2"
        },
        2: {  # Anglais avec VCTK
            0: "tts_models/en/vctk/vits",  # Modèle VCTK multi-speaker
            1: "tts_models/en/ljspeech/glow-tts",
            2: "tts_models/en/ljspeech/speedy-speech",
            3: "tts_models/en/vctk/fast_pitch",  # Changé pour FastPitch
            4: "tts_models/en/jenny/jenny"
        }
    }
    return models[lang].get(en_model if lang != 1 else fr_model, models[lang][0])

def get_model_suffix(lang: int, en_model: int = 0, fr_model: int = 0, speaker: str = None) -> str:
    """Retourne un suffixe distinctif pour le nom du fichier."""
    suffixes = {
        0: {  # Anglais
            0: "_en_tacotron",
            1: "_en_glowtts",
            2: "_en_speedyspeech",
            3: "_en_vits",
            4: "_en_jenny"
        },
        1: {  # Français
            0: "_fr_vits",
            1: "_fr_tacotron",
            2: "_fr_yourtts",
            3: "_fr_yourtts",
            4: "_fr_xtts_v2"
        },
        2: {  # Anglais avec VCTK
            0: "_en_vctk_vits",  # Modèle VCTK multi-speaker
            1: "_en_glowtts",
            2: "_en_speedyspeech",
            3: "_en_fastpitch",  # Changé pour FastPitch
            4: "_en_jenny"
        }
    }
    return suffixes[lang].get(en_model if lang != 1 else fr_model, "_unknown")

def initialize_tts(args, device):
    """
    Initialise le modèle TTS en fonction des arguments.
    """
    # Initialisation des variables par défaut
    speaker = None
    language = "en"
    speaker_wav = None
    
    model_name = get_model_name(args.lang, args.en_model, args.fr_model)
    
    if model_name:
        print(f"Chargement du modèle : {model_name}")
        
        # Configuration pour les différents modèles
        if args.fr_model == 4:  # XTTS v2
            if not args.reference_audio:
                print("Erreur : XTTS v2 nécessite un fichier audio de référence (--reference-audio)")
                sys.exit(1)
            
            # Patch temporaire pour PyTorch 2.6
            original_load = torch.load
            def patched_load(*args, **kwargs):
                kwargs['weights_only'] = False
                return original_load(*args, **kwargs)
            torch.load = patched_load
            
            tts = TTS(model_name).to(device)
            torch.load = original_load  # Restauration
            
            speaker = None
            language = "fr"
            speaker_wav = args.reference_audio
        elif args.lang == 1:  # Français
            if args.fr_model == 3:  # YourTTS
                tts = TTS(model_name).to(device)
                print("\nSpeakers disponibles pour YourTTS :")
                print(tts.speakers)
                speaker = args.yourtts_speaker
                language = "fr-fr"
            else:
                tts = TTS(model_name).to(device)
                language = "fr"
        else:  # Anglais (VCTK)
            if args.lang == 2 and args.en_model == 0:  # VITS VCTK
                tts = TTS(model_name).to(device)
                print("\nSpeakers disponibles pour VCTK :")
                # Liste des voix préférées
                preferred_voices = {
                    "p232": "Voix masculine, bien articulée",
                    "p273": "Voix féminine, bien articulée",
                    "p278": "Voix féminine, bien articulée",
                    "p279": "Voix masculine, bien articulée",
                    "p304": "Voix féminine, préférée"
                }
                print("\nVoix recommandées :")
                for speaker_id, description in preferred_voices.items():
                    print(f"{speaker_id} - {description}")
                
                # Convertir VCTK_pXXX en pXXX pour le modèle
                if args.speaker.startswith("VCTK_"):
                    speaker = args.speaker[5:]  # Enlève le préfixe "VCTK_"
                else:
                    speaker = args.speaker
                
                if not speaker.startswith("p") or not speaker[1:].isdigit():
                    print(f"Erreur : Format de speaker invalide. Utilisez le format VCTK_pXXX")
                    sys.exit(1)
                language = "en"
            else:
                tts = TTS(model_name).to(device)
                language = "en"
        
        return tts, speaker, language, speaker_wav
    else:
        print("Erreur : Modèle non reconnu")
        sys.exit(1)

def main():
    """Fonction principale du script."""
    args = get_parser().parse_args()
    
    # Vérification et lecture du fichier texte
    if args.text_file:
        text = read_text_file(args.text_file)
        if not text:
            print(f"Erreur: Impossible de lire le fichier {args.text_file}")
            sys.exit(1)
    else:
        text = args.text
    
    # Vérification de la présence du texte
    if not text:
        print("Erreur: Aucun texte fourni. Utilisez --text ou --text-file")
        sys.exit(1)
    
    # Configuration du device (CPU/CUDA)
    device = "cuda" if args.use_cuda and torch.cuda.is_available() else "cpu"
    print(f"Utilisation du device : {device}")
    
    # Initialisation du modèle TTS
    tts, speaker, language, speaker_wav = initialize_tts(args, device)
    
    # Création du nom de fichier de sortie
    if args.output:
        output_path = args.output
    else:
        # Création du dossier story_output si nécessaire
        os.makedirs("story_output", exist_ok=True)
        
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        model_suffix = get_model_suffix(args.lang, args.en_model, args.fr_model, speaker)
        output_path = f"story_output/output{model_suffix}_{timestamp}.wav"
    
    # Génération de l'audio
    try:
        # Approche simplifiée : utiliser des conditions spécifiques au modèle
        if args.fr_model == 4:  # XTTS v2
            # XTTS v2 nécessite speaker_wav et language
            tts.tts_to_file(text=text, file_path=output_path, speaker_wav=speaker_wav, language=language)
        elif args.lang == 1 and args.fr_model == 3:  # YourTTS français
            # YourTTS nécessite speaker et language
            tts.tts_to_file(text=text, file_path=output_path, speaker=speaker, language=language)
        elif args.lang == 2 and args.en_model == 0:  # VITS VCTK
            # VCTK nécessite speaker
            tts.tts_to_file(text=text, file_path=output_path, speaker=speaker)
        else:
            # Modèles standards sans paramètres supplémentaires
            tts.tts_to_file(text=text, file_path=output_path)
        
        print(f"Audio généré avec succès : {output_path}")
    except Exception as e:
        print(f"Erreur lors de la génération audio : {str(e)}")
        # Afficher plus de détails pour le débogage
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()
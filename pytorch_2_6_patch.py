# Patch pour PyTorch 2.6+ 
"""Patch pour assurer la compatibilité avec PyTorch 2.6+ qui utilise weights_only=True par défaut""" 
import sys 
import torch 
import importlib 
import logging 
 
logger = logging.getLogger(__name__) 
 
def apply_patch(): 
    """Applique le patch pour PyTorch 2.6+""" 
    try: 
        if hasattr(torch.serialization, 'add_safe_globals'): 
            logger.info("Application du patch PyTorch 2.6+ pour XTTS") 
 
            # Liste des classes à ajouter à safe_globals 
            classes_to_add = [ 
                ('TTS.tts.configs.xtts_config', 'XttsConfig'), 
                ('TTS.tts.configs.xtts_config', 'XttsAudioConfig'), 
                ('TTS.tts.models.xtts', 'Xtts'), 
                ('TTS.utils.audio.processor', 'AudioProcessor'), 
                ('TTS.config', 'load_config'), 
                ('TTS.tts.configs.shared_configs', 'BaseTTSConfig'), 
                ('TTS.utils.audio', 'TorchSTFT'), 
            ] 
 
            # Importer et ajouter chaque classe 
            for module_path, class_name in classes_to_add: 
                try: 
                    module = importlib.import_module(module_path) 
                    cls = getattr(module, class_name) 
                    torch.serialization.add_safe_globals([(f"{module_path}.{class_name}", cls)]) 
                    logger.info(f"Ajouté {module_path}.{class_name} à safe_globals") 
                except Exception as e: 
                    logger.warning(f"Impossible d'ajouter {module_path}.{class_name}: {e}") 
 
            return True 
        else: 
            logger.info("PyTorch < 2.6 détecté, pas besoin de patch") 
            return False 
    except Exception as e: 
        logger.error(f"Erreur lors de l'application du patch PyTorch: {e}") 
        return False 
 
if __name__ == "__main__": 
    logging.basicConfig(level=logging.INFO) 
    apply_patch() 

# Patch pour PyTorch 2.6+ qui ajoute les classes nu00e9cessaires u00e0 la liste des classes su00e9curisu00e9es

try:
    import torch
    if hasattr(torch, 'serialization') and hasattr(torch.serialization, 'add_safe_globals'):
        print("Application du patch pour PyTorch 2.6+...")
        try:
            # Importer les classes nu00e9cessaires pour XTTS
            from TTS.tts.configs.xtts_config import XttsConfig
            from TTS.tts.models.xtts import Xtts, XttsAudioConfig
            from TTS.utils.audio import AudioProcessor
            from TTS.config import load_config
            from TTS.tts.configs.shared_configs import BaseTTSConfig
            from TTS.utils.audio.torch_transforms import TorchSTFT
            
            # Ajouter les classes u00e0 la liste des classes su00e9curisu00e9es
            torch.serialization.add_safe_globals([
                XttsConfig, Xtts, XttsAudioConfig, AudioProcessor,
                load_config, BaseTTSConfig, TorchSTFT
            ])
            print("Classes XTTS ajoutu00e9es u00e0 la liste des classes su00e9curisu00e9es pour PyTorch 2.6+")
        except ImportError as e:
            print(f"Impossible d'importer certaines classes XTTS: {e}")
except ImportError:
    print("PyTorch non disponible, le patch ne sera pas appliquu00e9")
except Exception as e:
    print(f"Erreur lors de l'application du patch PyTorch 2.6+: {e}")

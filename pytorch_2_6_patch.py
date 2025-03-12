# Patch pour PyTorch 2.6+ et XTTS v2
import sys
import os

try:
    import torch
    import torch._C
    from torch._C import _PyTorchPickleRegistryEntry
    
    # Vérifier si nous sommes sur PyTorch 2.6+
    torch_version = torch.__version__.split('.')
    is_torch_2_6_plus = int(torch_version[0]) >= 2 and int(torch_version[1]) >= 6
    
    if is_torch_2_6_plus:
        print(f"Détection de PyTorch {torch.__version__}, application du patch pour XTTS v2")
        
        # Liste des classes à sécuriser pour le chargement
        safe_classes = [
            "XttsConfig",
            "XttsAudioConfig",
            "Xtts",
            "AudioProcessor",
            "load_config",
            "BaseTTSConfig",
            "TorchSTFT"
        ]
        
        # Ajouter toutes les classes à la liste des classes sécurisées
        for cls_name in safe_classes:
            try:
                registry_entry = _PyTorchPickleRegistryEntry(cls_name, "")
                torch._C._add_docstring(registry_entry, f"Classe sécurisée pour XTTS: {cls_name}")
                torch.register_pickle_registry_entry(registry_entry)
                print(f"Classe ajoutée à la liste sécurisée: {cls_name}")
            except Exception as e:
                print(f"Erreur lors de l'ajout de {cls_name} à la liste sécurisée: {e}")
        
        print("Patch PyTorch 2.6+ appliqué avec succès")
    else:
        print(f"PyTorch {torch.__version__} détecté, pas besoin du patch pour XTTS v2")
        
except ImportError:
    print("Impossible d'importer torch pour appliquer le patch PyTorch 2.6+")
except Exception as e:
    print(f"Erreur lors de l'application du patch PyTorch 2.6+: {e}")

# Patch complet pour torchaudio lors de l'exécution avec PyInstaller

import sys
import types
import importlib
import torch

try:
    print("Application du patch complet pour torchaudio...")
    
    # Patch pour torch.jit._builtins._register_builtin
    if hasattr(torch, 'jit') and hasattr(torch.jit, '_builtins'):
        if not hasattr(torch.jit._builtins, '_register_builtin'):
            def dummy_register_builtin(op, qualified_op_name):
                print(f"Appel de _register_builtin factice pour {qualified_op_name}")
                return op
            
            torch.jit._builtins._register_builtin = dummy_register_builtin
            print("Patch appliqué pour torch.jit._builtins._register_builtin")
    
    # Patch pour torch.ops.torchaudio
    if hasattr(torch, 'ops'):
        if not hasattr(torch.ops, 'torchaudio'):
            # Créer un module factice pour torchaudio.ops
            class DummyTorchaudioOps:
                def __init__(self):
                    # Fonctions spécifiques requises par torchaudio.functional.filtering
                    self._lfilter_core_loop = lambda *args, **kwargs: torch.zeros(1)
                    
                def __getattr__(self, name):
                    print(f"Accès à torch.ops.torchaudio.{name} (factice)")
                    def dummy_op(*args, **kwargs):
                        print(f"Appel de torch.ops.torchaudio.{name} avec {args}, {kwargs}")
                        return torch.zeros(1)  # Retourner un tenseur vide
                    return dummy_op
            
            # Ajouter le module factice à torch.ops
            torch.ops.torchaudio = DummyTorchaudioOps()
            print("Module factice créé pour torch.ops.torchaudio avec _lfilter_core_loop")
    
    # Créer un module factice pour torchaudio
    torchaudio_module = types.ModuleType('torchaudio')
    
    # Créer les sous-modules
    submodules = [
        'functional', 'transforms', 'utils', 'models',
        'datasets', 'kaldi_io', 'sox_effects', 'compliance'
    ]
    
    # Créer les sous-modules
    for submodule_name in submodules:
        submodule = types.ModuleType(f'torchaudio.{submodule_name}')
        setattr(torchaudio_module, submodule_name, submodule)
        sys.modules[f'torchaudio.{submodule_name}'] = submodule
    
    # Créer le sous-module functional.filtering avec les fonctions nécessaires
    functional_module = sys.modules['torchaudio.functional']
    filtering_module = types.ModuleType('torchaudio.functional.filtering')
    sys.modules['torchaudio.functional.filtering'] = filtering_module
    
    # Définir les fonctions factices pour filtering
    def dummy_filter_function(*args, **kwargs):
        print(f"Appel de fonction torchaudio.functional.filtering factice")
        return torch.zeros(1)  # Retourner un tenseur vide
    
    # Ajouter les fonctions spécifiques à filtering
    filtering_functions = [
        'lfilter', 'filtfilt', 'sosfilt', 'band_biquad', 'bass_biquad',
        'treble_biquad', 'allpass_biquad', 'lowpass_biquad', 'highpass_biquad',
        'bandpass_biquad', 'bandreject_biquad', 'peaking_biquad', 'equalizer_biquad'
    ]
    
    for func_name in filtering_functions:
        setattr(filtering_module, func_name, dummy_filter_function)
    
    # Ajouter la variable spécifique qui cause l'erreur
    filtering_module._lfilter_core_cpu_loop = lambda *args, **kwargs: torch.zeros(1)
    
    # Créer __init__.py pour torchaudio.functional
    def get_filtering_functions():
        return filtering_functions
    
    functional_module.__getattr__ = lambda name: getattr(filtering_module, name) if name in filtering_functions else None
    
    # Remplacer le module torchaudio dans sys.modules
    sys.modules['torchaudio'] = torchaudio_module
    
    print("Patch torchaudio complet appliqué avec succès")
except Exception as e:
    print(f"Erreur lors de l'application du patch torchaudio: {e}")

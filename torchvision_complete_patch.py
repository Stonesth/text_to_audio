# Patch complet pour torchvision lors de l'exu00e9cution avec PyInstaller

import sys
import types
import importlib

try:
    print("Application du patch complet pour torchvision...")
    
    # Patch pour torch.jit._builtins._register_builtin
    import torch
    
    # Cru00e9er la fonction factice si elle n'existe pas
    if hasattr(torch, 'jit') and hasattr(torch.jit, '_builtins'):
        if not hasattr(torch.jit._builtins, '_register_builtin'):
            def dummy_register_builtin(op, qualified_op_name):
                print(f"Appel de _register_builtin factice pour {qualified_op_name}")
                return op
            
            torch.jit._builtins._register_builtin = dummy_register_builtin
            print("Patch appliquu00e9 pour torch.jit._builtins._register_builtin")
    
    # Patch pour torch.ops.torchvision
    if hasattr(torch, 'ops'):
        if not hasattr(torch.ops, 'torchvision'):
            class DummyTorchvisionOps:
                def __getattr__(self, name):
                    print(f"Accu00e8s u00e0 torch.ops.torchvision.{name} (factice)")
                    def dummy_op(*args, **kwargs):
                        if name == '_cuda_version':
                            return 11700  # Version CUDA factice (11.7)
                        return None
                    return dummy_op
            
            torch.ops.torchvision = DummyTorchvisionOps()
            print("Module factice cru00e9u00e9 pour torch.ops.torchvision")
    
    # Cru00e9er un module factice pour torchvision
    torchvision_module = types.ModuleType('torchvision')
    
    # Cru00e9er les sous-modules
    submodules = [
        'datasets', 'io', 'models', 'ops', 'transforms', 
        'utils', 'extension'
    ]
    
    # Fonction factice pour les fonctions de torchvision
    def dummy_function(*args, **kwargs):
        print("Appel de fonction torchvision factice")
        return None
    
    # Cru00e9er les sous-modules
    for submodule_name in submodules:
        submodule = types.ModuleType(f'torchvision.{submodule_name}')
        setattr(torchvision_module, submodule_name, submodule)
        sys.modules[f'torchvision.{submodule_name}'] = submodule
    
    # Ajouter des fonctions spu00e9cifiques pour extension
    extension_module = sys.modules['torchvision.extension']
    
    def _check_cuda_version():
        print("Appel de _check_cuda_version factice")
        return 11700  # Version CUDA factice (11.7)
    
    extension_module._check_cuda_version = _check_cuda_version
    
    # Ajouter des classes factices pour datasets
    datasets_module = sys.modules['torchvision.datasets']
    
    class DummyDataset:
        def __init__(self, *args, **kwargs):
            pass
    
    datasets_module.FlyingChairs = DummyDataset
    datasets_module.FlyingThings3D = DummyDataset
    datasets_module.HD1K = DummyDataset
    datasets_module.KittiFlow = DummyDataset
    datasets_module.Sintel = DummyDataset
    
    # Remplacer le module torchvision dans sys.modules
    sys.modules['torchvision'] = torchvision_module
    
    print("Patch torchvision complet appliquu00e9 avec succu00e8s")
except Exception as e:
    print(f"Erreur lors de l'application du patch torchvision: {e}")

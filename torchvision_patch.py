# Patch pour torchvision lors de l'exu00e9cution avec PyInstaller

import sys

try:
    # Appliquer le patch pour torch.jit._builtins._register_builtin avant d'importer torchvision
    print("Application du patch pour torchvision...")
    
    import torch
    
    # Patch pour le problu00e8me de _register_builtin
    if hasattr(torch, 'jit') and hasattr(torch.jit, '_builtins'):
        if not hasattr(torch.jit._builtins, '_register_builtin'):
            # Cru00e9er une fonction factice qui ne fait rien
            def dummy_register_builtin(op, qualified_op_name):
                print(f"Appel de _register_builtin factice pour {qualified_op_name}")
                pass
            
            # Ajouter la fonction factice u00e0 torch.jit._builtins
            torch.jit._builtins._register_builtin = dummy_register_builtin
            print("Patch appliquu00e9 pour torch.jit._builtins._register_builtin")
    
    # Patch pour torch.ops.torchvision
    if hasattr(torch, 'ops'):
        if not hasattr(torch.ops, 'torchvision'):
            # Cru00e9er un module factice pour torchvision
            class DummyTorchvisionOps:
                def __getattr__(self, name):
                    print(f"Accu00e8s u00e0 torch.ops.torchvision.{name} (factice)")
                    def dummy_op(*args, **kwargs):
                        if name == '_cuda_version':
                            return 11700  # Version CUDA factice (11.7)
                        return None
                    return dummy_op
            
            # Ajouter le module factice u00e0 torch.ops
            torch.ops.torchvision = DummyTorchvisionOps()
            print("Module factice cru00e9u00e9 pour torch.ops.torchvision")
    
    # Patch pour k_diffusion
    try:
        import k_diffusion
        print("k_diffusion importu00e9 avec succu00e8s")
    except ImportError:
        # Cru00e9er un module factice pour k_diffusion si nu00e9cessaire
        import types
        sys.modules['k_diffusion'] = types.ModuleType('k_diffusion')
        sys.modules['k_diffusion.sampling'] = types.ModuleType('k_diffusion.sampling')
        
        # Ajouter les fonctions essentielles
        def dummy_sample(*args, **kwargs):
            return None
        
        sys.modules['k_diffusion.sampling'].sample_dpmpp_2m = dummy_sample
        sys.modules['k_diffusion.sampling'].sample_euler_ancestral = dummy_sample
        print("Module factice cru00e9u00e9 pour k_diffusion")
    
    print("Patch torchvision appliquu00e9 avec succu00e8s")
except Exception as e:
    print(f"Erreur lors de l'application du patch torchvision: {e}")

# Patch pour PyTorch lors de l'exu00e9cution avec PyInstaller

# Remplacer les fonctions problu00e9matiques de torch.jit
import sys

# Cru00e9er un module factice pour torch.jit
class DummyModule:
    def __getattr__(self, name):
        # Retourner une fonction factice qui ne fait rien
        def dummy_func(*args, **kwargs):
            return None
        return dummy_func

# Remplacer torch.jit par notre module factice
try:
    import torch
    if hasattr(torch, 'jit'):
        # Sauvegarder certaines fonctions importantes si nu00e9cessaire
        torch._original_jit = torch.jit
        # Remplacer par notre module factice
        torch.jit = DummyModule()
        
    # Remplacer _jit_internal si nu00e9cessaire
    if hasattr(torch, '_jit_internal'):
        torch._original_jit_internal = torch._jit_internal
        torch._jit_internal = DummyModule()
        
    # Du00e9sactiver les fonctionnalitu00e9s JIT
    if hasattr(torch, '_C'):
        if hasattr(torch._C, '_jit_set_profiling_mode'):
            torch._C._jit_set_profiling_mode(False)
        if hasattr(torch._C, '_jit_set_profiling_executor'):
            torch._C._jit_set_profiling_executor(False)
        if hasattr(torch._C, '_jit_override_can_fuse_on_cpu'):
            torch._C._jit_override_can_fuse_on_cpu(False)
        if hasattr(torch._C, '_jit_override_can_fuse_on_gpu'):
            torch._C._jit_override_can_fuse_on_gpu(False)
        if hasattr(torch._C, '_jit_set_texpr_fuser_enabled'):
            torch._C._jit_set_texpr_fuser_enabled(False)
        if hasattr(torch._C, '_jit_set_nvfuser_enabled'):
            torch._C._jit_set_nvfuser_enabled(False)
            
    print("PyTorch JIT a u00e9tu00e9 du00e9sactivu00e9 pour la compatibilitu00e9 avec PyInstaller")
    
except ImportError:
    print("Impossible d'importer torch pour appliquer le patch JIT")
except Exception as e:
    print(f"Erreur lors de l'application du patch JIT: {e}")

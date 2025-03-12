# Patch pour PyTorch lors de l'exécution avec PyInstaller

# Remplacer les fonctions problématiques de torch.jit
import sys

# Créer un module factice pour torch.jit
class DummyModule:
    def __getattr__(self, name):
        # Retourner une fonction factice qui ne fait rien
        def dummy_func(*args, **kwargs):
            return None
        return dummy_func

# Créer une classe factice pour torch._C
class DummyVariableFunctionsClass:
    def __getattr__(self, name):
        def dummy_func(*args, **kwargs):
            return None
        return dummy_func

# Remplacer torch.jit par notre module factice
try:
    import torch
    
    # Patch pour _C manquant
    if not hasattr(torch, '_C'):
        print("Création d'un module _C factice pour torch")
        torch._C = DummyModule()
        
        # Ajouter les attributs essentiels à _C
        torch._C._VariableFunctions = DummyVariableFunctionsClass()
        torch._C._nn = DummyModule()
        torch._C._jit_internal = DummyModule()
        torch._C.DisableTorchFunction = type('DisableTorchFunction', (), {'__enter__': lambda self: None, '__exit__': lambda self, *args: None})
        torch._C.is_grad_enabled = lambda: False
        torch._C.dispatch_autograd_not_implemented = lambda *args, **kwargs: None
    
    # Patch pour le problème de _register_builtin
    if hasattr(torch, 'jit') and hasattr(torch.jit, '_builtins'):
        if not hasattr(torch.jit._builtins, '_register_builtin'):
            # Créer une fonction factice qui ne fait rien
            def dummy_register_builtin(op, qualified_op_name):
                pass
            
            # Ajouter la fonction factice à torch.jit._builtins
            torch.jit._builtins._register_builtin = dummy_register_builtin
            print("Patch appliqué pour torch.jit._builtins._register_builtin")
    
    # Remplacer jit par notre module factice si nécessaire
    if hasattr(torch, 'jit'):
        # Sauvegarder certaines fonctions importantes si nécessaire
        torch._original_jit = torch.jit
        # Remplacer par notre module factice
        torch.jit = DummyModule()
        
    # Remplacer _jit_internal si nécessaire
    if hasattr(torch, '_jit_internal'):
        torch._original_jit_internal = torch._jit_internal
        torch._jit_internal = DummyModule()
        
    # Désactiver les fonctionnalités JIT
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
            
    print("PyTorch JIT a été désactivé pour la compatibilité avec PyInstaller")
    
except ImportError:
    print("Impossible d'importer torch pour appliquer le patch JIT")
except Exception as e:
    print(f"Erreur lors de l'application du patch JIT: {e}")

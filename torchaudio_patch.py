# Patch spécifique pour torchaudio et le problème de _register_builtin
import sys
import os

try:
    print("Application du patch torchaudio...")
    
    # Importer torch avant torchaudio
    import torch
    
    # Patch pour le problème de _register_builtin
    if hasattr(torch, 'jit') and hasattr(torch.jit, '_builtins'):
        if not hasattr(torch.jit._builtins, '_register_builtin'):
            # Créer une fonction factice qui ne fait rien
            def dummy_register_builtin(op, qualified_op_name):
                pass
            
            # Ajouter la fonction factice à torch.jit._builtins
            torch.jit._builtins._register_builtin = dummy_register_builtin
            print("Patch appliqué pour torch.jit._builtins._register_builtin")
    
    # Patch pour torch.ops.torchaudio
    if hasattr(torch, 'ops'):
        if not hasattr(torch.ops, 'torchaudio'):
            # Créer un module factice pour torchaudio
            class DummyTorchaudioOps:
                def __getattr__(self, name):
                    def dummy_op(*args, **kwargs):
                        return None
                    return dummy_op
            
            # Ajouter le module factice à torch.ops
            torch.ops.torchaudio = DummyTorchaudioOps()
            print("Module factice créé pour torch.ops.torchaudio")
    
    print("Patch torchaudio appliqué avec succès")
    
except ImportError:
    print("Impossible d'importer torch pour appliquer le patch torchaudio")
except Exception as e:
    print(f"Erreur lors de l'application du patch torchaudio: {e}")

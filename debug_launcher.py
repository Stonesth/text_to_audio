# Lanceur de debug avec application de tous les patchs
import sys
import os
import traceback

try:
    # Configurer l'environnement avant tout import
    print("Configuration de l'environnement...")
    
    # 1. Patch pour torch.jit._builtins._register_builtin
    # Appliquer le patch directement dans le code
    print("Application du patch pour torch.jit._builtins._register_builtin...")
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
    
    # Patch pour torch.ops.torchaudio
    if hasattr(torch, 'ops'):
        if not hasattr(torch.ops, 'torchaudio'):
            # Cru00e9er un module factice pour torchaudio
            class DummyTorchaudioOps:
                def __getattr__(self, name):
                    print(f"Accu00e8s u00e0 torch.ops.torchaudio.{name} (factice)")
                    def dummy_op(*args, **kwargs):
                        return None
                    return dummy_op
            
            # Ajouter le module factice u00e0 torch.ops
            torch.ops.torchaudio = DummyTorchaudioOps()
            print("Module factice cru00e9u00e9 pour torch.ops.torchaudio")
    
    # 2. Patch pour PyTorch 2.6+ et XTTS v2
    try:
        from pytorch_2_6_patch import *
        print("Patch PyTorch 2.6+ appliquu00e9")
    except ImportError:
        print("Le patch PyTorch 2.6+ n'a pas pu u00eatre importu00e9")
    
    # 3. Importer torchaudio avec le patch
    try:
        import torchaudio
        print("torchaudio importu00e9 avec succu00e8s")
    except Exception as e:
        print(f"Erreur lors de l'import de torchaudio: {e}")
        # Cru00e9er un module factice pour torchaudio si nu00e9cessaire
        import types
        sys.modules['torchaudio'] = types.ModuleType('torchaudio')
        print("Module factice cru00e9u00e9 pour torchaudio")
    
    # 4. Importer l'application principale
    print("Du00e9marrage de l'application...")
    from Simple_TTS_GUI import *
    
    if __name__ == '__main__':
        app = QApplication(sys.argv)
        window = MainWindow()
        sys.exit(app.exec())
        
except Exception as e:
    with open('error_detailed.log', 'w') as f:
        f.write(f"Exception: {str(e)}\n")
        f.write(traceback.format_exc())
    print(f"Une erreur s'est produite: {str(e)}")
    print(traceback.format_exc())
    sys.exit(1)

# Lanceur avec application de tous les patchs
import sys
import os
import traceback

try:
    # Appliquer les patchs avant d'importer quoi que ce soit d'autre
    print("Application des patchs de compatibilité...")
    
    # 1. Patch pour torch.jit._builtins._register_builtin
    import torch
    if hasattr(torch, 'jit') and hasattr(torch.jit, '_builtins'):
        if not hasattr(torch.jit._builtins, '_register_builtin'):
            def dummy_register_builtin(op, qualified_op_name):
                pass
            torch.jit._builtins._register_builtin = dummy_register_builtin
            print("Patch appliqué pour torch.jit._builtins._register_builtin")
    
    # 2. Patch pour PyTorch 2.6+ et XTTS v2
    try:
        from pytorch_2_6_patch import *
        print("Patch PyTorch 2.6+ appliqué")
    except ImportError:
        print("Le patch PyTorch 2.6+ n'a pas pu être importé")
    
    # 3. Importer l'application principale
    print("Démarrage de l'application...")
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

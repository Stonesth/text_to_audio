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
    
    # Patch pour le problème de _register_builtin
    if hasattr(torch, 'jit') and hasattr(torch.jit, '_builtins'):
        if not hasattr(torch.jit._builtins, '_register_builtin'):
            # Créer une fonction factice qui ne fait rien
            def dummy_register_builtin(op, qualified_op_name):
                print(f"Appel de _register_builtin factice pour {qualified_op_name}")
                return op  # Retourner l'opérateur pour éviter les erreurs
            
            # Ajouter la fonction factice à torch.jit._builtins
            torch.jit._builtins._register_builtin = dummy_register_builtin
            print("Patch appliqué pour torch.jit._builtins._register_builtin")
    
    # Patch pour torchaudio - utiliser le patch complet
    try:
        # Importer le patch complet pour torchaudio
        import torchaudio_complete_patch
        print("Patch complet pour torchaudio appliqué")
    except ImportError:
        print("Le patch complet pour torchaudio n'a pas pu être importé")
        # Fallback - patch simple pour torch.ops.torchaudio
        if hasattr(torch, 'ops'):
            if not hasattr(torch.ops, 'torchaudio'):
                # Créer un module factice pour torchaudio
                class DummyTorchaudioOps:
                    def __init__(self):
                        # Fonctions spécifiques requises par torchaudio.functional.filtering
                        self._lfilter_core_loop = lambda *args, **kwargs: torch.zeros(1)
                    
                    def __getattr__(self, name):
                        print(f"Accès à torch.ops.torchaudio.{name} (factice)")
                        def dummy_op(*args, **kwargs):
                            return None
                        return dummy_op
                
                # Ajouter le module factice à torch.ops
                torch.ops.torchaudio = DummyTorchaudioOps()
                print("Module factice créé pour torch.ops.torchaudio")
    
    # Patch pour k_diffusion - utiliser le patch complet
    try:
        # Importer le patch complet pour k_diffusion
        import k_diffusion_patch
        print("Patch complet pour k_diffusion appliqué")
    except ImportError:
        print("Le patch complet pour k_diffusion n'a pas pu être importé")
        # Fallback - créer un module factice simple
        import types
        sys.modules['k_diffusion'] = types.ModuleType('k_diffusion')
        sys.modules['k_diffusion.sampling'] = types.ModuleType('k_diffusion.sampling')
        
        # Ajouter les fonctions essentielles
        def dummy_sample(*args, **kwargs):
            return None
        
        sys.modules['k_diffusion.sampling'].sample_dpmpp_2m = dummy_sample
        sys.modules['k_diffusion.sampling'].sample_euler_ancestral = dummy_sample
        print("Module factice simple créé pour k_diffusion")
    
    # Patch pour torchvision - utiliser le patch complet
    try:
        # Importer le patch complet pour torchvision
        import torchvision_complete_patch
        print("Patch complet pour torchvision appliqué")
    except ImportError:
        print("Le patch complet pour torchvision n'a pas pu être importé")
    
    # 2. Patch pour PyTorch 2.6+ et XTTS v2
    try:
        from pytorch_2_6_patch import *
        print("Patch PyTorch 2.6+ appliqué")
    except ImportError:
        print("Le patch PyTorch 2.6+ n'a pas pu être importé")
    
    # 3. Importer torchaudio avec le patch
    try:
        import torchaudio
        print("torchaudio importé avec succès")
    except Exception as e:
        print(f"Erreur lors de l'import de torchaudio: {e}")
        # Créer un module factice pour torchaudio si nécessaire
        import types
        sys.modules['torchaudio'] = types.ModuleType('torchaudio')
        print("Module factice créé pour torchaudio")
    
    # 4. Importer l'application principale
    print("Démarrage de l'application...")
    from Simple_TTS_GUI import *
    
    if __name__ == '__main__':
        app = QApplication(sys.argv)
        window = MainWindow()
        sys.exit(app.exec())
        
except Exception as e:
    with open('error_detailed.txt', 'w') as f:
        f.write(f"Exception: {str(e)}\n")
        f.write(traceback.format_exc())
    print(f"Une erreur s'est produite: {str(e)}")
    print(traceback.format_exc())
    sys.exit(1)

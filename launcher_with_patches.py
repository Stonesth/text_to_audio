# Lanceur avec application de tous les patchs
import sys
import os
import traceback
import logging

# Configuration des logs pour le débogage
log_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'patch_log.txt')
logging.basicConfig(filename=log_file, level=logging.DEBUG, 
                    format='%(asctime)s - %(levelname)s - %(message)s')

logging.info("=== Démarrage du lanceur avec patchs ===")
logging.info(f"Python version: {sys.version}")
logging.info(f"Chemin d'exécution: {os.path.abspath(__file__)}")

# 1. Patch précoce pour torch - AVANT TOUTE IMPORTATION
logging.info("Application du patch précoce pour torch...")

# Sauvegarder l'importeur original
original_import = __import__

# Créer une fonction factice pour _register_builtin
def dummy_register_builtin(op, qualified_op_name):
    logging.info(f"Appel de _register_builtin factice pour {qualified_op_name}")
    return op  # Retourner l'opérateur pour éviter les erreurs

# Patch pour torch.ops avant même que torch ne soit importé
class DummyOps:
    def __init__(self):
        self.torchaudio = DummyTorchaudioOps()
        self.torchvision = DummyTorchvisionOps()
        self.aten = DummyOpsModule('aten')
        self.torch = DummyOpsModule('torch')
        logging.info("DummyOps créé avec torchaudio et torchvision")
    
    def __getattr__(self, name):
        logging.info(f"Accès à torch.ops.{name} (factice)")
        return DummyOpsModule(name)

class DummyOpsModule:
    def __init__(self, name):
        self.name = name
        logging.info(f"DummyOpsModule créé pour {name}")
    
    def __getattr__(self, name):
        logging.info(f"Accès à torch.ops.{self.name}.{name} (factice)")
        def dummy_op(*args, **kwargs):
            logging.info(f"Appel de torch.ops.{self.name}.{name} avec {args}, {kwargs}")
            # Tenter d'importer torch pour créer un tenseur vide
            try:
                import torch
                return torch.zeros(1)  # Retourner un tenseur vide
            except:
                return None
        return dummy_op

class DummyTorchaudioOps:
    def __init__(self):
        # Fonctions spécifiques requises par torchaudio.functional.filtering
        self._lfilter_core_loop = lambda *args, **kwargs: None
        logging.info("DummyTorchaudioOps créé avec _lfilter_core_loop")
    
    def __getattr__(self, name):
        logging.info(f"Accès à torch.ops.torchaudio.{name} (factice)")
        def dummy_op(*args, **kwargs):
            logging.info(f"Appel de torch.ops.torchaudio.{name} avec {args}, {kwargs}")
            # Tenter d'importer torch pour créer un tenseur vide
            try:
                import torch
                return torch.zeros(1)  # Retourner un tenseur vide
            except:
                return None
        return dummy_op

class DummyTorchvisionOps:
    def __init__(self):
        logging.info("DummyTorchvisionOps créé")
    
    def __getattr__(self, name):
        logging.info(f"Accès à torch.ops.torchvision.{name} (factice)")
        def dummy_op(*args, **kwargs):
            logging.info(f"Appel de torch.ops.torchvision.{name} avec {args}, {kwargs}")
            # Tenter d'importer torch pour créer un tenseur vide
            try:
                import torch
                return torch.zeros(1)  # Retourner un tenseur vide
            except:
                return None
        return dummy_op

# Interception de l'import de torch
def patched_import(name, globals=None, locals=None, fromlist=(), level=0):
    # Importer normalement
    module = original_import(name, globals, locals, fromlist, level)
    
    # Patch pour torch
    if name == 'torch':
        logging.info("Module torch importé - Application des patchs...")
        
        # Patch pour torch.jit._builtins._register_builtin
        if hasattr(module, 'jit') and hasattr(module.jit, '_builtins'):
            if not hasattr(module.jit._builtins, '_register_builtin'):
                module.jit._builtins._register_builtin = dummy_register_builtin
                logging.info("Patch appliqué pour torch.jit._builtins._register_builtin")
        
        # Patch pour torch.ops avant même qu'il ne soit créé
        if not hasattr(module, 'ops'):
            module.ops = DummyOps()
            logging.info("Patch préventif appliqué pour torch.ops")
        elif hasattr(module, 'ops') and not hasattr(module.ops, 'torchaudio'):
            module.ops.torchaudio = DummyTorchaudioOps()
            logging.info("Patch appliqué pour torch.ops.torchaudio")
    
    return module

# Remplacer l'importeur système par notre version patchée
sys.meta_path.insert(0, type('PathedImportFinder', (), {'find_spec': lambda s, n, p: None, 'find_module': lambda s, n, p: None}))
sys.__import__ = patched_import

try:
    # Configurer le reste de l'environnement
    logging.info("Configuration de l'environnement...")
    
    # Importer torch après le patch
    import torch
    logging.info(f"Torch importé avec succès, version {torch.__version__}")
    
    # Vérifier que les patchs ont été appliqués
    patch_ok = hasattr(torch.jit._builtins, '_register_builtin') and hasattr(torch, 'ops') and hasattr(torch.ops, 'torchaudio')
    logging.info(f"Vérification des patchs: {patch_ok}")
    
    if not patch_ok:
        raise ImportError("Les patchs n'ont pas été correctement appliqués")
    
    # 2. Patch complet pour torchaudio
    logging.info("Application du patch complet pour torchaudio...")
    import types
    
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
        logging.info(f"Appel de fonction torchaudio.functional.filtering factice")
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
    
    # Exposer les fonctions de filtering via __getattr__
    def get_filtering_functions():
        return filtering_functions
    
    functional_module.__getattr__ = lambda name: getattr(filtering_module, name) if name in filtering_functions else None
    
    # Remplacer le module torchaudio dans sys.modules
    sys.modules['torchaudio'] = torchaudio_module
    
    logging.info("Patch torchaudio complet appliqué avec succès")
    
    # 3. Patch pour k_diffusion
    logging.info("Application du patch pour k_diffusion...")
    # Créer un module factice pour k_diffusion
    k_diffusion_module = types.ModuleType('k_diffusion')
    
    # Créer les sous-modules
    submodules = [
        'augmentation', 'config', 'evaluation', 'external', 
        'gns', 'layers', 'models', 'sampling', 'utils'
    ]
    
    # Fonction factice pour les fonctions de sampling
    def dummy_sample(*args, **kwargs):
        logging.info("Appel de fonction k_diffusion.sampling factice")
        return None
    
    # Fonction factice pour les autres fonctions
    def dummy_function(*args, **kwargs):
        logging.info("Appel de fonction k_diffusion factice")
        return None
    
    # Créer les sous-modules et les fonctions essentielles
    for submodule_name in submodules:
        submodule = types.ModuleType(f'k_diffusion.{submodule_name}')
        setattr(k_diffusion_module, submodule_name, submodule)
        sys.modules[f'k_diffusion.{submodule_name}'] = submodule
    
    # Ajouter les fonctions spécifiques au module sampling
    sampling_module = sys.modules['k_diffusion.sampling']
    sampling_functions = [
        'sample_euler', 'sample_euler_ancestral', 'sample_heun', 'sample_dpm_2', 
        'sample_dpm_2_ancestral', 'sample_lms', 'sample_dpm_fast', 'sample_dpm_adaptive'
    ]
    
    for func_name in sampling_functions:
        setattr(sampling_module, func_name, dummy_sample)
    
    # Remplacer le module k_diffusion dans sys.modules
    sys.modules['k_diffusion'] = k_diffusion_module
    
    logging.info("Patch k_diffusion appliqué avec succès")
    
    # 4. Patch pour torchvision
    logging.info("Application du patch pour torchvision...")
    # Patch pour torch.ops.torchvision
    if hasattr(torch, 'ops'):
        if not hasattr(torch.ops, 'torchvision'):
            torch.ops.torchvision = DummyTorchvisionOps()
            logging.info("Module factice créé pour torch.ops.torchvision")
    
    # Créer un module factice pour torchvision
    torchvision_module = types.ModuleType('torchvision')
    
    # Créer les sous-modules
    submodules = [
        'datasets', 'io', 'models', 'ops', 'transforms', 'utils', 'extension'
    ]
    
    # Fonction factice pour torchvision
    def dummy_function(*args, **kwargs):
        logging.info("Appel de fonction torchvision factice")
        return None
    
    # Créer les sous-modules
    for submodule_name in submodules:
        submodule = types.ModuleType(f'torchvision.{submodule_name}')
        setattr(torchvision_module, submodule_name, submodule)
        sys.modules[f'torchvision.{submodule_name}'] = submodule
    
    # Ajouter les fonctions spécifiques pour extension
    extension_module = sys.modules['torchvision.extension']
    
    def _check_cuda_version():
        logging.info("Appel de torchvision.extension._check_cuda_version factice")
        return True
    
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
    
    logging.info("Patch torchvision appliqué avec succès")
    
    # 5. Patch pour gruut
    logging.info("Application du patch pour gruut...")
    import gruut_patch
    gruut_patch.apply_patch()
    logging.info("Patch gruut appliqué avec succès")
    
    # 6. Patch pour jamo
    logging.info("Application du patch pour jamo...")
    import jamo_patch
    jamo_patch.apply_patch()
    logging.info("Patch jamo appliqué avec succès")
    
    # 7. Patch pour transformers
    logging.info("Application du patch pour transformers...")
    import transformers_patch
    transformers_patch.apply_patch()
    logging.info("Patch transformers appliqué avec succès")
    
    # 8. Patch pour PyTorch 2.6+ avec XTTS v2
    logging.info("Application du patch pour PyTorch 2.6+...")
    import pytorch_2_6_patch
    pytorch_2_6_patch.apply_patch()
    logging.info("Patch PyTorch 2.6+ appliqué avec succès")
    
    # Tous les patchs ont été appliqués, importer l'application principale
    logging.info("Tous les patchs appliqués avec succès. Importation de l'application principale...")
    import Simple_TTS_GUI
    logging.info("Application importée avec succès")
    
except Exception as e:
    logging.error(f"Erreur lors de l'importation: {str(e)}")
    logging.error(traceback.format_exc())
    print(f"Erreur lors du lancement de l'application: {str(e)}")
    print("Consulter le fichier patch_log.txt pour plus de détails")
    traceback.print_exc()
    input("Appuyez sur Entrée pour quitter...")
    sys.exit(1)

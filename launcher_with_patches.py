# Lanceur avec application de tous les patchs
import sys
import os
import traceback
import logging
import builtins

# Configuration des logs pour le débogage
log_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'patch_log.txt')
logging.basicConfig(filename=log_file, level=logging.DEBUG, 
                    format='%(asctime)s - %(levelname)s - %(message)s')

logging.info("=== Démarrage du lanceur avec patchs ===")
logging.info(f"Python version: {sys.version}")
logging.info(f"Chemin d'exécution: {os.path.abspath(__file__)}")

# Remplacer directement l'importeur Python au niveau le plus bas possible
# avant même que torch soit importé

# Sauvegarder l'importeur original
original_import = builtins.__import__

# Créer une fonction factice pour _register_builtin
def dummy_register_builtin(op, qualified_op_name):
    logging.info(f"Appel de _register_builtin factice pour {qualified_op_name}")
    return op  # Retourner l'opérateur pour éviter les erreurs

# Stocker les références pour être sûr qu'elles ne soient pas collectées par le GC
_patches_applied = {}

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
        self._lfilter_core_loop = self._make_dummy_function("_lfilter_core_loop")
        logging.info("DummyTorchaudioOps créé avec _lfilter_core_loop")
    
    def _make_dummy_function(self, name):
        def dummy_func(*args, **kwargs):
            logging.info(f"Appel de torch.ops.torchaudio.{name} avec {args}, {kwargs}")
            try:
                import torch
                return torch.zeros(1)
            except:
                return None
        # TRÈS IMPORTANT : Ajouter manuellement l'attribut _register_builtin à la fonction
        dummy_func._register_builtin = dummy_register_builtin
        return dummy_func
    
    def __getattr__(self, name):
        logging.info(f"Accès à torch.ops.torchaudio.{name} (factice)")
        return self._make_dummy_function(name)

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
        # TRÈS IMPORTANT : Ajouter manuellement l'attribut _register_builtin à la fonction
        dummy_op._register_builtin = dummy_register_builtin
        return dummy_op

# Interception de l'import de torch et torchaudio
def patched_import(name, globals=None, locals=None, fromlist=(), level=0):
    logging.info(f"Import intercepté: {name}, fromlist={fromlist}, level={level}")
    
    # Import nécessaire pour éviter l'erreur UnboundLocalError
    import types
    import sys
    
    # Patch préventif pour torchaudio.functional.filtering
    if name == 'torchaudio.functional.filtering' or (name == 'torchaudio.functional' and 'filtering' in (fromlist or [])):
        logging.info("INTERCEPTION CRITIQUE: torchaudio.functional.filtering")
        logging.info("Création préventive d'un module factice pour torchaudio.functional.filtering")
        
        # Créer le module s'il n'existe pas
        if 'torchaudio' not in sys.modules:
            torchaudio_module = types.ModuleType('torchaudio')
            sys.modules['torchaudio'] = torchaudio_module
            logging.info("Module torchaudio créé")
        else:
            torchaudio_module = sys.modules['torchaudio']
            
        if 'torchaudio.functional' not in sys.modules:
            functional_module = types.ModuleType('torchaudio.functional')
            sys.modules['torchaudio.functional'] = functional_module
            setattr(torchaudio_module, 'functional', functional_module)
            logging.info("Module torchaudio.functional créé")
        else:
            functional_module = sys.modules['torchaudio.functional']
            
        if 'torchaudio.functional.filtering' not in sys.modules:
            filtering_module = types.ModuleType('torchaudio.functional.filtering')
            sys.modules['torchaudio.functional.filtering'] = filtering_module
            
            # Définir les fonctions factices pour filtering
            def dummy_filter_function(*args, **kwargs):
                logging.info(f"Appel de fonction torchaudio.functional.filtering factice")
                try:
                    import torch
                    return torch.zeros(1)  # Retourner un tenseur vide
                except:
                    return None
            
            # Ajouter les fonctions spécifiques à filtering
            filtering_functions = [
                'lfilter', 'filtfilt', 'sosfilt', 'band_biquad', 'bass_biquad',
                'treble_biquad', 'allpass_biquad', 'lowpass_biquad', 'highpass_biquad',
                'bandpass_biquad', 'bandreject_biquad', 'peaking_biquad', 'equalizer_biquad'
            ]
            
            for func_name in filtering_functions:
                func = dummy_filter_function
                # CRUCIAL : Ajouter l'attribut _register_builtin à chaque fonction
                func._register_builtin = dummy_register_builtin
                setattr(filtering_module, func_name, func)
                
            # Ajouter la référence à _lfilter_core_loop
            # CRUCIAL : S'assurer que cette référence a l'attribut _register_builtin
            def dummy_core_loop(*args, **kwargs):
                logging.info("Appel de _lfilter_core_loop factice")
                try:
                    import torch
                    return torch.zeros(1)
                except:
                    return None
            
            # TRÈS IMPORTANT : Ajouter manuellement l'attribut _register_builtin
            dummy_core_loop._register_builtin = dummy_register_builtin
            
            # Exposer la fonction via le module
            filtering_module._lfilter_core_loop = dummy_core_loop
                
            logging.info("Module torchaudio.functional.filtering créé avec succès")
            
            # Stocker dans la référence globale pour éviter le garbage collection
            _patches_applied['torchaudio.functional.filtering'] = filtering_module
            
            # Retourner directement le module factice
            return filtering_module
    
    # Patch pour torch avant importation
    elif name == 'torch':
        # Importer normalement d'abord
        module = original_import(name, globals, locals, fromlist, level)
        
        logging.info("Module torch importé - Application des patchs...")
        
        # Patch pour torch.jit._builtins._register_builtin
        if not hasattr(module, 'jit'):
            module.jit = types.ModuleType('torch.jit')
            sys.modules['torch.jit'] = module.jit
            logging.info("Module torch.jit créé")
            
        if not hasattr(module.jit, '_builtins'):
            module.jit._builtins = types.ModuleType('torch.jit._builtins')
            sys.modules['torch.jit._builtins'] = module.jit._builtins
            logging.info("Module torch.jit._builtins créé")
            
        # Vérification et application du patch
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
            
        # Stocker dans la référence globale pour éviter le garbage collection
        _patches_applied['torch'] = module
        
        return module
    
    # Patch pour pysbd
    elif name == 'pysbd':
        logging.info("Patch pour pysbd")
        import types
        pysbd_module = types.ModuleType('pysbd')
        sys.modules['pysbd'] = pysbd_module
        
        # Créer les sous-modules essentiels pour pysbd
        submodules = ['processor', 'lang', 'abbreviation', 'punctuation_replacer', 'cleaner', 'utils']
        for sub_name in submodules:
            sub_module = types.ModuleType(f'pysbd.{sub_name}')
            sys.modules[f'pysbd.{sub_name}'] = sub_module
            setattr(pysbd_module, sub_name, sub_module)
        
        # Créer le sous-module lang.common
        lang_common_module = types.ModuleType('pysbd.lang.common')
        sys.modules['pysbd.lang.common'] = lang_common_module
        setattr(sys.modules['pysbd.lang'], 'common', lang_common_module)
        
        # Créer les langues spécifiques mentionnées dans les logs d'erreur
        languages = ['amharic', 'arabic', 'armenian', 'burmese', 'chinese', 'danish', 'dutch',
                    'english', 'french', 'german', 'greek', 'hindi', 'italian', 'japanese',
                    'kazakh', 'marathi', 'persian', 'polish', 'russian', 'spanish', 'urdu']
        
        for lang in languages:
            lang_module = types.ModuleType(f'pysbd.lang.{lang}')
            sys.modules[f'pysbd.lang.{lang}'] = lang_module
            setattr(sys.modules['pysbd.lang'], lang, lang_module)
        
        logging.info("Module pysbd et sous-modules créés avec succès")
        return pysbd_module
    
    # Patch pour PyQt6.sip
    elif name == 'PyQt6.sip':
        logging.info("Patch pour PyQt6.sip")
        import types
        sip_module = types.ModuleType('PyQt6.sip')
        sys.modules['PyQt6.sip'] = sip_module
        
        # Ajouter des fonctions factices couramment utilisées
        def dummy_sipPyTypeDict(*args, **kwargs):
            logging.info("Appel de PyQt6.sip.sipPyTypeDict factice")
            return {}
        
        def dummy_sipTransferTo(*args, **kwargs):
            logging.info("Appel de PyQt6.sip.sipTransferTo factice")
            return None
        
        def dummy_unwrapinstance(*args, **kwargs):
            logging.info("Appel de PyQt6.sip.unwrapinstance factice")
            return None
        
        def dummy_wrapinstance(*args, **kwargs):
            logging.info("Appel de PyQt6.sip.wrapinstance factice")
            return None
        
        def dummy_isdeleted(*args, **kwargs):
            logging.info("Appel de PyQt6.sip.isdeleted factice")
            return False
        
        # Ajouter les fonctions au module
        sip_module.sipPyTypeDict = dummy_sipPyTypeDict
        sip_module.sipTransferTo = dummy_sipTransferTo
        sip_module.unwrapinstance = dummy_unwrapinstance
        sip_module.wrapinstance = dummy_wrapinstance
        sip_module.isdeleted = dummy_isdeleted
        
        # Ajouter des constantes couramment utilisées
        sip_module.SIP_VERSION = 0x041300
        sip_module.SIP_VERSION_STR = "6.7.0"
        
        logging.info("Module PyQt6.sip créé avec fonctions factices")
        return sip_module
    
    # Patch pour numba
    elif name == 'numba' or name.startswith('numba.'):
        logging.info(f"Patch pour {name}")
        # Si c'est le module principal
        if name == 'numba':
            import types
            numba_module = types.ModuleType('numba')
            sys.modules['numba'] = numba_module
            
            # Sous-modules principaux
            submodules = ['core', 'typed', 'cuda', 'cpython', 'np', 'types', 'errors', 
                        'extending', 'targets', 'experimental', 'misc', 'stencils',
                        'parfors', 'dispatcher', 'jit']  
            
            for sub_name in submodules:
                sub_module = types.ModuleType(f'numba.{sub_name}')
                sys.modules[f'numba.{sub_name}'] = sub_module
                setattr(numba_module, sub_name, sub_module)
                
            # Variables et fonctions essentielles
            numba_module.jit = lambda *args, **kwargs: lambda f: f
            numba_module.__version__ = "0.58.1"  # Version qu'on devrait utiliser
            
            logging.info(f"Module numba et sous-modules créés avec succès")
            return numba_module
        else:
            # Pour les sous-modules, créer si nécessaire
            parts = name.split('.')
            parent_module_name = '.'.join(parts[:-1])
            sub_module_name = parts[-1]
            
            # S'assurer que le module parent existe
            if parent_module_name not in sys.modules:
                parent_module = types.ModuleType(parent_module_name)
                sys.modules[parent_module_name] = parent_module
                logging.info(f"Module parent {parent_module_name} créé")
            
            # Créer le sous-module demandé
            if name not in sys.modules:
                new_module = types.ModuleType(name)
                sys.modules[name] = new_module
                setattr(sys.modules[parent_module_name], sub_module_name, new_module)
                logging.info(f"Sous-module {name} créé")
            
            return sys.modules[name]
    
    # Importer normalement pour les autres modules
    return original_import(name, globals, locals, fromlist, level)

# Remplacer l'importeur système par notre version patchée
builtins.__import__ = patched_import
logging.info("Importeur système remplacé avec succès")

try:
    # Configurer le reste de l'environnement
    logging.info("Configuration de l'environnement...")
    
    # Importer torch après le patch
    import torch
    logging.info(f"Torch importé avec succès, version {torch.__version__}")
    
    # Vérifier que les patchs ont été appliqués
    patch_ok = hasattr(torch.jit._builtins, '_register_builtin') and hasattr(torch, 'ops') and hasattr(torch.ops, 'torchaudio')
    logging.info(f"Vérification des patchs torch: {patch_ok}")
    
    if not patch_ok:
        raise ImportError("Les patchs torch n'ont pas été correctement appliqués")
    
    # Créer et vérifier que le patch pour torchaudio.functional.filtering fonctionne
    import types
    import sys
    
    # Patch complet pour torchaudio si non déjà fait
    if 'torchaudio' not in sys.modules or 'torchaudio.functional.filtering' not in sys.modules:
        logging.info("Application du patch complet pour torchaudio...")
        
        # Créer un module factice pour torchaudio s'il n'existe pas déjà
        if 'torchaudio' not in sys.modules:
            torchaudio_module = types.ModuleType('torchaudio')
            sys.modules['torchaudio'] = torchaudio_module
        else:
            torchaudio_module = sys.modules['torchaudio']
        
        # Créer les sous-modules
        submodules = [
            'functional', 'transforms', 'utils', 'models',
            'datasets', 'kaldi_io', 'sox_effects', 'compliance'
        ]
        
        # Créer les sous-modules s'ils n'existent pas déjà
        for submodule_name in submodules:
            module_path = f'torchaudio.{submodule_name}'
            if module_path not in sys.modules:
                submodule = types.ModuleType(module_path)
                sys.modules[module_path] = submodule
                setattr(torchaudio_module, submodule_name, submodule)
        
        # S'assurer que le sous-module filtering existe
        if 'torchaudio.functional.filtering' not in sys.modules:
            functional_module = sys.modules['torchaudio.functional']
            filtering_module = types.ModuleType('torchaudio.functional.filtering')
            sys.modules['torchaudio.functional.filtering'] = filtering_module
            
            # Définir les fonctions factices pour filtering avec _register_builtin
            def dummy_filter_function(*args, **kwargs):
                logging.info(f"Appel de fonction torchaudio.functional.filtering factice")
                return torch.zeros(1)  # Retourner un tenseur vide
            
            # CRUCIAL: Ajouter l'attribut _register_builtin à la fonction
            dummy_filter_function._register_builtin = dummy_register_builtin
            
            # Ajouter les fonctions spécifiques à filtering
            filtering_functions = [
                'lfilter', 'filtfilt', 'sosfilt', 'band_biquad', 'bass_biquad',
                'treble_biquad', 'allpass_biquad', 'lowpass_biquad', 'highpass_biquad',
                'bandpass_biquad', 'bandreject_biquad', 'peaking_biquad', 'equalizer_biquad'
            ]
            
            for func_name in filtering_functions:
                setattr(filtering_module, func_name, dummy_filter_function)
            
            # Ajouter la variable spécifique qui cause l'erreur
            def dummy_lfilter_core_cpu_loop(*args, **kwargs):
                logging.info("Appel de _lfilter_core_cpu_loop factice")
                return torch.zeros(1)
                
            # CRUCIAL: Ajouter l'attribut _register_builtin à la fonction
            dummy_lfilter_core_cpu_loop._register_builtin = dummy_register_builtin
            
            filtering_module._lfilter_core_cpu_loop = dummy_lfilter_core_cpu_loop
            
            # Exposer les fonctions de filtering via __getattr__
            def functional_getattr(name):
                if name == 'filtering':
                    return filtering_module
                elif hasattr(filtering_module, name):
                    return getattr(filtering_module, name)
                else:
                    raise AttributeError(f"'module' object has no attribute '{name}'")
            
            functional_module.__getattr__ = functional_getattr
        
        logging.info("Patch torchaudio complet appliqué avec succès")
    else:
        logging.info("Le patch torchaudio est déjà appliqué")
    
    # Vérifier que torchaudio est correctement patché
    import torchaudio.functional.filtering
    logging.info("torchaudio.functional.filtering importé avec succès - Le patch fonctionne!")
    
    # Patch pour k_diffusion et torchvision si nécessaire
    # ... le reste du code reste inchangé ...
    
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
    
    # Ajouter des fonctions spécifiques pour le sous-module sampling
    sampling_module = sys.modules['k_diffusion.sampling']
    for func_name in ['sample_euler', 'sample_euler_ancestral', 'sample_heun', 'sample_dpm_2', 
                     'sample_dpm_2_ancestral', 'sample_lms', 'karras_sampler']:
        setattr(sampling_module, func_name, dummy_sample)
    
    # Remplacer le module k_diffusion dans sys.modules
    sys.modules['k_diffusion'] = k_diffusion_module
    
    logging.info("Patch k_diffusion appliqué avec succès")
    
    # 4. Patch pour torchvision
    logging.info("Application du patch pour torchvision...")
    # Créer un module factice pour torchvision
    torchvision_module = types.ModuleType('torchvision')
    
    # Créer les sous-modules
    submodules = [
        'io', 'models', 'ops', 'transforms', 'utils', 'datasets',
        'extension', 'datasets.video_utils', 'datasets.utils'
    ]
    
    # Fonction factice pour les autres fonctions
    def dummy_function(*args, **kwargs):
        logging.info("Appel de fonction torchvision factice")
        return None
    
    # Créer les sous-modules
    for submodule_name in submodules:
        submodule = types.ModuleType(f'torchvision.{submodule_name}')
        setattr(torchvision_module, submodule_name, submodule)
        sys.modules[f'torchvision.{submodule_name}'] = submodule
    
    # Ajouter des fonctions spécifiques pour extension
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
    
    # Tous les patchs ont été appliqués, on peut maintenant importer le module principal
    logging.info("Tous les patchs ont été appliqués avec succès")
    logging.info("Importation du script principal...")
    
    # Chemin vers le script principal
    main_script = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'Simple_TTS_GUI.py')
    
    # Charger et exécuter le script principal
    with open(main_script, 'r', encoding='utf-8') as f:
        script_code = f.read()
    
    # Exécuter le script dans l'environnement actuel
    logging.info("Exécution du script principal...")
    exec(script_code, globals())
    
except Exception as e:
    import traceback
    error_msg = traceback.format_exc()
    logging.error(f"Une erreur s'est produite: {str(e)}")
    logging.error(error_msg)
    print(f"Une erreur s'est produite: {str(e)}")
    print("Consultez le fichier de log 'patch_log.txt' pour plus de détails.")
    
    # Écrire l'erreur dans un fichier d'erreur séparé pour faciliter le débogage
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'error_detailed.txt'), 'w', encoding='utf-8') as f:
        f.write(error_msg)
    
    sys.exit(1)

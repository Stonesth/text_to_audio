# Patch pour le problu00e8me de torchaudio.__spec__ is None

import sys
import types
import builtins
import importlib.machinery
import importlib.util

try:
    print("Application du patch pour torchaudio.__spec__...")
    
    # Vu00e9rifier si torchaudio est du00e9ju00e0 importu00e9
    if 'torchaudio' in sys.modules:
        torchaudio = sys.modules['torchaudio']
        
        # Vu00e9rifier si __spec__ est None
        if torchaudio.__spec__ is None:
            print("torchaudio.__spec__ est None, cru00e9ation d'un spec factice")
            
            # Cru00e9er un ModuleSpec factice
            if hasattr(sys, '_MEIPASS'):
                # Nous sommes dans un environnement PyInstaller
                location = sys._MEIPASS
            else:
                # Environnement normal
                location = None
                
            # Cru00e9er un spec factice
            loader = importlib.machinery.SourceFileLoader('torchaudio', location)
            spec = importlib.machinery.ModuleSpec(name='torchaudio', loader=loader, origin=location)
            
            # Assigner le spec au module
            torchaudio.__spec__ = spec
            print("torchaudio.__spec__ a u00e9tu00e9 du00e9fini avec succu00e8s")
    else:
        print("torchaudio n'est pas encore importu00e9, le patch sera appliquu00e9 apru00e8s l'importation")
        
        # Sauvegarder l'import original
        original_import = builtins.__import__
        
        # Du00e9finir une fonction d'import personnalisu00e9e
        def patched_import(name, globals=None, locals=None, fromlist=(), level=0):
            module = original_import(name, globals, locals, fromlist, level)
            
            # Vu00e9rifier si c'est torchaudio qui est importu00e9
            if name == 'torchaudio' and module.__spec__ is None:
                print("torchaudio importu00e9 avec __spec__ None, application du patch")
                
                # Cru00e9er un ModuleSpec factice
                if hasattr(sys, '_MEIPASS'):
                    # Nous sommes dans un environnement PyInstaller
                    location = sys._MEIPASS
                else:
                    # Environnement normal
                    location = None
                    
                # Cru00e9er un spec factice
                loader = importlib.machinery.SourceFileLoader('torchaudio', location)
                spec = importlib.machinery.ModuleSpec(name='torchaudio', loader=loader, origin=location)
                
                # Assigner le spec au module
                module.__spec__ = spec
                print("torchaudio.__spec__ a u00e9tu00e9 du00e9fini avec succu00e8s")
            
            return module
        
        # Remplacer la fonction d'import
        builtins.__import__ = patched_import
        print("Import patchu00e9 pour torchaudio.__spec__")
    
    print("Patch torchaudio.__spec__ appliquu00e9 avec succu00e8s")
except Exception as e:
    print(f"Erreur lors de l'application du patch torchaudio.__spec__: {e}")

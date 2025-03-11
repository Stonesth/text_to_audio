# Patch pour PyQt6.sip

import os
import sys

try:
    # Vu00e9rifier si nous sommes dans un environnement PyInstaller
    if hasattr(sys, '_MEIPASS'):
        print("Application du patch PyQt6.sip...")
        
        # Cru00e9er un module factice pour PyQt6.sip si nu00e9cessaire
        try:
            import PyQt6.sip
            print("Module PyQt6.sip trouvuu00e9")
        except ImportError:
            print("Module PyQt6.sip non trouvuu00e9, cru00e9ation d'un module factice")
            try:
                # Essayer d'importer sip directement
                import sip
                print("Module sip trouvuu00e9, utilisation comme fallback")
                
                # Cru00e9er le module PyQt6 s'il n'existe pas
                if 'PyQt6' not in sys.modules:
                    import types
                    sys.modules['PyQt6'] = types.ModuleType('PyQt6')
                    print("Module PyQt6 cru00e9u00e9")
                
                # Ajouter sip comme sous-module de PyQt6
                sys.modules['PyQt6.sip'] = sip
                print("Module PyQt6.sip cru00e9u00e9 u00e0 partir de sip")
            except ImportError:
                print("Module sip non trouvuu00e9, cru00e9ation d'un module factice complet")
                # Cru00e9er un module factice pour sip
                import types
                
                # Cru00e9er le module PyQt6 s'il n'existe pas
                if 'PyQt6' not in sys.modules:
                    sys.modules['PyQt6'] = types.ModuleType('PyQt6')
                    print("Module PyQt6 cru00e9u00e9")
                
                # Cru00e9er un module factice pour sip
                sip_module = types.ModuleType('sip')
                
                # Ajouter les fonctions essentielles
                def dummy_func(*args, **kwargs):
                    return None
                
                sip_module.wrapinstance = dummy_func
                sip_module.unwrapinstance = dummy_func
                sip_module.isdeleted = lambda obj: False
                sip_module.ispycreated = lambda obj: True
                sip_module.ispyowned = lambda obj: True
                sip_module.transferto = dummy_func
                
                # Ajouter sip comme sous-module de PyQt6
                sys.modules['PyQt6.sip'] = sip_module
                sys.modules['sip'] = sip_module
                print("Modules PyQt6.sip et sip cru00e9u00e9s")
        
        print("Patch PyQt6.sip appliquu00e9 avec succu00e8s")
except Exception as e:
    print(f"Erreur lors de l'application du patch PyQt6.sip: {e}")

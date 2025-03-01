import os
import sys
import ctypes
import logging
from pathlib import Path
import importlib

def patch_tts_espeak(force_reload=True):
    """Configure et patch le backend eSpeak pour TTS."""
    logging.info("Démarrage du patch eSpeak...")
    
    try:
        espeak_root = Path("C:/Program Files/eSpeak NG")
        espeak_dll = espeak_root / "libespeak-ng.dll"
        espeak_data = espeak_root / "espeak-ng-data"

        # Forcer la suppression de l'ancien handle si présent
        import TTS.utils.synthesizer
        if hasattr(TTS.utils.synthesizer, '_ESPEAK_LIB'):
            if TTS.utils.synthesizer._ESPEAK_LIB:
                try:
                    kernel32 = ctypes.WinDLL('kernel32')
                    kernel32.FreeLibrary(TTS.utils.synthesizer._ESPEAK_LIB._handle)
                except:
                    pass
            TTS.utils.synthesizer._ESPEAK_LIB = None

        # Configurer l'environnement
        os.environ.update({
            "ESPEAK_LIBRARY": str(espeak_dll),
            "ESPEAK_DATA_PATH": str(espeak_data),
            "PATH": str(espeak_root) + os.pathsep + os.environ.get("PATH", "")
        })

        # Recharger les modules TTS
        if force_reload:
            logging.info("Rechargement des modules TTS...")
            for module in list(sys.modules.keys()):
                if module.startswith('TTS'):
                    del sys.modules[module]

        # Import TTS à nouveau
        import TTS.utils.synthesizer

        # Charger la DLL avec des flags spécifiques
        flags = (
            0x00000100  # LOAD_LIBRARY_SEARCH_DEFAULT_DIRS
            | 0x00000800  # LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR
            | 0x00000008  # LOAD_WITH_ALTERED_SEARCH_PATH
        )

        logging.info(f"Chargement de la DLL: {espeak_dll}")
        try:
            espeak_lib = ctypes.CDLL(str(espeak_dll), winmode=flags)
            if not espeak_lib._handle:
                raise RuntimeError("Handle DLL invalide")
                
            logging.info("Configuration des fonctions...")
            espeak_lib.espeak_Initialize.argtypes = [
                ctypes.c_int, ctypes.c_int, ctypes.c_char_p, ctypes.c_int
            ]
            espeak_lib.espeak_Initialize.restype = ctypes.c_int
            
            # Test d'initialisation
            ret = espeak_lib.espeak_Initialize(
                1,  # AUDIO_OUTPUT_SYNCHRONOUS
                0,  # Buffer length
                str(espeak_data).encode(),
                0   # Options
            )
            
            if ret <= 0:
                raise RuntimeError(f"Échec initialisation (code {ret})")
                
            # Patch TTS
            TTS.utils.synthesizer._ESPEAK_LIB = espeak_lib
            
            logging.info("Vérification du patch...")
            if not hasattr(TTS.utils.synthesizer, '_ESPEAK_LIB') or \
               TTS.utils.synthesizer._ESPEAK_LIB is None:
                raise RuntimeError("Patch non appliqué")
                
            logging.info("Patch appliqué avec succès")
            return True

        except Exception as e:
            logging.error(f"Erreur chargement DLL: {str(e)}")
            return False

    except Exception as e:
        logging.error(f"Erreur générale: {str(e)}")
        return False

if __name__ == "__main__":
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s [%(levelname)s] %(message)s'
    )
    
    if patch_tts_espeak():
        print("Patch réussi")
    else:
        print("Échec du patch")

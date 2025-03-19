# Hook pour TTS 
from PyInstaller.utils.hooks import collect_all 
 
# Collecte de tous les packages liés à TTS 
datas, binaries, hiddenimports = collect_all('TTS') 
 
# Ajouter des imports supplémentaires 
hiddenimports += [ 
    'TTS', 
    'TTS.utils', 
    'TTS.utils.audio', 
    'TTS.tts', 
    'TTS.tts.models', 
    'TTS.tts.utils', 
    'TTS.tts.configs', 
] 

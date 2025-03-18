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
    'trainer',
    'trainer.trainer',
    'trainer.io',
    'trainer.logging',
    'trainer.callback',
]

# Spécifier explicitement que le module trainer est un hiddenimport
hiddenimports.append('trainer')

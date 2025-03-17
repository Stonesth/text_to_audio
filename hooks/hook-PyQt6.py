# Hook pour PyQt6 
from PyInstaller.utils.hooks import collect_all, collect_submodules 
 
# Collecte de tous les packages liés à PyQt6 
datas, binaries, hiddenimports = collect_all('PyQt6') 
 
# Ajouter spécifiquement PyQt6.sip qui pose souvent problème 
hiddenimports += [ 
    'PyQt6', 
    'PyQt6.sip', 
    'PyQt6.QtCore', 
    'PyQt6.QtGui', 
    'PyQt6.QtWidgets', 
    'PyQt6.uic', 
] 
 
# Collecte explicite des sous-modules PyQt6.sip 
sip_modules = collect_submodules('PyQt6.sip') 
hiddenimports += sip_modules 

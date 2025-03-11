# PyQt6 hook pour PyInstaller

from PyInstaller.utils.hooks import collect_data_files, collect_submodules, collect_dynamic_libs
import os
import sys
import glob

# Collecter tous les sous-modules de PyQt6
hiddenimports = collect_submodules('PyQt6')

# Ajouter explicitement les modules importants
hiddenimports.extend([
    'PyQt6.QtCore',
    'PyQt6.QtGui',
    'PyQt6.QtWidgets',
    'PyQt6.uic',
    'PyQt6.sip',
    'sip',  # Module sip de base
    'PyQt6.QtSvg',
    'PyQt6.QtPrintSupport',
])

# Collecter tous les fichiers de données
datas = collect_data_files('PyQt6')

# Collecter les bibliothèques dynamiques
binaries = collect_dynamic_libs('PyQt6')

# Ajouter explicitement le fichier sip.pyd
def hook(hook_api):
    # Obtenir le chemin d'installation de PyQt6
    import PyQt6
    pyqt6_path = os.path.dirname(PyQt6.__file__)
    
    # Chercher tous les fichiers sip*.pyd
    sip_files = glob.glob(os.path.join(pyqt6_path, 'sip*.pyd'))
    for sip_file in sip_files:
        if os.path.exists(sip_file):
            hook_api.add_datas([(sip_file, 'PyQt6')])
            print(f"Ajout du fichier SIP: {sip_file}")
    
    # Ajouter tous les fichiers .pyd de PyQt6
    for pyd_file in os.listdir(pyqt6_path):
        if pyd_file.endswith('.pyd'):
            pyd_path = os.path.join(pyqt6_path, pyd_file)
            hook_api.add_datas([(pyd_path, 'PyQt6')])
            print(f"Ajout du fichier PYD: {pyd_path}")
    
    # Ajouter les modules sip
    hook_api.add_imports(['PyQt6.sip', 'sip'])
    
    # Ajouter les binaires et datas collectés
    for src, dest in datas:
        hook_api.add_datas([(src, dest)])
    
    for src, dest in binaries:
        hook_api.add_binaries([(src, dest)])

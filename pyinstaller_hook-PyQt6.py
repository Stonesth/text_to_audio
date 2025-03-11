# PyQt6 hook pour PyInstaller

from PyInstaller.utils.hooks import collect_data_files, collect_submodules, collect_dynamic_libs

# Collecter tous les sous-modules de PyQt6
hiddenimports = collect_submodules('PyQt6')

# Ajouter explicitement les modules importants
hiddenimports.extend([
    'PyQt6.QtCore',
    'PyQt6.QtGui',
    'PyQt6.QtWidgets',
    'PyQt6.uic',
    'PyQt6.sip',
    'PyQt6.QtSvg',
    'PyQt6.QtPrintSupport',
])

# Collecter tous les fichiers de donnu00e9es
datas = collect_data_files('PyQt6')

# Collecter les bibliothu00e8ques dynamiques
binaries = collect_dynamic_libs('PyQt6')

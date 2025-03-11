# -*- mode: python ; coding: utf-8 -*-

from PyInstaller.utils.hooks import collect_submodules, collect_data_files, collect_dynamic_libs
import os
import sys
import glob

# Collecter tous les sous-modules de PyQt6 de manière plus complète
hiddenimports = collect_submodules('PyQt6') + [
    'PyQt6.QtWidgets',
    'PyQt6.QtCore',
    'PyQt6.QtGui',
    'PyQt6.uic',
    'PyQt6.sip',  # Ajout explicite de sip
    'sip',        # Module sip de base
    'PyQt6.QtSvg',
    'PyQt6.QtPrintSupport',
    'PyQt6.lupdate',
    'PyQt6.designer_source'
]

# Collecter les fichiers de données de PyQt6
pyqt6_datas = collect_data_files('PyQt6')

# Collecter les bibliothèques dynamiques
binaries = collect_dynamic_libs('PyQt6')

# Chemins de base pour les packages
base_path = 'C:\\Users\\JF30LB\\Projects\\python\\Projects\\text_to_audio\\venv_py310\\Lib\\site-packages'

# Rechercher tous les fichiers sip*.pyd dans PyQt6
pyqt6_path = os.path.join(base_path, 'PyQt6')
sip_files = []
if os.path.exists(pyqt6_path):
    sip_files = [(os.path.join(pyqt6_path, f), 'PyQt6') for f in os.listdir(pyqt6_path) if f.startswith('sip') and f.endswith('.pyd')]

a = Analysis(
    ['Simple_TTS_GUI.py'],
    pathex=[],
    binaries=binaries,  # Ajouter les bibliothèques dynamiques collectées
    datas=[
        (os.path.join(base_path, 'TTS', 'VERSION'), 'TTS'),
        (os.path.join(base_path, 'trainer', 'VERSION'), 'trainer'),
        (os.path.join(base_path, 'torch', '**', '*.py'), 'torch'),
        # Inclure les fichiers binaires (.dll, .pyd) de PyQt6
        (os.path.join(base_path, 'PyQt6', 'Qt6', 'bin', '*'), 'PyQt6/Qt6/bin'),
        (os.path.join(base_path, 'PyQt6', 'Qt6', 'plugins', '*'), 'PyQt6/Qt6/plugins'),
        (os.path.join(base_path, 'PyQt6', '*.pyd'), 'PyQt6'),
        (os.path.join(base_path, 'PyQt6', 'uic', '**', '*'), 'PyQt6/uic'),
        (os.path.join(base_path, 'PyQt6', 'lupdate', '**', '*'), 'PyQt6/lupdate'),
        # Ajouter explicitement le module sip avec le bon nom de fichier
        (os.path.join(base_path, 'PyQt6', 'sip.cp310-win_amd64.pyd'), 'PyQt6'),
    ] + pyqt6_datas + sip_files,  # Ajouter les fichiers sip trouvés
    hiddenimports=hiddenimports,
    hookspath=['c:\\Users\\JF30LB\\Projects\\python\\Projects\\text_to_audio'],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='Simple_TTS_GUI',
    debug=True,  # Activer le mode debug pour plus d'informations
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,  # Garder la console pour voir les erreurs
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

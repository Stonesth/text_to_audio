# -*- mode: python ; coding: utf-8 -*-

from PyInstaller.utils.hooks import collect_submodules, collect_data_files

# Collecter tous les sous-modules de PyQt6 de manière plus complète
hiddenimports = collect_submodules('PyQt6') + [
    'PyQt6.QtWidgets',
    'PyQt6.QtCore',
    'PyQt6.QtGui',
    'PyQt6.uic',
    'PyQt6.sip',
    'PyQt6.QtSvg',
    'PyQt6.QtPrintSupport',
    'PyQt6.lupdate',
    'PyQt6.designer_source'
]

# Collecter les fichiers de données de PyQt6
pyqt6_datas = collect_data_files('PyQt6')

a = Analysis(
    ['Simple_TTS_GUI.py'],
    pathex=[],
    binaries=[],
    datas=[
        ('C:\\Users\\JF30LB\\Projects\\python\\Projects\\text_to_audio\\venv_py310\\Lib\\site-packages\\TTS\\VERSION', 'TTS'),
        ('C:\\Users\\JF30LB\\Projects\\python\\Projects\\text_to_audio\\venv_py310\\Lib\\site-packages\\trainer\\VERSION', 'trainer'),
        ('C:\\Users\\JF30LB\\Projects\\python\\Projects\\text_to_audio\\venv_py310\\Lib\\site-packages\\torch\\**\\*.py', 'torch'),
        # Inclure les fichiers binaires (.dll, .pyd) de PyQt6
        ('C:\\Users\\JF30LB\\Projects\\python\\Projects\\text_to_audio\\venv_py310\\Lib\\site-packages\\PyQt6\\Qt6\\bin\\*', 'PyQt6/Qt6/bin'),
        ('C:\\Users\\JF30LB\\Projects\\python\\Projects\\text_to_audio\\venv_py310\\Lib\\site-packages\\PyQt6\\Qt6\\plugins\\*', 'PyQt6/Qt6/plugins'),
        ('C:\\Users\\JF30LB\\Projects\\python\\Projects\\text_to_audio\\venv_py310\\Lib\\site-packages\\PyQt6\\*.pyd', 'PyQt6'),
        ('C:\\Users\\JF30LB\\Projects\\python\\Projects\\text_to_audio\\venv_py310\\Lib\\site-packages\\PyQt6\\uic\\**\\*', 'PyQt6/uic'),
        ('C:\\Users\\JF30LB\\Projects\\python\\Projects\\text_to_audio\\venv_py310\\Lib\\site-packages\\PyQt6\\lupdate\\**\\*', 'PyQt6/lupdate')
    ] + pyqt6_datas,
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
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,  # Mettre à True pour voir les erreurs pendant le débogage
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

# -*- mode: python ; coding: utf-8 -*-
from PyInstaller.utils.hooks import collect_all

datas = [('venv_py310\\Lib\\site-packages\\TTS\\VERSION', 'TTS'), ('venv_py310\\Lib\\site-packages\\trainer\\VERSION', 'trainer'), ('pytorch_2_6_patch.py', '.'), ('style_nn.qss', '.')]
binaries = []
hiddenimports = ['PyQt6.QtWidgets', 'PyQt6.QtCore', 'PyQt6.QtGui', 'PyQt6.uic', 'PyQt6.sip', 'sip', 'torch', 'torch._C', 'torch.serialization', 'torch.nn', 'torch.nn.functional', 'torchaudio', 'TTS', 'TTS.api', 'TTS.tts.configs.xtts_config', 'TTS.tts.models.xtts', 'trainer']
tmp_ret = collect_all('PyQt6')
datas += tmp_ret[0]; binaries += tmp_ret[1]; hiddenimports += tmp_ret[2]
tmp_ret = collect_all('TTS')
datas += tmp_ret[0]; binaries += tmp_ret[1]; hiddenimports += tmp_ret[2]
tmp_ret = collect_all('torch')
datas += tmp_ret[0]; binaries += tmp_ret[1]; hiddenimports += tmp_ret[2]
tmp_ret = collect_all('numpy')
datas += tmp_ret[0]; binaries += tmp_ret[1]; hiddenimports += tmp_ret[2]
tmp_ret = collect_all('librosa')
datas += tmp_ret[0]; binaries += tmp_ret[1]; hiddenimports += tmp_ret[2]
tmp_ret = collect_all('torchaudio')
datas += tmp_ret[0]; binaries += tmp_ret[1]; hiddenimports += tmp_ret[2]


a = Analysis(
    ['launcher_with_patches.py'],
    pathex=[],
    binaries=binaries,
    datas=datas,
    hiddenimports=hiddenimports,
    hookspath=[],
    hooksconfig={},
    runtime_hooks=['torch_patch.py', 'tts_patch.py', 'pyqt_patch.py'],
    excludes=[],
    noarchive=True,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [('v', None, 'OPTION')],
    name='Simple_TTS_GUI',
    debug=True,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

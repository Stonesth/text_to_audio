# Hook personnalisu00e9 pour PyTorch

from PyInstaller.utils.hooks import collect_all, collect_submodules
import os

# Collecter tous les modules PyTorch nu00e9cessaires
datas, binaries, hiddenimports = collect_all('torch', include_py_files=True)

# Exclure les modules JIT qui posent probu00e8me
excludes = [
    'torch.jit',
    'torch._jit_internal',
    'torch.functional',
    'torch.autograd',
    'torch.cuda',
    'torch.utils.cpp_extension',
    'torch.distributed',
    'torch.testing',
    'torch.sparse',
    'torch.quantization',
    'torch.fx',
    'torch._inductor',
    'torch._dynamo',
    'torch.compiler',
]

# Filtrer les imports cachu00e9s pour exclure les modules problu00e9matiques
filtered_hiddenimports = []
for module in hiddenimports:
    skip = False
    for exclude in excludes:
        if module.startswith(exclude):
            skip = True
            break
    if not skip:
        filtered_hiddenimports.append(module)

# Remplacer les imports cachu00e9s par notre liste filtru00e9e
hiddenimports = filtered_hiddenimports

# Ajouter des modules essentiels pour TTS
hiddenimports.extend([
    'torch.nn',
    'torch.nn.functional',
    'torch.optim',
    'torch.utils',
    'torch.utils.data',
    'torch.serialization',
])

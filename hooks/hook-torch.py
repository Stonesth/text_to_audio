# Hook pour PyTorch 
from PyInstaller.utils.hooks import collect_all 
 
# Collecte de tous les packages liés à torch 
datas, binaries, hiddenimports = collect_all('torch') 
 
# Ajouter des imports supplémentaires 
hiddenimports += [ 
    'torch', 
    'torch.nn', 
    'torch.nn.functional', 
    'torch.utils', 
    'torch.utils.data', 
    'torch.serialization', 
    'torch.audio', 
    'torchvision', 
    'torchaudio', 
] 

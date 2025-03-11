# Hook personnalisé pour PyTorch avec PyInstaller

from PyInstaller.utils.hooks import collect_all

# Exclure les modules JIT de PyTorch qui posent problème
def hook(hook_api):
    # Modules à exclure
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
    
    # Informer PyInstaller d'exclure ces modules
    for module in excludes:
        hook_api.add_imports([f"ignore::{module}"])
    
    # Ajouter un patch pour éviter les erreurs avec torch.jit
    hook_api.add_runtime_module('torch_patch')

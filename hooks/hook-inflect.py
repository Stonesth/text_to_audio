# Fichier hook-inflect.py pour PyInstaller 
from PyInstaller.utils.hooks import collect_all, collect_submodules 
import os 
import sys 
 
# Collecter tous les modules et sous-modules 
datas, binaries, hiddenimports = collect_all('inflect') 
 
# Ajouter typeguard et ses sous-modules 
hiddenimports.extend(collect_submodules('typeguard')) 
 
# Créer un fichier d'environnement pour désactiver les vérifications typeguard 
typeguard_env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'typeguard_env.py') 
with open(typeguard_env_path, 'w') as f: 
    f.write('import os\nos.environ["TYPEGUARD_DISABLE"] = "1"\n') 
 
# Ajouter le fichier d'environnement aux données 
datas.append((typeguard_env_path, '.')) 

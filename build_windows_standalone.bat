@echo off
echo Création de l'exécutable Windows autonome...

:: Vérifier que l'environnement virtuel existe
if not exist "venv_py310\Scripts\python.exe" (
    echo ERREUR: L'environnement virtuel venv_py310 n'existe pas
    echo Veuillez d'abord créer et activer l'environnement virtuel
    pause
    exit /b 1
)

:: Installer PyInstaller si nécessaire
echo Installation de PyInstaller...
"venv_py310\Scripts\python.exe" -m pip install pyinstaller
if errorlevel 1 (
    echo ERREUR: Impossible d'installer PyInstaller
    pause
    exit /b 1
)

:: Mettre à jour NumPy
echo Mise à jour de NumPy...
"venv_py310\Scripts\python.exe" -m pip install --upgrade numpy
if errorlevel 1 (
    echo ERREUR: Impossible de mettre à jour NumPy
    pause
    exit /b 1
)

:: Créer l'exécutable
echo Création de l'exécutable...
"venv_py310\Scripts\python.exe" -m PyInstaller --onefile --noconsole ^
    --name "Simple_TTS_GUI" ^
    --collect-all torch ^
    --collect-all TTS ^
    --add-data="venv_py310\Lib\site-packages\TTS\VERSION;TTS" ^
    --add-data="venv_py310\Lib\site-packages\trainer\VERSION;trainer" ^
    --add-binary="venv_py310\Lib\site-packages\torchaudio\lib\libtorchaudio_ffmpeg.pyd;." ^
    --add-binary="venv_py310\Lib\site-packages\torchaudio\lib\_torchaudio_ffmpeg.pyd;." ^
    --hidden-import=torch.distributed._shard.checkpoint._dedup_tensors ^
    --hidden-import=torch.distributed._shard.checkpoint._nested_dict ^
    --hidden-import=torch.distributed._shard.checkpoint._sharded_tensor_utils ^
    --hidden-import=torch.distributed._shard.checkpoint._traverse ^
    --hidden-import=torch.distributed._shard.checkpoint.api ^
    --hidden-import=torch.distributed._shard.checkpoint.default_planner ^
    --hidden-import=torch.distributed._shard.checkpoint.filesystem ^
    --hidden-import=torch.distributed._shard.checkpoint.metadata ^
    --hidden-import=torch.distributed._shard.checkpoint.optimizer ^
    --hidden-import=torch.distributed._shard.checkpoint.planner ^
    --hidden-import=torch.distributed._shard.checkpoint.planner_helpers ^
    --hidden-import=torch.distributed._shard.checkpoint.resharding ^
    --hidden-import=torch.distributed._shard.checkpoint.state_dict_loader ^
    --hidden-import=torch.distributed._shard.checkpoint.state_dict_saver ^
    --hidden-import=torch.distributed._shard.checkpoint.storage ^
    --hidden-import=torch.distributed._shard.checkpoint.utils ^
    --hidden-import=torch.distributed._sharded_tensor._ops ^
    --hidden-import=torch.distributed._sharded_tensor._ops._common ^
    --hidden-import=torch.distributed._sharded_tensor._ops.binary_cmp ^
    --hidden-import=torch.distributed._sharded_tensor._ops.chunk ^
    --hidden-import=torch.distributed._sharded_tensor._ops.elementwise_ops ^
    --hidden-import=torch.distributed._sharded_tensor._ops.init ^
    --hidden-import=torch.distributed._sharded_tensor._ops.math_ops ^
    --hidden-import=torch.distributed._sharded_tensor._ops.matrix_ops ^
    --hidden-import=torch.distributed._sharded_tensor._ops.misc_ops ^
    --hidden-import=torch.distributed._sharded_tensor._ops.tensor_ops ^
    --hidden-import=torch.distributed._sharded_tensor.api ^
    --hidden-import=torch.distributed._sharded_tensor.metadata ^
    --hidden-import=torch.distributed._sharded_tensor.reshard ^
    --hidden-import=torch.distributed._sharded_tensor.shard ^
    --hidden-import=torch.distributed._sharded_tensor.utils ^
    --hidden-import=torch.distributed._sharding_spec._internals ^
    --hidden-import=torch.distributed._sharding_spec.api ^
    --hidden-import=torch.distributed._sharding_spec.chunk_sharding_spec ^
    --hidden-import=torch.distributed._sharding_spec.chunk_sharding_spec_ops ^
    --hidden-import=torch.distributed._sharding_spec.chunk_sharding_spec_ops._common ^
    --hidden-import=torch.distributed._sharding_spec.chunk_sharding_spec_ops.embedding ^
    --hidden-import=torch.distributed._sharding_spec.chunk_sharding_spec_ops.embedding_bag ^
    --hidden-import=torch.distributed._sharding_spec.chunk_sharding_spec_ops.linear ^
    --hidden-import=torch.distributed._sharding_spec.chunk_sharding_spec_ops.math_ops ^
    --hidden-import=torch.distributed._sharding_spec.chunk_sharding_spec_ops.matrix_ops ^
    --hidden-import=torch.distributed._sharding_spec.chunk_sharding_spec_ops.softmax ^
    --hidden-import=PyQt6 ^
    --hidden-import=PyQt6.sip ^
    --hidden-import=torch ^
    --hidden-import=torchaudio ^
    --hidden-import=pysbd ^
    --hidden-import=numba ^
    Simple_TTS_GUI.py

if errorlevel 1 (
    echo La création de l'exécutable a échoué
    pause
    exit /b 1
)

echo Création terminée avec succès!
echo L'exécutable se trouve dans le dossier dist/
pause

@echo off
echo Compilation de Simple TTS GUI avec le nouveau lanceur avec patchs...

:: Activer l'environnement virtuel Python 3.10
echo Activation de l'environnement virtuel Python 3.10...
call venv_py310\Scripts\activate.bat

:: Vérifier la version de Python
python --version

:: Nettoyer les dossiers de compilation précédents
if exist build rmdir /s /q build
if exist dist rmdir /s /q dist

:: Créer le dossier de sortie s'il n'existe pas
if not exist output mkdir output

:: Compiler l'application avec PyInstaller
pyinstaller --noconfirm --onedir --windowed --icon "icon.ico" ^^
--add-data "icon.ico;." ^^
--add-data "models;models" ^^
--add-data "launcher_with_patches.py;." ^^
--add-data "pytorch_2_6_patch.py;." ^^
--add-data "gruut_patch.py;." ^^
--add-data "jamo_patch.py;." ^^
--add-data "transformers_patch.py;." ^^
--hidden-import="torch" ^^
--hidden-import="torch.nn" ^^
--hidden-import="torch.nn.functional" ^^
--hidden-import="torch.nn.modules" ^^
--hidden-import="torch.nn.modules.activation" ^^
--hidden-import="torch.nn.modules.container" ^^
--hidden-import="torch.nn.modules.conv" ^^
--hidden-import="torch.nn.modules.linear" ^^
--hidden-import="torch.nn.modules.pooling" ^^
--hidden-import="torch.nn.modules.normalization" ^^
--hidden-import="torch.nn.parameter" ^^
--hidden-import="torch.optim" ^^
--hidden-import="torch.optim.optimizer" ^^
--hidden-import="torch.optim.lr_scheduler" ^^
--hidden-import="torch.distributions" ^^
--hidden-import="torch.distributions.normal" ^^
--hidden-import="torch.distributions.transforms" ^^
--hidden-import="torch.distributions.utils" ^^
--hidden-import="torch.distributions.constraints" ^^
--hidden-import="torch.distributions.kl" ^^
--hidden-import="torch.distributions.exp_family" ^^
--hidden-import="torch.distributions.bernoulli" ^^
--hidden-import="torch.distributions.categorical" ^^
--hidden-import="torch.distributions.cauchy" ^^
--hidden-import="torch.distributions.beta" ^^
--hidden-import="torch.distributions.binomial" ^^
--hidden-import="torch.distributions.continuous_bernoulli" ^^
--hidden-import="torch.distributions.dirichlet" ^^
--hidden-import="torch.distributions.gamma" ^^
--hidden-import="torch.distributions.geometric" ^^
--hidden-import="torch.distributions.gumbel" ^^
--hidden-import="torch.distributions.half_normal" ^^
--hidden-import="torch.distributions.laplace" ^^
--hidden-import="torch.distributions.lowrank_multivariate_normal" ^^
--hidden-import="torch.distributions.multinomial" ^^
--hidden-import="torch.distributions.multivariate_normal" ^^
--hidden-import="torch.distributions.negative_binomial" ^^
--hidden-import="torch.distributions.one_hot_categorical" ^^
--hidden-import="torch.distributions.pareto" ^^
--hidden-import="torch.distributions.poisson" ^^
--hidden-import="torch.distributions.relaxed_bernoulli" ^^
--hidden-import="torch.distributions.relaxed_categorical" ^^
--hidden-import="torch.distributions.studentT" ^^
--hidden-import="torch.distributions.uniform" ^^
--hidden-import="torch.distributions.von_mises" ^^
--hidden-import="torch.distributions.weibull" ^^
--hidden-import="torch.distributions.wishart" ^^
--hidden-import="torch.jit" ^^
--hidden-import="torch.jit.frontend" ^^
--hidden-import="torch.jit._builtins" ^^
--hidden-import="torch.jit.annotations" ^^
--hidden-import="torch.jit.utils" ^^
--hidden-import="torch.cuda" ^^
--hidden-import="torch.cuda.amp" ^^
--hidden-import="torch.cuda.amp.autocast_mode" ^^
--hidden-import="torch.cuda.amp.grad_scaler" ^^
--hidden-import="torch.utils" ^^
--hidden-import="torch.utils.data" ^^
--hidden-import="torch.utils.data.dataset" ^^
--hidden-import="torch.utils.data.dataloader" ^^
--hidden-import="torch.utils.data.sampler" ^^
--hidden-import="torch.utils.dlpack" ^^
--hidden-import="torch.utils.tensorboard" ^^
--hidden-import="torch.onnx" ^^
--hidden-import="torch.onnx.symbolic_helper" ^^
--hidden-import="torch.onnx.symbolic_opset9" ^^
--hidden-import="torch.onnx.utils" ^^
--hidden-import="torch.random" ^^
--hidden-import="torch.storage" ^^
--hidden-import="torch.serialization" ^^
--hidden-import="torch.sparse" ^^
--hidden-import="torch.special" ^^
--hidden-import="torch.profiler" ^^
--hidden-import="torch.ops" ^^
--hidden-import="torch.ops.aten" ^^
--hidden-import="torch.ops.torch" ^^
--hidden-import="torch.ops.torch_library" ^^
--hidden-import="torch.ops.torchvision" ^^
--hidden-import="torch.ops.torchaudio" ^^
--hidden-import="torch._ops" ^^
--hidden-import="torch._C" ^^
--hidden-import="torch._utils" ^^
--hidden-import="torch._tensor" ^^
--hidden-import="torch._tensor_str" ^^
--hidden-import="torch._torch_docs" ^^
--hidden-import="torch.functional" ^^
--hidden-import="torch.futures" ^^
--hidden-import="torch.autograd" ^^
--hidden-import="torch.autograd.function" ^^
--hidden-import="torch.autograd.functional" ^^
--hidden-import="torch.autograd.grad_mode" ^^
--hidden-import="torch.autograd.profiler" ^^
--hidden-import="torch.autograd.anomaly_mode" ^^
--hidden-import="torch.fft" ^^
--hidden-import="torch.linalg" ^^
--hidden-import="torch.fx" ^^
--hidden-import="torch.fx.experimental" ^^
--hidden-import="torch.fx.experimental.optimization" ^^
--hidden-import="torch.ao" ^^
--hidden-import="torch.ao.quantization" ^^
--hidden-import="torch.ao.quantization.quantize" ^^
--hidden-import="torch.ao.quantization.quantize_fx" ^^
--hidden-import="torch.ao.quantization.fx" ^^
--hidden-import="torch.ao.quantization.fx.prepare" ^^
--hidden-import="torch.ao.quantization.fx.convert" ^^
--hidden-import="torch.ao.quantization.fx.match_utils" ^^
--hidden-import="torch.ao.quantization.fx.pattern_utils" ^^
--hidden-import="torch.ao.quantization.fx.graph_module" ^^
--hidden-import="torch.ao.quantization.fx.custom_config" ^^
--hidden-import="torch.ao.quantization.fx.utils" ^^
--hidden-import="torch.ao.quantization.observer" ^^
--hidden-import="torch.ao.quantization.fake_quantize" ^^
--hidden-import="torch.ao.quantization.qconfig" ^^
--hidden-import="torch.ao.quantization.quant_type" ^^
--hidden-import="torch.ao.quantization.stubs" ^^
--hidden-import="torch.ao.quantization.utils" ^^
--hidden-import="torch.ao.nn" ^^
--hidden-import="torch.ao.nn.intrinsic" ^^
--hidden-import="torch.ao.nn.intrinsic.quantized" ^^
--hidden-import="torch.ao.nn.intrinsic.qat" ^^
--hidden-import="torch.ao.nn.quantized" ^^
--hidden-import="torch.ao.nn.quantized.dynamic" ^^
--hidden-import="torch.ao.nn.quantized.functional" ^^
--hidden-import="torch.ao.nn.qat" ^^
--hidden-import="torch.ao.nn.sparse" ^^
--hidden-import="torch.quantization" ^^
--hidden-import="torch.quantization.quantize" ^^
--hidden-import="torch.quantization.quantize_fx" ^^
--hidden-import="torch.quantization.fx" ^^
--hidden-import="torch.quantization.fx.prepare" ^^
--hidden-import="torch.quantization.fx.convert" ^^
--hidden-import="torch.quantization.fx.match_utils" ^^
--hidden-import="torch.quantization.fx.pattern_utils" ^^
--hidden-import="torch.quantization.fx.graph_module" ^^
--hidden-import="torch.quantization.fx.custom_config" ^^
--hidden-import="torch.quantization.fx.utils" ^^
--hidden-import="torch.quantization.observer" ^^
--hidden-import="torch.quantization.fake_quantize" ^^
--hidden-import="torch.quantization.qconfig" ^^
--hidden-import="torch.quantization.quant_type" ^^
--hidden-import="torch.quantization.stubs" ^^
--hidden-import="torch.quantization.utils" ^^
--hidden-import="torch.nn.quantized" ^^
--hidden-import="torch.nn.quantized.dynamic" ^^
--hidden-import="torch.nn.quantized.functional" ^^
--hidden-import="torch.nn.qat" ^^
--hidden-import="torch.nn.intrinsic" ^^
--hidden-import="torch.nn.intrinsic.quantized" ^^
--hidden-import="torch.nn.intrinsic.qat" ^^
--hidden-import="torch.nn.sparse" ^^
--hidden-import="torchaudio" ^^
--hidden-import="torchaudio.functional" ^^
--hidden-import="torchaudio.functional.filtering" ^^
--hidden-import="torchaudio.transforms" ^^
--hidden-import="torchaudio.utils" ^^
--hidden-import="torchaudio.models" ^^
--hidden-import="torchaudio.datasets" ^^
--hidden-import="torchaudio.kaldi_io" ^^
--hidden-import="torchaudio.sox_effects" ^^
--hidden-import="torchaudio.compliance" ^^
--hidden-import="torchvision" ^^
--hidden-import="torchvision.datasets" ^^
--hidden-import="torchvision.io" ^^
--hidden-import="torchvision.models" ^^
--hidden-import="torchvision.ops" ^^
--hidden-import="torchvision.transforms" ^^
--hidden-import="torchvision.utils" ^^
--hidden-import="torchvision.extension" ^^
--hidden-import="k_diffusion" ^^
--hidden-import="k_diffusion.sampling" ^^
--hidden-import="k_diffusion.augmentation" ^^
--hidden-import="k_diffusion.config" ^^
--hidden-import="k_diffusion.evaluation" ^^
--hidden-import="k_diffusion.external" ^^
--hidden-import="k_diffusion.gns" ^^
--hidden-import="k_diffusion.layers" ^^
--hidden-import="k_diffusion.models" ^^
--hidden-import="k_diffusion.utils" ^^
--hidden-import="gruut" ^^
--hidden-import="jamo" ^^
--hidden-import="transformers" ^^
--hidden-import="PyQt6" ^^
--hidden-import="PyQt6.QtCore" ^^
--hidden-import="PyQt6.QtGui" ^^
--hidden-import="PyQt6.QtWidgets" ^^
--hidden-import="PyQt6.sip" ^^
--hidden-import="TTS" ^^
--hidden-import="TTS.api" ^^
--hidden-import="TTS.utils" ^^
--hidden-import="TTS.utils.synthesizer" ^^
--hidden-import="TTS.tts" ^^
--hidden-import="TTS.tts.configs" ^^
--hidden-import="TTS.tts.configs.vits_config" ^^
--hidden-import="TTS.tts.models" ^^
--hidden-import="TTS.tts.models.vits" ^^
--hidden-import="TTS.tts.models.xtts" ^^
--hidden-import="TTS.tts.utils" ^^
--hidden-import="TTS.tts.utils.text" ^^
--hidden-import="TTS.tts.utils.text.phonemizers" ^^
--hidden-import="TTS.tts.utils.text.korean" ^^
--hidden-import="TTS.tts.utils.text.korean.phonemizer" ^^
launcher_with_patches.py

echo Compilation terminee. Verification des erreurs...

:: Verifier si la compilation a reussi
if exist dist\launcher_with_patches (  
    echo Compilation reussie. Copie des fichiers dans le dossier output...
    
    :: Copier le dossier dist dans output
    xcopy /E /I /Y dist\launcher_with_patches output\Simple_TTS_GUI
    
    echo Application compilee avec succes dans le dossier output\Simple_TTS_GUI
) else (
    echo Erreur lors de la compilation. Verifiez les messages d'erreur ci-dessus.
)

:: Désactiver l'environnement virtuel
call deactivate

echo Processus termine.
pause

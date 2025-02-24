@echo off
echo Création d'un nouvel environnement virtuel...
python -m venv venv_new
call venv_new\Scripts\activate

echo Installation des dépendances...
python -m pip install --upgrade pip
python -m pip install wheel setuptools
python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
python -m pip install -r requirements.txt

echo Installation terminée !
echo Pour activer l'environnement : venv_new\Scripts\activate

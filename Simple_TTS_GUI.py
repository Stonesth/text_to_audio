"""
Interface graphique pour Simple_TTS utilisant PyQt6
"""

import sys
import os
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                            QHBoxLayout, QLabel, QComboBox, QTextEdit, QPushButton,
                            QFileDialog, QProgressBar, QCheckBox)
from PyQt6.QtCore import Qt, QThread, pyqtSignal
from PyQt6.QtGui import QFont, QFontDatabase, QPixmap, QScreen
import torch
from TTS.api import TTS
from TTS.tts.configs.xtts_config import XttsConfig
from datetime import datetime

# Configuration pour PyTorch 2.6+
torch.serialization.add_safe_globals([XttsConfig])

class TTSWorker(QThread):
    """Thread worker pour la génération TTS"""
    finished = pyqtSignal()
    progress = pyqtSignal(str)
    error = pyqtSignal(str)

    def __init__(self, params):
        super().__init__()
        self.params = params

    def run(self):
        """Exécute la génération TTS dans un thread séparé."""
        try:
            # Affichage des paramètres sélectionnés
            self.progress.emit("\n=== Configuration ===")
            self.progress.emit(f"Langue : {self.params['lang']}")
            self.progress.emit(f"Modèle : {self.get_model_name()}")
            if self.params['speaker']:
                self.progress.emit(f"Speaker : {self.params['speaker']}")
            if self.params.get('reference_audio'):
                self.progress.emit(f"Fichier audio de référence : {self.params['reference_audio']}")
            self.progress.emit(f"Texte à synthétiser : {self.params['text']}")
            self.progress.emit("=" * 20 + "\n")

            # Configuration du device
            device = "cuda" if torch.cuda.is_available() and self.params['use_cuda'] else "cpu"
            self.progress.emit(f"Utilisation du device : {device}")
            
            model_name = self.get_model_name()
            self.progress.emit(f"Chargement du modèle : {model_name}")

            # Patch temporaire pour PyTorch 2.6 si c'est XTTS v2
            if "xtts_v2" in model_name:
                original_load = torch.load
                def patched_load(*args, **kwargs):
                    kwargs['weights_only'] = False
                    return original_load(*args, **kwargs)
                torch.load = patched_load

            # Initialisation TTS
            tts = TTS(model_name).to(device)
            
            # Restauration de torch.load si c'était XTTS v2
            if "xtts_v2" in model_name:
                torch.load = original_load

            # Configuration des paramètres selon le modèle
            kwargs = {}
            
            if self.params['lang'] == 1:  # Français
                if self.params['fr_model'] == 0:  # XTTS v2
                    kwargs['speaker_wav'] = self.params.get('reference_audio')
                    kwargs['language'] = 'fr'
                    self.progress.emit(f"Configuration XTTS v2 - Langue: fr, Fichier audio: {self.params.get('reference_audio')}")
                elif self.params['fr_model'] in [1, 2]:  # YourTTS
                    kwargs['speaker'] = 'male-en-2' if self.params['fr_model'] == 1 else 'female-en-5'
                    kwargs['language'] = 'fr-fr'
                    self.progress.emit(f"Configuration YourTTS - Langue: fr-fr, Speaker: {'male-en-2' if self.params['fr_model'] == 1 else 'female-en-5'}")
                elif self.params['fr_model'] == 3:  # VITS
                    self.progress.emit(f"Configuration VITS")
            elif self.params['lang'] == 2:  # VCTK
                speaker = self.params['speaker']
                if speaker.startswith("VCTK_"):
                    speaker = speaker[5:]
                kwargs['speaker'] = speaker
                self.progress.emit(f"Configuration VCTK - Speaker: {speaker}")
            
            # Affichage de la commande équivalente
            cmd = f"python Simple_TTS.py --lang {self.params['lang']} "
            if self.params['lang'] == 1:
                cmd += f"--fr-model {self.params['fr_model']} "
            else:
                cmd += f"--en-model {self.params['en_model']} "
            if self.params['speaker']:
                cmd += f"--speaker {self.params['speaker']} "
            if self.params.get('reference_audio'):
                cmd += f"--reference-audio {self.params['reference_audio']} "
            if self.params['use_cuda']:
                cmd += "--use-cuda "
            self.progress.emit("\nCommande équivalente :")
            self.progress.emit(cmd + "\n")

            # Génération audio
            self.progress.emit("Génération audio en cours...")
            tts.tts_to_file(
                text=self.params['text'],
                file_path=self.params['output_file'],
                **kwargs
            )
            
            self.progress.emit(f"Fichier audio généré avec succès : {self.params['output_file']}")
            self.finished.emit()

        except Exception as e:
            self.error.emit(str(e))

    def get_model_name(self):
        """Retourne le nom du modèle en fonction de la langue choisie."""
        lang_idx = self.params['lang']
        model_idx = self.params['en_model'] if lang_idx != 1 else self.params['fr_model']
        
        if lang_idx == 0:  # Anglais
            models = [
                "tts_models/en/jenny/jenny",
                "tts_models/en/ljspeech/tacotron2-DDC",
                "tts_models/en/ljspeech/glow-tts",
                "tts_models/en/ljspeech/speedy-speech",
                "tts_models/en/ljspeech/neural_hmm"
            ]
        elif lang_idx == 1:  # Français
            models = [
                "tts_models/multilingual/multi-dataset/xtts_v2",
                "tts_models/fr/css10/vits",
                "tts_models/multilingual/multi-dataset/your_tts",
                "tts_models/multilingual/multi-dataset/your_tts"
            ]
        else:  # Anglais (VCTK)
            models = [
                "tts_models/en/vctk/vits"
            ]
        
        return models[model_idx]

class CustomTextEdit(QTextEdit):
    def __init__(self, parent=None):
        super().__init__(parent)

    def keyPressEvent(self, event):
        if event.key() == Qt.Key.Key_V and event.modifiers() == Qt.KeyboardModifier.ControlModifier:
            self.paste()
        elif event.key() == Qt.Key.Key_C and event.modifiers() == Qt.KeyboardModifier.ControlModifier:
            self.copy()
        elif event.key() == Qt.Key.Key_X and event.modifiers() == Qt.KeyboardModifier.ControlModifier:
            self.cut()
        elif event.key() == Qt.Key.Key_A and event.modifiers() == Qt.KeyboardModifier.ControlModifier:
            self.selectAll()
        else:
            super().keyPressEvent(event)

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Simple TTS GUI")
        
        # Configuration en plein écran
        screen = QApplication.primaryScreen().geometry()
        self.setGeometry(0, 0, screen.width(), screen.height())
        
        # Chargement du style
        style_file = os.path.join(os.path.dirname(__file__), "style_nn.qss")
        if os.path.exists(style_file):
            with open(style_file, "r") as f:
                self.setStyleSheet(f.read())
        
        # Configuration de la police
        font_id = QFontDatabase.addApplicationFont(os.path.join(os.path.dirname(__file__), "fonts/NNDagny-Regular.ttf"))
        if font_id != -1:
            font_family = QFontDatabase.applicationFontFamilies(font_id)[0]
            self.setFont(QFont(font_family, 16))
        
        # Dossier de sortie par défaut
        self.output_dir = os.path.join(os.getcwd(), "story_output")
        os.makedirs(self.output_dir, exist_ok=True)
        
        # Widget principal avec marges
        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        layout = QVBoxLayout(main_widget)
        layout.setContentsMargins(24, 24, 24, 24)
        layout.setSpacing(16)

        # En-tête avec logo et titre
        header_layout = QHBoxLayout()
        
        # Logo NN
        logo_label = QLabel()
        logo_path = os.path.join(os.path.dirname(__file__), "resources/nn_logo.png")
        if os.path.exists(logo_path):
            pixmap = QPixmap(logo_path)
            # Agrandissement du logo à 48x48 pixels
            scaled_pixmap = pixmap.scaled(48, 48, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation)
            logo_label.setPixmap(scaled_pixmap)
            logo_label.setContentsMargins(0, 4, 24, 0)  # Augmentation de la marge droite
        header_layout.addWidget(logo_label)
        
        # Titre de l'application
        title_label = QLabel("Générateur de Voix")
        title_label.setStyleSheet("font-size: 24px; font-weight: bold; color: #000000;")
        header_layout.addWidget(title_label)
        header_layout.addStretch()
        
        layout.addLayout(header_layout)

        # Séparateur
        separator = QWidget()
        separator.setFixedHeight(1)
        separator.setStyleSheet("background-color: #E5E5E5;")
        layout.addWidget(separator)

        # Dossier de sortie
        output_layout = QHBoxLayout()
        output_label = QLabel("Dossier de sortie:")
        self.output_path_label = QLabel(self.output_dir)
        self.output_path_label.setStyleSheet("padding: 8px; border: 1px solid #666666; border-radius: 4px;")
        output_button = QPushButton("Choisir...")
        output_button.setProperty("class", "secondaryButton")
        output_layout.addWidget(output_label)
        output_layout.addWidget(self.output_path_label, stretch=1)
        output_layout.addWidget(output_button)
        layout.addLayout(output_layout)

        # Langue
        lang_layout = QHBoxLayout()
        lang_label = QLabel("Langue:")
        self.lang_combo = QComboBox()
        self.lang_combo.addItems(["Anglais", "Français", "Anglais (VCTK)"])
        lang_layout.addWidget(lang_label)
        lang_layout.addWidget(self.lang_combo)
        layout.addLayout(lang_layout)

        # Modèle
        model_layout = QHBoxLayout()
        model_label = QLabel("Modèle:")
        self.model_combo = QComboBox()
        self.update_model_list(0)
        model_layout.addWidget(model_label)
        model_layout.addWidget(self.model_combo)
        layout.addLayout(model_layout)

        # VCTK Speakers
        speaker_layout = QHBoxLayout()
        speaker_label = QLabel("Voix VCTK:")
        self.speaker_combo = QComboBox()
        self.speaker_combo.addItems([
            "VCTK_p232 (homme, bien)",
            "VCTK_p273 (femme, bien)",
            "VCTK_p278 (femme, bien)",
            "VCTK_p279 (homme, bien)",
            "VCTK_p304 (femme, voix préférée)"
        ])
        speaker_layout.addWidget(speaker_label)
        speaker_layout.addWidget(self.speaker_combo)
        self.speaker_combo.setEnabled(False)
        layout.addLayout(speaker_layout)

        # XTTS Reference Audio
        ref_audio_layout = QHBoxLayout()
        ref_audio_label = QLabel("Audio de référence (XTTS):")
        self.ref_audio_path = QLabel("Non sélectionné")
        self.ref_audio_path.setStyleSheet("padding: 8px; border: 1px solid #666666; border-radius: 4px;")
        ref_audio_button = QPushButton("Choisir...")
        ref_audio_button.setProperty("class", "secondaryButton")
        ref_audio_layout.addWidget(ref_audio_label)
        ref_audio_layout.addWidget(self.ref_audio_path, stretch=1)
        ref_audio_layout.addWidget(ref_audio_button)
        layout.addLayout(ref_audio_layout)

        # CUDA
        cuda_layout = QHBoxLayout()
        self.cuda_check = QCheckBox("Utiliser CUDA (si disponible)")
        self.cuda_check.setChecked(True)
        cuda_layout.addWidget(self.cuda_check)
        layout.addLayout(cuda_layout)

        # Zone de texte
        text_label = QLabel("Texte à convertir:")
        layout.addWidget(text_label)
        self.text_edit = CustomTextEdit()
        self.text_edit.setPlaceholderText("Entrez votre texte ici...")
        self.text_edit.setMinimumHeight(150)
        layout.addWidget(self.text_edit)

        # Boutons
        button_layout = QHBoxLayout()
        self.generate_button = QPushButton("Générer")
        self.cancel_button = QPushButton("Annuler")
        self.play_button = QPushButton("Écouter")
        self.play_button.setEnabled(False)
        self.play_button.setProperty("class", "secondaryButton")
        self.cancel_button.setProperty("class", "secondaryButton")
        self.cancel_button.setEnabled(False)
        button_layout.addWidget(self.generate_button)
        button_layout.addWidget(self.cancel_button)
        button_layout.addWidget(self.play_button)
        layout.addLayout(button_layout)

        # Barre de progression
        self.progress_bar = QProgressBar()
        self.progress_bar.setTextVisible(False)
        layout.addWidget(self.progress_bar)

        # Log
        log_label = QLabel("Messages:")
        layout.addWidget(log_label)
        self.log_text = CustomTextEdit()
        self.log_text.setReadOnly(True)
        self.log_text.setMaximumHeight(100)
        self.log_text.setObjectName("logText")
        self.log_text.setPlaceholderText("Les messages de log apparaîtront ici...")
        layout.addWidget(self.log_text)

        # Connexions
        self.lang_combo.currentIndexChanged.connect(self.on_lang_changed)
        self.model_combo.currentIndexChanged.connect(self.on_model_changed)
        output_button.clicked.connect(self.choose_output_dir)
        ref_audio_button.clicked.connect(self.choose_ref_audio)
        self.generate_button.clicked.connect(self.generate_audio)
        self.cancel_button.clicked.connect(self.cancel_generation)
        self.play_button.clicked.connect(self.play_audio)

        # Variables pour suivre le dernier fichier généré
        self.last_generated_file = None

    def update_model_list(self, lang_index):
        """Met à jour la liste des modèles en fonction de la langue."""
        self.model_combo.clear()
        if lang_index == 0:  # Anglais
            self.model_combo.addItems([
                "Jenny (voix féminine)",
                "Tacotron2-DDC",
                "Glow-TTS",
                "Speedy-Speech",
                "Neural HMM"
            ])
        elif lang_index == 1:  # Français
            self.model_combo.addItems([
                "XTTS v2",
                "VITS",
                "YourTTS (voix masculine)",
                "YourTTS (voix féminine)"
            ])
        else:  # Anglais (VCTK)
            self.model_combo.addItems([
                "VITS"
            ])
            # Mise à jour de la liste des speakers VCTK avec leurs descriptions
            self.speaker_combo.clear()
            self.speaker_combo.addItems([
                "VCTK_p232 (homme)",
                "VCTK_p273 (femme)",
                "VCTK_p278 (femme)",
                "VCTK_p279 (homme)",
                "VCTK_p304 (femme)"
            ])

        self.update_ui_elements()

    def on_lang_changed(self, lang_index):
        """Gère le changement de langue."""
        self.update_model_list(lang_index)
        self.speaker_combo.setEnabled(lang_index == 2)  # Active VCTK speakers uniquement pour VCTK
        # Active le choix du fichier audio de référence uniquement pour XTTS v2
        self.ref_audio_path.setEnabled(lang_index == 1 and self.model_combo.currentIndex() == 0)

    def on_model_changed(self, index):
        """Gère le changement de modèle."""
        # Active le choix du fichier audio de référence uniquement pour XTTS v2
        is_xtts = self.lang_combo.currentIndex() == 1 and index == 0
        self.ref_audio_path.setEnabled(is_xtts)

    def choose_output_dir(self):
        """Ouvre une boîte de dialogue pour choisir le dossier de sortie."""
        dir_path = QFileDialog.getExistingDirectory(self, "Choisir le dossier de sortie", self.output_dir)
        if dir_path:
            self.output_dir = dir_path
            self.output_path_label.setText(dir_path)

    def choose_ref_audio(self):
        """Ouvre une boîte de dialogue pour choisir le fichier audio de référence."""
        file_path, _ = QFileDialog.getOpenFileName(
            self,
            "Choisir un fichier audio de référence",
            "",
            "Fichiers audio (*.wav *.mp3)"
        )
        if file_path:
            self.ref_audio_path.setText(file_path)

    def generate_audio(self):
        """Lance la génération audio."""
        if not self.text_edit.toPlainText().strip():
            self.log_text.append("Erreur : Veuillez entrer du texte")
            return

        # Création du nom de fichier
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        model_suffix = ""
        if self.model_combo.currentText() == "XTTS v2":
            model_suffix = "_xtts"
        elif self.model_combo.currentText() == "VITS":
            model_suffix = "_vits"
        elif "YourTTS" in self.model_combo.currentText():
            model_suffix = "_yourtts"
        
        output_file = os.path.join(
            self.output_dir,
            f"audio_{timestamp}{model_suffix}.wav"
        )
        
        # Stocke le fichier qui va être généré
        self.last_generated_file = output_file
        self.play_button.setEnabled(False)

        # Configuration des paramètres
        params = {
            "text": self.text_edit.toPlainText().strip(),
            "output_file": output_file,
            "lang": self.lang_combo.currentIndex(),
            "en_model": self.model_combo.currentIndex(),
            "fr_model": self.model_combo.currentIndex(),
            "speaker": self.get_speaker(),
            "use_cuda": self.cuda_check.isChecked()
        }

        # Ajout des paramètres spécifiques selon le modèle
        if self.model_combo.currentText() == "XTTS v2":
            if not self.ref_audio_path.text() or self.ref_audio_path.text() == "Non sélectionné":
                self.log_text.append("Erreur : Veuillez sélectionner un fichier audio de référence pour XTTS.")
                return
            params["reference_audio"] = self.ref_audio_path.text()

        # Démarrage de la génération
        self.worker = TTSWorker(params)
        self.worker.progress.connect(self.update_progress)
        self.worker.error.connect(self.show_error)
        self.worker.finished.connect(self.generation_finished)
        
        self.worker.start()
        self.update_ui_elements()
        self.progress_bar.setValue(0)

    def cancel_generation(self):
        """Annule la génération en cours."""
        if hasattr(self, 'worker'):
            self.worker.terminate()
            self.worker.wait()
            self.generation_finished()
            self.log_text.append("Génération annulée")

    def update_progress(self, message):
        """Met à jour le message de progression."""
        self.log_text.append(message)

    def show_error(self, error_message):
        """Affiche un message d'erreur."""
        self.log_text.append(f"Erreur : {error_message}")
        self.generation_finished()

    def generation_finished(self):
        """Gère la fin de la génération."""
        self.update_ui_elements()
        self.progress_bar.setValue(100)
        self.worker = None
        
        # Active le bouton d'écoute si un fichier a été généré
        if self.last_generated_file and os.path.exists(self.last_generated_file):
            self.play_button.setEnabled(True)
            self.update_progress(f"Génération terminée ! Fichier créé : {os.path.basename(self.last_generated_file)}")
        else:
            self.play_button.setEnabled(False)
            self.update_progress("Génération terminée !")

    def play_audio(self):
        """Ouvre le fichier audio avec le lecteur par défaut."""
        if self.last_generated_file and os.path.exists(self.last_generated_file):
            if sys.platform == "darwin":  # macOS
                os.system(f'open "{self.last_generated_file}"')
            else:  # Autres systèmes
                if sys.platform == "win32":
                    os.startfile(self.last_generated_file)
                else:  # Linux
                    os.system(f'xdg-open "{self.last_generated_file}"')

    def get_speaker(self):
        """Retourne l'ID du speaker sans la description."""
        speaker = self.speaker_combo.currentText()
        if self.lang_combo.currentIndex() == 2:  # VCTK
            # Extraire uniquement l'ID du speaker (VCTK_pXXX) de la description
            return speaker.split(" ")[0]
        return speaker

    def get_model_name(self):
        """Retourne le nom du modèle en fonction de la langue choisie."""
        lang_idx = self.lang_combo.currentIndex()
        model_idx = self.model_combo.currentIndex()
        
        # Modèles pour l'anglais
        if lang_idx == 0:
            models = ["tts_models/en/jenny/jenny", "tts_models/en/ljspeech/tacotron2-DDC", 
                     "tts_models/en/ljspeech/glow-tts", "tts_models/en/ljspeech/speedy-speech",
                     "tts_models/en/ljspeech/neural_hmm"]
        # Modèles pour le français
        elif lang_idx == 1:
            models = ["tts_models/multilingual/multi-dataset/xtts_v2", "tts_models/fr/mai/vits",
                     "tts_models/multilingual/multi-dataset/your_tts", "tts_models/multilingual/multi-dataset/your_tts"]
        # Modèles VCTK
        else:
            models = ["tts_models/en/vctk/vits"]
        
        return models[model_idx]

    def update_ui_elements(self):
        pass

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())

"""
Interface graphique pour Simple_TTS utilisant PyQt6
"""

import sys
import os
import warnings
from pathlib import Path
from datetime import datetime

from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                            QHBoxLayout, QLabel, QComboBox, QTextEdit, QPushButton,
                            QFileDialog, QCheckBox, QGraphicsOpacityEffect,
                            QSizePolicy, QMessageBox)
from PyQt6.QtCore import Qt, QThread, pyqtSignal, QPropertyAnimation, QEasingCurve, QPoint, QTimer
from PyQt6.QtGui import QFont, QFontDatabase, QPixmap, QScreen, QColor
import torch
from TTS.api import TTS
from TTS.tts.configs.xtts_config import XttsConfig

# Filtrer les avertissements NumPy spécifiques
warnings.filterwarnings('ignore', message='.*API version.*numpy.*')

# Configuration pour PyTorch 2.6+
if hasattr(torch.serialization, 'add_safe_globals'):
    torch.serialization.add_safe_globals([XttsConfig])

class TTSWorker(QThread):
    """Thread worker pour la génération TTS"""
    finished = pyqtSignal()
    error = pyqtSignal(str)
    progress = pyqtSignal(str)

    def __init__(self, params):
        super().__init__()
        self.params = params

    def validate_text_length(self):
        """Valide la longueur du texte pour le modèle Speedy-Speech."""
        if "speedy-speech" in str(self.params['model_name']).lower():
            min_length = 30  # Augmentation significative de la longueur minimale
            text = self.params['text'].strip()
            if len(text) < min_length:
                # Ajouter des silences et du padding intelligent
                words = text.split()
                padded_words = []
                for word in words:
                    # Ajouter des pauses entre les mots
                    padded_words.extend([word, "...", "..."])
                padded_text = " ".join(padded_words)
                
                # S'assurer que le texte est assez long
                while len(padded_text) < min_length:
                    padded_text += " ... "
                
                self.progress.emit(f"Attention: Texte ajusté pour Speedy-Speech avec pauses")
                return padded_text
        return self.params['text']

    def run(self):
        """Exécute la génération TTS dans un thread séparé."""
        try:
            # Valider la longueur du texte
            validated_text = self.validate_text_length()

            # Configuration du device
            device = "cuda" if torch.cuda.is_available() and self.params['use_cuda'] else "cpu"
            
            model_name = self.get_model_name()

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
                elif self.params['fr_model'] in [1, 2]:  # YourTTS
                    kwargs['speaker'] = 'male-en-2' if self.params['fr_model'] == 1 else 'female-en-5'
                    kwargs['language'] = 'fr-fr'
                elif self.params['fr_model'] == 3:  # VITS
                    pass
            elif self.params['lang'] == 2:  # VCTK
                speaker = self.params['speaker']
                if speaker.startswith("VCTK_"):
                    speaker = speaker[5:]
                kwargs['speaker'] = speaker
            
            # Génération audio
            tts.tts_to_file(
                text=validated_text,
                file_path=self.params['output_file'],
                **kwargs
            )
            
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
        self.setMinimumWidth(800)
        
        # Charger les polices
        font_dir = os.path.join(os.path.dirname(__file__), "fonts")
        font_files = ["NNDagny-Regular.ttf"]
        
        # Police par défaut au cas où
        default_font = QFont()
        default_font.setPointSize(12)
        self.setFont(default_font)
        
        # Tentative de chargement de la police personnalisée
        for font_file in font_files:
            font_path = os.path.join(font_dir, font_file)
            if os.path.exists(font_path):
                font_id = QFontDatabase.addApplicationFont(font_path)
                if font_id != -1:
                    families = QFontDatabase.applicationFontFamilies(font_id)
                    if families:
                        self.setFont(QFont(families[0], 12))
                        break
        
        # Configuration de la fenêtre
        self.resize(800, 700)  # Taille initiale raisonnable
        self.setMinimumSize(800, 700)  # Taille minimum pour garantir la lisibilité
        
        # Chargement du style
        style_file = os.path.join(os.path.dirname(__file__), "style_nn.qss")
        if os.path.exists(style_file):
            with open(style_file, "r") as f:
                self.setStyleSheet(f.read())
        
        # Centrer la fenêtre sur l'écran
        screen = QApplication.primaryScreen().geometry()
        x = (screen.width() - self.width()) // 2
        y = (screen.height() - self.height()) // 2
        self.move(x, y)
        
        # Politique de redimensionnement
        self.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        
        # Dossier de sortie par défaut
        self.output_dir = os.path.join(os.getcwd(), "story_output")
        os.makedirs(self.output_dir, exist_ok=True)
        
        # Widget principal avec marges
        self.main_widget = QWidget()
        self.setCentralWidget(self.main_widget)
        
        # Création du layout principal
        self.main_layout = QVBoxLayout(self.main_widget)
        self.main_layout.setContentsMargins(24, 24, 24, 24)
        self.main_layout.setSpacing(16)
        
        # Créer l'interface
        self.setup_ui()
        
        # Effet d'opacité initial
        self.opacity_effect = QGraphicsOpacityEffect(self.main_widget)
        self.opacity_effect.setOpacity(0.0)
        self.main_widget.setGraphicsEffect(self.opacity_effect)
        
        # Configuration de l'animation de fade in
        self.fade_animation = QPropertyAnimation(self.opacity_effect, b"opacity")
        self.fade_animation.setDuration(3000)  # 3 secondes
        self.fade_animation.setStartValue(0.0)
        self.fade_animation.setEndValue(1.0)
        self.fade_animation.setEasingCurve(QEasingCurve.Type.InOutCubic)
        
        # Démarrer l'animation après un délai plus court
        QTimer.singleShot(500, self.start_fade_in)
        
        # Afficher la fenêtre
        self.show()

    def start_fade_in(self):
        """Démarre l'animation de fade in."""
        self.fade_animation.start()
    
    def setup_ui(self):
        """Configure l'interface utilisateur."""
        # Initialisation des variables importantes
        self.worker = None
        self.last_generated_file = None
        self.ref_audio_path = None
        
        # En-tête avec logo et titre
        header_layout = QHBoxLayout()
        
        # Logo
        logo_label = QLabel()
        logo_pixmap = QPixmap(os.path.join(os.path.dirname(__file__), "resources/nn_logo.png"))
        # Taille plus petite pour le logo
        logo_container_width = 80
        logo_container_height = 80
        logo_label.setMinimumSize(logo_container_width, logo_container_height)
        # Redimensionner le logo en préservant le ratio avec une meilleure qualité
        scaled_pixmap = logo_pixmap.scaled(logo_container_width, logo_container_height, 
                                         Qt.AspectRatioMode.KeepAspectRatio, 
                                         Qt.TransformationMode.SmoothTransformation)
        logo_label.setPixmap(scaled_pixmap)
        logo_label.setStyleSheet("""
            QLabel {
                background-color: transparent;
                padding: 5px;
                margin-right: 10px;
                margin-top: -40px;
            }
        """)
        header_layout.addWidget(logo_label)
        
        # Titre avec gestion de l'espace
        title_label = QLabel("Générateur de Voix")
        title_label.setStyleSheet("""
            QLabel {
                color: #333333;
                font-size: 24px;
                font-weight: bold;
                padding: 0 20px;
                min-width: 200px;
            }
        """)
        title_label.setSizePolicy(QSizePolicy.Policy.Minimum, QSizePolicy.Policy.Preferred)
        header_layout.addWidget(title_label)
        
        # Ajout d'un spacer flexible à la fin du header
        header_layout.addStretch(1)
        
        self.main_layout.addLayout(header_layout)

        # Séparateur avec animation de couleur
        self.separator = QWidget()
        self.separator.setFixedHeight(2)  # Augmentation de l'épaisseur
        self.separator.setStyleSheet("background-color: #E5E5E5;")
        self.main_layout.addWidget(self.separator)
        
        # Animation du séparateur
        self.separator_animation = QPropertyAnimation(self.separator, b"styleSheet")
        self.separator_animation.setDuration(1000)  # 1 seconde
        self.separator_animation.setLoopCount(-1)  # Boucle infinie
        
        def update_separator_color():
            self.separator_animation.setStartValue("background-color: #E5E5E5;")
            self.separator_animation.setEndValue("background-color: #FF6200;")
            self.separator_animation.start()
            QTimer.singleShot(1000, lambda: self.separator_animation.setStartValue("background-color: #FF6200;"))
            QTimer.singleShot(1000, lambda: self.separator_animation.setEndValue("background-color: #E5E5E5;"))
        
        # Démarrage de l'animation du séparateur
        update_separator_color()
        QTimer.singleShot(2000, update_separator_color)  # Répétition toutes les 2 secondes

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
        self.main_layout.addLayout(output_layout)

        # Options de langue et modèle sur la même ligne
        options_layout = QHBoxLayout()
        
        # Langue
        lang_layout = QHBoxLayout()
        lang_label = QLabel("Langue:")
        self.lang_combo = QComboBox()
        self.lang_combo.addItems(["Anglais", "Français", "Anglais (VCTK)"])
        self.lang_combo.currentIndexChanged.connect(self.on_lang_changed)
        lang_layout.addWidget(lang_label)
        lang_layout.addWidget(self.lang_combo)
        options_layout.addLayout(lang_layout)

        # Espacement entre les options
        options_layout.addSpacing(20)
        
        # Modèle
        model_layout = QHBoxLayout()
        model_label = QLabel("Modèle:")
        self.model_combo = QComboBox()
        self.update_model_list(0)
        model_layout.addWidget(model_label)
        model_layout.addWidget(self.model_combo)
        self.model_combo.currentIndexChanged.connect(self.on_model_changed)
        options_layout.addLayout(model_layout)
        
        # Ajout du layout des options au layout principal
        self.main_layout.addLayout(options_layout)

        # VCTK Speakers
        speaker_layout = QHBoxLayout()
        speaker_label = QLabel("Voix VCTK:")
        self.speaker_combo = QComboBox()
        self.speaker_combo.addItems([
            "VCTK_p232 (homme, bien)",
            "VCTK_p273 (femme, bien)",
            "VCTK_p278 (femme, bien)",
            "VCTK_p279 (homme, bien)",
            "VCTK_p304 (femme)"
        ])
        speaker_layout.addWidget(speaker_label)
        speaker_layout.addWidget(self.speaker_combo)
        self.speaker_combo.setEnabled(False)
        self.main_layout.addLayout(speaker_layout)

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
        self.main_layout.addLayout(ref_audio_layout)

        # CUDA
        cuda_layout = QHBoxLayout()
        self.cuda_check = QCheckBox("Utiliser CUDA (si disponible)")
        self.cuda_check.setChecked(True)
        cuda_layout.addWidget(self.cuda_check)
        self.main_layout.addLayout(cuda_layout)

        # Zone de texte avec taille minimum
        text_label = QLabel("Texte à convertir:")
        self.main_layout.addWidget(text_label)
        self.text_edit = CustomTextEdit()
        self.text_edit.setPlaceholderText("Entrez votre texte ici...")
        self.text_edit.setMinimumHeight(100)
        self.text_edit.setMinimumWidth(400)
        self.text_edit.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)
        self.main_layout.addWidget(self.text_edit)

        # Boutons
        button_layout = QHBoxLayout()
        
        # Bouton Générer
        self.generate_button = QPushButton("Générer")
        self.generate_button.setStyleSheet("""
            QPushButton {
                background-color: #FF6200;
                color: white;
                border: none;
                padding: 8px 16px;
                border-radius: 4px;
                font-weight: bold;
            }
            QPushButton:hover {
                background-color: #FF7D00;
            }
            QPushButton:pressed {
                background-color: #E65A00;
            }
            QPushButton:disabled {
                background-color: #CCCCCC;
            }
        """)
        button_layout.addWidget(self.generate_button)
        
        # Bouton Écouter
        self.play_button = QPushButton("Écouter")
        self.play_button.setEnabled(False)
        self.play_button.setStyleSheet("""
            QPushButton {
                background-color: #444444;
                color: white;
                border: none;
                padding: 8px 16px;
                border-radius: 4px;
                font-weight: bold;
            }
            QPushButton:hover {
                background-color: #666666;
            }
            QPushButton:pressed {
                background-color: #333333;
            }
            QPushButton:disabled {
                background-color: #CCCCCC;
            }
        """)
        button_layout.addWidget(self.play_button)
        
        self.main_layout.addLayout(button_layout)

        # Log avec taille minimum
        log_label = QLabel("Messages:")
        self.main_layout.addWidget(log_label)
        self.log_text = CustomTextEdit()
        self.log_text.setReadOnly(True)
        self.log_text.setMinimumHeight(60)
        self.log_text.setMinimumWidth(400)
        self.log_text.setMaximumHeight(150)
        self.log_text.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Minimum)
        self.log_text.setStyleSheet("background-color: #F5F5F5; border: 1px solid #CCCCCC;")
        self.log_text.setPlaceholderText("Les messages de log apparaîtront ici...")
        self.main_layout.addWidget(self.log_text)

        # Connexions
        output_button.clicked.connect(self.choose_output_dir)
        ref_audio_button.clicked.connect(self.choose_ref_audio)
        self.generate_button.clicked.connect(self.generate_audio)
        self.play_button.clicked.connect(self.play_audio)

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
        """Génère l'audio à partir du texte."""
        # Validation du texte avant génération
        text = self.text_edit.toPlainText().strip()
        if not text:
            QMessageBox.warning(self, "Erreur", "Veuillez entrer du texte à synthétiser")
            return

        # Vérification spéciale pour Speedy-Speech
        is_speedy = "speedy-speech" in str(self.model_combo.currentText()).lower()
        if is_speedy and len(text) < 30:  # Augmentation du seuil minimum
            msg = QMessageBox(self)
            msg.setIcon(QMessageBox.Icon.Warning)
            msg.setText("Attention - Texte court pour Speedy-Speech")
            msg.setInformativeText(
                "Pour de meilleurs résultats avec Speedy-Speech, le texte sera ajusté "
                "avec des pauses et des silences. Cela peut affecter la qualité de la sortie. "
                "\n\nVoulez-vous :\n"
                "1) Continuer avec l'ajustement automatique\n"
                "2) Utiliser un autre modèle (recommandé)\n"
                "3) Ajouter plus de texte"
            )
            msg.setStandardButtons(
                QMessageBox.StandardButton.Yes | 
                QMessageBox.StandardButton.No |
                QMessageBox.StandardButton.Cancel
            )
            msg.setButtonText(QMessageBox.StandardButton.Yes, "Continuer avec ajustement")
            msg.setButtonText(QMessageBox.StandardButton.No, "Changer de modèle")
            msg.setButtonText(QMessageBox.StandardButton.Cancel, "Annuler")
            
            response = msg.exec()
            if response == QMessageBox.StandardButton.No:
                # Changer automatiquement pour VITS ou Tacotron2
                if self.lang_combo.currentIndex() == 0:  # Anglais
                    self.model_combo.setCurrentIndex(0)  # Jenny/Tacotron2
                return
            elif response == QMessageBox.StandardButton.Cancel:
                return

        if not self.text_edit.toPlainText().strip():
            self.log_text.append("Erreur : Veuillez entrer du texte à convertir.")
            return
            
        if not hasattr(self, 'output_dir') or not self.output_dir:
            self.log_text.append("Erreur : Veuillez sélectionner un dossier de sortie.")
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
        
        # Stockage du fichier qui va être généré
        self.last_generated_file = output_file
        
        # Préparation des paramètres
        params = {
            "text": self.text_edit.toPlainText().strip(),
            "output_file": output_file,
            "lang": self.lang_combo.currentIndex(),
            "en_model": self.model_combo.currentIndex(),
            "fr_model": self.model_combo.currentIndex(),
            "speaker": self.get_speaker(),
            "use_cuda": self.cuda_check.isChecked(),
            "model_name": self.model_combo.currentText()
        }
        
        # Ajout des paramètres spécifiques selon le modèle
        if self.model_combo.currentText() == "XTTS v2":
            if not self.ref_audio_path.text() or self.ref_audio_path.text() == "Non sélectionné":
                self.log_text.append("Erreur : Veuillez sélectionner un fichier audio de référence pour XTTS.")
                return
            params["reference_audio"] = self.ref_audio_path.text()
        
        # Désactivation des boutons pendant la génération
        self.generate_button.setEnabled(False)
        self.play_button.setEnabled(False)
        
        # Création et démarrage du worker
        self.worker = TTSWorker(params)
        self.worker.finished.connect(self.generation_finished)
        self.worker.error.connect(self.show_error)
        self.worker.start()

    def show_error(self, error_message):
        """Affiche un message d'erreur."""
        self.log_text.append(f"Erreur : {error_message}")
        self.generation_finished()

    def generation_finished(self):
        """Gère la fin de la génération."""
        # Réactivation du bouton générer
        self.generate_button.setEnabled(True)
        
        # Active le bouton d'écoute si le fichier existe
        if self.last_generated_file and os.path.exists(self.last_generated_file):
            self.play_button.setEnabled(True)
            self.update_log(f"Génération terminée ! Fichier créé : {os.path.basename(self.last_generated_file)}")
        else:
            self.play_button.setEnabled(False)
            self.update_log("Génération terminée !")
            
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
            models = ["tts_models/multilingual/multi-dataset/xtts_v2", "tts_models/fr/css10/vits",
                     "tts_models/multilingual/multi-dataset/your_tts", "tts_models/multilingual/multi-dataset/your_tts"]
        # Modèles VCTK
        else:
            models = ["tts_models/en/vctk/vits"]
        
        return models[model_idx]

    def update_ui_elements(self):
        pass

    def update_log(self, message):
        self.log_text.append(message)

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = MainWindow()
    sys.exit(app.exec())

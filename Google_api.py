from gtts import gTTS
import os

text = "Hello, How are you ?"
language = 'en'
accent = 'com.au'

# Chemin du répertoire de sortie
output_dir = "story_output"

# Vérifier si le répertoire existe, sinon le créer
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# Sauvegarder le fichier audio
tts = gTTS(text=text, lang=language, tld=accent)
tts.save(os.path.join(output_dir, "output.mp3"))    
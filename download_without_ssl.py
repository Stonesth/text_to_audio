import requests

url = "URL_DU_MODELE_TTS"  # Remplacez par l'URL réelle du modèle
response = requests.get(url, verify=False)

with open("tts_models--nl--css10--vits.zip", "wb") as f:
    f.write(response.content)

print("Téléchargement terminé.")
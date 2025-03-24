import requests 
try: 
    response = requests.get('https://httpbin.org/get') 
    print('SUCCESS: La connexion SSL fonctionne!') 
    print(response.json()) 
except Exception as e: 
    print('ERREUR:', e) 

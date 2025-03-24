import requests
import certifi

response = requests.get('https://www.google.com', verify=certifi.where())
print(response.content)
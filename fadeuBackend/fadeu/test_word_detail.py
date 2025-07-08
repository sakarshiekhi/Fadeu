import requests
import json
import sys

# Set the default encoding to UTF-8 for stdout
sys.stdout.reconfigure(encoding='utf-8')

# Make a GET request to the word detail endpoint
response = requests.get('http://localhost:8000/api/words/1/')

# Check if the request was successful
if response.status_code == 200:
    try:
        # Parse the JSON response
        word = response.json()
        
        # Print the response in a more readable format
        print(json.dumps(word, indent=2, ensure_ascii=False))
        
    except json.JSONDecodeError as e:
        print(f"Error decoding JSON: {e}")
        print("Response content:")
        print(response.text)
else:
    print(f"Error: {response.status_code}")
    print(response.text)

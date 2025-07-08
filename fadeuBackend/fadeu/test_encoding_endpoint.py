import requests
import json
import sys

# Set the default encoding to UTF-8 for stdout
sys.stdout.reconfigure(encoding='utf-8')

def safe_print(text):
    """Helper function to safely print text with proper encoding"""
    try:
        print(text)
    except UnicodeEncodeError:
        # If we can't print it normally, print the repr
        print(repr(text))

# Make a GET request to the test encoding endpoint
response = requests.get('http://localhost:8000/api/test-encoding/')

# Check if the request was successful
if response.status_code == 200:
    try:
        # Parse the JSON response
        data = response.json()
        
        # Print the response in a more readable format
        safe_print(json.dumps(data, indent=2, ensure_ascii=False))
        
    except json.JSONDecodeError as e:
        safe_print(f"Error decoding JSON: {e}")
        safe_print("Response content:")
        safe_print(response.text)
else:
    safe_print(f"Error: {response.status_code}")
    safe_print(response.text)

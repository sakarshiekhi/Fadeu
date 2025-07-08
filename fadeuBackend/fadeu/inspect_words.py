import sqlite3
import json
import sys
from pathlib import Path

# Set the default encoding to UTF-8 for stdout
sys.stdout.reconfigure(encoding='utf-8')

# Path to the SQLite database
db_path = Path(__file__).parent / 'dictionary.db'

# Connect to the SQLite database
conn = sqlite3.connect(str(db_path))
conn.row_factory = sqlite3.Row  # This enables column access by name
cursor = conn.cursor()

def safe_print(text):
    """Helper function to safely print text with proper encoding"""
    try:
        print(text)
    except UnicodeEncodeError:
        # If we can't print it normally, print the repr
        print(repr(text))

# Get the schema of the words table
cursor.execute("PRAGMA table_info(words)")
columns = cursor.fetchall()
safe_print("\n=== Database Schema ===")
for col in columns:
    safe_print(f"{col['name']}: {col['type']} {'(PRIMARY KEY)' if col['pk'] else ''}")

# Get the first few rows to see the data
safe_print("\n=== First 5 Rows ===")
cursor.execute("SELECT * FROM words LIMIT 5")
rows = cursor.fetchall()

for row in rows:
    safe_print("\nRow:")
    for key in row.keys():
        value = row[key]
        # Truncate long values for display
        if isinstance(value, str) and len(value) > 50:
            value = value[:50] + "..."
        safe_print(f"  {key}: {value}")

# Check for any encoding issues
safe_print("\n=== Checking for encoding issues ===")
cursor.execute("SELECT id, german, persian FROM words LIMIT 5")
for row in cursor.fetchall():
    safe_print(f"\nID: {row['id']}")
    safe_print(f"German (raw): {row['german']!r}")
    safe_print(f"Persian (raw): {row['persian']!r}")
    
    # Print hex representation to check for encoding issues
    if row['persian']:
        safe_print(f"Persian (hex): {' '.join(f'{b:02x}' for b in row['persian'].encode('utf-8'))}")
    if row['german']:
        safe_print(f"German (hex): {' '.join(f'{b:02x}' for b in row['german'].encode('utf-8'))}")

# Check for any rows with potential encoding issues
safe_print("\n=== Checking for encoding issues in the database ===")
cursor.execute("""
    SELECT id, german, persian 
    FROM words 
    WHERE persian LIKE '%?%' 
       OR german LIKE '%?%'
    LIMIT 10
""")
problem_rows = cursor.fetchall()
if problem_rows:
    safe_print("\nFound potential encoding issues in these rows:")
    for row in problem_rows:
        safe_print(f"\nID: {row['id']}")
        safe_print(f"German: {row['german']!r}")
        safe_print(f"Persian: {row['persian']!r}")
else:
    safe_print("No obvious encoding issues found in the database.")

# Close the connection
conn.close()

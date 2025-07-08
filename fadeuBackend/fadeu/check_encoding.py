import sqlite3
import sys

def check_encoding():
    try:
        # Connect to the SQLite database
        conn = sqlite3.connect('dictionary.db')
        conn.text_factory = lambda x: x.decode('utf-8', errors='replace')
        cursor = conn.cursor()
        
        # Get sample data
        cursor.execute("SELECT german, persian FROM words WHERE german LIKE '%Haus%' LIMIT 5")
        results = cursor.fetchall()
        
        # Write output to a file to avoid console encoding issues
        with open('encoding_check.txt', 'w', encoding='utf-8') as f:
            f.write("Sample data from SQLite database:\n")
            for german, persian in results:
                f.write(f"\nGerman: {german}\n")
                f.write(f"Persian (raw): {persian}\n")
                
                # Get raw bytes
                try:
                    raw_bytes = persian.encode('latin1')
                    f.write(f"Persian (bytes): {raw_bytes}\n")
                except Exception as e:
                    f.write(f"Error getting bytes: {str(e)}\n")
                
                # Try different encodings
                for enc in ['utf-8', 'utf-16', 'cp1256', 'latin1']:
                    try:
                        if isinstance(persian, str):
                            # If it's already a string, try to encode as latin1 then decode
                            decoded = persian.encode('latin1').decode(enc)
                        else:
                            # If it's bytes, try to decode directly
                            decoded = persian.decode(enc)
                        f.write(f"Decoded with {enc}: {decoded}\n")
                    except Exception as e:
                        f.write(f"Failed to decode with {enc}: {str(e)}\n")
                
                f.write("-" * 50 + "\n")
            
            print("Check the file 'encoding_check.txt' for the results.")
            
    except Exception as e:
        print(f"Error: {str(e)}")
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    check_encoding()

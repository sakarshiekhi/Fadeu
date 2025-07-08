import sqlite3
import os

def check_schema():
    db_path = os.path.join(os.path.dirname(__file__), 'dictionary.db')
    print(f"Checking database schema at: {db_path}")
    
    if not os.path.exists(db_path):
        print("Error: Database file not found!")
        return
        
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Get table info
        cursor.execute("PRAGMA table_info(words)")
        columns = cursor.fetchall()
        
        print("\nColumns in 'words' table:")
        for col in columns:
            print(f"- {col[1]} ({col[2]})")
            
        # Get sample data
        cursor.execute("SELECT * FROM words LIMIT 1")
        row = cursor.fetchone()
        
        if row:
            print("\nSample row data:")
            for i, col in enumerate(columns):
                print(f"{col[1]}: {row[i]}")
        
    except sqlite3.Error as e:
        print(f"Database error: {e}")
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    check_schema()

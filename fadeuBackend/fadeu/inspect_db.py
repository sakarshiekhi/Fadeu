import os
import django
import pymysql
from django.conf import settings

def inspect_database():
    # Configure Django settings
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "fadeu.settings")
    django.setup()
    
    # Get database settings
    db_settings = settings.DATABASES['default']
    
    # Connect to the database
    connection = pymysql.connect(
        host=db_settings['HOST'],
        user=db_settings['USER'],
        password=db_settings['PASSWORD'],
        database=db_settings['NAME'],
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )
    
    try:
        with connection.cursor() as cursor:
            # List all tables
            cursor.execute("SHOW TABLES")
            tables = cursor.fetchall()
            print("\nTables in the database:")
            for table in tables:
                print(f"- {list(table.values())[0]}")
            
            # Use the words table directly
            word_table = 'words'
            print(f"\nUsing table: {word_table}")
            
            # Get column information
            cursor.execute(f"SHOW FULL COLUMNS FROM {word_table}")
            columns = cursor.fetchall()
            print("\nColumns in accounts_word table:")
            for col in columns:
                print(f"{col['Field']}: {col['Type']} {col['Collation'] or ''}")
            
            # Get sample data
            cursor.execute(f"SELECT id, german, persian, example, example_persian FROM {word_table} WHERE persian IS NOT NULL LIMIT 5")
            rows = cursor.fetchall()
            
            # Create a file to write the output
            with open('database_inspect_output.txt', 'w', encoding='utf-8') as f:
                f.write("Sample data from database:\n\n")
                
                for row in rows:
                    f.write(f"\nID: {row['id']}\n")
                    f.write(f"German: {row['german']}\n")
                    f.write(f"Persian (raw): {row['persian']}\n")
                    f.write(f"Persian (bytes): {row['persian'].encode('utf-8')}\n")
                    f.write(f"Example: {row['example']}\n")
                    f.write(f"Example Persian: {row['example_persian']}\n")
                    f.write("-" * 80 + "\n")
            
            print("\nInspection complete. Check 'database_inspect_output.txt' for the results.")
    
    finally:
        connection.close()

if __name__ == "__main__":
    inspect_database()

import os
import shutil
from django.db import connection

def reset_migrations():
    # Delete migration files
    for app in ['accounts', 'users', 'words']:
        migrations_dir = os.path.join(app, 'migrations')
        if os.path.exists(migrations_dir):
            for filename in os.listdir(migrations_dir):
                if filename != '__init__.py' and filename != '__pycache__':
                    file_path = os.path.join(migrations_dir, filename)
                    try:
                        if os.path.isfile(file_path):
                            os.unlink(file_path)
                        elif os.path.isdir(file_path):
                            shutil.rmtree(file_path)
                    except Exception as e:
                        print(f'Failed to delete {file_path}. Reason: {e}')
    
    # Delete SQLite database if it exists
    if os.path.exists('db.sqlite3'):
        os.remove('db.sqlite3')
    
    # Delete MySQL database
    with connection.cursor() as cursor:
        cursor.execute("DROP DATABASE IF EXISTS fadeu_db;")
        cursor.execute("CREATE DATABASE fadeu_db;")
    
    print("Migrations and database have been reset. Please run:\n")
    print("python manage.py makemigrations")
    print("python manage.py migrate")

if __name__ == "__main__":
    reset_migrations()

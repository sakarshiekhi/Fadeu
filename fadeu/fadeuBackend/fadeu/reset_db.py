import os
import sys
import django
from django.conf import settings

def reset_database():
    # Delete the SQLite database if it exists
    if os.path.exists('db.sqlite3'):
        os.remove('db.sqlite3')
    
    # Delete all migration files except __init__.py
    for root, dirs, files in os.walk('.'):
        if 'migrations' in dirs:
            migrations_dir = os.path.join(root, 'migrations')
            for item in os.listdir(migrations_dir):
                if item != '__init__.py' and item != '__pycache__':
                    path = os.path.join(migrations_dir, item)
                    try:
                        if os.path.isfile(path):
                            os.unlink(path)
                        elif os.path.isdir(path):
                            import shutil
                            shutil.rmtree(path)
                    except Exception as e:
                        print(f'Error deleting {path}: {e}')
    
    print("Database and migrations have been reset.")
    print("Please run the following commands:")
    print("1. python manage.py makemigrations")
    print("2. python manage.py migrate")
    print("3. python manage.py createsuperuser")

if __name__ == "__main__":
    reset_database()

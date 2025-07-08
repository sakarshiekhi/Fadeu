import os
import shutil
import subprocess

def reset_migrations():
    # Delete migration files
    for app in ['accounts', 'users', 'words']:
        migrations_dir = os.path.join(app, 'migrations')
        if os.path.exists(migrations_dir):
            print(f"Cleaning migrations in {migrations_dir}")
            for filename in os.listdir(migrations_dir):
                if filename not in ['__init__.py', '__pycache__']:
                    file_path = os.path.join(migrations_dir, filename)
                    try:
                        if os.path.isfile(file_path):
                            os.unlink(file_path)
                            print(f"Deleted file: {file_path}")
                        elif os.path.isdir(file_path):
                            shutil.rmtree(file_path)
                            print(f"Deleted directory: {file_path}")
                    except Exception as e:
                        print(f'Failed to delete {file_path}. Reason: {e}')
    
    print("\nMigrations have been reset. Please run the following commands:")
    print("1. python manage.py makemigrations")
    print("2. python manage.py migrate")
    print("\nNote: You may need to manually drop and recreate your database.")

if __name__ == "__main__":
    reset_migrations()

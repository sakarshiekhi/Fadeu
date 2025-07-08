import os
import shutil

def clean_migrations():
    # List of apps to clean
    apps = ['accounts', 'users', 'words']
    
    for app in apps:
        migrations_dir = os.path.join(app, 'migrations')
        if os.path.exists(migrations_dir):
            print(f"Cleaning {migrations_dir}")
            for filename in os.listdir(migrations_dir):
                if filename != '__init__.py' and filename != '__pycache__':
                    file_path = os.path.join(migrations_dir, filename)
                    try:
                        if os.path.isfile(file_path) or os.path.islink(file_path):
                            os.unlink(file_path)
                            print(f"Deleted file: {file_path}")
                        elif os.path.isdir(file_path):
                            shutil.rmtree(file_path)
                            print(f"Deleted directory: {file_path}")
                    except Exception as e:
                        print(f'Failed to delete {file_path}. Reason: {e}')

if __name__ == "__main__":
    clean_migrations()
    print("\nMigration cleanup complete. Please run the following commands:")
    print("1. python manage.py makemigrations")
    print("2. python manage.py migrate")
    print("3. python manage.py createsuperuser")

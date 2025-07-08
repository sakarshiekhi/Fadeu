import os
import sys

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'fadeu.settings')
import django
django.setup()

# Now we can import Django settings
from django.conf import settings

print("\n=== Database Configuration ===")
print(f"DATABASES: {settings.DATABASES}")
print(f"DATABASE_ROUTERS: {getattr(settings, 'DATABASE_ROUTERS', None)}")
print("===========================\n")

# Try to access the dictionary database
from django.db import connections

try:
    print("\n=== Testing Database Connections ===")
    print("Available connections:", list(connections.databases.keys()))
    
    # Test default database
    with connections['default'].cursor() as cursor:
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = [row[0] for row in cursor.fetchall()]
        print(f"\nTables in 'default' database: {tables}")
    
    # Test dictionary database if it exists
    if 'dictionary' in connections.databases:
        with connections['dictionary'].cursor() as cursor:
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            tables = [row[0] for row in cursor.fetchall()]
            print(f"\nTables in 'dictionary' database: {tables}")
    else:
        print("\n'dictionary' database not found in connections")
        
except Exception as e:
    print(f"\nError: {e}")

print("\n=== Settings Module ===")
print(f"DJANGO_SETTINGS_MODULE: {os.environ.get('DJANGO_SETTINGS_MODULE')}")
print("=====================\n")

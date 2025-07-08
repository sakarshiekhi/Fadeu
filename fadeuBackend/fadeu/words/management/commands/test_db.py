from django.core.management.base import BaseCommand
from django.db import connections

class Command(BaseCommand):
    help = 'Test database connections'

    def handle(self, *args, **options):
        # Test default database
        try:
            with connections['default'].cursor() as cursor:
                cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
                tables = cursor.fetchall()
                self.stdout.write(self.style.SUCCESS(f"Default database tables: {tables}"))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Error accessing default database: {e}"))
        
        # Test dictionary database
        try:
            with connections['dictionary_db'].cursor() as cursor:
                cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
                tables = cursor.fetchall()
                self.stdout.write(self.style.SUCCESS(f"Dictionary database tables: {tables}"))
                
                # Try to read from words_word table
                cursor.execute("SELECT COUNT(*) FROM words_word")
                count = cursor.fetchone()[0]
                self.stdout.write(self.style.SUCCESS(f"Found {count} words in dictionary database"))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Error accessing dictionary database: {e}"))

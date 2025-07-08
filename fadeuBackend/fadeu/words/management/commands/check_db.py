from django.core.management.base import BaseCommand
from django.db import connections

class Command(BaseCommand):
    help = 'Check database connections and routing'

    def handle(self, *args, **options):
        # Print available database connections
        self.stdout.write("Available database connections:")
        for db_name in connections:
            self.stdout.write(f"- {db_name}")
        
        # Test default database
        self.stdout.write("\nTesting default database:")
        try:
            with connections['default'].cursor() as cursor:
                cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
                tables = [row[0] for row in cursor.fetchall()]
                self.stdout.write(f"Tables in default database: {tables}")
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Error accessing default database: {e}"))
        
        # Test dictionary database
        self.stdout.write("\nTesting dictionary database:")
        try:
            with connections['dictionary'].cursor() as cursor:
                cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
                tables = [row[0] for row in cursor.fetchall()]
                self.stdout.write(f"Tables in dictionary database: {tables}")
                
                cursor.execute("SELECT COUNT(*) FROM words_word")
                count = cursor.fetchone()[0]
                self.stdout.write(f"Number of words in dictionary: {count}")
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Error accessing dictionary database: {e}"))
        
        # Test database router
        from django.apps import apps
        from words.models import Word
        
        self.stdout.write("\nTesting database router:")
        word_model = apps.get_model('words', 'Word')
        self.stdout.write(f"Word model: {word_model.__module__}.{word_model.__name__}")
        
        # Test database for reading
        from django.db import router
        db_for_read = router.db_for_read(word_model)
        self.stdout.write(f"Database for reading Word model: {db_for_read}")
        
        # Try to get a word
        try:
            word = word_model.objects.using(db_for_read).first()
            if word:
                self.stdout.write(f"First word: {word.word} - {word.translation}")
            else:
                self.stdout.write("No words found in the database")
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"Error fetching word: {e}"))

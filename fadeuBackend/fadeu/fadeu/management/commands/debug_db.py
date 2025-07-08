from django.core.management.base import BaseCommand
from django.conf import settings
from django.db import connections
import sys

class Command(BaseCommand):
    help = 'Debug database configuration and connections'

    def handle(self, *args, **options):
        self.stdout.write("=== Debugging Database Configuration ===\n")
        
        # 1. Print DATABASES setting
        self.stdout.write("1. DATABASES setting:")
        for db_name, config in settings.DATABASES.items():
            self.stdout.write(f"   {db_name}: {config['ENGINE']} - {config['NAME']}")
        
        # 2. Print database routers
        self.stdout.write("\n2. DATABASE_ROUTERS:")
        for router in getattr(settings, 'DATABASE_ROUTERS', []):
            self.stdout.write(f"   - {router}")
        
        # 3. Print installed apps
        self.stdout.write("\n3. INSTALLED_APPS:")
        for app in settings.INSTALLED_APPS:
            self.stdout.write(f"   - {app}")
        
        # 4. Test database connections
        self.stdout.write("\n4. Testing database connections:")
        for db_name in settings.DATABASES:
            try:
                with connections[db_name].cursor() as cursor:
                    cursor.execute("SELECT 'success'")
                    result = cursor.fetchone()
                    self.stdout.write(self.style.SUCCESS(f"   {db_name}: Connection successful ({result[0] if result else 'No result'})"))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"   {db_name}: Connection failed - {str(e)}"))
        
        # 5. Check if the router is being used
        self.stdout.write("\n5. Checking database router usage:")
        from words.models import Word
        from django.db import router as db_router
        
        router = db_router.routers[0] if db_router.routers else None
        if router:
            self.stdout.write(f"   Using router: {router.__class__.__name__}")
            db_for_read = router.db_for_read(Word)
            self.stdout.write(f"   db_for_read(Word): {db_for_read}")
            
            try:
                word = Word.objects.using(db_for_read).first()
                self.stdout.write(self.style.SUCCESS(f"   Successfully queried Word model: {word}"))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"   Error querying Word model: {str(e)}"))
        else:
            self.stdout.write("   No database routers found")
        
        self.stdout.write("\n=== Debugging Complete ===")

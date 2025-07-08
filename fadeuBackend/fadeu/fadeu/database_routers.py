class DictionaryRouter:
    """
    A router to control all database operations on models in the
    words application.
    """
    def db_for_read(self, model, **hints):
        """
        Attempts to read Word model go to dictionary database (SQLite).
        All other models go to default database (MySQL).
        """
        # Debug print to see which models are being accessed
        print(f"DB Read - App: {model._meta.app_label}, Model: {model._meta.model_name}, Table: {model._meta.db_table}")
        
        if model._meta.app_label == 'words':
            if model._meta.model_name == 'word':
                print("Routing Word model to 'dictionary' database")
                return 'dictionary'  # Read Word model from SQLite
            # Ensure SavedWord and other models use the default database
            print(f"Routing {model._meta.model_name} to 'default' database")
            return 'default'
        return 'default'  # All other models from MySQL

    def db_for_write(self, model, **hints):
        """
        Attempts to write Word model are not allowed (read-only).
        UserWordProgress and SavedWord can be written to default database (MySQL).
        """
        # Debug print to see which models are being written to
        print(f"DB Write - App: {model._meta.app_label}, Model: {model._meta.model_name}")
        
        if model._meta.app_label == 'words':
            if model._meta.model_name == 'word':
                print("Preventing write to Word model (read-only)")
                return None  # Prevent writes to Word model (read-only)
            # Allow writes to SavedWord and other models in the default database
            print(f"Allowing write to {model._meta.model_name} in 'default' database")
            return 'default'
        return 'default'  # All other models to MySQL

    def allow_relation(self, obj1, obj2, **hints):
        """
        Allow relations between objects if they're both in the same database.
        """
        # Allow relations between objects in the same database
        if obj1._state.db == obj2._state.db:
            return True
        
        # Allow relations between User and UserWordProgress across databases
        user_model = obj1 if obj1._meta.model_name == 'user' else (obj2 if obj2._meta.model_name == 'user' else None)
        progress_model = obj1 if obj1._meta.model_name == 'userwordprogress' else (obj2 if obj2._meta.model_name == 'userwordprogress' else None)
        
        if user_model and progress_model:
            return True
            
        return None

    def allow_migrate(self, db, app_label, model_name=None, **hints):
        """
        Only allow migrations for the 'default' database (MySQL).
        The 'dictionary' database (SQLite) is read-only and should not be migrated.
        """
        # Debug print for migration attempts
        print(f"Migration - DB: {db}, App: {app_label}, Model: {model_name}")
        
        if db == 'dictionary':
            return False  # Never migrate the dictionary database
        
        # Only allow migrations for the 'words' app in the default database
        if app_label == 'words':
            if model_name == 'userwordprogress':
                return db == 'default'
            return False  # Don't create tables for Word model in default DB
            
        # Allow all other migrations in the default database
        return db == 'default'

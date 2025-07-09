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
                print("Routing Word model to 'dictionary' database (SQLite)")
                return 'dictionary'  # Read Word model from SQLite
            print(f"Routing {model._meta.model_name} model to 'default' database (MySQL)")
            return 'default'  # All other models in words app from MySQL
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
            print(f"Allowing write to {model._meta.model_name} in 'default' database (MySQL)")
            return 'default'  # Allow writes to other models in words app (MySQL)
        return 'default'  # All other models to MySQL

    def allow_relation(self, obj1, obj2, **hints):
        """
        Allow relations between objects if they're both in the same database
        or if they're related through a foreign key relationship that crosses databases.
        """
        # Allow relations between objects in the same database
        if obj1._state.db == obj2._state.db:
            return True
            
        # Get model names for easier comparison
        model_names = {obj1._meta.model_name, obj2._meta.model_name}
        
        # Allow relations between User and UserWordProgress/SavedWord across databases
        if 'user' in model_names and ('userwordprogress' in model_names or 'savedword' in model_names):
            print(f"Allowing relation between {obj1._meta.model_name} and {obj2._meta.model_name}")
            return True
            
        # Allow relations between SavedWord and Word across databases
        if 'savedword' in model_names and 'word' in model_names:
            print(f"Allowing relation between SavedWord and Word across databases")
            return True
            
        # No opinion on other cross-database relations
        print(f"No opinion on relation between {obj1._meta.model_name} and {obj2._meta.model_name}")
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
            # Allow migrations for UserWordProgress and SavedWord models in default DB
            if model_name in ['userwordprogress', 'savedword']:
                return db == 'default'
            return False  # Don't create tables for other models in default DB
            
        # Allow all other migrations in the default database
        return db == 'default'

"""
Django settings for fadeu project with SQLite database.
"""
from .settings import *

# Database
# https://docs.djangoproject.com/en/5.2/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    },
    'dictionary': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': str(BASE_DIR / 'dictionary.db'),
        'OPTIONS': {
            'timeout': 20,
        }
    }
}

# Database router for handling multiple databases
DATABASE_ROUTERS = ['fadeu.database_routers.DictionaryRouter']

# Database routing rules
DATABASE_APPS_MAPPING = {
    'words.word': 'dictionary',  # Word model uses dictionary SQLite
    'words.userwordprogress': 'default',  # User data uses default SQLite
}

# Default database for apps not in DATABASE_APPS_MAPPING
DATABASE_DEFAULT = 'default'

"""
WSGI config for fabeu project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/5.2/howto/deployment/wsgi/
"""

import os

from django.core.wsgi import get_wsgi_application

<<<<<<< HEAD
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'fadeu.settings')
=======
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'fabeu.settings')
>>>>>>> 69f1c219ac6270f866a57c3a1743b32fccc23d7d

application = get_wsgi_application()

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'fadeu.settings')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

try:
    # Check if superuser already exists
    if not User.objects.filter(email='admin@fadeu.com').exists():
        User.objects.create_superuser(
            email='admin@fadeu.com',
            password='admin123',
            first_name='Admin',
            last_name='User',
            is_active=True,
            is_staff=True
        )
        print('Superuser created successfully!')
    else:
        print('Superuser already exists.')
except Exception as e:
    print(f'Error creating superuser: {e}')

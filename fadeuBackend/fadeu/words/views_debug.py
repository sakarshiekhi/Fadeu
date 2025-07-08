from django.http import JsonResponse
from django.conf import settings

def debug_settings(request):
    """View to debug database settings"""
    response_data = {
        'DATABASES': {
            name: {
                'ENGINE': config['ENGINE'],
                'NAME': str(config['NAME']),
                'HOST': config.get('HOST'),
                'PORT': config.get('PORT'),
                'USER': config.get('USER'),
            }
            for name, config in settings.DATABASES.items()
        },
        'DATABASE_ROUTERS': settings.DATABASE_ROUTERS,
        'INSTALLED_APPS': settings.INSTALLED_APPS,
    }
    
    # Try to import the router
    try:
        from fadeu.database_routers import DictionaryRouter
        response_data['router_imported'] = True
    except ImportError as e:
        response_data['router_import_error'] = str(e)
    
    return JsonResponse(response_data)

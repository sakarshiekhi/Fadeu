from django.http import JsonResponse
from django.views.decorators.http import require_GET
from django.db import connections
import json

@require_GET
def test_connection(request):
    """Test database connection and word retrieval"""
    try:
        # Test default database connection
        with connections['default'].cursor() as cursor:
            cursor.execute("SELECT 1")
            default_db_ok = cursor.fetchone()[0] == 1
            
        # Test dictionary database connection
        with connections['dictionary'].cursor() as cursor:
            cursor.execute("SELECT 1")
            dict_db_ok = cursor.fetchone()[0] == 1
            
            # Try to get word count
            cursor.execute("SELECT COUNT(*) FROM words")
            word_count = cursor.fetchone()[0]
            
            # Get sample words
            cursor.execute("SELECT * FROM words LIMIT 5")
            columns = [col[0] for col in cursor.description]
            sample_words = [
                dict(zip(columns, row)) 
                for row in cursor.fetchall()
            ]
            
        return JsonResponse({
            'status': 'success',
            'databases': {
                'default': 'connected' if default_db_ok else 'error',
                'dictionary': 'connected' if dict_db_ok else 'error',
            },
            'word_count': word_count,
            'sample_words': sample_words,
        })
        
    except Exception as e:
        return JsonResponse({
            'status': 'error',
            'message': str(e),
            'databases': {
                'default': 'error',
                'dictionary': 'error',
            },
        }, status=500)

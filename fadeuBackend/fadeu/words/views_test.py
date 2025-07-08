from django.http import JsonResponse
from django.db import connections

def test_db_connection(request):
    results = {}
    
    # Test default database
    try:
        with connections['default'].cursor() as cursor:
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            results['default_tables'] = cursor.fetchall()
    except Exception as e:
        results['default_error'] = str(e)
    
    # Test dictionary database
    try:
        with connections['dictionary'].cursor() as cursor:  # Updated to use 'dictionary' instead of 'dictionary_db'
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
            results['dictionary_tables'] = cursor.fetchall()
            
            # Try to read from words_word table
            cursor.execute("SELECT COUNT(*) FROM words_word")
            results['word_count'] = cursor.fetchone()[0]
    except Exception as e:
        results['dictionary_error'] = str(e)
    
    return JsonResponse(results)

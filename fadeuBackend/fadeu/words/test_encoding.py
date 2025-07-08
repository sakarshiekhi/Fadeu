from django.http import JsonResponse
from django.views import View
from django.db import connection
from .models import Word
import json

class TestEncodingView(View):
    """
    A test view to verify text encoding is working correctly
    """
    def get(self, request, *args, **kwargs):
        # Get the first 5 words
        words = Word.objects.all()[:5]
        
        # Get raw database connection
        with connection.cursor() as cursor:
            cursor.execute("SELECT id, german, persian FROM words LIMIT 5")
            raw_words = cursor.fetchall()
        
        # Prepare the response data
        response_data = {
            'status': 'success',
            'django_orm': [],
            'raw_sql': []
        }
        
        # Test with Django ORM
        for word in words:
            word_data = {
                'id': word.id,
                'german': word.german,
                'english': word.english,
                'persian': word.persian,
                'german_type': str(type(word.german)),
                'persian_type': str(type(word.persian)),
                'german_repr': repr(word.german),
                'persian_repr': repr(word.persian),
                'german_hex': ' '.join(f'{b:02x}' for b in word.german.encode('utf-8')) if word.german else '',
                'persian_hex': ' '.join(f'{b:02x}' for b in word.persian.encode('utf-8')) if word.persian else ''
            }
            response_data['django_orm'].append(word_data)
        
        # Test with raw SQL
        for row in raw_words:
            word_id, german, persian = row
            word_data = {
                'id': word_id,
                'german': german,
                'persian': persian,
                'german_type': str(type(german)) if german is not None else 'None',
                'persian_type': str(type(persian)) if persian is not None else 'None',
                'german_repr': repr(german) if german is not None else 'None',
                'persian_repr': repr(persian) if persian is not None else 'None',
                'german_hex': ' '.join(f'{b:02x}' for b in german.encode('utf-8')) if german else '',
                'persian_hex': ' '.join(f'{b:02x}' for b in persian.encode('utf-8')) if persian else ''
            }
            response_data['raw_sql'].append(word_data)
        
        # Set content type with charset
        response = JsonResponse(response_data, json_dumps_params={'ensure_ascii': False, 'indent': 2})
        response['Content-Type'] = 'application/json; charset=utf-8'
        return response

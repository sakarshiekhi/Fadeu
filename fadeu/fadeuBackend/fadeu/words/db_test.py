from django.http import JsonResponse
from django.views import View
from django.db import connections
import sqlite3
import json

class DatabaseTestView(View):
    """
    A view to test database connection and encoding
    """
    def get(self, request, *args, **kwargs):
        response_data = {
            'status': 'success',
            'database': {},
            'raw_test': {}
        }
        
        # Test Django database connection
        try:
            with connections['dictionary'].cursor() as cursor:
                cursor.execute("SELECT sqlite_version()")
                version = cursor.fetchone()[0]
                
                # Check database encoding
                cursor.execute("PRAGMA encoding")
                encoding = cursor.fetchone()[0]
                
                # Check table info
                cursor.execute("PRAGMA table_info(words)")
                columns = [dict(zip(['cid', 'name', 'type', 'notnull', 'dflt_value', 'pk'], row)) 
                          for row in cursor.fetchall()]
                
                # Get sample data
                cursor.execute("SELECT id, german, persian FROM words LIMIT 1")
                sample_row = cursor.fetchone()
                
                response_data['database'].update({
                    'sqlite_version': version,
                    'encoding': encoding,
                    'columns': columns,
                    'sample_row': {
                        'id': sample_row[0],
                        'german': sample_row[1],
                        'persian': sample_row[2],
                        'german_type': str(type(sample_row[1])),
                        'persian_type': str(type(sample_row[2])),
                        'german_hex': ' '.join(f'{b:02x}' for b in sample_row[1].encode('utf-8')) if sample_row[1] else '',
                        'persian_hex': ' '.join(f'{b:02x}' for b in sample_row[2].encode('utf-8')) if sample_row[2] else ''
                    } if sample_row else None
                })
                
        except Exception as e:
            response_data['database']['error'] = str(e)
        
        # Test direct SQLite connection
        try:
            db_path = connections['dictionary'].settings_dict['NAME']
            conn = sqlite3.connect(db_path)
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            
            # Get sample data
            cursor.execute("SELECT id, german, persian FROM words LIMIT 1")
            row = cursor.fetchone()
            
            if row:
                response_data['raw_test'] = {
                    'id': row['id'],
                    'german': row['german'],
                    'persian': row['persian'],
                    'german_type': str(type(row['german'])),
                    'persian_type': str(type(row['persian'])),
                    'german_hex': ' '.join(f'{b:02x}' for b in row['german'].encode('utf-8')),
                    'persian_hex': ' '.join(f'{b:02x}' for b in row['persian'].encode('utf-8'))
                }
            
            conn.close()
            
        except Exception as e:
            response_data['raw_test']['error'] = str(e)
        
        # Set content type with charset
        response = JsonResponse(response_data, json_dumps_params={'ensure_ascii': False, 'indent': 2})
        response['Content-Type'] = 'application/json; charset=utf-8'
        return response

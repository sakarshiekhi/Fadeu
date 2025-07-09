import json
from django.core.management.base import BaseCommand
from words.models import Word

class Command(BaseCommand):
    help = 'Load initial set of words into the database'

    def handle(self, *args, **options):
        words_data = [
            {"word": "hello", "translation": "سلام", "level": "A1", "example": "Hello! How are you?"},
            {"word": "goodbye", "translation": "خداحافظ", "level": "A1", "example": "Goodbye! See you later!"},
            {"word": "thank you", "translation": "متشکرم", "level": "A1", "example": "Thank you for your help!"},
            {"word": "please", "translation": "لطفاً", "level": "A1", "example": "Please sit down."},
            {"word": "sorry", "translation": "ببخشید", "level": "A1", "example": "I'm sorry I'm late."},
            
            {"word": "book", "translation": "کتاب", "level": "A1", "example": "I'm reading an interesting book."},
            {"word": "pen", "translation": "خودکار", "level": "A1", "example": "Can I borrow your pen?"},
            {"word": "teacher", "translation": "معلم", "level": "A1", "example": "Our teacher is very kind."},
            
            {"word": "beautiful", "translation": "زیبا", "level": "A2", "example": "What a beautiful day!"},
            {"word": "difficult", "translation": "سخت", "level": "A2", "example": "This exercise is very difficult."},
            
            {"word": "accomplish", "translation": "انجام دادن", "level": "B1", "example": "We need to accomplish our goals."},
            {"word": "challenge", "translation": "چالش", "level": "B1", "example": "This project is a big challenge for us."},
        ]
        
        created_count = 0
        for word_data in words_data:
            _, created = Word.objects.get_or_create(
                word=word_data['word'].lower(),
                defaults={
                    'translation': word_data['translation'],
                    'level': word_data['level'],
                    'example': word_data['example']
                }
            )
            if created:
                created_count += 1
                
        self.stdout.write(self.style.SUCCESS(f'Successfully loaded {created_count} words into the database.'))

from django.db import models
from django.conf import settings
import json

# Use the custom User model from the users app
User = settings.AUTH_USER_MODEL

class Word(models.Model):
    LEVEL_CHOICES = [
        ('A1', 'A1 (Beginner)'),
        ('A2', 'A2 (Elementary)'),
        ('B1', 'B1 (Intermediate)'),
        ('B2', 'B2 (Upper-Intermediate)'),
        ('C1', 'C1 (Advanced)'),
        ('C2', 'C2 (Proficiency)'),
    ]
    
    id = models.AutoField(primary_key=True)
    german = models.TextField()
    english = models.TextField()
    persian = models.TextField()
    level = models.CharField(max_length=2, choices=LEVEL_CHOICES, default='A1')
    example = models.TextField(blank=True, null=True)
    example_english = models.TextField(blank=True, null=True)
    example_persian = models.TextField(blank=True, null=True)
    part_of_speech = models.CharField(max_length=50, blank=True, null=True)
    article = models.CharField(max_length=10, blank=True, null=True)  # der, die, das
    plural = models.CharField(max_length=100, blank=True, null=True)
    cases = models.TextField(blank=True, null=True)  # JSON string for different cases
    tenses = models.TextField(blank=True, null=True)  # JSON string for verb conjugations
    audio_filename = models.CharField(max_length=255, blank=True, null=True)
    
    class Meta:
        db_table = 'words'  # Explicitly set the table name
        
    def __str__(self):
        return f"{self.german} ({self.english})"
    
    def get_cases(self):
        """Parse and return the cases as a dictionary."""
        if self.cases:
            try:
                return json.loads(self.cases)
            except json.JSONDecodeError:
                return {}
        return {}
    
    def get_tenses(self):
        """Parse and return the tenses as a dictionary."""
        if self.tenses:
            try:
                return json.loads(self.tenses)
            except json.JSONDecodeError:
                return {}
        return {}
    
    def to_dict(self, include_examples=True, include_advanced=False):
        """Convert the word to a dictionary with all fields."""
        data = {
            'id': self.id,
            'german': self.german,
            'english': self.english,
            'persian': self.persian,
            'level': self.level,
            'part_of_speech': self.part_of_speech,
            'article': self.article,
        }
        
        if include_examples:
            data.update({
                'example': self.example or '',
                'example_english': self.example_english or '',
                'example_persian': self.example_persian or '',
            })
            
        if include_advanced:
            data.update({
                'plural': self.plural,
                'cases': self.get_cases(),
                'tenses': self.get_tenses(),
                'audio_filename': self.audio_filename,
            })
            
        return data
    
    @classmethod
    def from_text(cls, text):
        """Create a Word instance from a text representation."""
        try:
            data = json.loads(text)
            word = cls()
            for field in cls._meta.fields:
                if field.name in data:
                    setattr(word, field.name, data[field.name])
            return word
        except json.JSONDecodeError:
            return None
    
    def to_text(self):
        """Convert the word to a JSON string."""
        data = {}
        for field in self._meta.fields:
            data[field.name] = str(getattr(self, field.name, ''))
        return json.dumps(data)


class UserWordProgress(models.Model):
    """Tracks user's progress with words"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='word_progress')
    word_id = models.IntegerField(null=True)  # Make nullable initially
    is_known = models.BooleanField(default=False)
    last_reviewed = models.DateTimeField(auto_now=True)
    review_count = models.IntegerField(default=0)
    
    class Meta:
        unique_together = ('user', 'word_id')
        db_table = 'user_word_progress'
    
    @property
    def word(self):
        # Get the word from the dictionary database
        return Word.objects.using('dictionary').get(pk=self.word_id)
    
    def __str__(self):
        try:
            word = self.word
            return f"{self.user.email} - {word.german} (Known: {self.is_known})"
        except Word.DoesNotExist:
            return f"{self.user.email} - Word ID: {self.word_id} (Not Found)"


class SavedWord(models.Model):
    """Tracks user's saved/starred words"""
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='saved_words')
    word_id = models.IntegerField(null=True)  # Make nullable initially
    saved_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('user', 'word_id')
        db_table = 'saved_words'
        ordering = ['-saved_at']
    
    @property
    def word(self):
        # Get the word from the dictionary database
        if not self.word_id:
            return None
        return Word.objects.using('dictionary').get(pk=self.word_id)
    
    def __str__(self):
        try:
            word = self.word
            if word:
                return f"{self.user.email} - {word.german} (Saved: {self.saved_at})"
            return f"{self.user.email} - Invalid Word ID: {self.word_id} (Saved: {self.saved_at})"
        except Exception as e:
            return f"{self.user.email} - Error: {str(e)} (Saved: {self.saved_at})"

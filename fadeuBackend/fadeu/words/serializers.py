from rest_framework import serializers
from .models import Word, UserWordProgress, SavedWord
import json

class WordSerializer(serializers.ModelSerializer):
    # Add computed properties for backward compatibility
    word = serializers.CharField(source='german', read_only=True)
    translation = serializers.CharField(source='english', read_only=True)
    
    class Meta:
        model = Word
        fields = [
            'id', 'german', 'english', 'persian', 'level', 'example',
            'example_english', 'example_persian', 'part_of_speech',
            'article', 'plural', 'cases', 'tenses', 'audio_filename',
            'word', 'translation'  # Include computed properties
        ]
    
    def to_representation(self, instance):
        # Convert string fields to JSON objects if they contain JSON
        ret = super().to_representation(instance)
        
        # Ensure all text fields are properly encoded
        text_fields = [
            'german', 'english', 'persian', 'example', 
            'example_english', 'example_persian', 'article', 'plural'
        ]
        
        for field in text_fields:
            if field in ret and ret[field] is not None:
                value = ret[field]
                try:
                    if isinstance(value, str):
                        # If it's a string, ensure it's properly encoded
                        ret[field] = value.encode('utf-8', errors='replace').decode('utf-8')
                    elif isinstance(value, bytes):
                        # If it's bytes, decode it
                        ret[field] = value.decode('utf-8', errors='replace')
                except (UnicodeEncodeError, UnicodeDecodeError) as e:
                    # If there's an encoding error, replace with a placeholder
                    ret[field] = f"[Encoding Error: {str(e)}]"
        
        # Parse JSON strings to objects for the frontend
        for field in ['cases', 'tenses']:
            if field in ret and ret[field] is not None:
                try:
                    if isinstance(ret[field], str):
                        ret[field] = json.loads(ret[field])
                except (json.JSONDecodeError, TypeError):
                    ret[field] = None
        
        return ret


class SavedWordSerializer(serializers.ModelSerializer):
    word = WordSerializer(read_only=True)
    
    class Meta:
        model = SavedWord
        fields = ['id', 'word', 'saved_at']
        read_only_fields = ['user', 'saved_at']
    
    def create(self, validated_data):
        # Get the user from the request context
        user = self.context['request'].user
        # Get the word ID from the URL parameters
        word_id = self.context['view'].kwargs.get('word_id')
        
        # Create and return a new saved word
        saved_word = SavedWord.objects.create(
            user=user,
            word_id=word_id,
            **validated_data
        )
        return saved_word

class UserWordProgressSerializer(serializers.ModelSerializer):
    word = WordSerializer()
    
    class Meta:
        model = UserWordProgress
        fields = ['id', 'word', 'is_known', 'last_reviewed', 'review_count']
        read_only_fields = ['user']

class WordWithProgressSerializer(WordSerializer):
    progress = serializers.SerializerMethodField()
    
    class Meta(WordSerializer.Meta):
        fields = WordSerializer.Meta.fields + ['progress']
    
    def get_progress(self, obj):
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return None
            
        try:
            progress = UserWordProgress.objects.get(user=request.user, word=obj)
            return {
                'is_known': progress.is_known,
                'last_reviewed': progress.last_reviewed,
                'review_count': progress.review_count
            }
        except UserWordProgress.DoesNotExist:
            return None

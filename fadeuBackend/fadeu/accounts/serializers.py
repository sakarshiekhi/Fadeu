# In accounts/serializers.py

from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import UserActivity
from django.utils import timezone

User = get_user_model()

class UserActivitySerializer(serializers.ModelSerializer):
    class Meta:
        model = UserActivity
        fields = [
            'id', 'user', 
            'total_study_time', 'last_studied',
            'words_learned', 'words_reviewed', 'words_mastered',
            'flashcards_completed', 'quizzes_completed', 'practice_sessions',
            'current_streak', 'longest_streak',
            'level', 'experience_points',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'user', 'created_at', 'updated_at',
            'current_streak', 'longest_streak', 'level'
        ]
    
    def update(self, instance, validated_data):
        # Update the activity metrics
        for attr, value in validated_data.items():
            # For numeric fields, increment the existing value
            if attr in ['total_study_time', 'words_learned', 'words_reviewed', 
                       'words_mastered', 'flashcards_completed', 'quizzes_completed',
                       'practice_sessions', 'experience_points']:
                setattr(instance, attr, getattr(instance, attr, 0) + value)
            else:
                setattr(instance, attr, value)
        
        # Update the last_studied timestamp and streak
        instance.last_studied = timezone.now()
        instance.update_streak()
        
        # Update level based on experience points (1000 XP per level)
        new_level = (instance.experience_points // 1000) + 1
        if new_level > instance.level:
            instance.level = new_level
        
        instance.save()
        return instance

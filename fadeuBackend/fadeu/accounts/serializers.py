<<<<<<< HEAD
# In accounts/serializers.py

from rest_framework import serializers
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from .models import UserActivity

User = get_user_model()

class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    # Remove the username_field as it's not needed with our custom User model
    default_error_messages = {
        'no_active_account': 'Invalid email or password.',
        'inactive_account': 'This account is inactive. Please check your email to verify your account.',
        'invalid_credentials': 'Invalid email or password.',
    }

    def validate(self, attrs):
        email = attrs.get("email")
        password = attrs.get("password")

        # Input validation
        if not email or not password:
            raise serializers.ValidationError(
                {"success": False, "error": "Email and password are required."},
                code='authorization'
            )

        # Get user by email (case-insensitive lookup)
        user = User.objects.filter(email__iexact=email).first()
        
        # Check if user exists and password is correct
        if user is None or not user.check_password(password):
            raise serializers.ValidationError(
                {"success": False, "error": "Invalid email or password."},
                code='authorization'
            )
            
        # Check if account is active
        if not user.is_active:
            raise serializers.ValidationError(
                {"success": False, "error": "This account is inactive. Please check your email to verify your account."},
                code='inactive_account'
            )
        
        # Default validation to get the token
        data = super().validate(attrs)
        
        # Get the refresh token
        refresh = self.get_token(user)
        
        # Format the response to match frontend expectations
        response_data = {
            'success': True,
            'message': 'Login successful',
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': {
                'id': user.id,
                'email': user.email,
                'first_name': user.first_name or '',
                'last_name': user.last_name or '',
            }
        }
        
        # Include any additional data from the parent class
        data.update(response_data)
        return data

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
=======
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView
from django.contrib.auth.models import User
from rest_framework import serializers

class MyTokenObtainPairSerializer(TokenObtainPairSerializer):
    username_field = User.EMAIL_FIELD

    def validate(self, attrs):
        credentials = {
            'email': attrs.get("email"),
            'password': attrs.get("password")
        }

        user = User.objects.filter(email=credentials['email']).first()
        if user is None or not user.check_password(credentials['password']):
            raise serializers.ValidationError("Invalid email or password")

        data = super().validate({
            'username': user.username,
            'password': credentials['password']
        })
        return data
>>>>>>> 69f1c219ac6270f866a57c3a1743b32fccc23d7d

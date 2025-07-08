<<<<<<< HEAD
# In accounts/models.py

from django.db import models
from django.conf import settings
from django.utils import timezone

# This is your existing PasswordResetCode model
class PasswordResetCode(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
=======
from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils import timezone
from datetime import timedelta

class User(AbstractUser):
    email = models.EmailField(unique=True)
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']  # Email & password are required by default

    def __str__(self):
        return self.email

class PasswordResetCode(models.Model):
    user = models.ForeignKey('accounts.User', on_delete=models.CASCADE)  # Use string reference
>>>>>>> 69f1c219ac6270f866a57c3a1743b32fccc23d7d
    code = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)

    def is_expired(self):
<<<<<<< HEAD
        return (timezone.now() - self.created_at).seconds > 3600 # 1 hour expiry

class UserActivity(models.Model):
    """Model to track user activity and progress"""
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, 
        on_delete=models.CASCADE, 
        related_name='activities'
    )
    
    # Study progress
    total_study_time = models.IntegerField(default=0, help_text='Total study time in seconds')
    last_studied = models.DateTimeField(auto_now=True)
    
    # Vocabulary tracking
    words_learned = models.IntegerField(default=0)
    words_reviewed = models.IntegerField(default=0)
    words_mastered = models.IntegerField(default=0)
    
    # Activity metrics
    flashcards_completed = models.IntegerField(default=0)
    quizzes_completed = models.IntegerField(default=0)
    practice_sessions = models.IntegerField(default=0)
    
    # Streaks
    current_streak = models.IntegerField(default=0)
    longest_streak = models.IntegerField(default=0)
    
    # Progress tracking
    level = models.IntegerField(default=1)
    experience_points = models.IntegerField(default=0)
    
    # Timestamps
    created_at = models.DateTimeField(default=timezone.now)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name_plural = 'User Activities'
        ordering = ['-last_studied']
    
    def __str__(self):
        return f'{self.user.email} - Last studied: {self.last_studied}'
    
    def update_streak(self):
        """Update the user's streak based on their last study date"""
        from datetime import timedelta
        
        today = timezone.now().date()
        yesterday = today - timedelta(days=1)
        
        # If this is the first activity or the last activity was yesterday
        if not self.last_studied or self.last_studied.date() == yesterday:
            self.current_streak += 1
        # If the last activity was today, don't increase the streak
        elif self.last_studied.date() == today:
            pass
        # If there was a gap, reset the streak
        else:
            self.current_streak = 1
        
        # Update longest streak if needed
        if self.current_streak > self.longest_streak:
            self.longest_streak = self.current_streak
        
        self.save()
        return self.current_streak


# Dictionary functionality is now handled by direct SQLite access
=======
        # Code expires after 10 minutes
        return timezone.now() > self.created_at + timedelta(minutes=10)
>>>>>>> 69f1c219ac6270f866a57c3a1743b32fccc23d7d

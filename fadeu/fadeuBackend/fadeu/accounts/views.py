# In accounts/views.py

import json
import logging
import random
import string
import smtplib
from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.mail import send_mail, BadHeaderError
from django.utils import timezone
from rest_framework_simplejwt.tokens import RefreshToken

# Django REST Framework imports
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView

# Local imports
from .models import PasswordResetCode, UserActivity
from .register_serializer import RegisterSerializer
from .serializers import UserActivitySerializer, MyTokenObtainPairSerializer

logger = logging.getLogger(__name__)
User = get_user_model()




# =================================================================
# USER ACTIVITY AND AUTHENTICATION VIEWS
# =================================================================

class SyncUserActivityView(APIView):
    """
    API endpoint to sync user activity and progress data.
    This endpoint accepts incremental updates to user activity metrics.
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request, *args, **kwargs):
        logger.info("=" * 50)
        logger.info("🔄 ACTIVITY SYNC REQUEST RECEIVED")
        logger.info(f"👤 User: {request.user.email} (ID: {request.user.id})")
        logger.info(f"📊 Activity Data: {json.dumps(request.data, indent=2)}")
        logger.info("=" * 50)

        try:
            # Get or create user activity
            activity, created = UserActivity.objects.get_or_create(user=request.user)
            
            # Map frontend field names to model field names if needed
            activity_data = {
                'watch_time_seconds': request.data.get('watch_time_seconds', 0),
                'words_searched': request.data.get('words_searched', 0),
                'words_saved': request.data.get('words_saved', 0),
                'flashcards_completed': request.data.get('flashcards_completed', 0),
                'longest_streak': request.data.get('longest_streak', 0),
                # Add any other fields that need to be updated
            }
            
            # Update the activity with new data
            for field, value in activity_data.items():
                if hasattr(activity, field):
                    current_value = getattr(activity, field) or 0
                    setattr(activity, field, current_value + value)
            
            # Update last studied timestamp
            activity.last_studied = timezone.now()
            
            # Save the activity
            activity.save()
            
            # Update streak if needed
            activity.update_streak()
            
            # Prepare response data
            response_data = {
                'success': True,
                'message': 'Activity synced successfully',
                'data': {
                    'watch_time_seconds': activity.watch_time_seconds,
                    'words_searched': activity.words_searched,
                    'words_saved': activity.words_saved,
                    'flashcards_completed': activity.flashcards_completed,
                    'current_streak': activity.current_streak,
                    'longest_streak': activity.longest_streak,
                    'last_studied': activity.last_studied.isoformat() if activity.last_studied else None,
                    'level': activity.level,
                    'experience_points': activity.experience_points,
                }
            }
            
            logger.info(f"✅ Activity sync successful: {json.dumps(response_data, indent=2)}")
            return Response(response_data, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"❌ Error syncing activity: {str(e)}", exc_info=True)
            return Response(
                {
                    'success': False, 
                    'error': 'Failed to sync activity',
                    'details': str(e)
                }, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        


class RegisterView(APIView):
    def post(self, request):
        email = request.data.get('email')
        password = request.data.get('password')
        password_confirm = request.data.get('password_confirm', '')
        
        # Input validation
        if not email or not password:
            return Response(
                {"success": False, "message": "Email and password are required."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # If password_confirm is provided, validate it matches password
        if password_confirm and password != password_confirm:
            return Response(
                {"success": False, "message": "Passwords do not match."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if len(password) < 8:
            return Response(
                {"success": False, "message": "Password must be at least 8 characters long."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if User.objects.filter(email=email).exists():
            return Response(
                {"success": False, "message": "A user with this email already exists."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Prepare data for serializer
        user_data = {
            'email': email,
            'password': password,
            'password_confirm': password_confirm or password,
            'first_name': request.data.get('first_name', ''),
            'last_name': request.data.get('last_name', ''),
        }
        
        serializer = RegisterSerializer(data=user_data)
        if serializer.is_valid():
            try:
                user = serializer.save()
                logger.info(f"New user registered: {user.email}")
                
                # Generate tokens for auto-login after registration
                refresh = RefreshToken.for_user(user)
                
                return Response({
                    "success": True,
                    "message": "Registration successful.",
                    "access": str(refresh.access_token),
                    "refresh": str(refresh),
                    "user": {
                        "id": user.id,
                        "email": user.email,
                        "first_name": user.first_name or "",
                        "last_name": user.last_name or "",
                    }
                }, status=status.HTTP_201_CREATED)
                
            except Exception as e:
                logger.error(f"Error during user registration: {str(e)}")
                return Response(
                    {"success": False, "message": "An error occurred during registration. Please try again."},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        # Handle serializer errors
        errors = {}
        for field, error_list in serializer.errors.items():
            if isinstance(error_list, list):
                errors[field] = error_list[0] if error_list else "Invalid value"
            else:
                errors[field] = str(error_list)
        
        logger.warning(f"User registration failed: {errors}")
        return Response(
            {"success": False, "message": "Registration failed. Please check your input.", "errors": errors},
            status=status.HTTP_400_BAD_REQUEST
        )

class EmailTokenObtainPairView(TokenObtainPairView):
    serializer_class = MyTokenObtainPairSerializer
    
    def post(self, request, *args, **kwargs):
        try:
            response = super().post(request, *args, **kwargs)
            
            # If the response is already in the correct format, return it as is
            if isinstance(response.data, dict) and 'success' in response.data:
                return response
                
            # Otherwise, format the response to match our standard format
            data = response.data
            if 'refresh' in data and 'access' in data:
                return Response({
                    'success': True,
                    'message': 'Login successful',
                    'access': data['access'],
                    'refresh': data['refresh'],
                    'user': {
                        'id': request.user.id if request.user.is_authenticated else None,
                        'email': request.user.email if request.user.is_authenticated else None,
                    }
                })
                
            return response
            
        except Exception as e:
            logger.error(f'Login error: {str(e)}')
            return Response(
                {"success": False, "error": "An error occurred during login. Please try again."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class ForgotPasswordView(APIView):
    permission_classes = []  # Allow any user
    
    def post(self, request):
        email = request.data.get('email')
        
        # Input validation
        if not email:
            return Response(
                {"success": False, "error": "Email address is required."},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        if not '@' in email or '.' not in email.split('@')[-1]:
            return Response(
                {"success": False, "error": "Please enter a valid email address."},
                status=status.HTTP_400_BAD_REQUEST
            )

        logger.info(f'Password reset requested for email: {email}')
        
        user = User.objects.filter(email=email).first()

        if user:
            try:
                # Delete any existing reset codes for this user
                PasswordResetCode.objects.filter(user=user).delete()
                
                # Generate a new 6-digit code
                code = ''.join(random.choices(string.digits, k=6))
                PasswordResetCode.objects.create(user=user, code=code)
                
                # Send the email with the reset code
                try:
                    send_mail(
                        'Your Password Reset Code',
                        f'Your password reset code for Fadeu is: {code}\n\nThis code will expire in 1 hour.',
                        settings.DEFAULT_FROM_EMAIL,
                        [email],
                        fail_silently=False,
                    )
                    logger.info(f'Password reset code sent to {email}')
                    
                    return Response({
                        "success": True,
                        "message": "If an account with that email exists, a password reset code has been sent.",
                        "email": email
                    })
                    
                except (BadHeaderError, smtplib.SMTPException) as e:
                    logger.error(f"Email sending failed for {email}: {e}")
                    return Response(
                        {"success": False, "error": "Failed to send reset email. Please try again later."},
                        status=status.HTTP_500_INTERNAL_SERVER_ERROR
                    )
                    
            except Exception as e:
                logger.error(f"An unexpected error occurred during password reset for {email}: {e}")
                return Response(
                    {"success": False, "error": "An error occurred while processing your request. Please try again."},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )
        
        # Return a generic success message even if the email doesn't exist (for security)
        return Response({
            "success": True,
            "message": "If an account with that email exists, a password reset code has been sent.",
            "email": email
        })


class VerifyCodeView(APIView):
    permission_classes = []  # Allow any user
    def post(self, request):
        email = request.data.get('email')
        # Accept both 'otp' and 'code' parameters for better compatibility
        code = request.data.get('otp') or request.data.get('code')
        
        # Input validation
        if not email or not code:
            return Response(
                {"error": "Email and verification code are required."},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        try:
            user = User.objects.get(email=email)
            reset_entry = PasswordResetCode.objects.filter(user=user, code=code).last()

            if not reset_entry:
                logger.warning(f"No reset code found for {email}")
                return Response(
                    {"success": False, "error": "Invalid verification code."},
                    status=status.HTTP_400_BAD_REQUEST
                )
                
            if reset_entry.is_expired():
                logger.warning(f"Expired code used for {email}")
                return Response(
                    {"success": False, "error": "Verification code has expired. Please request a new one."},
                    status=status.HTTP_400_BAD_REQUEST
                )
                
            logger.info(f"Code verified successfully for {email}")
            return Response({
                "success": True,
                "message": "Code verified successfully.",
                "email": email,
                "reset_token": str(reset_entry.id)  # Return a token that can be used for password reset
            })
            
        except User.DoesNotExist:
            logger.warning(f"Password reset attempt for non-existent email: {email}")
            return Response(
                {"success": False, "error": "No account found with this email address."},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f"Error in VerifyCodeView: {str(e)}")
            return Response(
                {"success": False, "error": "An error occurred while verifying the code."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class ResetPasswordView(APIView):
    permission_classes = []  # Allow any user
    def post(self, request):
        email = request.data.get('email')
        code = request.data.get('otp')  # Changed from 'code' to 'otp' to match frontend
        new_password = request.data.get('password')
        password_confirm = request.data.get('password_confirm')
        
        # Input validation
        if not all([email, code, new_password, password_confirm]):
            return Response(
                {"success": False, "error": "All fields are required."},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        if new_password != password_confirm:
            return Response(
                {"success": False, "error": "Passwords do not match."},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        if len(new_password) < 8:
            return Response(
                {"success": False, "error": "Password must be at least 8 characters long."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            user = User.objects.get(email=email)
            reset_entry = PasswordResetCode.objects.filter(user=user, code=code).last()
            
            if not reset_entry:
                logger.warning(f"No reset code found for {email}")
                return Response(
                    {"success": False, "error": "Invalid verification code."},
                    status=status.HTTP_400_BAD_REQUEST
                )
                
            if reset_entry.is_expired():
                logger.warning(f"Expired code used for password reset: {email}")
                return Response(
                    {"success": False, "error": "Verification code has expired. Please request a new one."},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Reset the password
            user.set_password(new_password)
            user.save()
            
            # Delete the used reset code
            reset_entry.delete()
            
            logger.info(f"Password reset successful for {email}")
            return Response({
                "success": True,
                "message": "Your password has been reset successfully. You can now log in with your new password.",
                "email": email
            })
            
        except User.DoesNotExist:
            logger.warning(f"Password reset attempt for non-existent email: {email}")
            return Response(
                {"success": False, "error": "No account found with this email address."},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f"Error in ResetPasswordView: {str(e)}")
            return Response(
                {"success": False, "error": "An error occurred while resetting your password. Please try again."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from django.views.generic import TemplateView

from . import views
from .password_reset_views import (
    PasswordResetRequestView,
    PasswordResetConfirmView,
    PasswordChangeView
)

app_name = 'users'

urlpatterns = [
    # Authentication
    path('token/', views.CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    
    # User management
    path('register/', views.UserCreateView.as_view(), name='register'),
    path('profile/', views.UserProfileView.as_view(), name='profile'),
    path('check-auth/', views.CheckAuthView.as_view(), name='check_auth'),
    
    # Password management
    path('password/reset/', PasswordResetRequestView.as_view(), name='password_reset'),
    path('password/reset/confirm/', PasswordResetConfirmView.as_view(), name='password_reset_confirm'),
    path('password/change/', PasswordChangeView.as_view(), name='password_change'),
    
    # Password reset success page (for direct browser access)
    path('password/reset/done/', 
         TemplateView.as_view(template_name='registration/password_reset_done.html'), 
         name='password_reset_done'),
    path('password/reset/complete/', 
         TemplateView.as_view(template_name='registration/password_reset_complete.html'), 
         name='password_reset_complete'),
]

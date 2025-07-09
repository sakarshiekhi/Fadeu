from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import (
    EmailTokenObtainPairView, RegisterView, ForgotPasswordView,
    VerifyCodeView, ResetPasswordView, SyncUserActivityView
)

urlpatterns = [
    # Authentication endpoints - these are relative to the included path (api/accounts/)
    path('password-reset/', ForgotPasswordView.as_view(), name='password_reset'),
    path('password-reset/verify/', VerifyCodeView.as_view(), name='verify_code'),
    path('reset-password/', ResetPasswordView.as_view(), name='reset_password'),
    
    # User activity tracking
    path('sync-activity/', SyncUserActivityView.as_view(), name='sync_activity'),
    
    # Backward compatibility (legacy endpoints without the api/accounts/ prefix)
    path('token/', EmailTokenObtainPairView.as_view(), name='token_obtain_pair_legacy'),
    path('register/', RegisterView.as_view(), name='register_legacy'),
    path('forgot-password/', ForgotPasswordView.as_view(), name='forgot_password_legacy'),
    path('verify-code/', VerifyCodeView.as_view(), name='verify_code_legacy'),
    path('reset-password-legacy/', ResetPasswordView.as_view(), name='reset_password_legacy'),
]

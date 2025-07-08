from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
    # Admin site
    path('admin/', admin.site.urls),
    
    # API endpoints
    path('api/auth/', include('users.urls')),  # User authentication endpoints
    path('api/accounts/', include('accounts.urls')),  # Legacy accounts endpoints
    path('api/words/', include('words.urls')),  # Words app endpoints
    
    # JWT token refresh endpoint
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]

# Serve static and media files in development
if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

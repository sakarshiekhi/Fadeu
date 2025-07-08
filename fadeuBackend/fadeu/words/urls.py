from django.urls import path
from .views import (
    WordListView,
    WordDetailView,
    UpdateWordProgressView,
    UserWordProgressView,
    SavedWordListView,
    SavedWordDetailView
)
from .views_test import test_db_connection
from .views_debug import debug_settings
from .test_connection import test_connection
from .test_encoding import TestEncodingView
from .db_test import DatabaseTestView

urlpatterns = [
    path('debug-settings/', debug_settings, name='debug-settings'),
    path('test-db/', test_db_connection, name='test-db'),
    path('test-connection/', test_connection, name='test-connection'),
    path('test-encoding/', TestEncodingView.as_view(), name='test-encoding'),
    path('test-db-encoding/', DatabaseTestView.as_view(), name='test-db-encoding'),
    path('words/', WordListView.as_view(), name='word-list'),
    path('words/<int:pk>/', WordDetailView.as_view(), name='word-detail'),
    path('words/<int:word_id>/progress/', UpdateWordProgressView.as_view(), name='update-word-progress'),
    path('user/words/progress/', UserWordProgressView.as_view(), name='user-word-progress'),
    
    # Saved words endpoints
    path('saved-words/', SavedWordListView.as_view(), name='saved-word-list'),
    path('saved-words/<int:word_id>/', SavedWordDetailView.as_view(), name='saved-word-detail'),
]

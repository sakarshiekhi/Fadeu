from rest_framework import status, generics, filters
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from django_filters.rest_framework import DjangoFilterBackend
from django.shortcuts import get_object_or_404

from .models import Word, UserWordProgress, SavedWord
from .serializers import (
    WordSerializer, 
    UserWordProgressSerializer, 
    WordWithProgressSerializer,
    SavedWordSerializer
)
from django.db.models import Q
from django.db import IntegrityError
import random

class WordListView(generics.ListAPIView):
    serializer_class = WordSerializer  # Use the simpler serializer without progress for unauthenticated users
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['level']
    search_fields = ['german', 'english', 'persian']
    permission_classes = []  # Remove authentication requirement
    pagination_class = None  # Disable pagination to return all results
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        # Only include progress data if user is authenticated
        if self.request.user.is_authenticated:
            context['request'] = self.request
        return context
        
    def get_serializer_class(self):
        # Use the progress serializer only for authenticated users
        if self.request.user.is_authenticated:
            return WordWithProgressSerializer
        return WordSerializer

    def get_queryset(self):
        queryset = Word.objects.all()
        level = self.request.query_params.get('level', None)
        shuffle = self.request.query_params.get('shuffle', 'false').lower() == 'true'
        
        if level and level.lower() != 'all':
            queryset = queryset.filter(level=level.upper())
        
        # Convert to list and shuffle if needed, but return a new queryset with the same ordering
        if shuffle:
            word_ids = list(queryset.values_list('id', flat=True))
            random.shuffle(word_ids)
            # Create a custom ordering using the shuffled IDs
            from django.db.models import Case, When
            preserved = Case(*[When(pk=pk, then=pos) for pos, pk in enumerate(word_ids)])
            queryset = Word.objects.filter(id__in=word_ids).order_by(preserved)
            
        return queryset
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context

class ToggleSaveWordView(APIView):
    """
    View to toggle save status of a word for the authenticated user.
    Returns {'status': 'saved'} if the word was saved, {'status': 'unsaved'} if unsaved.
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request, word_id):
        try:
            # Verify the word exists in the dictionary database
            word = Word.objects.using('dictionary').get(id=word_id)
        except Word.DoesNotExist:
            return Response(
                {'error': 'Word not found'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Check if the word is already saved
        saved_word = SavedWord.objects.filter(
            user=request.user, 
            word_id=word_id  # Use word_id instead of word
        ).first()
        
        if saved_word:
            # Word is saved, so unsave it
            saved_word.delete()
            return Response({'status': 'unsaved'}, status=status.HTTP_200_OK)
        else:
            # Word is not saved, so save it
            try:
                SavedWord.objects.create(user=request.user, word_id=word_id)  # Use word_id instead of word
                return Response({'status': 'saved'}, status=status.HTTP_201_CREATED)
            except IntegrityError as e:
                # In case of race condition or other integrity error
                return Response(
                    {'error': f'Failed to save word: {str(e)}'}, 
                    status=status.HTTP_400_BAD_REQUEST
                )


class WordDetailView(generics.RetrieveAPIView):
    queryset = Word.objects.all()
    serializer_class = WordSerializer  # Default to simple serializer
    permission_classes = []  # Remove authentication requirement
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        # Only include progress data if user is authenticated
        if self.request.user.is_authenticated:
            context['request'] = self.request
        return context
        
    def get_serializer_class(self):
        # Use the progress serializer only for authenticated users
        if self.request.user.is_authenticated:
            return WordWithProgressSerializer
        return WordSerializer

class UpdateWordProgressView(APIView):
    permission_classes = [IsAuthenticated]  # Authentication required to save progress
    
    def post(self, request, word_id):
        try:
            word = Word.objects.get(id=word_id)
            is_known = request.data.get('is_known', None)
            
            if is_known is None:
                return Response(
                    {'error': 'is_known field is required'},
                    status=status.HTTP_400_BAD_REQUEST
                )
                
            progress, created = UserWordProgress.objects.get_or_create(
                user=request.user,
                word=word,
                defaults={
                    'is_known': is_known,
                    'review_count': 1,
                    'last_reviewed': timezone.now()
                }
            )
            
            if not created:
                # Only update if the status has changed
                if progress.is_known != is_known:
                    progress.is_known = is_known
                    progress.review_count += 1
                    progress.last_reviewed = timezone.now()
                    progress.save()
                
            serializer = UserWordProgressSerializer(progress)
            return Response(
                serializer.data,
                status=status.HTTP_201_CREATED if created else status.HTTP_200_OK
            )
            
        except Word.DoesNotExist:
            return Response(
                {'error': 'Word not found'}, 
                status=status.HTTP_404_NOT_FOUND
            )

class UserWordProgressView(generics.ListAPIView):
    serializer_class = UserWordProgressSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return UserWordProgress.objects.filter(user=self.request.user)


class SavedWordListView(generics.ListCreateAPIView):
    """
    View to list all saved words for the authenticated user or save a new word.
    """
    serializer_class = SavedWordSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        # Get saved words with word data from dictionary database
        saved_words = SavedWord.objects.filter(user=self.request.user)
        return saved_words
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['request'] = self.request
        return context
        
    def create(self, request, *args, **kwargs):
        word_id = request.data.get('word_id') or request.data.get('word')
        if not word_id:
            return Response(
                {'error': 'Word ID is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
        try:
            # Verify word exists in dictionary database
            word = Word.objects.using('dictionary').get(id=word_id)
        except Word.DoesNotExist:
            return Response(
                {'error': 'Word not found'}, 
                status=status.HTTP_404_NOT_FOUND
            )
            
        # Check if already saved
        if SavedWord.objects.filter(user=request.user, word_id=word_id).exists():
            return Response(
                {'error': 'Word is already saved'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
        try:
            saved_word = SavedWord.objects.create(user=request.user, word_id=word_id)
            serializer = self.get_serializer(saved_word)
            headers = self.get_success_headers(serializer.data)
            return Response(
                serializer.data, 
                status=status.HTTP_201_CREATED, 
                headers=headers
            )
        except IntegrityError as e:
            return Response(
                {'error': f'Failed to save word: {str(e)}'},
                status=status.HTTP_400_BAD_REQUEST
            )


class SavedWordDetailView(generics.DestroyAPIView):
    """
    View to delete a saved word.
    """
    queryset = SavedWord.objects.all()
    permission_classes = [IsAuthenticated]
    lookup_field = 'word_id'
    
    def get_queryset(self):
        # Only allow users to delete their own saved words
        return SavedWord.objects.filter(user=self.request.user)
    
    def destroy(self, request, *args, **kwargs):
        try:
            instance = self.get_object()
            self.perform_destroy(instance)
            return Response(status=status.HTTP_204_NO_CONTENT)
        except SavedWord.DoesNotExist:
            return Response(
                {'error': 'Saved word not found'}, 
                status=status.HTTP_404_NOT_FOUND
            )

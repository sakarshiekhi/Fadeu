from django.contrib import admin
from .models import Word, UserWordProgress

@admin.register(Word)
class WordAdmin(admin.ModelAdmin):
    list_display = ('german', 'english', 'persian', 'level', 'part_of_speech', 'preview_example')
    list_filter = ('level', 'part_of_speech', 'article')
    search_fields = ('german', 'english', 'persian', 'example')
    ordering = ('german',)  # Order by german field
    list_per_page = 50
    
    fieldsets = (
        ('Word Information', {
            'fields': ('german', 'english', 'persian', 'level', 'part_of_speech', 'article', 'plural')
        }),
        ('Examples', {
            'fields': ('example', 'example_english', 'example_persian'),
            'classes': ('collapse',)
        }),
        ('Advanced', {
            'fields': ('cases', 'tenses', 'audio_filename'),
            'classes': ('collapse',)
        }),
    )
    
    def preview_example(self, obj):
        if obj.example:
            return obj.example[:50] + ('...' if len(obj.example) > 50 else '')
        return ""
    preview_example.short_description = 'Example Preview'

@admin.register(UserWordProgress)
class UserWordProgressAdmin(admin.ModelAdmin):
    list_display = ('user', 'word', 'is_known', 'last_reviewed', 'review_count')
    list_filter = ('is_known', 'last_reviewed')
    search_fields = ('user__email', 'word__word')
    ordering = ('-last_reviewed',)

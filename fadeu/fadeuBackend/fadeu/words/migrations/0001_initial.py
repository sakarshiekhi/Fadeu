# Generated by Django 4.2.7 on 2025-07-08 14:50

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='Word',
            fields=[
                ('id', models.AutoField(primary_key=True, serialize=False)),
                ('german', models.TextField()),
                ('english', models.TextField()),
                ('persian', models.TextField()),
                ('level', models.CharField(choices=[('A1', 'A1 (Beginner)'), ('A2', 'A2 (Elementary)'), ('B1', 'B1 (Intermediate)'), ('B2', 'B2 (Upper-Intermediate)'), ('C1', 'C1 (Advanced)'), ('C2', 'C2 (Proficiency)')], default='A1', max_length=2)),
                ('example', models.TextField(blank=True, null=True)),
                ('example_english', models.TextField(blank=True, null=True)),
                ('example_persian', models.TextField(blank=True, null=True)),
                ('part_of_speech', models.CharField(blank=True, max_length=50, null=True)),
                ('article', models.CharField(blank=True, max_length=10, null=True)),
                ('plural', models.CharField(blank=True, max_length=100, null=True)),
                ('cases', models.TextField(blank=True, null=True)),
                ('tenses', models.TextField(blank=True, null=True)),
                ('audio_filename', models.CharField(blank=True, max_length=255, null=True)),
            ],
            options={
                'db_table': 'words',
            },
        ),
        migrations.CreateModel(
            name='UserWordProgress',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('is_known', models.BooleanField(default=False)),
                ('last_reviewed', models.DateTimeField(auto_now=True)),
                ('review_count', models.IntegerField(default=0)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='word_progress', to=settings.AUTH_USER_MODEL)),
                ('word', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='words.word')),
            ],
            options={
                'db_table': 'user_word_progress',
                'unique_together': {('user', 'word')},
            },
        ),
        migrations.CreateModel(
            name='SavedWord',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('word_id', models.IntegerField(null=True)),
                ('saved_at', models.DateTimeField(auto_now_add=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='saved_words', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'db_table': 'saved_words',
                'ordering': ['-saved_at'],
                'unique_together': {('user', 'word_id')},
            },
        ),
    ]

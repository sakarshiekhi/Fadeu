import 'package:flutter/material.dart';
import 'package:fadeu/models/word_model.dart';
import 'package:fadeu/services/DatabaseHelper.dart';
import 'package:fadeu/services/api_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

class WordDetailView extends StatefulWidget {
  final int wordId;
  final bool isDarkMode;

  const WordDetailView({
    Key? key,
    required this.wordId,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<WordDetailView> createState() => _WordDetailViewState();
}

class _WordDetailViewState extends State<WordDetailView> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Word? _word;
  bool _isLoading = true;
  bool _isBookmarked = false;
  
  @override
  bool get mounted => super.mounted;
  
  // Helper method to update state safely
  void _safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Details'),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? Colors.amber : null,
            ),
            onPressed: _toggleBookmark,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _word == null
              ? const Center(child: Text('Word not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '${_word!.article ?? ''} ${_word!.germanWord ?? ''}'.trim(),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      if (_word!.englishWord?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              _word!.englishWord!,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                      if (_word!.persianWord?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              _word!.persianWord!,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                      if (_word!.example?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 16.0),
                        const Divider(),
                        Text(
                          'Example:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(_word!.example!),
                        ),
                      ],
                      if (_word!.exampleEnglish?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              _word!.exampleEnglish!,
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                        ),
                      if (_word!.examplePersian?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              _word!.examplePersian!,
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                        ),
                      if (_word!.partOfSpeech?.isNotEmpty ?? false)
                        _buildInfoRow('Part of Speech', _word!.partOfSpeech!),
                      if (_word!.plural?.isNotEmpty ?? false)
                        _buildInfoRow('Plural', _word!.plural!),
                      if (_word!.cases?.isNotEmpty ?? false)
                        _buildInfoRow('Cases', _word!.cases!),
                      if (_word!.tenses?.isNotEmpty ?? false)
                        _buildInfoRow('Tenses', _word!.tenses!),
                    ],
                  ),
                ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadWord();
  }
  
  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
  
  Future<void> _loadWord() async {
    _safeSetState(() {
      _isLoading = true;
    });
    
    try {
      Word? word;
      
      if (kIsWeb) {
        // Fetch word from API on web
        final apiService = ApiService();
        word = await apiService.fetchWordById(widget.wordId);
      } else {
        // Fetch word from local database on mobile
        word = await _dbHelper.getWordById(widget.wordId);
      }
      
      _safeSetState(() {
        _word = word;
        _isBookmarked = word?.isSaved ?? false;
        _isLoading = false;
      });
      
      // Track word view for user activity
      if (word != null) {
        await _trackWordView();
      }
    } catch (e) {
      debugPrint('Error loading word: $e');
      _safeSetState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _trackWordView() async {
    if (_word == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toIso8601String();
      
      // Track locally
      await prefs.setString('last_word_viewed', now);
      
      // Sync with backend if online
      if (kIsWeb) {
        final apiService = ApiService();
        await apiService.syncUserActivity(
          watchTimeSeconds: 0,
          wordsSearched: 1,
          wordsSaved: 0,
          flashcardsCompleted: 0,
          longestStreak: 0,
        );
      }
    } catch (e) {
      debugPrint('Error tracking word view: $e');
    }
  }

  Future<void> _toggleBookmark() async {
    if (_word == null) return;

    try {
      final newBookmarkStatus = !_isBookmarked;
      
      if (kIsWeb) {
        // For web, update local state and sync with backend
        _safeSetState(() {
          _isBookmarked = newBookmarkStatus;
        });
        
        // Track the bookmark action
        final prefs = await SharedPreferences.getInstance();
        final wordsSaved = prefs.getInt('words_saved') ?? 0;
        await prefs.setInt('words_saved', wordsSaved + (newBookmarkStatus ? 1 : -1));
        
        // Sync with backend
        final apiService = ApiService();
        await apiService.syncUserActivity(
          watchTimeSeconds: 0,
          wordsSearched: 0,
          wordsSaved: newBookmarkStatus ? 1 : 0,
          flashcardsCompleted: 0,
          longestStreak: 0,
        );
      } else {
        // For mobile, update local database
        await _dbHelper.toggleSaveStatus(_word!.id, newBookmarkStatus);
        
        // Update the local state by creating a new Word instance
        _safeSetState(() {
          _isBookmarked = newBookmarkStatus;
          _word = Word(
            id: _word!.id,
            article: _word!.article,
            germanWord: _word!.germanWord,
            englishWord: _word!.englishWord,
            persianWord: _word!.persianWord,
            partOfSpeech: _word!.partOfSpeech,
            plural: _word!.plural,
            cases: _word!.cases,
            tenses: _word!.tenses,
            example: _word!.example,
            exampleEnglish: _word!.exampleEnglish,
            examplePersian: _word!.examplePersian,
            isSaved: newBookmarkStatus,
            level: _word!.level,
          );
        });
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      // Revert UI on error
      _safeSetState(() {
        _isBookmarked = !_isBookmarked;
      });
    }
  }
}

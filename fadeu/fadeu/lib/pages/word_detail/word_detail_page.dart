import 'package:flutter/material.dart';
import 'package:fadeu/models/word_model.dart';
import 'package:fadeu/services/DatabaseHelper.dart';
import 'package:fadeu/services/api_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fadeu/widgets/bi_directional_text.dart';
import 'package:fadeu/l10n/app_localizations.dart';

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
        title: Text(AppLocalizations.of(context)!.wordDetailsError.replaceAll('Error loading ', '')),
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
              ? Center(child: Text(AppLocalizations.of(context)!.noResults))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_word!.article ?? ''} ${_word!.germanWord ?? ''}'.trim(),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        textDirection: TextDirection.ltr, // Force LTR for German text
                      ),
                      if (_word!.englishWord?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _word!.englishWord!,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      if (_word!.persianWord?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: BiDirectionalText(
                            _word!.persianWord!,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      if (_word!.example?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 16.0),
                        const Divider(),
                        Text(
                          '${AppLocalizations.of(context)!.exampleGerman}:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(_word!.example!),
                      ],
                      if (_word!.exampleEnglish?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: BiDirectionalText(
                            _word!.exampleEnglish!,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                            forceLTR: true, // English examples should be LTR
                          ),
                        ),
                      if (_word!.examplePersian?.isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                          child: BiDirectionalText(
                            _word!.examplePersian!,
                            style: const TextStyle(fontStyle: FontStyle.italic),
                            forceLTR: true, // Persian examples should be LTR
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
        // Update UI optimistically
        _safeSetState(() {
          _isBookmarked = newBookmarkStatus;
        });
        
        // Call the API to toggle save status
        final apiService = ApiService();
        final isSaved = await apiService.toggleSaveWord(_word!.id);
        
        // Update UI based on API response
        _safeSetState(() {
          _isBookmarked = isSaved;
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
            isSaved: isSaved,
            level: _word!.level,
          );
        });
        
        // Update local storage for offline tracking
        final prefs = await SharedPreferences.getInstance();
        final wordsSaved = prefs.getInt('words_saved') ?? 0;
        await prefs.setInt('words_saved', isSaved ? wordsSaved + 1 : wordsSaved - 1);
        
        // Sync user activity
        await apiService.syncUserActivity(
          watchTimeSeconds: 0,
          wordsSearched: 0,
          wordsSaved: isSaved ? 1 : -1,
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

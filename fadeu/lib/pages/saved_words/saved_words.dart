
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fadeu/models/word_model.dart';
import 'package:fadeu/services/DatabaseHelper.dart';
import 'package:fadeu/services/api_service.dart';
import 'package:fadeu/pages/word_detail/word_detail_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SavedWordsPage extends StatefulWidget {
  final bool isDarkMode;
  const SavedWordsPage({super.key, required this.isDarkMode});

  @override
  State<SavedWordsPage> createState() => _SavedWordsPageState();
}

class _SavedWordsPageState extends State<SavedWordsPage> {
  DatabaseHelper? _dbHelper;
  List<Word> _savedWords = [];
  bool _isLoading = true;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      // Mobile: Use local database
      _dbHelper = DatabaseHelper();
      _loadSavedWords();
    } else {
      // Web: Load from API
      _loadSavedWordsFromApi();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!kIsWeb) {
      _loadSavedWords();
    } else {
      _loadSavedWordsFromApi();
    }
  }

  Future<void> _removeSavedWord(int wordId) async {
    if (kIsWeb) {
      // Web: Remove from backend API
      try {
        final success = await _apiService.delete('/api/words/saved-words/$wordId/');
        if (success && mounted) {
          setState(() {
            _savedWords.removeWhere((word) => word.id == wordId);
          });
          
          // Show success message
          if (mounted) {
            final word = _savedWords.firstWhere(
              (w) => w.id == wordId,
              orElse: () => Word(id: wordId, germanWord: 'Word'),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${word.germanWord} removed from saved words')),
            );
          }
        } else if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to remove saved word')),
          );
        }
      } catch (e) {
        debugPrint('Error removing saved word: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An error occurred while removing the word')),
          );
        }
      }
    } else {
      // Mobile: Remove from local storage
      try {
        final prefs = await SharedPreferences.getInstance();
        final List<String> savedIds = prefs.getStringList('bookmarkedWordIds') ?? [];

        if (savedIds.remove(wordId.toString())) {
          await prefs.setStringList('bookmarkedWordIds', savedIds);
          int currentWordsSaved = prefs.getInt('wordsSaved') ?? 0;
          if (currentWordsSaved > 0) {
            await prefs.setInt('wordsSaved', currentWordsSaved - 1);
          }
          if (mounted) {
            final word = _savedWords.firstWhere(
              (w) => w.id == wordId,
              orElse: () => Word(id: wordId, germanWord: 'Word'),
            );
            setState(() {
              _savedWords.removeWhere((word) => word.id == wordId);
            });
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${word.germanWord} removed from saved words')),
            );
          }
        }
      } catch (e) {
        debugPrint('Error removing saved word: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to remove saved word')),
          );
        }
      }
    }
  }

  Future<void> _clearAllSavedWords() async {
    if (kIsWeb) {
      // Web: Clear all saved words from backend
      try {
        bool allDeleted = true;
        
        // Delete each saved word one by one
        for (final word in List<Word>.from(_savedWords)) {
          try {
            final success = await _apiService.delete('/api/words/saved-words/${word.id}/');
            if (!success) {
              allDeleted = false;
              debugPrint('Failed to delete word with ID: ${word.id}');
            }
          } catch (e) {
            allDeleted = false;
            debugPrint('Error deleting word with ID ${word.id}: $e');
          }
        }
        
        if (mounted) {
          setState(() {
            _savedWords.clear();
          });
          
          // Show appropriate message
          if (allDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('All saved words cleared')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Some words could not be removed')),
            );
          }
        }
      } catch (e) {
        debugPrint('Error clearing saved words: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to clear saved words')),
          );
        }
      }
    } else {
      // Mobile: Clear from local storage
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('bookmarkedWordIds', []); 
        await prefs.setInt('wordsSaved', 0);
        if (mounted) {
          setState(() {
            _savedWords.clear();
          });
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All saved words cleared')),
          );
        }
      } catch (e) {
        debugPrint('Error clearing saved words: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to clear saved words')),
          );
        }
      }
    }
  }

  // Load saved words from local database (mobile)
  Future<void> _loadSavedWords() async {
    if (!mounted || _dbHelper == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList('bookmarkedWordIds')?.map(int.parse).toList() ?? [];

      if (ids.isNotEmpty) {
        final List<Word> words = await _dbHelper!.getWordsByIds(ids);
        if (mounted) {
          setState(() {
            _savedWords = words.reversed.toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _savedWords = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saved words: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Load saved words from API (web)
  Future<void> _loadSavedWordsFromApi() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final words = await _apiService.getSavedWords();
      if (mounted) {
        setState(() {
          _savedWords = words;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading saved words from API: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Show error message with retry option
        final scaffold = ScaffoldMessenger.of(context);
        scaffold.showSnackBar(
          SnackBar(
            content: const Text('Failed to load saved words'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                // Retry loading
                _loadSavedWordsFromApi();
              },
            ),
          ),
        );
      }
    }
  }

  Widget _buildWordList() {
    final themeColor = widget.isDarkMode ? Colors.white : Colors.black;
    return ListView.builder(
      itemCount: _savedWords.length,
      itemBuilder: (context, index) {
        final word = _savedWords[index];
        return Dismissible(
          key: ValueKey(word.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) {
            _removeSavedWord(word.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${word.germanWord ?? 'Word'} removed from saved.')),
            );
          },
          child: Card(
            color: widget.isDarkMode
                ? Colors.grey[850]
                : Colors.white,
            margin: const EdgeInsets.symmetric(
                vertical: 4, horizontal: 16),
            child: ListTile(
              title: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(word.germanWord ?? 'N/A',
                    style: TextStyle(
                        color: themeColor,
                        fontWeight: FontWeight.bold)),
              ),
              subtitle: Directionality(
                textDirection: TextDirection.rtl,
                child: Text(word.persianWord ?? 'No translation',
                    style: const TextStyle(
                        color: Colors.blueAccent, fontSize: 16)),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WordDetailView(
                    wordId: word.id, 
                    isDarkMode: widget.isDarkMode,
                  ),
                ),
              ).then((_) => kIsWeb ? _loadSavedWordsFromApi() : _loadSavedWords()),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isDarkMode ? Colors.white : Colors.black;

    if (kIsWeb) {
      return RefreshIndicator(
        onRefresh: _loadSavedWordsFromApi,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _savedWords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_outline, size: 60, color: themeColor.withAlpha(150)),
                        const SizedBox(height: 20),
                        Text(
                          'No saved words found.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: themeColor.withAlpha(200)),
                        ),
                        TextButton(
                          onPressed: _loadSavedWordsFromApi,
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  )
                : _buildWordList(),
      );
    }

    return RefreshIndicator(
      onRefresh: kIsWeb ? _loadSavedWordsFromApi : _loadSavedWords,
      child: Stack( 
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _savedWords.isEmpty
                  ? Center(
                      child: Text('You have no saved words.\nPull down to refresh.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: themeColor.withAlpha(178))),
                    )
                  : _buildWordList(),
          if (_savedWords.isNotEmpty && !_isLoading)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text('Clear All Saved Words?'),
                        content: const Text('This action cannot be undone.'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Cancel'),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                          TextButton(
                            child: const Text('Clear All'),
                            onPressed: () {
                              _clearAllSavedWords();
                              Navigator.of(dialogContext).pop();
                              if(mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('All saved words cleared.')),
                                );
                              }
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                label: const Text('Clear All'),
                icon: const Icon(Icons.clear_all),
                backgroundColor: Colors.red,
              ),
            ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:fadeu/l10n/app_localizations.dart';
import 'package:fadeu/models/word_model.dart';
import 'package:fadeu/services/DatabaseHelper.dart';
import 'package:fadeu/services/auth_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fadeu/pages/word_detail/word_detail_page.dart';
import 'package:fadeu/widgets/bi_directional_text.dart';

// Model for PONS translations (for mobile)
class PonsTranslation {
  final String source;
  final String target;

  PonsTranslation({required this.source, required this.target});

  factory PonsTranslation.fromJson(Map<String, dynamic> json) {
    return PonsTranslation(
      source: json['source'] as String? ?? '',
      target: json['target'] as String? ?? '',
    );
  }
}

class SearchView extends StatefulWidget {
  final bool isDarkMode;
  final ScrollController scrollController;
  final VoidCallback onSearchPerformed;
  
  // Make constructor const and initialize services in the state
  const SearchView({
    super.key,
    required this.isDarkMode,
    required this.scrollController,
    required this.onSearchPerformed,
  });

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AuthService _authService = AuthService();
  String get _backendUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      final scheme = Uri.base.scheme;
      return '$scheme://$host:8000';
    } else {
      return 'http://10.0.2.2:8000';
    }
  }
  late SharedPreferences _prefs;
  Timer? _debounce;
  Set<int> _bookmarkedWordIds = {};
  static const _bookmarksKey = 'bookmarkedWordIds';

  List<String> _searchHistory = [];
  static const int _maxHistorySize = 10;
  static const String _historyKey = 'searchHistory';

  List<Word> _offlineResults = [];
  List<PonsTranslation> _backendOnlineResults = [];
  
  bool _isLoadingOffline = false;
  bool _isLoadingBackend = false;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    try {
      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();
      
      // Initialize database if on mobile
      if (!kIsWeb) {
        await _dbHelper.database; // This will initialize the database
      }
      
      // Load bookmarks and search history
      await _loadBookmarks();
      await _loadSearchHistory();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing search view: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing search: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadBookmarks() async {
    try {
      if (kIsWeb) {
        // On web, fetch saved words from the backend if user is logged in
        final token = await _authService.getToken();
        if (token != null) {
          debugPrint('User is logged in, fetching saved words from backend...');
          try {
            final response = await http.get(
              Uri.parse('$_backendUrl/api/words/saved-words/'),
              headers: await _getAuthHeaders(),
            );
            
            if (response.statusCode == 200) {
              final List<dynamic> savedWords = json.decode(response.body);
              final savedWordIds = savedWords.map((word) => word['id'] as int).toSet();
              if (mounted) {
                setState(() {
                  _bookmarkedWordIds = savedWordIds;
                });
              }
              debugPrint('Loaded ${savedWordIds.length} saved words from backend');
              return;
            } else {
              debugPrint('Failed to load saved words: ${response.statusCode}');
            }
          } catch (e) {
            debugPrint('Error loading saved words: $e');
          }
        }
      }
      
      // Fall back to local storage if on mobile or if backend fetch fails
      final ids = _prefs.getStringList(_bookmarksKey)?.map(int.parse).toSet() ?? {};
      if (mounted) setState(() => _bookmarkedWordIds = ids);
      debugPrint('Loaded ${ids.length} bookmarks from local storage');
    } catch (e) {
      debugPrint('Error in _loadBookmarks: $e');
    }
  }

  Future<void> _loadSearchHistory() async {
    final history = _prefs.getStringList(_historyKey) ?? [];
    if (mounted) setState(() => _searchHistory = history);
  }

  Future<void> _saveSearchQuery(String query) async {
    if (_searchHistory.contains(query)) {
      _searchHistory.remove(query);
    }
    _searchHistory.insert(0, query);
    if (_searchHistory.length > _maxHistorySize) {
      _searchHistory = _searchHistory.sublist(0, _maxHistorySize);
    }
    await _prefs.setStringList(_historyKey, _searchHistory);
    if (mounted) setState(() {});
  }
  
  Future<void> _removeSearchHistoryItem(int index) async {
    if (index >= 0 && index < _searchHistory.length) {
      setState(() {
        _searchHistory.removeAt(index);
      });
      await _prefs.setStringList(_historyKey, _searchHistory);
    }
  }

  Future<void> _clearAllSearchHistory() async {
     // Your existing dialog logic can go here
  }

  Future<void> _toggleBookmark(int wordId) async {
    if (!mounted || !_isInitialized) return;
    
    try {
      final isBookmarked = _bookmarkedWordIds.contains(wordId);
      final newBookmarkState = !isBookmarked;
      
      debugPrint('Toggling bookmark for word $wordId. New state: $newBookmarkState');
      
      // Update backend if on web and user is logged in
      if (kIsWeb && await _authService.isLoggedIn()) {
        try {
          final response = await http.post(
            Uri.parse('$_backendUrl/api/words/toggle-save/'),
            headers: await _getAuthHeaders(),
            body: json.encode({
              'word_id': wordId,
              'action': newBookmarkState ? 'save' : 'unsave',
            }),
          );
          
          if (response.statusCode != 200) {
            throw Exception('Failed to update bookmark on server');
          }
          
          debugPrint('Successfully updated bookmark on server');
        } catch (e) {
          debugPrint('Error updating bookmark on server: $e');
          rethrow; // Re-throw to trigger the error handling below
        }
      }
      
      // Optimistically update UI
      if (mounted) {
        setState(() {
          if (newBookmarkState) {
            _bookmarkedWordIds.add(wordId);
          } else {
            _bookmarkedWordIds.remove(wordId);
          }
          
          // Update the word in the results
          _offlineResults = _offlineResults.map((word) {
            if (word.id == wordId) {
              return word.copyWith(isSaved: newBookmarkState);
            }
            return word;
          }).toList();
        });
      }
      
      // Update local state
      if (!kIsWeb) {
        // Only update local storage if not on web
        final bookmarksList = _bookmarkedWordIds.map((id) => id.toString()).toList();
        await _prefs.setStringList(_bookmarksKey, bookmarksList);
        debugPrint('Updated bookmarks in SharedPreferences: $bookmarksList');
        
        // Update the local database
        try {
          await _dbHelper.toggleSaveStatus(wordId, newBookmarkState);
          debugPrint('Successfully updated save status in database');
        } catch (e) {
          debugPrint('Error updating save status in database: $e');
          // Don't revert UI for database errors if SharedPreferences was updated successfully
        }
      }
      
      // Update the word count in SharedPreferences
      final currentCount = _prefs.getInt('wordsSaved') ?? 0;
      if (newBookmarkState) {
        await _prefs.setInt('wordsSaved', currentCount + 1);
      } else if (currentCount > 0) {
        await _prefs.setInt('wordsSaved', currentCount - 1);
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Word ${newBookmarkState ? 'saved' : 'removed'} successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update word: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }



  Future<void> _performSearch(String query) async {
    if (!mounted || !_isInitialized) return;
    
    // Don't search if query is too short
    if (query.length < 2) {
      if (mounted) {
        setState(() {
          _offlineResults = [];
          _backendOnlineResults = [];
          _isLoadingOffline = false;
          _isLoadingBackend = false;
        });
      }
      return;
    }
    
    debugPrint('Performing search for: $query');
    
    if (mounted) {
      setState(() {
        _isLoadingOffline = true;
        _isLoadingBackend = true;
      });
    }

    widget.onSearchPerformed();

    try {
      if (!kIsWeb) {
        // On mobile, search local database
        try {
          debugPrint('Searching local database...');
          final words = await _dbHelper.searchWords(query);
          debugPrint('Found ${words.length} results in local database');
          
          if (mounted) {
            setState(() {
              // Update the saved state for each word based on bookmarks
              _offlineResults = words.map((word) {
                return word.copyWith(isSaved: _bookmarkedWordIds.contains(word.id));
              }).toList();
              _isLoadingOffline = false;
            });
          }
        } catch (e) {
          debugPrint('Error searching local database: $e');
          if (mounted) {
            setState(() {
              _isLoadingOffline = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error searching local database'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // On web, search the backend API
        try {
          final response = await _searchBackend(query);
          debugPrint('Search response status: ${response.statusCode}');
          debugPrint('Response body length: ${response.body.length}');
          
          if (response.statusCode == 200) {
            final dynamic responseData = json.decode(response.body);
            
            // Handle different response formats
            List<dynamic> items = [];
            
            if (responseData is List) {
              // If response is directly a list
              items = responseData;
            } else if (responseData is Map && responseData['results'] != null) {
              // If response has a 'results' key
              items = responseData['results'] is List ? responseData['results'] : [];
            } else if (responseData is Map && responseData.isNotEmpty) {
              // If response is a single item as a map
              items = [responseData];
            }
            
            debugPrint('Found ${items.length} items in response');
            
            final results = items.map((item) {
              try {
                return Word.fromMap(item);
              } catch (e) {
                debugPrint('Error parsing word: $e');
                return null;
              }
            }).whereType<Word>().toList();
            
            debugPrint('Successfully parsed ${results.length} words');
            
            if (mounted) {
              setState(() {
                _offlineResults = results;
                _isLoadingOffline = false;
              });
            }
          } else {
            throw Exception('Failed to load search results: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('Error during backend search: $e');
          if (mounted) {
            setState(() {
              _isLoadingOffline = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error searching backend: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error performing search: $e');
      if (mounted) {
        setState(() {
          _isLoadingOffline = false;
          _isLoadingBackend = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error performing search. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBackend = false;
        });
      }
    }
  }

  Future<http.Response> _searchBackend(String query) async {
    try {
      final url = Uri.parse('$_backendUrl/api/words/words/?search=$query&page_size=20');
      debugPrint('Searching for: $query');
      debugPrint('Using base URL: $_backendUrl');
      
      final headers = await _getAuthHeaders();
      debugPrint('Got headers, making request...');
      
      final response = await http.get(url, headers: headers);
      debugPrint('Request completed with status: ${response.statusCode}');
      
      return response;
    } catch (e) {
      debugPrint('Error in _searchBackend: $e');
      rethrow;
    }
  }
  
  Future<Map<String, String>> _getAuthHeaders() async {
    try {
      debugPrint('Getting auth headers...');
      final token = await _authService.getToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        debugPrint('Auth token found in storage');
        headers['Authorization'] = 'JWT $token';
        debugPrint('Added Authorization header');
      } else {
        debugPrint('No auth token found');
      }
      
      return headers;
    } catch (e) {
      debugPrint('Error getting auth headers: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  List<dynamic> get _displayResults {
    List<dynamic> results = [];
    if (_offlineResults.isNotEmpty) {
      results.add(kIsWeb ? "Backend Search Results" : "From Your Dictionary");
      results.addAll(_offlineResults);
    }
    // Only show the PONS results on mobile
    if (_backendOnlineResults.isNotEmpty && !kIsWeb) {
      if (results.isNotEmpty) results.add(""); // Spacer
      results.add("Online Results (PONS)");
      results.addAll(_backendOnlineResults);
    }
    return results;
  }
  
  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isDarkMode ? Colors.white : Colors.black;
    final anyLoading = _isLoadingOffline || _isLoadingBackend;
    final bool showHistory = _searchController.text.isEmpty && !anyLoading;
    final bool showResults = _searchController.text.isNotEmpty && !anyLoading;
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: TextStyle(color: themeColor),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchHint,
              prefixIcon: Icon(
                Icons.search,
                color: themeColor,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              filled: true,
              fillColor: widget.isDarkMode ? Colors.grey[800] : Colors.grey[200],
            ),
            onChanged: (query) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () {
                if (query.trim().isNotEmpty) {
                  _performSearch(query.trim());
                  _saveSearchQuery(query.trim());
                } else {
                  setState(() {
                    _offlineResults = [];
                    _backendOnlineResults = [];
                    _isLoadingOffline = false;
                    _isLoadingBackend = false;
                  });
                  _loadSearchHistory();
                }
              });
            },
          ),
        ),
        Expanded(
          child: Builder(builder: (context) {
            if (showHistory) {
              return _buildHistoryList(themeColor);
            }
            if (showResults) {
              if (_displayResults.isEmpty && _searchController.text.isNotEmpty) {
                return Center(
                  child: Text(
                    '${AppLocalizations.of(context)!.noResults} "${_searchController.text}"',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }
              return _buildResultsList();
            }
            if(anyLoading && _searchController.text.isNotEmpty) {
              return const SizedBox.shrink(); 
            }
            return Center(child: Text(
              AppLocalizations.of(context)!.startTypingToSearch,
              style: TextStyle(color: themeColor.withOpacity(0.7))
            ));
          }),
        ),
      ],
    );
  }
  
  ListView _buildResultsList() {
    final results = _displayResults;
    final themeColor = widget.isDarkMode ? Colors.white : Colors.black;
    
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];

        if (item is String) { 
          if (item.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Text(
              AppLocalizations.of(context)!.errorLoadingSearchResults,
              style: const TextStyle(color: Colors.red)
            ),
          );
        }

        if (item is Word) { 
          final isBookmarked = _bookmarkedWordIds.contains(item.id);
          return ListTile(
            title: BiDirectionalText(
              item.germanWord ?? 'N/A', 
              style: TextStyle(color: themeColor, fontWeight: FontWeight.bold),
              forceLTR: true, // German words should be LTR
            ),
            subtitle: BiDirectionalText(
              item.persianWord ?? AppLocalizations.of(context)!.noTranslationAvailable,
              style: const TextStyle(color: Colors.blueAccent, fontSize: 16),
            ),
            trailing: IconButton(
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border, 
                color: isBookmarked ? Colors.amber : themeColor.withAlpha(128),
              ),
              onPressed: () => _toggleBookmark(item.id),
            ),
            onTap: () => Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (context) => WordDetailView(
                  wordId: item.id,
                  isDarkMode: Theme.of(context).brightness == Brightness.dark,
                ),
              ),
            ),
          );
        }
        
        if (item is PonsTranslation) { 
          return ListTile(
            title: Text(item.source, style: TextStyle(color: themeColor)),
            subtitle: Text(item.target, style: const TextStyle(color: Colors.green, fontSize: 16)),
            leading: const Icon(Icons.cloud_queue_outlined, color: Colors.green),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHistoryList(Color themeColor) {
    if (_searchHistory.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off, size: 48, color: themeColor.withAlpha(128)),
              const SizedBox(height: 16),
              Text(
                'Try Again',
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ],
          ),
        );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.recentSearches,
                style: TextStyle(
                  color: themeColor.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.bold
                ),
              ),
              TextButton(
                onPressed: _clearAllSearchHistory,
                child: Text(AppLocalizations.of(context)!.clearAll),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
              controller: widget.scrollController,
              itemCount: _searchHistory.length,
              itemBuilder: (context, index) {
                  final historyItem = _searchHistory[index];
                  return ListTile(
                      title: Text(historyItem, style: TextStyle(color: themeColor)),
                      leading: Icon(Icons.history, color: themeColor.withOpacity(0.7)),
                      trailing: IconButton(
                          icon: Icon(Icons.close, size: 18, color: themeColor.withOpacity(0.7)),
                          onPressed: () => _removeSearchHistoryItem(index),
                      ),
                      onTap: () {
                          _searchController.text = historyItem;
                          _searchController.selection = TextSelection.fromPosition(TextPosition(offset: _searchController.text.length));
                          _performSearch(historyItem);
                      },
                  );
              },
          ),
        ),
      ],
    );
  }
}

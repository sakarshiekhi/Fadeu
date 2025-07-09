import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Import for Completer

// Import your other pages like the Vocabulary Trainer page
// import 'path/to/vocabulary_trainer_page.dart';
// import 'package:jalali_calendar/jalali_calendar.dart';

// Define a simple model to parse the API response
class DictionaryEntry {
  final int id;
  final String germanTerm;
  final String persianTranslation;
  final String persianDefinition;
  final String germanGender;
  final String germanPlural;

  DictionaryEntry({
    required this.id,
    required this.germanTerm,
    required this.persianTranslation,
    required this.persianDefinition,
    required this.germanGender,
    required this.germanPlural,
  });

  // Factory constructor to create a DictionaryEntry from a JSON map
  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    return DictionaryEntry(
      id: json['id'] ?? 0, // Provide a default or handle null if id is optional
      germanTerm: json['german_term'] ?? '',
      persianTranslation: json['persian_translation'] ?? '',
      persianDefinition: json['persian_definition'] ?? '', // Currently empty from API
      germanGender: json['german_gender'] ?? '', // Currently empty from API
      germanPlural: json['german_plural'] ?? '', // Currently empty from API
    );
  }

  // Add toJson for saving bookmarks if needed (by ID or term)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'german_term': germanTerm,
      'persian_translation': persianTranslation,
      'persian_definition': persianDefinition,
      'german_gender': germanGender,
      'german_plural': germanPlural,
    };
  }
}


class DictionaryHomePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const DictionaryHomePage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<DictionaryHomePage> createState() => _DictionaryHomePageState();
}

class _DictionaryHomePageState extends State<DictionaryHomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<DictionaryEntry> _searchResults = []; // List to hold search results
  bool _isLoading = false; // To show a loading indicator for the overall list
  List<String> _searchHistory = []; // List to hold recent search terms
  Set<int> _bookmarkedWordIds = {}; // Set to hold IDs of bookmarked words
  final FocusNode _searchFocusNode = FocusNode(); // To track search bar focus

  static const _historyKey = 'searchHistory';
  static const _bookmarksKey = 'bookmarkedWordIds';

  // For managing the ongoing HTTP request for cancellation
  http.Client? _httpClient;
  Completer<void>? _currentSearchCompleter;


  @override
  void initState() {
    super.initState();
    _loadHistoryAndBookmarks(); // Load data when the widget initializes
    // Optionally fetch daily word when the page initializes (function kept but not displayed)
    // _fetchDailyWord(); // Uncomment if needed
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose(); // Dispose focus node
    _httpClient?.close(); // Close the client when the widget is disposed
    _currentSearchCompleter?.completeError(Exception('Widget disposed')); // Complete completer on dispose
    super.dispose();
  }

  // --- Persistence Functions ---
  Future<void> _loadHistoryAndBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load history (default to empty list if not found)
      _searchHistory = prefs.getStringList(_historyKey) ?? [];
      // Load bookmarks (convert List<String> to Set<int>)
      final bookmarkedIdsStringList = prefs.getStringList(_bookmarksKey) ?? [];
      _bookmarkedWordIds = bookmarkedIdsStringList.map((id) => int.tryParse(id) ?? 0).where((id) => id != 0).toSet();
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(_historyKey, _searchHistory);
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    // Convert Set<int> to List<String> for saving
    final bookmarkedIdsStringList = _bookmarkedWordIds.map((id) => id.toString()).toList();
    prefs.setStringList(_bookmarksKey, bookmarkedIdsStringList);
  }

  void _addSearchTermToHistory(String term) {
    if (term.trim().isEmpty) return;
    // Remove the term if it already exists to move it to the top
    _searchHistory.remove(term);
    // Add the new term at the beginning of the list
    _searchHistory.insert(0, term);
    // Keep the history size manageable (e.g., max 10 terms)
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.sublist(0, 10);
    }
    _saveHistory(); // Save updated history
  }

  void _toggleBookmark(DictionaryEntry entry) {
    setState(() {
      if (_bookmarkedWordIds.contains(entry.id)) {
        _bookmarkedWordIds.remove(entry.id);
      } else {
        _bookmarkedWordIds.add(entry.id);
      }
    });
    _saveBookmarks(); // Save updated bookmarks
    // Optionally show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${entry.germanTerm} ${_bookmarkedWordIds.contains(entry.id) ? "bookmarked" : "unbookmarked"}!')),
    );
  }

  void _cancelSearch() {
    // Close the current HTTP client, which will cancel the ongoing request
    _httpClient?.close();
    _httpClient = null; // Clear the client
    _currentSearchCompleter?.completeError(Exception('Search cancelled')); // Complete with error
    _currentSearchCompleter = null; // Clear the completer

    setState(() {
      _isLoading = false; // Hide loading indicator
      // Optionally clear results or show a cancelled message
      // _searchResults = [];
    });
     ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search cancelled.')),
      );
  }

  // --- API CALL FUNCTION ---
  Future<void> _performSearch(String query) async {
    // If a search is already in progress, cancel it first
    if (_isLoading) {
      _cancelSearch();
      // A brief delay might be needed to ensure client is closed before new request
      await Future.delayed(Duration(milliseconds: 50));
    }

    if (query.isEmpty) {
      setState(() {
        _searchResults = []; // Clear results if search bar is empty
      });
      return;
    }

    // Add the search term to history *before* performing the search
    _addSearchTermToHistory(query);

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    // Create a new HTTP client for this request
    _httpClient = http.Client();
    // Create a new completer to track this specific search operation
    _currentSearchCompleter = Completer<void>();

    // Replace with your actual Django API URL
    final url = Uri.parse('http://10.0.2.2:8000/api/dictionary/search/?q=${Uri.encodeComponent(query)}');
    // Use 10.0.2.2 for Android emulator to reach host machine's localhost
    // Use 127.0.0.1 or localhost for iOS simulator or desktop

    try {
      // Use the new client to make the request
      final response = await _httpClient!.get(url);

      // Check if the completer hasn't been completed yet (i.e., not cancelled)
      if (_currentSearchCompleter != null && !_currentSearchCompleter!.isCompleted) {
        if (response.statusCode == 200) {
          final dynamic data = jsonDecode(response.body);

          if (data != null && data['results'] is List) {
            final List<dynamic> resultsList = data['results'];
            setState(() {
              _searchResults = resultsList.map((item) => DictionaryEntry.fromJson(item)).toList();
            });
          } else {
              print('API response did not contain a list in "results": $data');
              setState(() {
              _searchResults = []; // Clear previous results on error
              });
          }

        } else {
          print('API request failed with status: ${response.statusCode}');
          print('Response body: ${response.body}');
          setState(() {
            _searchResults = []; // Clear previous results on error
          });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to fetch dictionary entries.')),
            );
        }
      }

    } catch (e) {
       // Check if the completer hasn't been completed (e.g., by cancellation)
       if (_currentSearchCompleter != null && !_currentSearchCompleter!.isCompleted) {
          print('Error fetching dictionary entries: $e');
            setState(() {
            _searchResults = []; // Clear previous results on error
            });
          // Only show snackbar if it wasn't a deliberate cancellation
          if (e is! Exception || e.toString() != 'Exception: Search cancelled') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Network error: ${e.toString()}')),
            );
          }
       }
    } finally {
      // Ensure state is updated only if not cancelled externally
       if (_currentSearchCompleter != null && !_currentSearchCompleter!.isCompleted) {
         setState(() {
           _isLoading = false; // Hide loading indicator
         });
         _httpClient?.close(); // Close the client after the request is done
         _httpClient = null; // Clear the client
         _currentSearchCompleter?.complete(); // Complete the completer successfully
         _currentSearchCompleter = null; // Clear the completer
       } else if (_isLoading && (_currentSearchCompleter == null || _currentSearchCompleter!.isCompleted)) {
          // If loading was true but completer is already done (due to cancellation),
          // ensure isLoading is set to false
           setState(() {
             _isLoading = false;
           });
           _httpClient?.close(); // Close any remaining client
           _httpClient = null;
           _currentSearchCompleter = null;
       }
    }
  }


  // --- Placeholder Functions (Kept but not in UI except add to trainer) ---
  // --- Placeholder Function for adding words to trainer ---
    void _addWordToTrainer(DictionaryEntry entry) {
    // TODO: Implement logic to add a word to the vocabulary trainer list
    print("Adding word ${entry.germanTerm} to trainer...");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${entry.germanTerm} added to trainer!')),
      );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final themeColor = isDark ? Colors.white : Colors.black;
    final Color cardColor = isDark ? Colors.grey[800]! : Colors.white;

    // Determine the suffix icon content based on loading state and text presence
    Widget? suffixIconContent;
    if (_isLoading) {
      suffixIconContent = Row(
        mainAxisSize: MainAxisSize.min, // Use minimum space
        children: [
          SizedBox(
            width: 20, // Adjust size of loading indicator
            height: 20, // Adjust size of loading indicator
            child: CircularProgressIndicator(
              strokeWidth: 2.5, // Adjust thickness
              color: Colors.deepPurple, // Loading indicator color
            ),
          ),
          const SizedBox(width: 8), // Space between loading and cancel
          IconButton(
            icon: Icon(Icons.cancel, color: themeColor.withOpacity(0.7)),
            onPressed: _cancelSearch, // Call the cancel function
            tooltip: 'Cancel Search',
          ),
        ],
      );
    } else if (_searchController.text.isNotEmpty) {
      suffixIconContent = IconButton(
          icon: Icon(Icons.clear, color: themeColor.withOpacity(0.7)),
          onPressed: () {
            _searchController.clear();
            _performSearch(''); // Clear results when search is cleared
          },
          tooltip: 'Clear Search',
        );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "fadeu", // App title
            style: GoogleFonts.pacifico(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: themeColor,
            ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => RotationTransition(
                turns: Tween(begin: 0.75, end: 1.0).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Icon(
                isDark ? Icons.wb_sunny : Icons.nightlight_round,
                key: ValueKey<bool>(isDark),
                color: themeColor,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- SEARCH BAR ---
            const SizedBox(height: 20),
            TextFormField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              keyboardType: TextInputType.text,
              style: TextStyle(color: themeColor),
              decoration: InputDecoration(
                hintText: 'Search word...',
                hintStyle: TextStyle(color: themeColor.withOpacity(0.6)),
                prefixIcon: Icon(Icons.search, color: themeColor),
                filled: true,
                fillColor: isDark ? Colors.black26 : Colors.grey[200],
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: themeColor.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.deepPurple),
                  borderRadius: BorderRadius.circular(12),
                ),
                 // Animated Suffix Icon
                 suffixIcon: AnimatedSwitcher(
                   duration: const Duration(milliseconds: 300),
                   transitionBuilder: (child, animation) => FadeTransition(
                     opacity: animation,
                     child: child,
                   ),
                   child: suffixIconContent, // Use the determined content
                   // Key is important for AnimatedSwitcher to differentiate states
                   key: ValueKey<bool>(_isLoading),
                 ),
              ),
              onChanged: (value) {
                  // Debounce or throttle search for performance in a real app
                  _performSearch(value);
              },
              onFieldSubmitted: (value) {
                 _performSearch(value);
              },
            ),

            // --- SEARCH RESULTS / HISTORY LIST ---
            const SizedBox(height: 20),
             if (_searchController.text.isNotEmpty && _searchResults.isNotEmpty && !_isLoading)
              Text(
                  "Search Results",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            if (_searchFocusNode.hasFocus && _searchController.text.isEmpty && _searchHistory.isNotEmpty && !_isLoading)
               Text(
                  "Recent Searches",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
             const SizedBox(height: 8),

            _isLoading && _searchResults.isEmpty // Show loading indicator only when no results are displayed yet
                ? Center(child: CircularProgressIndicator(color: Colors.deepPurple))
                : Expanded(
                    child: _searchController.text.isEmpty && _searchHistory.isNotEmpty && _searchFocusNode.hasFocus && !_isLoading
                        ? ListView.builder( // Display search history when focused and empty
                             itemCount: _searchHistory.length,
                             itemBuilder: (context, index) {
                               final term = _searchHistory[index];
                               return ListTile(
                                 leading: Icon(Icons.history, color: themeColor.withOpacity(0.7)),
                                 title: Text(term, style: TextStyle(color: themeColor)),
                                 trailing: IconButton(
                                   icon: Icon(Icons.clear, size: 20, color: themeColor.withOpacity(0.7)),
                                   onPressed: () {
                                     setState(() {
                                       _searchHistory.remove(term);
                                     });
                                     _saveHistory(); // Save after removing
                                   },
                                 ),
                                 onTap: () {
                                   _searchController.text = term;
                                   _performSearch(term); // Perform search for history item
                                 },
                               );
                             },
                           )
                        : _searchResults.isEmpty && _searchController.text.isNotEmpty && !_isLoading
                            ? Center(
                                child: Text(
                                  "No results found.",
                                  style: TextStyle(fontSize: 16, color: themeColor.withOpacity(0.8)),
                                ),
                              )
                            : _searchResults.isEmpty && _searchController.text.isEmpty && !_searchFocusNode.hasFocus && !_isLoading
                                ? Center( // Initial message when search is empty and not focused
                                    child: Text(
                                      "Start typing to search the dictionary.",
                                       style: TextStyle(fontSize: 16, color: themeColor.withOpacity(0.8)),
                                    )
                                  )
                                : ListView.builder( // Display search results
                                    itemCount: _searchResults.length,
                                    itemBuilder: (context, index) {
                                      final entry = _searchResults[index];
                                      final isBookmarked = _bookmarkedWordIds.contains(entry.id);
                                      return Card(
                                        color: cardColor,
                                        elevation: 2,
                                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: ListTile(
                                          title: Text(
                                            entry.germanTerm,
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: themeColor,
                                              ),
                                          ),
                                          subtitle: Text(
                                            entry.persianTranslation,
                                            style: TextStyle(
                                                fontSize: 15,
                                                color: themeColor.withOpacity(0.9)
                                              ),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(
                                                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                                                    color: isBookmarked ? Colors.amber : themeColor.withOpacity(0.7)
                                                    ),
                                                onPressed: () {
                                                   _toggleBookmark(entry);
                                                },
                                                tooltip: isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
                                              ),
                                              IconButton(
                                                  icon: Icon(Icons.add_circle_outline, color: Colors.deepPurple),
                                                  onPressed: () {
                                                     _addWordToTrainer(entry);
                                                    },
                                                  tooltip: 'Add to Trainer',
                                                  ),
                                            ],
                                          ),
                                          onTap: () {
                                            // Navigate to a detail page or show a dialog
                                            print("Tapped on ${entry.germanTerm}");
                                          },
                                        ),
                                      );
                                    },
                                  ),
                  ),
          ],
        ),
      ),
    );
  }
}
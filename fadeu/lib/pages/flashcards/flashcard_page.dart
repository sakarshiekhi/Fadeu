import 'package:flutter/material.dart';
import 'package:fadeu/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:fadeu/models/word_model.dart';
// --- FIX: Reverting to the original DatabaseHelper and ApiService ---
import 'package:fadeu/services/DatabaseHelper.dart';
import 'package:fadeu/services/api_service.dart';
import 'package:fadeu/pages/flashcards/flashcard.dart';
// --- FIX: Import to check for web platform ---
import 'package:flutter/foundation.dart' show kIsWeb;

class FlashcardsPage extends StatefulWidget {
  final bool isDarkMode;
  const FlashcardsPage({super.key, required this.isDarkMode});

  @override
  State<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends State<FlashcardsPage> {
  // --- FIX: Use the original DatabaseHelper instance ---
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final PageController _pageController = PageController();

  List<Word> _flashcardWords = [];
  bool _isLoading = true;
  String _selectedLevel = 'All';
  final List<String> _levels = ['All', 'A1', 'A2', 'B1'];

  Timer? _watchTimeTimer;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    debugPrint('FlashcardsPage initState: Starting _initializeAndLoad...');
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    // Prefs are needed on both platforms for stats
    _prefs = await SharedPreferences.getInstance();
    debugPrint('FlashcardsPage: SharedPreferences initialized.');
    _loadWordsForLevel(_selectedLevel);
    // Only start the timer on mobile where local stats are primary
    if (!kIsWeb) {
      _startWatchTimeTimer();
    }
  }

  void _startWatchTimeTimer() {
    if (_watchTimeTimer == null || !_watchTimeTimer!.isActive) {
      _watchTimeTimer =
          Timer.periodic(const Duration(seconds: 10), (timer) async {
        int currentWatchTimeSeconds = _prefs.getInt('watchTimeSeconds') ?? 0;
        await _prefs.setInt('watchTimeSeconds', currentWatchTimeSeconds + 10);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _watchTimeTimer?.cancel();
    super.dispose();
  }

  // --- FIX: This method now uses the correct logic for each platform ---
  Future<void> _loadWordsForLevel(String level) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _selectedLevel = level;
      debugPrint('FlashcardsPage: Loading words for level: $level');
    });

    await Future.delayed(const Duration(milliseconds: 300));

    List<Word> words;
    // On the web, fetch from the Django backend
    if (kIsWeb) {
      // Fetch all words for the level without any limit
      final apiService = ApiService();
      words = await apiService.fetchFlashcardWords(level: level);
      debugPrint('Fetched ${words.length} words from the backend for level: $level');
    } 
    // On mobile, fetch from the local SQLite database
    else {
      if (level == 'All') {
        // Get all words without limit
        words = await _dbHelper.getRandomWords(limit: 0); // 0 means no limit
      } else {
        // Get all words for the level without limit
        words = await _dbHelper.getWordsByLevel(level, limit: 0); // 0 means no limit
      }
      debugPrint('Fetched ${words.length} words from local database for level: $level');
    }

    if (mounted) {
      setState(() {
        _flashcardWords = words;
        _isLoading = false;
        debugPrint(
            'FlashcardsPage: Words loaded for level: $level. Count: ${words.length}');
      });
      if (_pageController.hasClients && _pageController.page != 0) {
        _pageController.jumpToPage(0);
      }
    }
  }

  void _incrementFlippedWordCount() async {
    int currentTotalFlipped = _prefs.getInt('flashcardsCompleted') ?? 0;
    await _prefs.setInt('flashcardsCompleted', currentTotalFlipped + 1);

    String levelKey = 'flashcardsFlipped_${_selectedLevel.replaceAll(' ', '')}';
    int currentLevelFlipped = _prefs.getInt(levelKey) ?? 0;
    await _prefs.setInt(levelKey, currentLevelFlipped + 1);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isDarkMode ? Colors.white : Colors.black;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Wrap(
            spacing: 8.0,
            alignment: WrapAlignment.center,
            children: _levels.map((level) {
              return ChoiceChip(
                label: Text(_getLocalizedLevel(level)),
                selected: _selectedLevel == level,
                onSelected: (isSelected) {
                  if (isSelected) {
                    _loadWordsForLevel(level);
                  }
                },
                selectedColor: Colors.deepPurple,
                labelStyle: TextStyle(
                  color: _selectedLevel == level
                      ? Colors.white
                      : (widget.isDarkMode ? Colors.white70 : Colors.black87),
                ),
                backgroundColor:
                    widget.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                showCheckmark: false,
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _isLoading
                ? const Center(
                    key: ValueKey('loading'),
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                    ),
                  )
                : _flashcardWords.isEmpty
                    ? Center(
                        key: const ValueKey('no_words_found'),
                        child: Text(
                            AppLocalizations.of(context)!.noWordsFoundForLevel,
                            style: TextStyle(color: themeColor.withOpacity(0.7))))
                    : PageView.builder(
                        key: ValueKey(_selectedLevel),
                        controller: _pageController,
                        scrollDirection: Axis.vertical,
                        itemCount: _flashcardWords.length,
                        onPageChanged: (index) {
                          _incrementFlippedWordCount();
                        },
                        itemBuilder: (context, index) {
                          return Center(
                            child: AspectRatio(
                              aspectRatio: 3 / 4,
                              child: Flashcard(
                                key: ValueKey(_flashcardWords[index].id),
                                word: _flashcardWords[index],
                                isDarkMode: widget.isDarkMode,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }

  String _getLocalizedLevel(String level) {
    switch (level) {
      case 'All':
        return AppLocalizations.of(context)!.flashcardLevelAll;
      case 'A1':
        return AppLocalizations.of(context)!.flashcardLevelA1;
      case 'A2':
        return AppLocalizations.of(context)!.flashcardLevelA2;
      case 'B1':
        return AppLocalizations.of(context)!.flashcardLevelB1;
      default:
        return level;
    }
  }
}

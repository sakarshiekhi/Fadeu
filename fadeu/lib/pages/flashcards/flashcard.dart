import 'package:flutter/material.dart';
import 'package:fadeu/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../models/word_model.dart';
import '../../services/DatabaseHelper.dart';

class Flashcard extends StatefulWidget {
  final Word word;
  final bool isDarkMode;
  const Flashcard({super.key, required this.word, required this.isDarkMode});

  @override
  State<Flashcard> createState() => _FlashcardState();
}

class _FlashcardState extends State<Flashcard> {
  bool _isFlipped = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadBookmarkState();
  }

  Future<void> _loadBookmarkState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isSaved = (prefs.getStringList('bookmarkedWordIds') ?? [])
            .contains(widget.word.id.toString());
      });
    }
  }

  Future<void> _toggleSave() async {
    if (!mounted) return;
    
    final newSaveState = !_isSaved;
    
    // Optimistically update UI
    setState(() {
      _isSaved = newSaveState;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> savedIds = prefs.getStringList('bookmarkedWordIds') ?? [];
      
      if (newSaveState) {
        if (!savedIds.contains(widget.word.id.toString())) {
          savedIds.add(widget.word.id.toString());
        }
      } else {
        savedIds.remove(widget.word.id.toString());
      }
      
      await prefs.setStringList('bookmarkedWordIds', savedIds);
      
      // Update the word count in SharedPreferences
      final currentCount = prefs.getInt('wordsSaved') ?? 0;
      if (newSaveState) {
        await prefs.setInt('wordsSaved', currentCount + 1);
      } else if (currentCount > 0) {
        await prefs.setInt('wordsSaved', currentCount - 1);
      }
      
      // Update the local database if not on web
      if (!kIsWeb) {
        final dbHelper = DatabaseHelper();
        await dbHelper.toggleSaveStatus(widget.word.id, newSaveState);
      }
      
    } catch (e) {
      debugPrint('Error toggling save state: $e');
      
      // Revert UI on error
      if (mounted) {
        setState(() {
          _isSaved = !newSaveState;
        });
      }
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${newSaveState ? 'save' : 'unsave'} word'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void didUpdateWidget(covariant Flashcard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.word.id != oldWidget.word.id) {
      setState(() {
        _isFlipped = false;
      });
      _loadBookmarkState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isDarkMode ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isFlipped = !_isFlipped),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) {
                final rotateAnim =
                    Tween(begin: 3.14, end: 0.0).animate(animation);
                return AnimatedBuilder(
                  animation: rotateAnim,
                  child: child,
                  builder: (context, child) {
                    return Transform(
                        transform: Matrix4.rotationY(rotateAnim.value),
                        alignment: Alignment.center,
                        child: child);
                  },
                );
              },
              child: _isFlipped ? _buildBackCard() : _buildFrontCard(),
            ),
          ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: IconButton(
              onPressed: _toggleSave,
              icon: Icon(
                _isSaved ? Icons.bookmark : Icons.bookmark_border,
                // --- FIX: Using withAlpha to avoid deprecated member ---
                color: _isSaved ? Colors.amber : themeColor.withAlpha(178),
                size: 32,
              ),
              tooltip: AppLocalizations.of(context)!.saveWordTooltip,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontCard() {
    final cardColor =
        widget.isDarkMode ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final exampleColor =
        widget.isDarkMode ? Colors.grey[400] : Colors.grey[700];
    final articleColor =
        widget.isDarkMode ? Colors.deepPurple[300] : Colors.deepPurple[700];

    return Card(
      key: const ValueKey(true),
      color: cardColor,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                // --- FIX: Force LTR for German content ---
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.lato(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: textColor),
                            children: [
                              if (widget.word.article != null &&
                                  widget.word.article!.isNotEmpty)
                                TextSpan(
                                  text: '${widget.word.article} ',
                                  style: TextStyle(
                                      color: articleColor,
                                      fontWeight: FontWeight.normal),
                                ),
                              TextSpan(
                                text: widget.word.germanWord?.isNotEmpty == true 
                                    ? widget.word.germanWord 
                                    : 'No translation available',
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (widget.word.example != null &&
                          widget.word.example!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 24.0, left: 16.0, right: 16.0),
                          child: Text(
                            widget.word.example!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(
                                fontSize: 18,
                                fontStyle: FontStyle.italic,
                                color: exampleColor),
                            softWrap: true,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard() {
    const cardColor = Colors.deepPurple;
    const textColor = Colors.white;
    final exampleColor = Colors.white.withAlpha(217); // ~85% opacity

    return Card(
      key: const ValueKey(false),
      color: cardColor,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- FIX: Force RTL for Persian Word ---
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.word.persianWord?.isNotEmpty == true 
                                ? widget.word.persianWord! 
                                : 'ترجمه موجود نیست', // 'No translation available' in Persian
                            textAlign: TextAlign.center,
                            style: GoogleFonts.lato(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: textColor),
                          ),
                        ),
                      ),
                      // --- FIX: Force RTL for Persian Example ---
                      if (widget.word.examplePersian != null &&
                          widget.word.examplePersian!.isNotEmpty)
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(top: 8.0, bottom: 24.0),
                            child: Text(
                              widget.word.examplePersian!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                  fontSize: 18,
                                  fontStyle: FontStyle.italic,
                                  color: exampleColor),
                              softWrap: true,
                            ),
                          ),
                        ),

                      // --- FIX: Force LTR for English Word ---
                      if (widget.word.englishWord != null &&
                          widget.word.englishWord!.isNotEmpty)
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.word.englishWord!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                  fontSize: 28,
                                  // --- FIX: Using withAlpha to avoid deprecated member ---
                                  color: textColor.withAlpha(204), // ~80% opacity
                                  fontStyle: FontStyle.italic),
                            ),
                          ),
                        ),

                      // --- FIX: Force LTR for English Example ---
                      if (widget.word.exampleEnglish != null &&
                          widget.word.exampleEnglish!.isNotEmpty)
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              widget.word.exampleEnglish!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                  fontSize: 18,
                                  fontStyle: FontStyle.italic,
                                  color: exampleColor),
                              softWrap: true,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

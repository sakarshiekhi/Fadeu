// lib/pages/dictionary/homePage.dart (assuming this is your main_home_page.dart)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Still needed for SearchView callbacks
import 'package:fadeu/l10n/app_localizations.dart';

import 'package:fadeu/pages/settings/settings.dart';
import 'package:fadeu/pages/flashcards/flashcard_page.dart';
import 'package:fadeu/pages/saved_words/saved_words.dart'; // Assuming you removed the 'as saved_words' if not needed globally
import 'package:fadeu/pages/search/search_view.dart'; // Assuming you removed the 'as search_view' if not needed globally

// --- Main Application Home Page ---
class MainHomePage extends StatefulWidget {
  final bool isDarkMode;
  final Function(ThemeMode) onThemeChanged;
  final Function(Locale) onLanguageChanged;
  final Locale currentLocale;

  const MainHomePage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.currentLocale,
  });

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _showSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color:
                    widget.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              // Now using the external SearchView
              child: SearchView(
                // Used directly, not aliased
                isDarkMode: widget.isDarkMode,
                scrollController: scrollController,
                onSearchPerformed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  int currentSearched = prefs.getInt('wordsSearched') ?? 0;
                  await prefs.setInt('wordsSearched', currentSearched + 1);
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isDarkMode ? Colors.white : Colors.black;

    final List<Widget> pages = <Widget>[
      // Using the external FlashcardsPage
      FlashcardsPage(
          isDarkMode: widget.isDarkMode), // <<<--- No alias needed here
      // Using the external SavedWordsPage
      SavedWordsPage(
          isDarkMode: widget.isDarkMode), // Used directly, not aliased
      SettingsPage(
        isDarkMode: widget.isDarkMode,
        onLanguageChanged: widget.onLanguageChanged,
        onThemeChanged: widget.onThemeChanged,
        currentLocale: widget.currentLocale,
        currentThemeMode: widget.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          "fadeu",
          style: GoogleFonts.pacifico(fontSize: 28, color: themeColor),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            color: themeColor,
            onPressed: () => _showSearchSheet(context),
            tooltip: AppLocalizations.of(context)!.searchTooltip,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: pages.length,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return pages[index];
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.style),
            label: AppLocalizations.of(context)!.flashcardsTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bookmark),
            label: AppLocalizations.of(context)!.savedTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: AppLocalizations.of(context)!.settingsTab,
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor:
            widget.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor:
            widget.isDarkMode ? Colors.grey[600] : Colors.grey[800],
        showUnselectedLabels: false,
        showSelectedLabels: true,
      ),
    );
  }
}

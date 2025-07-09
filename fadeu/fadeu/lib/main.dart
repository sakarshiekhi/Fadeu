import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:fadeu/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Import to check for web platform

// --- Imports for your app's pages ---
import 'package:fadeu/pages/auth/login.dart';
import 'package:fadeu/pages/dictionary/homePage.dart';
import 'package:fadeu/pages/welcome/welcom.dart';

// --- Imports for services and packages ---
import 'package:google_fonts/google_fonts.dart';
import 'package:fadeu/services/notification_service.dart';
import 'package:fadeu/services/background_handler.dart';
import 'package:fadeu/services/navigator_service.dart';
import 'package:fadeu/services/sync_service.dart';
import 'package:fadeu/utils/sync_utils.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

// This function will only be used on mobile, so it's safe.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await NotificationService().init();
      await BackgroundHandler.executeTask();
      return Future.value(true);
    } catch (e) {
      print("Background task failed with error: $e");
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services for the main app
  await NotificationService().init();
  
  // Initialize sync service
  final syncService = SyncService();
  
  try {
    await syncService.initialize();
    
    // Initialize background sync only on mobile/desktop
    if (!kIsWeb) {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: true,
      );
      
      // Register background sync task
      await Workmanager().registerPeriodicTask(
        '1',
        'syncTask',
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
      );
    }
  } catch (e) {
    debugPrint('Error during service initialization: $e');
  }

  debugPrint('App started: WidgetsFlutterBinding initialized.');
  // Wrap the app with SyncInitializer to handle sync operations
  runApp(
    Provider<SyncService>.value(
      value: syncService,
      child: SyncInitializer(
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool? initialHasCompletedLogin;
  const MyApp({super.key, this.initialHasCompletedLogin});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');

  late SharedPreferences _prefs;
  bool _isLoadingApp = true;
  bool _hasCompletedLogin = false;

  @override
  void initState() {
    super.initState();
    debugPrint('MyApp initState: Starting _loadAppState...');
    _loadAppState();
  }

  Future<void> _loadAppState() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('MyApp: SharedPreferences initialized.');

    final themeString = _prefs.getString('themeMode');
    if (themeString != null) {
      _themeMode = themeString == 'dark' ? ThemeMode.dark : ThemeMode.light;
    } else {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _themeMode =
          brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    }

    final localeString = _prefs.getString('locale');
    if (localeString != null) {
      _locale = Locale(localeString);
    } else {
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      _locale = AppLocalizations.supportedLocales.contains(systemLocale)
          ? systemLocale
          : const Locale('en');
    }

    _hasCompletedLogin = _prefs.getBool('hasCompletedLogin') ?? false;

    if (mounted) {
      setState(() {
        _isLoadingApp = false;
      });
      debugPrint('MyApp: Initial state loaded.');
    }

    await _checkAndIncrementStreak();
  }

  void _changeTheme(ThemeMode newThemeMode) {
    setState(() {
      _themeMode = newThemeMode;
    });
    _prefs.setString(
        'themeMode', newThemeMode == ThemeMode.dark ? 'dark' : 'light');
    debugPrint('MyApp: Theme changed and saved.');
  }

  void _changeLanguage(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
    _prefs.setString('locale', newLocale.languageCode);
    debugPrint(
        'MyApp: Language changed to ${newLocale.languageCode} and saved.');
  }

  Future<void> _checkAndIncrementStreak() async {
    final String? lastUsageDateString = _prefs.getString('lastAppUsageDate');
    int currentStreak = _prefs.getInt('longestStreak') ?? 0;
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    if (lastUsageDateString != null) {
      final DateTime lastUsageDate = DateTime.parse(lastUsageDateString);
      if (today.difference(lastUsageDate).inDays == 1) {
        currentStreak++;
      } else if (today.difference(lastUsageDate).inDays > 1) {
        currentStreak = 1;
      }
    } else {
      currentStreak = 1;
    }
    await _prefs.setInt('longestStreak', currentStreak);
    await _prefs.setString('lastAppUsageDate', today.toIso8601String());
  }

  // Helper method to get text direction based on locale
  TextDirection _getTextDirection(Locale locale) {
    switch (locale.languageCode) {
      case 'fa':
        return TextDirection.rtl;
      default:
        return TextDirection.ltr;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the text direction based on current locale
    final textDirection = _getTextDirection(_locale);
    
    if (_isLoadingApp) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Directionality(
          textDirection: textDirection,
          child: const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Fadeu',
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigatorService.navigatorKey,
      themeMode: _themeMode,
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return Directionality(
          textDirection: textDirection,
          child: child!,
        );
      },
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[100],
        fontFamily: GoogleFonts.vazirmatn().fontFamily,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        fontFamily: GoogleFonts.vazirmatn().fontFamily,
      ),
      home: _hasCompletedLogin
          ? MainHomePage(
              isDarkMode: _themeMode == ThemeMode.dark,
              onThemeChanged: _changeTheme,
              onLanguageChanged: _changeLanguage,
              currentLocale: _locale,
            )
          : WelcomePage(
              isDarkMode: _themeMode == ThemeMode.dark,
              onThemeChanged: _changeTheme,
              onLanguageChanged: _changeLanguage,
              currentLocale: _locale,
            ),
      routes: {
        '/login': (context) => Login(
              onThemeChanged: _changeTheme,
              onLanguageChanged: _changeLanguage,
              currentLocale: _locale,
              isDarkMode: _themeMode == ThemeMode.dark,
            ),
        '/home': (context) => MainHomePage(
              isDarkMode: _themeMode == ThemeMode.dark,
              onThemeChanged: _changeTheme,
              onLanguageChanged: _changeLanguage,
              currentLocale: _locale,
            ),
      },
    );
  }
}

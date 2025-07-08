import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:fadeu/services/DatabaseHelper.dart';
import 'package:fadeu/models/word_model.dart';
import 'package:fadeu/l10n/app_localizations.dart';
import 'dart:convert';
import 'package:fadeu/services/navigator_service.dart';
import 'package:fadeu/pages/word_detail/word_detail_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService with WidgetsBindingObserver {
  static final NotificationService _notificationService = NotificationService._internal();
  factory NotificationService() {
    return _notificationService;
  }
  NotificationService._internal() {
    if (!kIsWeb) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  // --- FIX: Using the original DatabaseHelper ---
  final DatabaseHelper _dbHelper = DatabaseHelper();

  bool _isAppActive = true;

  static const String _channelId = 'word_reminders_channel';
  static const String _channelName = 'Word Reminders';
  static const String _channelDescription = 'Notifications with new words to learn.';

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!kIsWeb) {
      _isAppActive = (state == AppLifecycleState.resumed);
    }
  }

  bool get isAppActive => _isAppActive;

  Future<void> init() async {
    if (kIsWeb) {
      debugPrint("Skipping Notification Service initialization on web.");
      return;
    }

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tehran'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onDidReceiveBackgroundNotificationResponse,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();

    debugPrint("Notification Service Initialized");
  }

  static void _onDidReceiveNotificationResponse(NotificationResponse response) async {
    if (response.payload?.isNotEmpty ?? false) {
      try {
        debugPrint('Notification tapped with payload: ${response.payload}');
        final payloadData = jsonDecode(response.payload!);
        final wordId = payloadData['wordId'];
        
        if (wordId != null && NavigatorService.navigatorKey.currentContext != null) {
          Navigator.of(NavigatorService.navigatorKey.currentContext!).push(
            MaterialPageRoute(
              builder: (context) => WordDetailView(
                wordId: wordId,
                isDarkMode: Theme.of(NavigatorService.navigatorKey.currentContext!).brightness == Brightness.dark,
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error handling notification response: $e');
      }
    }
  }
  
  @pragma('vm:entry-point')
  static void _onDidReceiveBackgroundNotificationResponse(NotificationResponse response) {
    // This is a top-level function that will be called when the app is in the background
    // or terminated. We just forward to the main handler.
    _onDidReceiveNotificationResponse(response);
  }


  Future<void> showInstantWordNotification({
    required String level,
    required AppLocalizations l10n,
  }) async {
    if (kIsWeb || isAppActive) {
      debugPrint("App is active or on web, suppressing notification.");
      return;
    }
    final Word? word = await _getRandomWordFromDb(level);

    if (word != null) {
      final String germanWord = word.germanWord ?? 'Word';
      final String persianMeaning = word.persianWord ?? '';
      final String germanExample = word.example ?? '';

      final String title = '🇩🇪 ${l10n.word}: $germanWord';
      final String body = '🇮🇷 $persianMeaning\n"${germanExample}"';

      final BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
        body,
        htmlFormatBigText: false,
        contentTitle: title,
        summaryText: l10n.wordReminders,
      );

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: bigTextStyleInformation,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: const DarwinNotificationDetails(presentSound: true),
      );
      
      final String payload = jsonEncode({'wordId': word.id});
      
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.toSigned(53),
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
      debugPrint("Instant notification shown for: $germanWord with payload: $payload");
    } else {
      debugPrint("Could not fetch a word from the database to show notification.");
    }
  }

  Future<Word?> _getRandomWordFromDb(String level) async {
    debugPrint("Fetching word for level: $level from DB for notification...");
    try {
      final List<Word> words = await _dbHelper.getWordsByLevel(level, limit: 1);
      if (words.isNotEmpty) {
        return words.first;
      }
    } catch (e) {
      debugPrint("Error fetching word from DB for notification: $e");
    }
    return null;
  }
}

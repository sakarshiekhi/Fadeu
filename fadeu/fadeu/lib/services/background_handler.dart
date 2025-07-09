// --- lib/services/background_handler.dart ---

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fadeu/services/notification_service.dart';
import 'package:fadeu/l10n/app_localizations.dart';

/// This class contains the logic that is executed by the Workmanager background task.
class BackgroundHandler {
  /// Fetches necessary data and triggers a notification.
  /// This runs in a separate isolate from the main UI.
  static Future<void> executeTask() async {
    debugPrint("BackgroundHandler: Executing background task...");
    try {
      final prefs = await SharedPreferences.getInstance();

      // --- FIX APPLIED HERE ---
      // We retrieve the level selected by the user on the settings page.
      // The key MUST match the one used in NotificationSettingsPage ('notificationLevel').
      // Default to 'All' if no level has been set, to match the settings page default.
      final String level = prefs.getString('notificationLevel') ?? 'All';

      // Background isolates don't have a BuildContext, so we cannot use AppLocalizations.of(context).
      // Instead, we manually load the localization strings using the saved locale preference.
      final String localeString = prefs.getString('locale') ?? 'en';
      final Locale locale = Locale(localeString);

      // AppLocalizations.delegate.load is the official way to get localizations without a context.
      final l10n = await AppLocalizations.delegate.load(locale);

      // Initialize the notification service and show the notification.
      final notificationService = NotificationService();
      await notificationService.init(); // Ensure it's initialized in this isolate.
      await notificationService.showInstantWordNotification(
        level: level,
        l10n: l10n,
      );
      debugPrint("BackgroundHandler: Background task completed successfully for level '$level'.");
    } catch (e) {
      debugPrint("BackgroundHandler: Error during background task: $e");
    }
  }
}

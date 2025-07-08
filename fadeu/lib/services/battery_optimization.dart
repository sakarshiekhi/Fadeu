// --- lib/services/battery_optimization.dart ---

import 'dart:io';
import 'package:flutter/services.dart';

/// A service class to handle checking and disabling battery optimization.
/// This is crucial for ensuring background tasks (like notifications) run reliably.
class BatteryOptimization {
  static const MethodChannel _channel =
      MethodChannel('fadeu/battery_optimization');

  /// Checks if battery optimization is already disabled for this app.
  ///
  /// Returns `true` if disabled, `false` if enabled, and `null` if the
  /// status cannot be determined (e.g., on iOS where this is not applicable).
  static Future<bool?> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return null;
    try {
      final bool? result =
          await _channel.invokeMethod('isBatteryOptimizationDisabled');
      return result;
    } catch (_) {
      return null;
    }
  }

  /// Opens the phone's system settings page where the user can manually
  /// disable battery optimization for the app.
  ///
  /// This is the recommended approach as automatically disabling it is not
  /// possible on modern Android versions.
  /// On iOS, this feature is not available, so the method will do nothing.
  static Future<void> showDisableBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('showDisableBatteryOptimizationSettings');
    } catch (_) {}
  }
}

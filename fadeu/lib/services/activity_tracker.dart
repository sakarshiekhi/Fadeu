import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fadeu/services/api_service.dart';

class ActivityTracker {
  static const _syncInterval = Duration(minutes: 5); // Sync every 5 minutes
  static const _minSyncInterval = Duration(seconds: 30); // Minimum time between syncs
  static Timer? _syncTimer;
  static DateTime? _lastSyncTime;

  // Track activity metrics
  static int _watchTimeSeconds = 0;
  static int _wordsSearched = 0;
  static int _wordsSaved = 0;
  static int _flashcardsCompleted = 0;
  static int _longestStreak = 0;
  static DateTime? _lastAppUsageDate;

  // Initialize the tracker
  static Future<void> initialize() async {
    await _loadFromPrefs();
    _startSyncTimer();
  }

  // Start the periodic sync timer
  static void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) => _syncWithBackend());
  }

  // Load saved data from SharedPreferences
  static Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _watchTimeSeconds = prefs.getInt('watchTimeSeconds') ?? 0;
    _wordsSearched = prefs.getInt('wordsSearched') ?? 0;
    _wordsSaved = prefs.getInt('wordsSaved') ?? 0;
    _flashcardsCompleted = prefs.getInt('flashcardsCompleted') ?? 0;
    _longestStreak = prefs.getInt('longestStreak') ?? 0;
    final lastSync = prefs.getString('lastSyncTime');
    _lastSyncTime = lastSync != null ? DateTime.parse(lastSync) : null;
  }

  // Save data to SharedPreferences
  static Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('watchTimeSeconds', _watchTimeSeconds);
    await prefs.setInt('wordsSearched', _wordsSearched);
    await prefs.setInt('wordsSaved', _wordsSaved);
    await prefs.setInt('flashcardsCompleted', _flashcardsCompleted);
    await prefs.setInt('longestStreak', _longestStreak);
    await prefs.setString('lastSyncTime', _lastSyncTime?.toIso8601String() ?? '');
  }

  // Increment watch time
  static void incrementWatchTime(int seconds) {
    _watchTimeSeconds += seconds;
    _lastAppUsageDate = DateTime.now();
    _scheduleSync();
  }

  // Increment words searched
  static void incrementWordsSearched() {
    _wordsSearched++;
    _lastAppUsageDate = DateTime.now();
    _scheduleSync();
  }

  // Increment words saved
  static void incrementWordsSaved() {
    _wordsSaved++;
    _lastAppUsageDate = DateTime.now();
    _scheduleSync();
  }

  // Increment flashcards completed
  static void incrementFlashcardsCompleted() {
    _flashcardsCompleted++;
    _lastAppUsageDate = DateTime.now();
    _scheduleSync();
  }

  // Update longest streak
  static void updateLongestStreak(int newStreak) {
    if (newStreak > _longestStreak) {
      _longestStreak = newStreak;
      _scheduleSync();
    }
  }

  // Schedule a sync with the backend
  static void _scheduleSync() {
    final now = DateTime.now();
    if (_lastSyncTime == null || now.difference(_lastSyncTime!) > _minSyncInterval) {
      _syncWithBackend();
    }
  }

  // Sync data with the backend
  /// Clears all user-specific activity data
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('watchTimeSeconds');
    await prefs.remove('wordsSearched');
    await prefs.remove('wordsSaved');
    await prefs.remove('flashcardsCompleted');
    await prefs.remove('longestStreak');
    await prefs.remove('lastSyncTime');
    
    // Reset in-memory values
    _watchTimeSeconds = 0;
    _wordsSearched = 0;
    _wordsSaved = 0;
    _flashcardsCompleted = 0;
    _longestStreak = 0;
    _lastSyncTime = null;
  }
  
  /// Updates local activity data with data from the server
  static Future<void> updateFromServer(Map<String, dynamic> serverData) async {
    try {
      debugPrint('Updating activity data from server: $serverData');
      
      // Update in-memory values
      _watchTimeSeconds = serverData['watchTimeSeconds'] ?? _watchTimeSeconds;
      _wordsSearched = serverData['wordsSearched'] ?? _wordsSearched;
      _wordsSaved = serverData['wordsSaved'] ?? _wordsSaved;
      _flashcardsCompleted = serverData['flashcardsCompleted'] ?? _flashcardsCompleted;
      _longestStreak = serverData['longestStreak'] ?? _longestStreak;
      
      // Update last sync time
      _lastSyncTime = DateTime.now();
      
      // Save to SharedPreferences
      await _saveToPrefs();
      
      debugPrint('Successfully updated local activity data from server');
    } catch (e) {
      debugPrint('Error updating activity data from server: $e');
      rethrow;
    }
  }
  
  /// Forces a sync with the backend
  static Future<bool> forceSync() async {
    try {
      await _syncWithBackend();
      return true;
    } catch (e) {
      debugPrint('Force sync failed: $e');
      return false;
    }
  }
  
  static Future<void> _syncWithBackend() async {
    try {
      final now = DateTime.now();
      if (_lastSyncTime != null && now.difference(_lastSyncTime!) < _minSyncInterval) {
        return; // Don't sync too frequently
      }

      final apiService = ApiService();
      final success = await apiService.syncUserActivity(
        watchTimeSeconds: _watchTimeSeconds,
        wordsSearched: _wordsSearched,
        wordsSaved: _wordsSaved,
        flashcardsCompleted: _flashcardsCompleted,
        longestStreak: _longestStreak,
      );

      if (success) {
        _lastSyncTime = now;
        await _saveToPrefs();
      }
    } catch (e) {
      // Silently fail, we'll try again on the next sync interval
      debugPrint('Failed to sync activity data: $e');
    }
  }

  // Get current activity data
  static Map<String, dynamic> getActivityData() {
    return {
      'watchTimeSeconds': _watchTimeSeconds,
      'wordsSearched': _wordsSearched,
      'wordsSaved': _wordsSaved,
      'flashcardsCompleted': _flashcardsCompleted,
      'longestStreak': _longestStreak,
      'lastAppUsageDate': _lastAppUsageDate,
    };
  }



  // Clean up resources
  static void dispose() {
    _syncTimer?.cancel();
    _syncWithBackend(); // One final sync before disposing
  }
}

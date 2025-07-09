import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fadeu/services/activity_tracker.dart';
import 'package:fadeu/services/api_service.dart';
import 'package:fadeu/services/sync_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  bool _isSyncing = false;
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  Future<void> setToken(String token) async {
    if (token.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    
    // If we're setting a token, it means user just logged in - sync data
    debugPrint('Auth token set, triggering post-login sync');
    _syncAfterLogin();
  }
  
  Future<void> setUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
  }
  
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }
  
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
  
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    
    // Clear any sensitive data from activity tracker
    await ActivityTracker.clearUserData();
  }
  
  Future<void> _syncAfterLogin() async {
    if (_isSyncing) {
      debugPrint('Sync already in progress, skipping');
      return;
    }
    _isSyncing = true;
    
    try {
      debugPrint('Starting post-login sync...');
      
      // Initialize activity tracker
      await ActivityTracker.initialize();
      
      // Sync any pending activity data
      await ActivityTracker.forceSync();
      
      // Perform full data sync
      final syncService = SyncService();
      await syncService.syncAllData();
      
      debugPrint('Post-login sync completed');
    } catch (e) {
      debugPrint('Error during post-login sync: $e');
    } finally {
      _isSyncing = false;
    }
  }
}

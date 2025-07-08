import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fadeu/services/activity_tracker.dart';
import 'package:fadeu/services/api_service.dart';

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    
    // If we're setting a token, it means user just logged in - sync activity
    if (token.isNotEmpty) {
      _syncActivityAfterLogin();
    }
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
  
  Future<void> _syncActivityAfterLogin() async {
    // Prevent multiple syncs at the same time
    if (_isSyncing) return;
    _isSyncing = true;
    
    try {
      // Initialize activity tracker if not already initialized
      await ActivityTracker.initialize();
      
      // Sync any pending activity data
      await ActivityTracker.forceSync();
      
      // Fetch and update activity data from the backend
      final token = await getToken();
      if (token != null) {
        // Get the latest activity data from the backend
        final response = await _apiService.get('/api/user/activity/');
        if (response != null) {
          // Update local activity data with the latest from the server
          await ActivityTracker.updateFromServer(response);
        }
      }
    } catch (e) {
      debugPrint('Error syncing activity after login: $e');
    } finally {
      _isSyncing = false;
    }
  }
}

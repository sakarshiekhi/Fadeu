import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fadeu/models/word_model.dart';

/// ApiService handles all communication with the Django backend.
///
/// It is implemented as a Singleton and provides a stable public API
/// for the rest of the app while handling all complex internal logic like
/// automatic token refreshing and request retries.
class ApiService {
  // --- Singleton Setup ---
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // --- Class Properties ---
  String? _cachedBaseUrl;
  final http.Client _httpClient = http.Client();
  String? _inMemoryToken; // In-memory cache for the access token

  // --- Constants for SharedPreferences keys ---
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userEmailKey = 'user_email';

  // --- Base URL Configuration ---
  String get baseUrl {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;
    if (kIsWeb) {
      final host = Uri.base.host;
      final scheme = Uri.base.scheme;
      _cachedBaseUrl = '$scheme://$host:8000';
    } else {
      _cachedBaseUrl = 'http://10.0.2.2:8000';
    }
    debugPrint('[ApiService] Base URL set to: $_cachedBaseUrl');
    return _cachedBaseUrl!;
  }

  // --- Internal Core Request Logic ---

  /// Internal generic request handler that includes logic for token refreshing and retrying requests.
  Future<http.Response> _makeRequest(
      Future<http.Response> Function(Map<String, String> headers) requestFunction) async {
    Map<String, String> headers = await _getHeaders();
    http.Response response = await requestFunction(headers);

    if (response.statusCode == 401) {
      debugPrint('[ApiService] Token expired. Attempting to refresh...');
      final bool refreshed = await _refreshToken();
      if (refreshed) {
        debugPrint('[ApiService] Token refreshed. Retrying the original request...');
        headers = await _getHeaders(); // Get the new headers with the new token
        response = await requestFunction(headers);
      }
    }
    return response;
  }

  /// Internal helper to decode JSON from a response, throwing a detailed error on failure.
  dynamic _decodeResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final responseBody = utf8.decode(response.bodyBytes);
        return responseBody.isNotEmpty ? json.decode(responseBody) : null;
      } catch (e) {
        throw Exception('Failed to parse server response.');
      }
    } else {
      final errorBody = utf8.decode(response.bodyBytes);
      debugPrint('[ApiService] Request failed. Status: ${response.statusCode}, Body: $errorBody');
      throw Exception('Server error: ${response.statusCode}');
    }
  }
  
  // --- Public API Methods ---

  /// Toggles the saved status of a word. Returns `true` if saved, `false` if unsaved.
  Future<bool> toggleSaveWord(int wordId) async {
    final response = await _makeRequest((headers) => _httpClient.post(
          Uri.parse('$baseUrl/api/words/words/$wordId/toggle-save/'),
          headers: headers,
        ));
    final data = _decodeResponse(response);
    return data != null && data['status'] == 'saved';
  }

  /// Fetches a list of saved words for the user.
  Future<List<Word>> getSavedWords() async {
    final response = await _makeRequest((headers) => _httpClient.get(
          Uri.parse('$baseUrl/api/words/saved-words/'),
          headers: headers,
        ));
    final data = _decodeResponse(response);
    final List results = data is Map && data.containsKey('results') ? data['results'] : data as List;
    return _parseWordsFromList(results);
  }

  /// Fetches a single word by its ID.
  Future<Word?> fetchWordById(int wordId) async {
      final response = await _makeRequest((headers) => _httpClient.get(
        Uri.parse('$baseUrl/api/words/words/$wordId/'),
        headers: headers,
      ));
      final data = _decodeResponse(response);
      return data != null ? Word.fromMap(data) : null;
  }

  /// Fetches words for the flashcard feature.
  Future<List<Word>> fetchFlashcardWords({String level = 'All'}) async {
    final queryParams = {
      'shuffle': 'true',
      'page_size': '50',
    };
    if (level != 'All') {
      queryParams['level'] = level;
    }

    final response = await _makeRequest((headers) => _httpClient.get(
      Uri.parse('$baseUrl/api/words/words/').replace(queryParameters: queryParams),
      headers: headers,
    ));
    
    final data = _decodeResponse(response);
    final List results = data is Map && data.containsKey('results') ? data['results'] : data as List;
    return _parseWordsFromList(results);
  }

  /// Synchronizes user activity data with the backend.
  Future<bool> syncUserActivity({
    required int watchTimeSeconds,
    required int wordsSearched,
    required int wordsSaved,
    required int flashcardsCompleted,
    required int longestStreak,
  }) async {
    final body = {
      'watch_time_seconds': watchTimeSeconds,
      'words_searched': wordsSearched,
      'words_saved': wordsSaved,
      'flashcards_completed': flashcardsCompleted,
      'longest_streak': longestStreak,
    };
    final response = await _makeRequest((headers) => _httpClient.post(
          Uri.parse('$baseUrl/api/sync-activity/'),
          headers: headers,
          body: jsonEncode(body),
        ));
    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// Helper to parse a list of JSON maps into a list of Word objects.
  List<Word> _parseWordsFromList(List items) {
    return items.map<Word>((item) {
      try {
        final Map<String, dynamic> wordData = item.containsKey('word') && item['word'] is Map<String, dynamic>
            ? item['word']
            : item as Map<String, dynamic>;
        return Word.fromMap(wordData);
      } catch (e) {
        return Word.fromMap({});
      }
    }).where((word) => word.id != 0).toList();
  }

  // --- Authentication Flow Methods ---

  Future<Map<String, dynamic>> signup(String email, String password, [String? firstName, String? lastName]) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'password_confirm': password,
          'first_name': firstName ?? 'User',
          'last_name': lastName ?? DateTime.now().millisecondsSinceEpoch.toString(),
        }),
      );
      
      final responseBody = utf8.decode(response.bodyBytes);
      final data = responseBody.isNotEmpty ? jsonDecode(responseBody) : {};
      
      if (response.statusCode == 201) {
        return await login(email, password);
      }
      
      // Handle validation errors
      if (response.statusCode == 400) {
        final errorMessage = data is Map 
            ? (data['email']?.first ?? 
               data['password']?.first ?? 
               data['non_field_errors']?.first ?? 
               'Registration failed. Please check your input.')
            : 'Registration failed. Please check your input.';
        return {'success': false, 'message': errorMessage};
      }
      
      return {'success': false, 'message': data['detail'] ?? 'Registration failed.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/api/auth/token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      
      // Cache the token in memory immediately
      _inMemoryToken = data['access'];

      // Save to storage asynchronously
      await prefs.setString(_accessTokenKey, data['access']);
      await prefs.setString(_refreshTokenKey, data['refresh']);
      await prefs.setString(_userEmailKey, email);

      return {
        'success': true, 
        'message': 'Login successful.',
        'access': data['access'],
        'refresh': data['refresh'],
      };
    }
    return {'success': false, 'message': data['detail'] ?? 'Login failed.'};
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);
    if (refreshToken != null) {
      await _httpClient.post(
        Uri.parse('$baseUrl/api/token/blacklist/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );
    }
    // Clear the in-memory token
    _inMemoryToken = null;

    // Clear storage
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userEmailKey);
  }

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/auth/password/reset/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return _handleAuthResponse(response, 'If an account exists, an email has been sent.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to send password reset email. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/auth/password/reset/verify/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );
      return _handleAuthResponse(response, 'Code verified successfully.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to verify code. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/api/auth/password/reset/confirm/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'token': code,
          'password': newPassword,
          'password_confirm': newPassword,
        }),
      );
      return _handleAuthResponse(response, 'Password reset successful.');
    } catch (e) {
      return {'success': false, 'message': 'Failed to reset password. Please try again.'};
    }
  }
  
  /// Helper for handling simple auth responses.
  Map<String, dynamic> _handleAuthResponse(http.Response response, String successMessage) {
    try {
      final responseBody = utf8.decode(response.bodyBytes);
      final data = responseBody.isNotEmpty ? jsonDecode(responseBody) : {};
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'message': successMessage, 'data': data};
      }
      
      // Handle different error statuses
      String errorMessage = 'An error occurred.';
      if (data is Map) {
        errorMessage = data['detail'] ?? 
                     data['message'] ??
                     data.values.firstWhere(
                       (v) => v is List && v.isNotEmpty,
                       orElse: () => 'An error occurred.'
                     ).toString();
      }
      
      return {
        'success': false, 
        'message': errorMessage,
        'statusCode': response.statusCode,
        'details': data
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to process the response. Please try again.',
        'statusCode': response.statusCode,
      };
    }
  }

  // --- Internal Helper Methods ---

  Future<String?> _getAccessToken() async {
    // 1. Prioritize the in-memory token for speed.
    if (_inMemoryToken != null) {
      return _inMemoryToken;
    }

    // 2. If not in memory, load from storage.
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString(_accessTokenKey);

    // 3. Cache it in memory for subsequent requests.
    if (storedToken != null) {
      _inMemoryToken = storedToken;
    }

    return storedToken;
  }

  Future<Map<String, String>> _getHeaders() async {
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    final token = await _getAccessToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<bool> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(_refreshTokenKey);
    if (refreshToken == null) {
      await logout();
      return false;
    }
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/api/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newAccessToken = data['access'];
      // Update both in-memory and storage
      _inMemoryToken = newAccessToken;
      await prefs.setString(_accessTokenKey, newAccessToken);
      return true;
    }
    await logout();
    return false;
  }
  
  // Generic post method for SyncService
  Future<dynamic> post(String endpoint, {Object? body}) async {
    final response = await _makeRequest((headers) => _httpClient.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body)
    ));
    return _decodeResponse(response);
  }

  // Generic delete method for SyncService
  Future<dynamic> delete(String endpoint) async {
    final response = await _makeRequest((headers) => _httpClient.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers
    ));
    return _decodeResponse(response);
  }
}

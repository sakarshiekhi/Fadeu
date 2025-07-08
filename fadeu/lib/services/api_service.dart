import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fadeu/models/word_model.dart';

// Model for your backend's PONS search (for mobile)
class PonsTranslation {
  final String source;
  final String target;

  PonsTranslation({required this.source, required this.target});

  factory PonsTranslation.fromJson(Map<String, dynamic> json) {
    return PonsTranslation(
      source: json['source'] as String? ?? '',
      target: json['target'] as String? ?? '',
    );
  }
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  
  // Factory constructor to return the same instance
  factory ApiService() => _instance;
  
  // Private constructor
  ApiService._internal();
  
  // Instance variables
  String? _cachedBaseUrl;
  
  // Get the base URL for API requests
  String get baseUrl {
    if (_cachedBaseUrl != null) {
      return _cachedBaseUrl!;
    }
    
    if (kIsWeb) {
      // For web, use the current host and port 8000
      final host = Uri.base.host;
      final scheme = Uri.base.scheme;
      
      _cachedBaseUrl = '$scheme://$host:8000';
    } else {
      // For mobile, use localhost
      _cachedBaseUrl = 'http://10.0.2.2:8000';
    }
    
    return _cachedBaseUrl!;
  }
  
  // Get the authentication token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? 
           prefs.getString('token') ?? 
           prefs.getString('access_token');
  }
  
  /// Get headers for HTTP requests
  /// Get headers for HTTP requests
  /// 
  /// [token] - Optional auth token. If not provided, it will be fetched if required.
  /// [requiresAuth] - Whether to include authentication headers.
  Future<Map<String, String>> _getHeaders([String? token, bool requiresAuth = true]) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (requiresAuth) {
      final authToken = token ?? await _getToken();
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }
    }
    
    return headers;
  }
  
  /// Handle HTTP response and decode JSON
  /// Handle HTTP response and decode JSON
  Future<Map<String, dynamic>?> _handleResponse(http.Response response) async {
    try {
      final responseBody = utf8.decode(response.bodyBytes);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody.isEmpty) return null;
        try {
          return json.decode(responseBody);
        } catch (e) {
          debugPrint('Error decoding response: $e');
          return null;
        }
      } else {
        debugPrint('Request failed with status: ${response.statusCode}');
        debugPrint('Response body: $responseBody');
        
        // Handle token expiration
        if (response.statusCode == 401) {
          // Try to refresh token if possible
          final refreshed = await _refreshToken();
          if (refreshed) {
            // The caller should handle the retry
            return null;
          }
        }
        
        return null;
      }
    } catch (e) {
      debugPrint('Error handling response: $e');
      return null;
    }
  }
  
  /// Make an HTTP GET request
  Future<Map<String, dynamic>?> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final token = await _getToken();
      var url = Uri.parse('${baseUrl}${endpoint.startsWith('/') ? '' : '/'}$endpoint');
      
      // Add query parameters if provided
      if (queryParams != null && queryParams.isNotEmpty) {
        url = url.replace(queryParameters: {
          for (var entry in queryParams.entries)
            if (entry.value != null) entry.key: entry.value.toString(),
        });
      }
      
      final response = await http.get(
        url,
        headers: await _getHeaders(token),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('GET request failed: $e');
      rethrow;
    }
  }
  
  /// Make an HTTP POST request
  Future<Map<String, dynamic>?>
      post(String endpoint, {
        Map<String, dynamic>? body,
        bool requiresAuth = true,
      }) async {
    try {
      final token = requiresAuth ? await _getToken() : null;
      final url = Uri.parse('${baseUrl}${endpoint.startsWith('/') ? '' : '/'}$endpoint');
      
      final response = await http.post(
        url,
        headers: await _getHeaders(token, requiresAuth),
        body: body != null ? json.encode(body) : null,
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('POST request failed: $e');
      rethrow;
    }
  }
  
  /// Make an HTTP PUT request
  Future<Map<String, dynamic>?> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${baseUrl}${endpoint.startsWith('/') ? '' : '/'}$endpoint');
      
      final response = await http.put(
        url,
        headers: await _getHeaders(token),
        body: body != null ? json.encode(body) : null,
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('PUT request failed: $e');
      rethrow;
    }
  }
  
  /// Make an HTTP DELETE request
  Future<bool> delete(String endpoint) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${baseUrl}${endpoint.startsWith('/') ? '' : '/'}$endpoint');
      
      final response = await http.delete(
        url,
        headers: await _getHeaders(token),
      );
      
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('DELETE request failed: $e');
      rethrow;
    }
  }
  
  /// Search for words in the backend
  Future<List<Word>> searchWords(String query) async {
    try {
      final response = await get(
        '/api/words/search/', 
        queryParams: {'q': query}
      );
      
      if (response != null && response['results'] != null) {
        final results = response['results'] as List;
        return results.map((e) => Word.fromMap(Map<String, dynamic>.from(e))).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Exception during search: $e');
      rethrow;
    }
  }
  
  /// Fetches all words for the flashcard feature from the backend (for web).
  Future<List<Word>> fetchFlashcardWords({String level = 'All'}) async {
    print('=== Fetching flashcard words ===');
    print('Level: $level');
    
    try {
      // Build the URL with query parameters
      final url = Uri.parse('$baseUrl/api/words/words/').replace(
        queryParameters: {
          if (level != 'All') 'level': level,
          'shuffle': 'true',
          'page_size': '50',  // Request more words per page
        },
      );
      
      print('Request URL: $url');
      
      // Get headers with auth token if available
      final headers = await _getHeaders();
      print('Request headers: $headers');
      
      // Make the HTTP request
      final response = await http.get(
        url,
        headers: headers,
      );
      
      print('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Decode the response body with UTF-8 to handle special characters
        final responseBody = utf8.decode(response.bodyBytes);
        print('Response body length: ${responseBody.length} bytes');
        
        try {
          // First try to decode the response
          dynamic decodedData;
          try {
            decodedData = json.decode(responseBody);
          } catch (e) {
            print('Error decoding JSON: $e');
            print('Response body: $responseBody');
            return [];
          }
          
          // Handle both list and map responses
          List<dynamic> data;
          if (decodedData is List) {
            // Direct list response
            data = decodedData;
          } else if (decodedData is Map && decodedData.containsKey('results')) {
            // Paginated response with 'results' key
            data = decodedData['results'] is List ? decodedData['results'] : [];
          } else {
            // Single item or unexpected format
            data = [decodedData];
          }
          
          print('Found ${data.length} words in response');
          
          if (data.isEmpty) {
            print('Warning: No words found in the response');
            print('Response data: $decodedData');
            return [];
          }
          
          // Convert each item to a Word object using the fromMap factory
          final words = <Word>[];
          for (var item in data) {
            try {
              // Ensure all keys are strings and handle any potential null values
              final Map<String, dynamic> wordMap = {};
              
              // Convert all keys to snake_case and handle null values
              item.forEach((key, value) {
                if (key is String) {
                  // Convert camelCase to snake_case
                  final snakeKey = key.replaceAllMapped(
                    RegExp(r'([A-Z])'),
                    (match) => '_${match.group(0)?.toLowerCase() ?? ''}',
                  );
                  wordMap[snakeKey] = value;
                }
              });
              
              // Use the fromMap factory to create the Word instance
              final word = Word.fromMap(wordMap);
              words.add(word);
              print('Added word: ${word.germanWord} (${word.level})');
            } catch (e) {
              print('Error parsing word: $e');
              print('Problematic item: $item');
            }
          }
          
          print('Successfully processed ${words.length} words');
          return words;
        } catch (e) {
          print('Error parsing JSON response: $e');
          print('Response body: ${response.body}');
        }
      } else {
        print('Error response (${response.statusCode}): ${response.body}');
      }
    } catch (e, stackTrace) {
      print('Exception during flashcard fetch:');
      print('Type: ${e.runtimeType}');
      print('Message: $e');
      print('Stack trace: $stackTrace');
    }
    
    print('Returning empty list due to error');
    return [];
  }

  /// Fetches translations from your Django backend's PONS proxy (for mobile).
  Future<List<PonsTranslation>> fetchPonsTranslations(String query) async {
    if (query.isEmpty) return [];
    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse('$baseUrl/api/dictionary-search/?q=$encodedQuery');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        if (data.isNotEmpty && data[0]['hits'] is List) {
          final hits = data[0]['hits'] as List<dynamic>;
          List<PonsTranslation> translations = [];
          for (var hit in hits) {
            if (hit['roms'] != null) {
              for (var rom in hit['roms']) {
                if (rom['arabs'] != null) {
                  for (var arab in rom['arabs']) {
                    if (arab['translations'] != null) {
                      for (var trans in arab['translations']) {
                        translations.add(PonsTranslation.fromJson(trans));
                      }
                    }
                  }
                }
              }
            }
          }
          return translations;
        }
      }
    } catch (e) {
      debugPrint('Exception during PONS API call: $e');
    }
    return [];
  }

  /// Fetches a single word by ID from the backend.
  Future<Word?> fetchWordById(int wordId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/words/words/$wordId/'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(responseBody);
        
        // Check if the response has a 'results' key (for consistency with list endpoints)
        final wordData = data.containsKey('results') ? data['results'] : data;
        
        // If wordData is a list, take the first item if it exists
        if (wordData is List && wordData.isNotEmpty) {
          final firstItem = wordData.first;
          if (firstItem is Map<String, dynamic>) {
            return Word.fromMap(firstItem);
          } else if (firstItem is Map) {
            // Convert Map<dynamic, dynamic> to Map<String, dynamic>
            return Word.fromMap(Map<String, dynamic>.from(firstItem));
          }
        } else if (wordData is Map<String, dynamic>) {
          return Word.fromMap(wordData);
        } else if (wordData is Map) {
          // Convert Map<dynamic, dynamic> to Map<String, dynamic>
          return Word.fromMap(Map<String, dynamic>.from(wordData));
        }
        
        debugPrint('Unexpected response format: $data');
        return null;
      } else {
        debugPrint('Failed to fetch word: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception fetching word: $e');
      return null;
    }
  }

  /// Sends all locally stored user activity data to the backend.
  Future<bool> syncUserActivity({
    required int watchTimeSeconds,
    required int wordsSearched,
    required int wordsSaved,
    required int flashcardsCompleted,
    required int longestStreak,
  }) async {
    try {
      print('🔵 [API] Syncing user activity with backend...');
      print('📊 Watch Time: $watchTimeSeconds seconds');
      print('🔍 Words Searched: $wordsSearched');
      print('💾 Words Saved: $wordsSaved');
      print('🎴 Flashcards Completed: $flashcardsCompleted');
      print('🔥 Longest Streak: $longestStreak');
      
      // Get headers with authentication
      final headers = await _getHeaders(await _getToken(), true);
      
      // Check if we have an auth token
      final prefs = await SharedPreferences.getInstance();
      final hasAuthToken = prefs.getString('auth_token') != null ||
                         prefs.getString('token') != null ||
                         prefs.getString('access_token') != null;
      
      if (!hasAuthToken) {
        print('🔴 [API] No auth token found, user not logged in');
        return false;
      }
      
      final url = '$baseUrl/api/accounts/sync-activity/'; // Corrected endpoint
      print('🌐 [API] Sending request to: $url');
      
      final payload = {
        'watch_time_seconds': watchTimeSeconds,
        'words_searched': wordsSearched,
        'words_saved': wordsSaved,
        'flashcards_completed': flashcardsCompleted,
        'longest_streak': longestStreak,
      };
      
      print('📦 Payload: $payload');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(payload),
      );
      
      print('📥 [API] Response status: ${response.statusCode}');
      print('📄 [API] Response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [API] Successfully synced user activity');
        return true;
      } else if (response.statusCode == 401) {
        // Token might be expired, try to refresh
        print('🔑 [API] Token might be expired, attempting to refresh...');
        final refreshSuccess = await _refreshToken();
        if (refreshSuccess) {
          // Retry the request with the new token
          return await syncUserActivity(
            watchTimeSeconds: watchTimeSeconds,
            wordsSearched: wordsSearched,
            wordsSaved: wordsSaved,
            flashcardsCompleted: flashcardsCompleted,
            longestStreak: longestStreak,
          );
        }
      }
      
      print('❌ [API] Failed to sync user activity: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e, stackTrace) {
      print('❌ [API] Exception during syncUserActivity:');
      print('Type: ${e.runtimeType}');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }
  
  // Helper method to refresh the access token
  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      if (refreshToken == null) {
        print('🔴 [API] No refresh token available');
        return false;
      }
      
      print('🔄 [API] Refreshing access token...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/token/refresh/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh': refreshToken}),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final newAccessToken = responseData['access'];
        
        if (newAccessToken != null) {
          // Save the new access token
          await prefs.setString('access_token', newAccessToken);
          await prefs.setString('auth_token', newAccessToken);
          await prefs.setString('token', newAccessToken);
          
          print('✅ [API] Successfully refreshed access token');
          return true;
        }
      }
      
      print('❌ [API] Failed to refresh token: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print('❌ [API] Error refreshing token: $e');
      return false;
    }
  }

  /// User authentication methods
  
  // Register a new user
  Future<Map<String, dynamic>> signup(String email, String password) async {
    try {
      print('👤 [Auth] Attempting signup with email: $email');
      
      // First, check if the email is valid
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        return {'success': false, 'message': 'Please enter a valid email address'};
      }
      
      // Validate password
      if (password.length < 8) {
        return {'success': false, 'message': 'Password must be at least 8 characters long'};
      }
      
      print('🔗 [Auth] Sending signup request to: $baseUrl/api/auth/register/');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'username': email.split('@')[0], // Use part before @ as username
          'password': password,
          'password_confirm': password,
        }),
      );
      
      print('📥 [Auth] Signup response: ${response.statusCode}');
      print('📦 [Auth] Response body: ${response.body}');
      
      // Check if the response is HTML (indicating an error page)
      if (response.body.trim().startsWith('<!DOCTYPE html>')) {
        return {
          'success': false, 
          'message': 'Server error: Received HTML instead of JSON. Please check the server logs.',
          'statusCode': response.statusCode,
        };
      }
      
      try {
        final responseData = jsonDecode(response.body);
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          // If the response includes tokens, save them
          if (responseData['access'] != null) {
            final prefs = await SharedPreferences.getInstance();
            final token = responseData['access'];
            
            // Save tokens
            await prefs.setString('access_token', token);
            await prefs.setString('auth_token', token);
            await prefs.setString('token', token);
            
            if (responseData['refresh'] != null) {
              await prefs.setString('refresh_token', responseData['refresh']);
            }
            
            // Save user email
            await prefs.setString('user_email', email);
            
            print('✅ [Auth] Signup successful and tokens saved');
            
            return {
              'success': true,
              'message': responseData['message'] ?? 'Registration successful',
              'token': token,
              'refresh_token': responseData['refresh'],
            };
          }
          
          return {
            'success': true, 
            'message': responseData['message'] ?? 'Registration successful. Please log in.'
          };
        } else {
          // Handle validation errors
          String errorMessage = responseData['error'] ?? 
                              responseData['detail'] ?? 
                              responseData['message'] ??
                              'Failed to sign up';
                              
          // Handle field-specific errors
          if (responseData is Map) {
            final fieldErrors = responseData.entries
                .where((e) => e.key != 'error' && 
                             e.key != 'detail' && 
                             e.key != 'message' &&
                             e.value != null)
                .map((e) => '${e.key}: ${e.value is List ? e.value.join(', ') : e.value}')
                .join('\n');
                
            if (fieldErrors.isNotEmpty) {
              errorMessage = fieldErrors;
            }
          }
          
          print('❌ [Auth] Signup failed: $errorMessage');
          return {'success': false, 'message': errorMessage};
        }
      } catch (e) {
        print('❌ [Auth] Error parsing signup response: $e');
        return {
          'success': false, 
          'message': 'Error processing server response. Please try again.'
        };
      }
    } catch (e) {
      print('❌ [Auth] Error during signup: $e');
      return {
        'success': false,
        'message': 'An error occurred during signup. Please try again.',
      };
    }
  }
  
  // Login an existing user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔑 [Auth] Attempting login with email: $email');
      
      // First, check if the email is valid
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        return {'success': false, 'message': 'Please enter a valid email address'};
      }
      
      print('🔑 [Auth] Sending login request to: $baseUrl/api/auth/token/');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/token/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      print('📥 [Auth] Login response: ${response.statusCode}');
      print('📦 [Auth] Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final token = responseData['access'];
        final refreshToken = responseData['refresh'];
        
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          
          // Save tokens
          await prefs.setString('access_token', token);
          await prefs.setString('auth_token', token);
          await prefs.setString('token', token);
          
          if (refreshToken != null) {
            await prefs.setString('refresh_token', refreshToken);
          }
          
          // Save user email
          await prefs.setString('user_email', email);
          
          print('✅ [Auth] Login successful');
          
          return {
            'success': true,
            'message': 'Login successful',
            'token': token,
            'refresh_token': refreshToken,
            'user': {'email': email}
          };
        }
      }
      
      // Handle error responses
      String errorMessage = 'Login failed. Please check your credentials.';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map) {
          if (errorData['detail'] != null) {
            errorMessage = errorData['detail'];
          } else if (errorData['non_field_errors'] != null) {
            errorMessage = errorData['non_field_errors'].join('\n');
          }
        }
      } catch (e) {
        print('⚠️ [Auth] Error parsing error response: $e');
      }
      
      print('❌ [Auth] Login failed: $errorMessage');
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e, stackTrace) {
      print('❌ [Auth] Error during login: $e');
      print('📝 Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'An error occurred during login. Please check your connection and try again.',
      };
    }
  }

  // Request a password reset
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      print('🔑 [Auth] Requesting password reset for email: $email');
      
      // First, check if the email is valid
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        return {'success': false, 'message': 'Please enter a valid email address'};
      }
      
      print('🔑 [Auth] Sending password reset request to: $baseUrl/api/accounts/password-reset/');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/accounts/password-reset/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );
      
      print('📥 [Auth] Password reset response: ${response.statusCode}');
      print('📦 [Auth] Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'If an account exists with this email, you will receive a password reset link.',
        };
      } else {
        // Parse error message if available
        String errorMessage = 'Failed to send password reset email';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData['email'] != null) {
            errorMessage = errorData['email'] is List 
                ? errorData['email'].join('\n')
                : errorData['email'].toString();
          } else if (errorData is Map && errorData['detail'] != null) {
            errorMessage = errorData['detail'];
          }
        } catch (e) {
          print('⚠️ [Auth] Error parsing error response: $e');
        }
        
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('❌ [Auth] Error during password reset request: $e');
      return {
        'success': false,
        'message': 'An error occurred while requesting a password reset. Please try again.',
      };
    }
  }

  // Verify password reset code
  Future<Map<String, dynamic>> verifyCode(String email, String code) async {
    try {
      print('🔍 [Auth] Verifying password reset code for email: $email');
      
      // Validate inputs
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}').hasMatch(email)) {
        return {'success': false, 'message': 'Please enter a valid email address'};
      }
      
      if (code.isEmpty) {
        return {'success': false, 'message': 'Verification code cannot be empty'};
      }
      
      print('🔑 [Auth] Verifying code at: $baseUrl/api/accounts/password-reset/verify/');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/accounts/password-reset/verify/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'code': code,  
        }),
      );
      
      print('📥 [Auth] Verify code response: ${response.statusCode}');
      print('📦 [Auth] Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Code verified successfully',
        };
      } else {
        // Parse error message if available
        String errorMessage = 'Invalid or expired code';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData['detail'] != null) {
            errorMessage = errorData['detail'];
          }
        } catch (e) {
          print('⚠️ [Auth] Error parsing error response: $e');
        }
        
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('❌ [Auth] Error during code verification: $e');
      return {
        'success': false,
        'message': 'An error occurred while verifying the code. Please try again.',
      };
    }
  }

  // Reset password with code
  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      print('🔄 [Auth] Resetting password for email: $email');
      
      // Validate inputs
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}').hasMatch(email)) {
        return {'success': false, 'message': 'Please enter a valid email address'};
      }
      
      if (code.isEmpty) {
        return {'success': false, 'message': 'Verification code cannot be empty'};
      }
      
      if (newPassword.length < 8) {
        return {'success': false, 'message': 'Password must be at least 8 characters long'};
      }
      
      print('🔑 [Auth] Resetting password at: $baseUrl/api/accounts/reset-password/');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/accounts/reset-password/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': code,
          'password': newPassword,
          'password_confirm': newPassword,
        }),
      );
      
      print('📥 [Auth] Reset password response: ${response.statusCode}');
      print('📦 [Auth] Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Password reset successful. You can now log in with your new password.',
        };
      } else {
        // Parse error message if available
        String errorMessage = 'Failed to reset password';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map) {
            if (errorData['new_password'] != null) {
              errorMessage = errorData['new_password'] is List
                  ? errorData['new_password'].join('\n')
                  : errorData['new_password'].toString();
            } else if (errorData['detail'] != null) {
              errorMessage = errorData['detail'];
            }
          }
        } catch (e) {
          print('⚠️ [Auth] Error parsing error response: $e');
        }
        
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('❌ [Auth] Error during password reset: $e');
      return {
        'success': false,
        'message': 'An error occurred while resetting your password. Please try again.',
      };
    }
  }

  // Get saved words from the backend
  Future<List<Word>> getSavedWords() async {
    try {
      final response = await get('/api/words/saved-words/');
      if (response != null) {
        // The response is a list of saved words with word details nested
        return (response as List).map((item) {
          // Handle the nested word object from the response
          final wordData = item['word'] ?? item;
          return Word.fromMap(wordData);
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching saved words: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      debugPrint('👋 [Auth] Logging out user...');
      
      // Get the current token before clearing it
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? 
                  prefs.getString('token') ?? 
                  prefs.getString('access_token');
      
      // Notify the backend about logout if we have a token
      bool backendLogoutSuccess = false;
      
      if (token != null) {
        try {
          debugPrint('🌐 [Auth] Notifying backend about logout at: $baseUrl/api/token/blacklist/');
          final refreshToken = prefs.getString('refresh_token');
          
          if (refreshToken != null) {
            final response = await http.post(
              Uri.parse('$baseUrl/api/token/blacklist/'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({'refresh': refreshToken}),
            );
            
            backendLogoutSuccess = response.statusCode == 200 || response.statusCode == 204;
            debugPrint('📡 [Auth] Backend logout ${backendLogoutSuccess ? 'successful' : 'failed'}: ${response.statusCode}');
            
            if (!backendLogoutSuccess) {
              debugPrint('⚠️ [Auth] Failed to log out from server: ${response.statusCode} - ${response.body}');
            }
          } else {
            debugPrint('⚠️ [Auth] No refresh token found, skipping backend logout');
          }
        } catch (e) {
          debugPrint('⚠️ [Auth] Error during server logout (might be offline): $e');
          // Continue with local logout even if server logout fails
        }
      } else {
        debugPrint('ℹ️ [Auth] No auth token found, performing local logout only');
      }
      
      // Clear all auth-related data
      await prefs.remove('auth_token');
      await prefs.remove('token');
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('username');
      
      debugPrint('✅ [Auth] Logout completed');
      return {
        'success': true,
        'message': 'Logged out successfully',
        'backend_logout': backendLogoutSuccess,
      };
    } catch (e) {
      debugPrint('❌ [Auth] Error during logout: $e');
      return {
        'success': false,
        'message': 'Error during logout',
        'backend_logout': false,
      };
    }
  }
}

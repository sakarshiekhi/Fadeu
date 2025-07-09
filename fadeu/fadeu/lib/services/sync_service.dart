import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fadeu/services/api_service.dart';
import 'package:fadeu/services/auth_service.dart';
import 'package:fadeu/services/connectivity_service.dart';
import 'package:workmanager/workmanager.dart';

// Unique task name for background sync
const String syncTaskName = 'syncTask';

// Keys for pending operations
const String _pendingSyncOperationsKey = 'pending_sync_operations';
const int _maxRetryCount = 5;
const Duration _initialRetryDelay = Duration(seconds: 5);
const Duration _maxRetryDelay = Duration(minutes: 30);

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final ConnectivityService _connectivity = ConnectivityService();
  
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  
  // Stream controller for sync status updates
  final _syncController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatus => _syncController.stream;
  
  // Queue for pending operations
  final List<Map<String, dynamic>> _pendingOperations = [];
  
  // Retry state
  int _retryCount = 0;
  Timer? _retryTimer;
  
  // Initialize the service
  Future<void> initialize() async {
    try {
      // Only initialize connectivity service on mobile/desktop
      if (!kIsWeb) {
        await _connectivity.initialize();
        
        // Listen to connectivity changes on mobile/desktop
        _connectivity.connectionStatus.listen((isConnected) {
          if (isConnected) {
            _processPendingOperations();
          }
        });
        
        // Initialize background tasks only on mobile/desktop
        await Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: kDebugMode,
        );
        
        // Register periodic sync task (runs every 15 minutes when conditions are met)
        await Workmanager().registerPeriodicTask(
          '1',
          syncTaskName,
          frequency: const Duration(minutes: 15),
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: true,
          ),
        );
      }
      
      // Load any pending operations
      await _loadPendingOperations();
      
      // If web, process any pending operations immediately
      if (kIsWeb) {
        _processPendingOperations();
      }
    } catch (e) {
      debugPrint('Error initializing SyncService: $e');
    }
  }
  
  /// Sync all user data with the backend
  Future<bool> syncAllData({bool retry = false}) async {
    if (_isSyncing) {
      debugPrint('Sync already in progress');
      return false;
    }
    
    _isSyncing = true;
    _syncController.add(SyncStatus.inProgress);
    
    try {
      // Check if user is logged in
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) {
        debugPrint('User not logged in, skipping sync');
        _syncController.add(SyncStatus.notLoggedIn);
        return false;
      }
      
      // Check connectivity
      final isConnected = await _connectivity.isConnected;
      if (!isConnected) {
        debugPrint('No internet connection, queueing sync');
        _queueSyncOperation('full_sync', {});
        _syncController.add(SyncStatus.queued);
        return false;
      }
      
      debugPrint('Starting full data sync...');
      
      // Sync saved words
      await _syncSavedWords();
      
      // Sync activity data
      await _syncActivityData();
      
      // Process any pending operations
      await _processPendingOperations();
      
      debugPrint('Sync completed successfully');
      _syncController.add(SyncStatus.completed);
      _resetRetryCount();
      return true;
    } catch (e, stackTrace) {
      debugPrint('Sync failed: $e\n$stackTrace');
      
      if (!retry) {
        _handleSyncFailure(e);
      }
      
      _syncController.add(SyncStatus.failed);
      return false;
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Sync saved words between local and remote
  Future<void> _syncSavedWords() async {
    debugPrint('Syncing saved words...');
    
    try {
      // Get local saved words
      final prefs = await SharedPreferences.getInstance();
      final localSavedIds = (prefs.getStringList('bookmarkedWordIds') ?? [])
          .map((id) => int.tryParse(id))
          .whereType<int>()
          .toList();
      
      debugPrint('Local saved word IDs: $localSavedIds');
      
      // Get server saved words using the dedicated method
      final savedWords = await _apiService.getSavedWords();
      final serverSavedIds = savedWords.map((word) => word.id).toList();
      
      debugPrint('Server saved word IDs: $serverSavedIds');
      
      // Find words to add to server
      final wordsToAdd = localSavedIds.where((id) => !serverSavedIds.contains(id)).toList();
      
      // Find words to remove from server
      final wordsToRemove = serverSavedIds.where((id) => !localSavedIds.contains(id)).toList();
      
      debugPrint('Words to add to server: $wordsToAdd');
      debugPrint('Words to remove from server: $wordsToRemove');
      
      // Sync additions
      for (final wordId in wordsToAdd) {
        try {
          await _apiService.post(
            '/api/words/saved-words/',
            body: {'word_id': wordId},
          );
          debugPrint('Added word $wordId to server');
        } catch (e) {
          debugPrint('Failed to add word $wordId: $e');
        }
      }
      
      // Sync removals
      for (final wordId in wordsToRemove) {
        try {
          await _apiService.delete('/api/words/saved-words/$wordId/');
          debugPrint('Removed word $wordId from server');
        } catch (e) {
          debugPrint('Failed to remove word $wordId: $e');
        }
      }
      
      // Update local database with server state
      if (wordsToAdd.isNotEmpty || wordsToRemove.isNotEmpty) {
        await _updateLocalSavedWords(serverSavedIds);
      }
    } catch (e) {
      debugPrint('Error syncing saved words: $e');
      rethrow;
    }
  }
  
  /// Update local saved words with server state
  Future<void> _updateLocalSavedWords(List<int> serverSavedIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'bookmarkedWordIds',
        serverSavedIds.map((id) => id.toString()).toList(),
      );
      debugPrint('Updated local saved words with server state');
    } catch (e) {
      debugPrint('Error updating local saved words: $e');
    }
  }
  
  /// Sync activity data with the server
  Future<void> _syncActivityData() async {
    debugPrint('Syncing activity data...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get local activity data with null safety
      final watchTimeSeconds = prefs.getInt('watchTimeSeconds') ?? 0;
      final wordsSearched = prefs.getInt('wordsSearched') ?? 0;
      final wordsSaved = prefs.getInt('wordsSaved') ?? 0;
      final flashcardsCompleted = prefs.getInt('flashcardsCompleted') ?? 0;
      final longestStreak = prefs.getInt('longestStreak') ?? 0;
      
      debugPrint('Local activity data: {\n  watchTimeSeconds: $watchTimeSeconds,\n  wordsSearched: $wordsSearched,\n  wordsSaved: $wordsSaved,\n  flashcardsCompleted: $flashcardsCompleted,\n  longestStreak: $longestStreak\n}');
      
      // Only sync if there's actual data
      if (watchTimeSeconds > 0 || 
          wordsSearched > 0 || 
          wordsSaved > 0 || 
          flashcardsCompleted > 0 || 
          longestStreak > 0) {
            
        // Send to server
        final response = await _apiService.syncUserActivity(
          watchTimeSeconds: watchTimeSeconds,
          wordsSearched: wordsSearched,
          wordsSaved: wordsSaved,
          flashcardsCompleted: flashcardsCompleted,
          longestStreak: longestStreak,
        );
        
        if (response) {
          debugPrint('Successfully synced activity data with server');
          
          // Optionally clear local activity data after successful sync
          await Future.wait([
            prefs.remove('watchTimeSeconds'),
            prefs.remove('wordsSearched'),
            prefs.remove('wordsSaved'),
            prefs.remove('flashcardsCompleted'),
            // Don't remove longestStreak as it should be preserved
          ]);
        } else {
          debugPrint('Failed to sync activity data with server');
        }
      } else {
        debugPrint('No activity data to sync');
      }
    } catch (e) {
      debugPrint('Error syncing activity data: $e');
      rethrow;
    }
  }
  
  /// Queue a sync operation for when the device is back online
  void _queueSyncOperation(String type, Map<String, dynamic> data) async {
    final operation = {
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _pendingOperations.add(operation);
    await _savePendingOperations();
    
    // Try to process the queue if we're online
    if (await _connectivity.isConnected) {
      await _processPendingOperations();
    }
  }
  
  /// Process all pending sync operations
  Future<void> _processPendingOperations() async {
    if (_pendingOperations.isEmpty || _isSyncing) return;
    
    final isConnected = await _connectivity.isConnected;
    if (!isConnected) return;
    
    // Make a copy to avoid concurrent modification
    final operations = List<Map<String, dynamic>>.from(_pendingOperations);
    
    for (final operation in operations) {
      try {
        switch (operation['type']) {
          case 'save_word':
            await _apiService.post(
              '/api/words/saved-words/',
              body: operation['data'],
            );
            break;
            
          case 'delete_word':
            await _apiService.delete('/api/words/saved-words/${operation['data']['id']}/');
            break;
            
          case 'activity':
            await _apiService.syncUserActivity(
              watchTimeSeconds: operation['data']['watchTimeSeconds'],
              wordsSearched: operation['data']['wordsSearched'],
              wordsSaved: operation['data']['wordsSaved'],
              flashcardsCompleted: operation['data']['flashcardsCompleted'],
              longestStreak: operation['data']['longestStreak'],
            );
            break;
            
          case 'full_sync':
            await syncAllData(retry: true);
            break;
        }
        
        // Remove completed operation
        _pendingOperations.remove(operation);
      } catch (e) {
        debugPrint('Failed to process sync operation: $e');
        // Keep the operation in the queue for retry
        break;
      }
    }
    
    await _savePendingOperations();
  }
  
  /// Handle sync failure with retry logic
  void _handleSyncFailure(dynamic error) {
    _retryCount++;
    
    if (_retryCount > _maxRetryCount) {
      debugPrint('Max retry attempts reached, giving up');
      return;
    }
    
    // Exponential backoff with jitter
    final delay = Duration(
      seconds: (_initialRetryDelay.inSeconds * _retryCount * _retryCount)
          .clamp(0, _maxRetryDelay.inSeconds),
    );
    
    debugPrint('Retrying sync in ${delay.inSeconds} seconds (attempt $_retryCount)');
    
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      syncAllData(retry: true);
    });
  }
  
  /// Reset the retry counter on successful sync
  void _resetRetryCount() {
    _retryCount = 0;
    _retryTimer?.cancel();
  }
  
  /// Load pending operations from storage
  Future<void> _loadPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_pendingSyncOperationsKey);
      if (json != null) {
        final List<dynamic> operations = jsonDecode(json);
        _pendingOperations.addAll(operations.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      debugPrint('Error loading pending operations: $e');
    }
  }
  
  /// Save pending operations to storage
  Future<void> _savePendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _pendingSyncOperationsKey,
        jsonEncode(_pendingOperations),
      );
    } catch (e) {
      debugPrint('Error saving pending operations: $e');
    }
  }
  
  /// Manually trigger a sync
  Future<void> manualSync() async {
    await syncAllData();
  }
  
  /// Close the sync service
  void dispose() {
    _retryTimer?.cancel();
    _connectivity.dispose();
    _syncController.close();
  }
}

/// Represents the current sync status
enum SyncStatus {
  inProgress,
  completed,
  failed,
  notLoggedIn,
  queued,
  retrying,
}

/// Background task entry point
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Background sync task started: $task');
    
    try {
      final syncService = SyncService();
      await syncService.initialize();
      await syncService.syncAllData();
      return true;
    } catch (e) {
      debugPrint('Background sync failed: $e');
      return false;
    }
  });
}

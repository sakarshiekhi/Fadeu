import 'dart:async';
import 'dart:io' show InternetAddress, SocketException;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  bool _isConnected = false;
  final _connectionController = StreamController<bool>.broadcast();
  
  Stream<bool> get connectionStatus => _connectionController.stream;
  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    try {
      // Initial check
      await _checkConnection();
      
      // Listen for connectivity changes
      _connectivity.onConnectivityChanged.listen((result) async {
        await _checkConnection();
      });
    } catch (e) {
      debugPrint('ConnectivityService initialization error: $e');
      // Assume connected if there's an error
      _updateConnectionStatus(true);
    }
  }

  Future<bool> _checkConnection() async {
    if (kIsWeb) {
      // For web, we'll assume connection is always available
      _updateConnectionStatus(true);
      return true;
    }
    
    // For mobile/desktop platforms
    bool hasConnection = false;
    
    try {
      final result = await InternetAddress.lookup('google.com');
      hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      hasConnection = false;
    }
    
    _updateConnectionStatus(hasConnection);
    return hasConnection;
  }
  
  void _updateConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectionController.add(isConnected);
    }
  }
  
  void dispose() {
    _connectionController.close();
  }
}

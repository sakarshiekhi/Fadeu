import 'package:flutter/material.dart';
import 'package:fadeu/services/sync_service.dart';
import 'package:provider/provider.dart';

/// A widget that initializes the sync service and sets up sync triggers
class SyncInitializer extends StatefulWidget {
  final Widget child;
  
  const SyncInitializer({Key? key, required this.child}) : super(key: key);

  @override
  _SyncInitializerState createState() => _SyncInitializerState();
}

class _SyncInitializerState extends State<SyncInitializer> with WidgetsBindingObserver {
  late final SyncService _syncService;
  
  @override
  void initState() {
    super.initState();
    _syncService = SyncService();
    _initializeSync();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    _syncService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Trigger sync when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _triggerSync();
    }
  }
  
  Future<void> _initializeSync() async {
    try {
      await _syncService.initialize();
      // Initial sync when app starts
      await _triggerSync();
    } catch (e) {
      debugPrint('Failed to initialize sync: $e');
    }
  }
  
  Future<void> _triggerSync() async {
    try {
      await _syncService.manualSync();
    } catch (e) {
      debugPrint('Failed to trigger sync: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Provider<SyncService>.value(
      value: _syncService,
      child: widget.child,
    );
  }
}

/// Extension to easily access the sync service from any BuildContext
extension SyncServiceExtension on BuildContext {
  SyncService get syncService => read<SyncService>();
}

/// Call this function to manually trigger a sync from anywhere in the app
Future<void> triggerSync(BuildContext context) async {
  try {
    await context.syncService.manualSync();
  } catch (e) {
    debugPrint('Failed to trigger sync: $e');
    // Optionally show a snackbar to the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to sync data. Please check your connection.')),
    );
  }
}

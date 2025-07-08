import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fadeu/l10n/app_localizations.dart';
import 'package:fadeu/services/activity_tracker.dart';

class UserActivityPage extends StatefulWidget {
  final bool isDarkMode;

  const UserActivityPage({super.key, required this.isDarkMode});

  @override
  State<UserActivityPage> createState() => _UserActivityPageState();
}

class _UserActivityPageState extends State<UserActivityPage> {
  // Activity data
  Map<String, dynamic> _activityData = {
    'watchTimeSeconds': 0,
    'wordsSearched': 0,
    'wordsSaved': 0,
    'flashcardsCompleted': 0,
    'longestStreak': 0,
    'lastAppUsageDate': null,
  };
  
  bool _isSyncing = false;
  bool _autoSyncEnabled = true;
  SharedPreferences? _prefs;
  String? _userEmail; // Add state variable for user email

  @override
  void initState() {
    super.initState();
    _loadUserEmail(); // Call method to load email
    _loadActivityData();
    _initializeActivityTracker();
  }

  Future<void> _loadUserEmail() async { // Method to load user email
    _prefs ??= await SharedPreferences.getInstance();
    setState(() {
      _userEmail = _prefs?.getString('user_email');
    });
  }
  
  void _loadActivityData() {
    setState(() {
      _activityData = ActivityTracker.getActivityData();
    });
  }

  Future<void> _initializeActivityTracker() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await ActivityTracker.initialize();
      await _loadAutoSyncPreference();
      _loadActivityData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorInitializingData),
          ),
        );
      }
    }
  }

  Future<void> _loadAutoSyncPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoSyncEnabled = prefs.getBool('auto_sync_enabled') ?? true;
    });
  }

  Future<void> _toggleAutoSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync_enabled', value);
    setState(() {
      _autoSyncEnabled = value;
    });
  }



  // Function to manually sync data to the backend
  Future<void> _syncActivityToBackend() async {
    if (!mounted) return;

    setState(() {
      _isSyncing = true;
    });

    // Show a loading message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Syncing data to cloud...')),
      );
    }

    final bool success = await ActivityTracker.forceSync();
    
    if (mounted) {
      setState(() {
        _isSyncing = false;
        _activityData = ActivityTracker.getActivityData();
      });

      // Show a success or failure message
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
              ? 'Data synced successfully!'
              : 'Failed to sync data. Will retry later.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final descriptionColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.yourActivity,
            style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _syncActivityToBackend,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display User Email
              if (_userEmail != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: descriptionColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _userEmail!,
                        style: TextStyle(fontSize: 16, color: descriptionColor),
                      ),
                    ],
                  ),
                ),
              // Sync Settings Card
              Card(
                elevation: 4,
                color: Colors.deepPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: _isSyncing 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Icon(Icons.sync, color: Colors.white),
                      title: Text(
                        'Cloud Sync', 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                      subtitle: Text(
                        _autoSyncEnabled ? 'Auto-sync is enabled' : 'Auto-sync is disabled', 
                        style: TextStyle(color: Colors.white70)
                      ),
                      onTap: _isSyncing ? null : _syncActivityToBackend,
                      trailing: Switch(
                        value: _autoSyncEnabled,
                        onChanged: _isSyncing ? null : _toggleAutoSync,
                        activeColor: Colors.white,
                        activeTrackColor: Colors.white70,
                      ),
                    ),
                    if (!_autoSyncEnabled)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0, left: 16, right: 16),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.cloud_upload, color: Colors.white),
                          label: const Text('Sync Now', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          onPressed: _isSyncing ? null : _syncActivityToBackend,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(l10n.yourProgressAtAGlance,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildActivityCard(
                  l10n,
                  Icons.timer,
                  l10n.totalStudyTime,
                  '${((_activityData['watchTimeSeconds'] as int) / 60).round()} ${l10n.minutes}',
                  l10n.totalStudyTimeDescription,
                  (_activityData['watchTimeSeconds'] as int) / 120000, // 2000 minutes max
                  isDarkMode),
              _buildActivityCard(
                  l10n,
                  Icons.search,
                  l10n.wordsSearched,
                  '${_activityData['wordsSearched']} ${l10n.words}',
                  l10n.wordsSearchedDescription,
                  (_activityData['wordsSearched'] as int) / 500,
                  isDarkMode),
              _buildActivityCard(
                  l10n,
                  Icons.bookmark_added,
                  l10n.wordsSaved,
                  '${_activityData['wordsSaved']} ${l10n.words}',
                  l10n.wordsSavedDescription,
                  (_activityData['wordsSaved'] as int) / 100,
                  isDarkMode),
              _buildActivityCard(
                  l10n,
                  Icons.auto_stories,
                  l10n.flashcardsViewedTotal,
                  '${_activityData['flashcardsCompleted']} ${l10n.flashcards}',
                  l10n.flashcardsViewedTotalDescription,
                  (_activityData['flashcardsCompleted'] as int) / 200,
                  isDarkMode),
              const SizedBox(height: 30),
              Text(l10n.flashcardsViewedByLevel,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildLevelFlippedRow(
                          l10n, l10n.a1Level, _activityData['flippedA1'] ?? 0, isDarkMode),
                      _buildLevelFlippedRow(
                          l10n, l10n.a2Level, _activityData['flippedA2'] ?? 0, isDarkMode),
                      _buildLevelFlippedRow(
                          l10n, l10n.b1Level, _activityData['flippedB1'] ?? 0, isDarkMode),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildActivityCard(
                  l10n,
                  Icons.local_fire_department,
                  l10n.longestDailyStreak,
                  '${_activityData['longestStreak']} ${l10n.days}',
                  l10n.longestDailyStreakDescription,
                  (_activityData['longestStreak'] as int) / 30,
                  isDarkMode),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Row(children: [
                  Icon(Icons.calendar_today, size: 24, color: descriptionColor),
                  const SizedBox(width: 10),
                  Text(
                      _activityData['lastAppUsageDate'] != null
                          ? l10n.lastUsed(DateFormat.yMMMMd().format(_activityData['lastAppUsageDate'] as DateTime))
                          : l10n.notAvailable,
                      style: TextStyle(color: descriptionColor, fontSize: 16)),
                ]),
              ),
              Text(l10n.comparison,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildBarChartCard(l10n, _activityData['wordsSearched'] as int, 
                  _activityData['wordsSaved'] as int, _activityData['flashcardsCompleted'] as int, isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(AppLocalizations l10n, IconData icon, String title,
      String value, String description, double progress, bool isDarkMode) {
    final valueColor = isDarkMode ? Colors.deepPurple[300] : Colors.deepPurple;
    final descriptionColor = isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
    final trackColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 30, color: valueColor),
              const SizedBox(width: 15),
              Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 15),
            Text(value,
                style: GoogleFonts.lato(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: valueColor)),
            const SizedBox(height: 10),
            Text(description,
                style: TextStyle(fontSize: 16, color: descriptionColor)),
            const SizedBox(height: 20),
            LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: trackColor,
                color: valueColor,
                minHeight: 8,
                borderRadius: BorderRadius.circular(10)),
            const SizedBox(height: 5),
            Text(l10n.towardsGoal((progress * 100).toInt()),
                style: TextStyle(
                    fontSize: 14, color: descriptionColor.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelFlippedRow(
      AppLocalizations l10n, String levelName, int count, bool isDarkMode) {
    final countColor = isDarkMode ? Colors.deepPurple[300] : Colors.deepPurple;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(levelName, style: Theme.of(context).textTheme.titleMedium),
        Text('$count ${l10n.flashcards}',
            style: GoogleFonts.lato(
                fontSize: 18, fontWeight: FontWeight.bold, color: countColor)),
      ]),
    );
  }

  Widget _buildBarChartCard(AppLocalizations l10n, int wordsSearched,
      int wordsSaved, int flashcardsViewed, bool isDarkMode) {
    final titleColor = isDarkMode ? Colors.white : Colors.black87;
    final labelColor = isDarkMode ? Colors.white70 : Colors.black54;
    final barColor1 = Colors.deepPurple.shade300;
    final barColor2 = Colors.orange.shade300;
    final barColor3 = Colors.green.shade300;
    final double maxActivity = [wordsSearched, wordsSaved, flashcardsViewed]
        .reduce((a, b) => a > b ? a : b)
        .toDouble()
        .clamp(1.0, double.infinity);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.yourMainActivities,
                style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: titleColor),
                textAlign: TextAlign.center),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar((wordsSearched / maxActivity) * 150, barColor1,
                    l10n.searched, wordsSearched, labelColor),
                _buildBar((wordsSaved / maxActivity) * 150, barColor2,
                    l10n.saved, wordsSaved, labelColor),
                _buildBar((flashcardsViewed / maxActivity) * 150, barColor3,
                    l10n.viewed, flashcardsViewed, labelColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(
      double height, Color color, String label, int value, Color labelColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('$value',
            style: GoogleFonts.lato(
                fontSize: 14, fontWeight: FontWeight.bold, color: labelColor)),
        const SizedBox(height: 8),
        Container(
            height: height.clamp(0, 150),
            width: 50,
            decoration: BoxDecoration(
                color: color,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)))),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.lato(fontSize: 14, color: labelColor)),
      ],
    );
  }
}

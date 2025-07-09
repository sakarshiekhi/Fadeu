import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../services/battery_optimization.dart';
import '../../l10n/app_localizations.dart';

class NotificationSettingsPage extends StatefulWidget {
  final bool isDarkMode;
  const NotificationSettingsPage({super.key, required this.isDarkMode});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _notificationsEnabled = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);
  int _selectedInterval = 60;
  late String _selectedLevel;
  late List<String> _levels;

  static const String _backgroundTaskName = "fadeuPeriodicWordTask";
  final List<int> _intervals = [15, 30, 60, 120, 240];

  @override
  void initState() {
    super.initState();
    // Delay initialization to didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeLevels();
  }

  void _initializeLevels() {
    final localizations = AppLocalizations.of(context)!;
    _levels = [
      localizations.allLevels,
      localizations.flashcardLevelA1,
      localizations.flashcardLevelA2,
      localizations.flashcardLevelB1,
    ];
    _selectedLevel = _levels[0];
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
      _startTime = _timeFromString(
        prefs.getString('notificationStartTime') ?? '08:00',
      );
      _endTime = _timeFromString(
        prefs.getString('notificationEndTime') ?? '22:00',
      );
      _selectedInterval = prefs.getInt('notificationInterval') ?? 60;
      final savedLevel = prefs.getString('notificationLevel');
      if (savedLevel != null && _levels.contains(savedLevel)) {
        _selectedLevel = savedLevel;
      }
    });
  }

  TimeOfDay _timeFromString(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _stringFromTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _handleBatteryOptimization() async {
    bool? isAlreadyDisabled = await BatteryOptimization.isBatteryOptimizationDisabled();
    if (isAlreadyDisabled == false) {
      BatteryOptimization.showDisableBatteryOptimizationSettings();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Battery optimization is already disabled for this app.',
              style: TextStyle(fontFamily: 'Vazirmatn'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _scheduleOrCancelBackgroundTask(bool isEnabled) {
    if (isEnabled) {
      final currentLocale = Localizations.localeOf(context).languageCode;
      Workmanager().registerPeriodicTask(
        _backgroundTaskName,
        _backgroundTaskName,
        frequency: Duration(minutes: _selectedInterval),
        inputData: {
          'locale': currentLocale,
          'level': _selectedLevel,
        },
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(networkType: NetworkType.not_required),
      );
    } else {
      Workmanager().cancelByUniqueName(_backgroundTaskName);
    }
  }

  void _saveAndSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setString('notificationStartTime', _stringFromTime(_startTime));
    await prefs.setString('notificationEndTime', _stringFromTime(_endTime));
    await prefs.setInt('notificationInterval', _selectedInterval);
    await prefs.setString('notificationLevel', _selectedLevel);
    await prefs.setInt('lastNotificationTimestamp', 0);

    _scheduleOrCancelBackgroundTask(_notificationsEnabled);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _notificationsEnabled
                ? 'Learning session scheduled! You will get words every ${_formatInterval(_selectedInterval)}.'
                : 'Notifications disabled.',
          ),
        ),
      );
    }
  }

  String _formatInterval(int minutes) {
    final localizations = AppLocalizations.of(context)!;
    if (minutes < 60) {
      return minutes == 1
          ? '1 ${localizations.minute}'
          : '$minutes ${localizations.minutes}';
    } else {
      final hours = minutes ~/ 60;
      return hours == 1
          ? '1 ${localizations.hour}'
          : '$hours ${localizations.hours}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isDarkMode ? Colors.white : Colors.black;
    final backgroundColor = widget.isDarkMode ? Colors.black : Colors.grey[100];
    final cardColor = widget.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white70 : Colors.black87;
    final iconColor = widget.isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.notificationSettings,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Vazirmatn',
            color: themeColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: themeColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            color: cardColor,
            child: SwitchListTile(
              title: Text(
                AppLocalizations.of(context)!.enableLearningSessions,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              value: _notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              secondary: Icon(Icons.school_outlined, color: iconColor),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: cardColor,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.hourglass_top_outlined, color: iconColor),
                  title: Text(
                    AppLocalizations.of(context)!.startTime,
                    style: TextStyle(color: textColor, fontFamily: 'Vazirmatn'),
                  ),
                  trailing: Text(_startTime.format(context), style: TextStyle(color: themeColor, fontSize: 16)),
                  onTap: () => _pickTime(true),
                  enabled: _notificationsEnabled,
                ),
                ListTile(
                  leading: Icon(Icons.hourglass_bottom_outlined, color: iconColor),
                  title: Text(AppLocalizations.of(context)!.endTime, style: TextStyle(color: textColor, fontFamily: 'Vazirmatn')),
                  trailing: Text(_endTime.format(context), style: TextStyle(color: themeColor, fontSize: 16)),
                  onTap: () => _pickTime(false),
                  enabled: _notificationsEnabled,
                ),
                ListTile(
                  leading: Icon(Icons.timer_outlined, color: iconColor),
                  title: Text(AppLocalizations.of(context)!.frequency, style: TextStyle(color: textColor, fontFamily: 'Vazirmatn')),
                  trailing: DropdownButton<int>(
                    value: _selectedInterval,
                    dropdownColor: cardColor,
                    style: TextStyle(color: themeColor, fontSize: 16),
                    underline: const SizedBox(),
                    items: _intervals.map((int value) => DropdownMenuItem<int>(value: value, child: Text(_formatInterval(value)))).toList(),
                    onChanged: _notificationsEnabled ? (int? newValue) => setState(() => _selectedInterval = newValue!) : null,
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.layers_outlined, color: iconColor),
                  title: Text(AppLocalizations.of(context)!.wordLevel, style: TextStyle(color: textColor, fontFamily: 'Vazirmatn')),
                  trailing: DropdownButton<String>(
                    value: _selectedLevel,
                    dropdownColor: cardColor,
                    style: TextStyle(color: themeColor, fontSize: 16),
                    underline: const SizedBox(),
                    items: _levels.map((value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                    onChanged: _notificationsEnabled ? (String? newValue) => setState(() => _selectedLevel = newValue!) : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: cardColor,
            child: ListTile(
              leading: Icon(Icons.power_settings_new_outlined, color: Colors.orangeAccent),
              title: Text(AppLocalizations.of(context)!.improveNotificationDelivery, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
              subtitle: Text(AppLocalizations.of(context)!.essentialForNotifications, style: TextStyle(color: textColor.withOpacity(0.7), fontFamily: 'Vazirmatn')),
              onTap: _handleBatteryOptimization,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _saveAndSchedule,
            child: Text(AppLocalizations.of(context)!.saveSettings, style: const TextStyle(fontFamily: 'Vazirmatn')),
          ),
        ],
      ),
    );
  }
}
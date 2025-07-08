import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:workmanager/workmanager.dart';
import '../../services/battery_optimization.dart';

class NotificationSettingsPage extends StatefulWidget {
  final bool isDarkMode;
  const NotificationSettingsPage({super.key, required this.isDarkMode});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // --- State variables are unchanged ---
  bool _notificationsEnabled = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);
  int _selectedInterval = 60;
  String _selectedLevel = 'All';

  static const String _backgroundTaskName = "fadeuPeriodicWordTask";

  final List<int> _intervals = [15, 30, 60, 120, 240];

  @override
  void initState() {
    super.initState();
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
      _selectedLevel = prefs.getString('notificationLevel') ?? 'All';
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

  // --- 2. ADD THE LOGIC FOR THE NEW BUTTON ---
  Future<void> _handleBatteryOptimization() async {
    bool? isAlreadyDisabled =
        await BatteryOptimization.isBatteryOptimizationDisabled();
    if (isAlreadyDisabled == false) {
      BatteryOptimization.showDisableBatteryOptimizationSettings();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Battery optimization is already disabled for this app.',
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
      final selectedLevel = _selectedLevel;

      Workmanager().registerPeriodicTask(
        _backgroundTaskName,
        _backgroundTaskName,
        frequency: Duration(minutes: _selectedInterval),
        inputData: <String, dynamic>{
          'locale': currentLocale,
          'level': selectedLevel,
        },
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(networkType: NetworkType.not_required),
      );
      debugPrint("Workmanager task registered: $_backgroundTaskName");
    } else {
      Workmanager().cancelByUniqueName(_backgroundTaskName);
      debugPrint("Workmanager task cancelled: $_backgroundTaskName");
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
    if (minutes < 60) {
      return '$minutes minutes';
    } else {
      final hours = minutes ~/ 60;
      return '$hours hour${hours > 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isDarkMode ? Colors.white : Colors.black;
    final backgroundColor = widget.isDarkMode ? Colors.black : Colors.grey[100];
    final cardColor = widget.isDarkMode
        ? const Color(0xFF1C1C1E)
        : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white70 : Colors.black87;
    final iconColor = widget.isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: GoogleFonts.lato(
            fontSize: 22,
            fontWeight: FontWeight.bold,
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
                'Enable Learning Sessions',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
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
                  title: Text('Start Time', style: TextStyle(color: textColor)),
                  trailing: Text(
                    _startTime.format(context),
                    style: TextStyle(color: themeColor, fontSize: 16),
                  ),
                  onTap: () => _pickTime(true),
                  enabled: _notificationsEnabled,
                ),
                ListTile(
                  leading: Icon(
                    Icons.hourglass_bottom_outlined,
                    color: iconColor,
                  ),
                  title: Text('End Time', style: TextStyle(color: textColor)),
                  trailing: Text(
                    _endTime.format(context),
                    style: TextStyle(color: themeColor, fontSize: 16),
                  ),
                  onTap: () => _pickTime(false),
                  enabled: _notificationsEnabled,
                ),
                ListTile(
                  leading: Icon(Icons.timer_outlined, color: iconColor),
                  title: Text('Frequency', style: TextStyle(color: textColor)),
                  trailing: DropdownButton<int>(
                    value: _selectedInterval,
                    dropdownColor: cardColor,
                    style: TextStyle(color: themeColor, fontSize: 16),
                    underline: const SizedBox(),
                    items: _intervals.map<DropdownMenuItem<int>>((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(_formatInterval(value)),
                      );
                    }).toList(),
                    onChanged: _notificationsEnabled
                        ? (int? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedInterval = newValue;
                              });
                            }
                          }
                        : null,
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.layers_outlined, color: iconColor),
                  title: Text('Word Level', style: TextStyle(color: textColor)),
                  trailing: DropdownButton<String>(
                    value: _selectedLevel,
                    dropdownColor: cardColor,
                    style: TextStyle(color: themeColor, fontSize: 16),
                    underline: const SizedBox(),
                    items: ['All', 'A1', 'A2', 'B1']
                        .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        })
                        .toList(),
                    onChanged: _notificationsEnabled
                        ? (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedLevel = newValue;
                              });
                            }
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- 3. ADD THE NEW UI WIDGET ---
          Card(
            color: cardColor,
            child: ListTile(
              leading: Icon(
                Icons.power_settings_new_outlined,
                color: Colors.orangeAccent,
              ),
              title: Text(
                'Improve Notification Delivery',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Essential for notifications to work correctly on some devices.',
                style: TextStyle(color: textColor.withOpacity(0.7)),
              ),
              onTap: _handleBatteryOptimization,
            ),
          ),

          // ------------------------------------
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _saveAndSchedule,
            child: const Text(
              'Save Settings',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

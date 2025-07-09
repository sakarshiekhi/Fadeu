import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fadeu/pages/auth/signup.dart';
import 'package:fadeu/pages/auth/login.dart';
import 'package:fadeu/pages/auth/forgetPassword.dart';
import 'package:fadeu/pages/settings/user_activity.dart' show UserActivityPage;
import 'package:fadeu/pages/settings/notification_settings_page.dart';
import 'package:fadeu/l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  final bool isDarkMode;
  final Function(Locale) onLanguageChanged;
  final Function(ThemeMode) onThemeChanged;
  final Locale currentLocale;
  final ThemeMode currentThemeMode;

  const SettingsPage({
    super.key,
    required this.isDarkMode,
    required this.onLanguageChanged,
    required this.onThemeChanged,
    required this.currentLocale,
    required this.currentThemeMode,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final themeColor = widget.isDarkMode ? Colors.white : Colors.black;
    final backgroundColor = widget.isDarkMode ? Colors.black : Colors.grey[100];
    final cardColor =
        widget.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white70 : Colors.black87;
    final iconColor = widget.isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.settings,
          style: GoogleFonts.lato(
              fontSize: 22, fontWeight: FontWeight.bold, color: themeColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: themeColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Language and Theme Settings
          Card(
            color: cardColor,
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.language, color: iconColor),
                  title: Text(
                    l10n.language,
                    style: GoogleFonts.lato(fontSize: 18, color: textColor),
                  ),
                  trailing: DropdownButton<Locale>(
                    value: widget.currentLocale,
                    icon: Icon(Icons.arrow_drop_down, color: iconColor),
                    dropdownColor: cardColor,
                    onChanged: (Locale? newLocale) {
                      if (newLocale != null) {
                        widget.onLanguageChanged(newLocale);
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: Locale('en'),
                        child: Text('English'),
                      ),
                      DropdownMenuItem(
                        value: Locale('fa'),
                        child: Text('فارسی'),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.brightness_6, color: iconColor),
                  title: Text(
                    l10n.theme,
                    style: GoogleFonts.lato(fontSize: 18, color: textColor),
                  ),
                  trailing: Switch(
                    value: widget.isDarkMode,
                    onChanged: (bool isDark) {
                      widget.onThemeChanged(
                          isDark ? ThemeMode.dark : ThemeMode.light);
                    },
                    activeColor: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),

          // User Activity Option
          Card(
            color: cardColor,
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              leading: Icon(Icons.timeline, color: iconColor),
              title: Text(
                l10n.userActivity,
                style: GoogleFonts.lato(fontSize: 18, color: textColor),
              ),
              trailing:
                  Icon(Icons.arrow_forward_ios, size: 16, color: iconColor),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          UserActivityPage(isDarkMode: widget.isDarkMode)),
                );
              },
            ),
          ),

          // Notifications Option
          Card(
            color: cardColor,
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              leading:
                  Icon(Icons.notifications_active_outlined, color: iconColor),
              title: Text(
                l10n.notifications,
                style: GoogleFonts.lato(fontSize: 18, color: textColor),
              ),
              trailing:
                  Icon(Icons.arrow_forward_ios, size: 16, color: iconColor),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => NotificationSettingsPage(
                          isDarkMode: widget.isDarkMode)),
                );
              },
            ),
          ),

          // SignUp
          Card(
            color: cardColor,
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              leading: Icon(Icons.person_add, color: iconColor),
              title: Text(
                l10n.signUp,
                style: GoogleFonts.lato(fontSize: 18, color: textColor),
              ),
              trailing:
                  Icon(Icons.arrow_forward_ios, size: 16, color: iconColor),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignUp(
                      isDarkMode: widget.isDarkMode,
                      onThemeChanged: widget.onThemeChanged,
                      onLanguageChanged: widget.onLanguageChanged,
                      currentLocale: widget.currentLocale,
                    ),
                  ),
                );
              },
            ),
          ),

          // Login
          Card(
            color: cardColor,
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              leading: Icon(Icons.login, color: iconColor),
              title: Text(
                l10n.login,
                style: GoogleFonts.lato(fontSize: 18, color: textColor),
              ),
              trailing:
                  Icon(Icons.arrow_forward_ios, size: 16, color: iconColor),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Login(
                      isDarkMode: widget.isDarkMode,
                      onThemeChanged: widget.onThemeChanged,
                      onLanguageChanged: widget.onLanguageChanged,
                      currentLocale: widget.currentLocale,
                    ),
                  ),
                );
              },
            ),
          ),

          // Forgotten Password
          Card(
            color: cardColor,
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              leading: Icon(Icons.lock_reset, color: iconColor),
              title: Text(
                l10n.forgottenPassword,
                style: GoogleFonts.lato(fontSize: 18, color: textColor),
              ),
              trailing:
                  Icon(Icons.arrow_forward_ios, size: 16, color: iconColor),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ForgetPassword(
                            isDarkMode: widget.isDarkMode,
                            onThemeChanged: widget.onThemeChanged,
                            onLanguageChanged: widget.onLanguageChanged,
                            currentLocale: widget.currentLocale,
                          )),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

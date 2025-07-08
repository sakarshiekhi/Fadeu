import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fadeu/l10n/app_localizations.dart';
import 'package:fadeu/pages/auth/verifycode.dart';
import 'package:fadeu/services/api_service.dart';

class ForgetPassword extends StatefulWidget {
  final bool isDarkMode;
  final Function(ThemeMode) onThemeChanged;
  final Function(Locale) onLanguageChanged;
  final Locale currentLocale;

  const ForgetPassword({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.currentLocale,
  });

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final TextEditingController emailController = TextEditingController();
  bool _submitted = false;
  bool _isLoading = false;

  Future<void> _sendResetRequest() async {
    final enteredEmail = emailController.text.trim();
    if (enteredEmail.isEmpty) return;

    setState(() {
      _isLoading = true;
      _submitted = false;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.requestPasswordReset(enteredEmail);

      if (!mounted) return;

      if (response['success'] == true) {
        // Navigate to verify code page on success
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyCodePage(
                email: enteredEmail,
                isDarkMode: widget.isDarkMode,
                onThemeChanged: widget.onThemeChanged,
                onLanguageChanged: widget.onLanguageChanged,
                currentLocale: widget.currentLocale,
              ),
            ),
          );
        }
      }
      
      // Show success or error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? AppLocalizations.of(context)!.resetRequestFailed),
            backgroundColor: response['success'] == true ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Password reset request error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.connectionError),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _submitted = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final themeColor = isDark ? Colors.white : Colors.black;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: BackButton(color: themeColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              l10n.resetPasswordTitle,
              style: GoogleFonts.vazirmatn(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.resetPasswordInstruction,
              textAlign: TextAlign.center,
              style: TextStyle(color: themeColor.withOpacity(0.7)),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: themeColor),
              decoration: InputDecoration(
                labelText: l10n.emailHint,
                labelStyle: TextStyle(color: themeColor),
                prefixIcon: Icon(Icons.email, color: themeColor),
                filled: true,
                fillColor: isDark ? Colors.black26 : Colors.grey[200],
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: themeColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.deepPurple),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoading ? null : _sendResetRequest,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      l10n.weWillSendYouTheCode,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
            if (_submitted)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  l10n.resetEmailSentConfirmation,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: themeColor.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

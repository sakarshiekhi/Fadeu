import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fadeu/services/api_service.dart';
import 'package:fadeu/pages/auth/resetPassword.dart';
import 'package:fadeu/l10n/app_localizations.dart';

class VerifyCodePage extends StatefulWidget {
  final String email;
  final bool isDarkMode;
  final Function(ThemeMode) onThemeChanged;
  final Function(Locale) onLanguageChanged;
  final Locale currentLocale;

  const VerifyCodePage({
    super.key,
    required this.email,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.currentLocale,
  });

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final TextEditingController codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final enteredCode = codeController.text.trim();
    if (enteredCode.length != 6) {
      _showSnack('Please enter a valid 6-digit code');
      return;
    }
    
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final response = await apiService.verifyCode(widget.email, enteredCode);
      
      if (!mounted) return;

      if (response['success'] == true) {
        _showSnack(response['message'] ?? 'Code verified successfully', isError: false);
        
        // Give user time to see success message
        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPassword(
              email: widget.email,
              code: enteredCode,
              isDarkMode: widget.isDarkMode,
              onThemeChanged: widget.onThemeChanged,
              onLanguageChanged: widget.onLanguageChanged,
              currentLocale: widget.currentLocale,
            ),
          ),
        );
      } else {
        // Handle different error cases
        String errorMessage = response['message'] ?? 
                            response['detail'] ?? 
                            l10n.verificationFailed;
        
        // Check for specific error cases
        if (response['statusCode'] == 400) {
          errorMessage = 'Invalid or expired verification code';
        } else if (response['statusCode'] == 404) {
          errorMessage = 'No password reset request found for this email';
        }
        
        _showSnack(errorMessage);
      }
    } catch (e) {
      print('Verification error: $e');
      if (mounted) {
        _showSnack('Network error. Please check your connection and try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnack(String message, {bool isError = true}) {
    if (!mounted) return;
    
    // Hide any existing snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    // Show new snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isDarkMode ? Colors.white : Colors.black;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.verifyCodeTitle),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: BackButton(color: themeColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                l10n.enterCodeInstruction,
                textAlign: TextAlign.center,
                style: GoogleFonts.vazirmatn(
                    fontSize: 18, color: themeColor.withOpacity(0.8)),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                    fontSize: 28, color: themeColor, letterSpacing: 12),
                decoration: InputDecoration(
                  counterText: "", // Hide the character counter
                  hintText: '______',
                  hintStyle: TextStyle(
                      color: Colors.grey[600], letterSpacing: 12, fontSize: 28),
                  border: const UnderlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return null; // Commented out l10n.invalidCodeError
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(l10n.verifyButton,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

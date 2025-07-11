import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fadeu/l10n/app_localizations.dart';
import 'package:fadeu/services/api_service.dart';

class ResetPassword extends StatefulWidget {
  final String email;
  final String code;
  final bool isDarkMode;
  final Function(ThemeMode) onThemeChanged;
  final Function(Locale) onLanguageChanged;
  final Locale currentLocale;

  const ResetPassword({
    super.key,
    required this.email,
    required this.code,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.currentLocale,
  });

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // Password validation
    if (newPassword.length < 8) {
      _showError('Password must be at least 8 characters long');
      return;
    }

    if (newPassword != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.resetPassword(
        email: widget.email,
        code: widget.code,
        newPassword: newPassword,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        // Show success message
        _showSnackBar(
          response['message'] ?? 'Password reset successfully',
          isError: false,
        );

        // Navigate back to login after a short delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } else {
        // Handle different error cases
        String errorMessage = response['message'] ?? 
                            response['detail'] ?? 
                            'Failed to reset password';
        
        // Check for specific error cases
        if (response['statusCode'] == 400) {
          errorMessage = 'Invalid or expired reset token';
        } else if (response['statusCode'] == 404) {
          errorMessage = 'No password reset request found';
        }
        
        _showError(errorMessage);
      }
    } catch (e) {
      print('Reset password error: $e');
      _showError('Network error. Please check your connection and try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
    });
    
    // Auto-hide error after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          if (_errorMessage == message) {
            _errorMessage = null;
          }
        });
      }
    });
  }

  void _showSnackBar(String message, {bool isError = true}) {
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
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
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
        child: Form(
          key: _formKey,
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
                'Create a new password for ${widget.email}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: themeColor.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              
              // New Password Field
              TextFormField(
                controller: newPasswordController,
                obscureText: _obscurePassword,
                style: TextStyle(color: themeColor),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(color: themeColor),
                  prefixIcon: Icon(Icons.lock_outline, color: themeColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: themeColor.withOpacity(0.7),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.black26 : Colors.grey[200],
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: themeColor.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.deepPurple),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  } else if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Confirm Password Field
              TextFormField(
                controller: confirmPasswordController,
                obscureText: _obscureConfirm,
                style: TextStyle(color: themeColor),
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  labelStyle: TextStyle(color: themeColor),
                  prefixIcon: Icon(Icons.lock_outline, color: themeColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      color: themeColor.withOpacity(0.7),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.black26 : Colors.grey[200],
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: themeColor.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.deepPurple),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password';
                  } else if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Reset Password Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Reset Password',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

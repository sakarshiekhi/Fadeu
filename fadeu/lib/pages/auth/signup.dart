import 'package:fadeu/l10n/app_localizations.dart';
import 'package:fadeu/pages/auth/login.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fadeu/services/api_service.dart';

class SignUp extends StatefulWidget {
  final bool isDarkMode;
  final Function(ThemeMode) onThemeChanged;
  final Function(Locale) onLanguageChanged;
  final Locale currentLocale;

  const SignUp({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.currentLocale,
  });

  @override
  State<SignUp> createState() => SignUpPageState();
}

class SignUpPageState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // Helper function to handle navigation back to the Login page
  void _goToLoginPage() {
    Navigator.pushReplacement(
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
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.passwordsDoNotMatchError),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final response = await apiService.signup(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (mounted) {
        final message = response['message'] ?? (response['success'] ? l10n.signupSuccessful : l10n.signupFailed);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: response['success'] ? Colors.green : Colors.red,
          ),
        );
      }

      if (response['success'] == true && mounted) {
        // Wait a moment for the user to see the success message
        await Future.delayed(const Duration(seconds: 2));
        _goToLoginPage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.signupFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final themeColor = isDark ? Colors.white : Colors.black;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _goToLoginPage();
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: themeColor),
            onPressed: _goToLoginPage,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  l10n.createAccountTitle,
                  style: GoogleFonts.vazirmatn(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 32),
                _buildTextField(
                  controller: emailController,
                  label: l10n.emailLabel,
                  icon: Icons.email,
                  isDark: isDark,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return l10n.emailRequiredError;
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return l10n.invalidEmailError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: passwordController,
                  label: l10n.passwordLabel,
                  isObscured: _obscurePassword,
                  onToggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
                _buildPasswordField(
                  controller: confirmPasswordController,
                  label: l10n.confirmPasswordLabel,
                  isObscured: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  isDark: isDark,
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
                  onPressed: _isLoading ? null : _handleSignUp,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          l10n.signUpButton,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
                        ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _goToLoginPage,
                  child: Text(
                    l10n.alreadyHaveAccount,
                    style: const TextStyle(color: Colors.deepPurple),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isDark = true,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final themeColor = isDark ? Colors.white : Colors.black;
    final l10n = AppLocalizations.of(context)!;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: themeColor),
      validator: validator ??
          (value) =>
              value == null || value.isEmpty ? l10n.requiredFieldError : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: themeColor),
        prefixIcon: Icon(icon, color: themeColor),
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
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isObscured,
    required VoidCallback onToggle,
    required bool isDark,
  }) {
    final themeColor = isDark ? Colors.white : Colors.black;
    final l10n = AppLocalizations.of(context)!;

    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      style: TextStyle(color: themeColor),
      validator: (value) =>
          value == null || value.length < 6 ? l10n.passwordLengthError : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: themeColor),
        prefixIcon: Icon(Icons.lock, color: themeColor),
        filled: true,
        fillColor: isDark ? Colors.black26 : Colors.grey[200],
        suffixIcon: IconButton(
          key: ValueKey(isObscured),
          icon: Icon(
            isObscured ? Icons.visibility_off : Icons.visibility,
            color: themeColor,
          ),
          onPressed: onToggle,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: themeColor),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.deepPurple),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

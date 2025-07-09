import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:fadeu/l10n/app_localizations.dart';
import 'package:fadeu/pages/auth/forgetPassword.dart';
import 'package:fadeu/pages/dictionary/homePage.dart';
import 'package:fadeu/pages/auth/signup.dart';
import 'package:fadeu/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  final bool isDarkMode;
  final Function(ThemeMode) onThemeChanged;
  final Function(Locale) onLanguageChanged;
  final Locale currentLocale;

  const Login({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.currentLocale,
  });

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> loginUser(String email, String password) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    // Clear any previous errors
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }

    try {
      print('Starting login process for: $email');
      final apiService = ApiService();
      final response = await apiService.login(
        email.trim(),
        password,
      );
      print('Login response received: $response');

      if (!mounted) return;

      if (response['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        
        // Store the auth tokens
        final accessToken = response['access'];
        final refreshToken = response['refresh'];
        
        if (accessToken == null) {
          throw Exception('No access token received');
        }
        
        // Store tokens
        await Future.wait([
          prefs.setString('access_token', accessToken),
          if (refreshToken != null) prefs.setString('refresh_token', refreshToken),
          prefs.setString('user_email', email),
          prefs.setBool('hasCompletedLogin', true),
          // For backward compatibility
          prefs.setString('auth_token', accessToken),
          prefs.setString('token', accessToken),
        ]);

        print("Login successful. Tokens stored.");

        // Navigate to home page
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => MainHomePage(
                isDarkMode: widget.isDarkMode,
                onThemeChanged: widget.onThemeChanged,
                onLanguageChanged: widget.onLanguageChanged,
                currentLocale: widget.currentLocale,
              ),
            ),
            (route) => false,
          );
        }
      } else {
        // Handle error response
        final localizations = AppLocalizations.of(context)!;
        String errorMessage = response['message'] ?? localizations.unknownError;
        
        // Handle specific error cases
        if (response['statusCode'] == 400 || response['statusCode'] == 401) {
          errorMessage = 'Invalid email or password. Please try again.';
        } else if (response['statusCode'] == 403) {
          errorMessage = 'Your account has been disabled. Please contact support.';
        } else if (response['statusCode'] == 404) {
          errorMessage = 'User not found. Please check your email and try again.';
        } else if (response['statusCode'] == 500) {
          errorMessage = 'Server error. Please try again later.';
        }
        
        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } on ClientException catch (e) {
      print('Network error during login: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection error. Please check your internet connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on Exception catch (e, stackTrace) {
      print('Unexpected error during login: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        String errorMessage = 'Login failed. Please check your credentials and try again.';
        
        // For any exception, just use its string representation
        errorMessage = e.toString();
        
        // If it's a DioError, we can extract more specific error information
        if (e is ClientException) {
          errorMessage = 'Network error: ${e.message}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> skipLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedLogin', true);
    print("User skipped login. Status stored.");

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => MainHomePage(
          isDarkMode: widget.isDarkMode,
          onThemeChanged: widget.onThemeChanged,
          onLanguageChanged: widget.onLanguageChanged,
          currentLocale: widget.currentLocale,
        ),
      ),
      (route) => false,
    );
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
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "fadeu",
                  style: GoogleFonts.pacifico(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: themeColor),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        !value.contains('@')) {
                      return l10n.emailValidationError;
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: l10n.emailHint,
                    labelStyle: TextStyle(color: themeColor),
                    prefixIcon: Icon(Icons.email, color: themeColor),
                    filled: true,
                    fillColor: isDark ? Colors.black26 : Colors.grey[200],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: themeColor),
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 6) {
                      return l10n.passwordValidationError;
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: l10n.passwordHint,
                    labelStyle: TextStyle(color: themeColor),
                    prefixIcon: Icon(Icons.lock, color: themeColor),
                    filled: true,
                    fillColor: isDark ? Colors.black26 : Colors.grey[200],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: themeColor),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () => loginUser(
                          emailController.text.trim(), passwordController.text),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(l10n.loginButton,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ForgetPassword(
                            isDarkMode: widget.isDarkMode,
                            onThemeChanged: widget.onThemeChanged,
                            onLanguageChanged: widget.onLanguageChanged,
                            currentLocale: widget.currentLocale,
                          ),
                        ),
                      ),
                      child: Text(l10n.forgotPasswordButton,
                          style: const TextStyle(color: Colors.deepPurple)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SignUp(
                            isDarkMode: widget.isDarkMode,
                            onThemeChanged: widget.onThemeChanged,
                            onLanguageChanged: widget.onLanguageChanged,
                            currentLocale: widget.currentLocale,
                          ),
                        ),
                      ),
                      child: Text(l10n.signUpButton,
                          style: const TextStyle(color: Colors.deepPurple)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: skipLogin,
                  child: Text(l10n.skipButton,
                      style: TextStyle(color: themeColor.withOpacity(0.7))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

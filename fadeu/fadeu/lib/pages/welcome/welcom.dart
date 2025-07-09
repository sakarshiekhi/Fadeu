import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fadeu/pages/auth/signup.dart'; 

class WelcomePage extends StatefulWidget {
  final bool isDarkMode;
  final Function(ThemeMode) onThemeChanged;
  final Function(Locale) onLanguageChanged;
  final Locale currentLocale;

  const WelcomePage({
    super.key, 
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.currentLocale,
  });

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _showBottomText = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _showBottomText = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.isDarkMode
                ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
                : [Colors.white, Colors.grey[200]!],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // Using a more evocative icon. The 'auto_stories' icon looks like an open book.
                const Icon(Icons.auto_stories_outlined, size: 60, color: Color.fromARGB(255, 162, 0, 255)),
                const SizedBox(height: 30),

                AnimatedTextKit(
                  isRepeatingAnimation: false,
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'Unlock Persian',
                      textAlign: TextAlign.center,
                      textStyle: GoogleFonts.lalezar( 
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                      speed: const Duration(milliseconds: 150),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 700),
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => SignUp(
                            isDarkMode: widget.isDarkMode,
                            onThemeChanged: widget.onThemeChanged,
                            onLanguageChanged: widget.onLanguageChanged,
                            currentLocale: widget.currentLocale,
                          ),
                        ),
                      );
                    },
                    child: const Text('Start Your Journey', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
                const Spacer(flex: 3),
                
                AnimatedOpacity(
                  opacity: _showBottomText ? 1.0 : 0.0,
                  duration: const Duration(seconds: 1),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.5, 
                      ),
                      children: [
                        const TextSpan(text: "Inspired by the classics of Goethe.\n"),
                        TextSpan(
                          text: "Crafted with ❤️ by a student for fellow learners.",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

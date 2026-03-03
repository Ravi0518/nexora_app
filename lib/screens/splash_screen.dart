import 'package:flutter/material.dart';
import 'language_screen.dart';
import '../services/language_service.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3)); // තප්පර 3ක් පෙන්වනවා

    String? lang = await LanguageService.getLang(); // කලින් භාෂාවක් තෝරලා තියෙනවද බලනවා

    if (!mounted) return;
    // ලොගින් ලොජික් එක මෙතනට පසුව ඇතුළත් කළ හැක
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => MainNavigation(lang: lang, role: 'user')));
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A120A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ලෝගෝ එක (Icon එකක් ලෙස දැනට)
            const Icon(Icons.bug_report, color: Color(0xFF00FF66), size: 100),
            const SizedBox(height: 20),
            const Text(
              "NEXORA",
              style: TextStyle(
                color: Color(0xFF00FF66),
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: 5,
              ),
            ),
            const SizedBox(height: 10),
            const Text("SNAKE IDENTIFIER", style: TextStyle(color: Colors.white24, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}
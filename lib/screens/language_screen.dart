import 'package:flutter/material.dart';
import '../services/language_service.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'English';
  bool _isSaving = false;

  // Save language preference and continue to Login
  Future<void> _continue() async {
    setState(() => _isSaving = true);
    await LanguageService.setLang(_selectedLanguage);
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final lang = _selectedLanguage;
    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Globe Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132A1C),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.language,
                      color: Color(0xFF00FF66), size: 35),
                ),
              ),
              const SizedBox(height: 30),

              Text(
                LanguageService.t(lang, 'choose_lang'),
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                LanguageService.t(lang, 'choose_lang_sub'),
                style: const TextStyle(color: Colors.white54, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Language Options
              _buildLanguageCard('English', 'Global'),
              _buildLanguageCard('සිංහල', 'Sinhala'),
              _buildLanguageCard('தமிழ்', 'Tamil'),

              const Spacer(),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 65,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF66),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 10,
                    shadowColor: const Color(0xFF00FF66).withOpacity(0.3),
                  ),
                  onPressed: _isSaving ? null : _continue,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              LanguageService.t(lang, 'continue_btn'),
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.arrow_forward,
                                color: Colors.black),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                LanguageService.t(lang, 'lang_change_hint'),
                style: const TextStyle(color: Colors.white24, fontSize: 12),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard(String title, String subtitle) {
    bool isSelected = _selectedLanguage == title;

    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF131A14),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFF00FF66) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(subtitle,
                    style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF00FF66)
                            : Colors.white24,
                        fontSize: 14)),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color:
                        isSelected ? const Color(0xFF00FF66) : Colors.white12,
                    width: 2),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Color(0xFF00FF66), size: 18)
                  : const SizedBox(width: 18, height: 18),
            ),
          ],
        ),
      ),
    );
  }
}

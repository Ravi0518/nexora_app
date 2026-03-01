import 'package:flutter/material.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  // English comments: Tracks the currently selected language
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07120B), // English comments: Dark greenish-black theme
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // English comments: Top Globe Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132A1C),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.language, color: Color(0xFF00FF66), size: 35),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Choose Language",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Select your preferred language to continue",
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              const SizedBox(height: 40),

              // English comments: Language Option List
              _buildLanguageCard("English", "Global"),
              _buildLanguageCard("සිංහල", "Sinhala"),
              _buildLanguageCard("தமிழ்", "Tamil"),

              const Spacer(),

              // English comments: Continue Button
              SizedBox(
                width: double.infinity,
                height: 65,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF66), // English comments: Vibrant neon green
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 10,
                    shadowColor: const Color(0xFF00FF66).withOpacity(0.3),
                  ),
                  onPressed: () {
                    // English comments: Logic to navigate to Login or Splash based on choice
                    Navigator.pushNamed(context, '/login');
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Continue",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward, color: Colors.black),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "You can change this anytime in settings",
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // English comments: Helper widget to build the language selection cards
  Widget _buildLanguageCard(String title, String subtitle) {
    bool isSelected = _selectedLanguage == title;

    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF131A14), // English comments: Card background
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
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF00FF66) : Colors.white24,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            // English comments: Custom Checkbox / Radio Icon
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF00FF66) : Colors.white12,
                  width: 2,
                ),
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
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/language_service.dart';

class EmergencyScreen extends StatelessWidget {
  final String lang;
  const EmergencyScreen({super.key, required this.lang});

  // දුරකථන ඇමතුම් ලබාගැනීමේ function එක
  Future<void> _makeCall(String number) async {
    final Uri url = Uri.parse("tel:$number");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    var t = LanguageService.translations[lang]!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A120A),
      appBar: AppBar(
        title: Text(lang == 'si' ? "හදිසි සහාය" : (lang == 'ta' ? "அவசர உதவி" : "Emergency Help"),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 100),
            const SizedBox(height: 30),

            Text(
              lang == 'si' ? "ප්‍රමාද නොවන්න! වහාම අමතන්න." :
              (lang == 'ta' ? "தாமதிக்க வேண்டாம்! உடனே அழையுங்கள்." : "Do not delay! Call immediately."),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            // --- 1. SUWA SERIYA AMBULANCE (1990) ---
            _emergencyCard(
              title: "1990: Suwa Seriya",
              subtitle: lang == 'si' ? "නොමිලේ ගිලන්රථ සේවාව" : "Free Ambulance Service",
              icon: Icons.medical_services,
              color: Colors.redAccent,
              onTap: () => _makeCall("1990"),
            ),

            const SizedBox(height: 20),

            // --- 2. POLICE EMERGENCY (119) ---
            _emergencyCard(
              title: "119: Police Emergency",
              subtitle: lang == 'si' ? "පොලිස් හදිසි ඇමතුම්" : "Sri Lanka Police Hotline",
              icon: Icons.local_police,
              color: Colors.blueAccent,
              onTap: () => _makeCall("119"),
            ),

            const Spacer(),

            // --- FIRST AID QUICK ACCESS ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F1A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF00FF66)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      lang == 'si' ? "ප්‍රථමාධාර උපදෙස් බලන්න" : "View First Aid Guidelines",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _emergencyCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 28,
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.call, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/language_service.dart';

/// PROFESSIONAL ENGLISH DOCUMENTATION
/// * FILE: enthusiast_home_screen.dart
/// PURPOSE: Dashboard for Snake Enthusiasts to view and accept rescue requests.
/// * TECHNICAL FEATURES:
/// 1. Localization: Implements translations for English, Sinhala, and Tamil.
/// 2. Branding: Displays 'logo.png' in the drawer/app bar.
/// 3. Deep Linking: Uses 'url_launcher' to open Google Maps for navigation.
/// 4. UX: Handles request acceptance and rejection states.

class EnthusiastHomeScreen extends StatefulWidget {
  final String lang; // English: Fixed the missing parameter error
  // Inside enthusiast_home_screen.dart
  const EnthusiastHomeScreen({super.key, required this.lang});

  @override
  State<EnthusiastHomeScreen> createState() => _EnthusiastHomeScreenState();
}

class _EnthusiastHomeScreenState extends State<EnthusiastHomeScreen> {
  // English: Helper to get translations based on current language
  Map<String, String> get t =>
      LanguageService.translations[widget.lang] ??
      LanguageService.translations['English']!;

  // Mock Request Data
  final Map<String, dynamic> _mockRequest = {
    'id': 'REQ-9902',
    'location_name': 'Mihintale, Anuradhapura',
    'lat': 8.3444,
    'lng': 80.5024,
    'time': '5 mins ago',
    'distance': '1.2 km away',
    'description':
        'Large snake found near the garden gate. Seems inactive but needs removal.',
    'image': 'https://images.unsplash.com/photo-1531386151447-ad762e755da6'
  };

  // --- PROFESSIONAL METHOD: Trigger Google Maps ---
  Future<void> _openMap() async {
    final String googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=${_mockRequest['lat']},${_mockRequest['lng']}";
    final Uri url = Uri.parse(googleMapsUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Image.asset('assets/images/logo.png',
            height: 40), // English: Logo in App Bar
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lang == 'සිංහල'
                  ? "නව සහාය ඉල්ලීම්"
                  : (widget.lang == 'தமிழ்'
                      ? "புதிய உதவி கோரிக்கைகள்"
                      : "New Assistance Requests"),
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 20),

            // --- REQUEST CARD (Screen 19 UI) ---
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF131A14),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(30)),
                    child: Image.network(_mockRequest['image'],
                        height: 250, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _infoBadge(
                                Icons.location_on, _mockRequest['distance']),
                            _infoBadge(Icons.access_time, _mockRequest['time']),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.lang == 'සිංහල'
                              ? "යූසර්ගේ විස්තරය"
                              : "User's Description",
                          style: const TextStyle(
                              color: Color(0xFF00FF66),
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _mockRequest['description'],
                          style: const TextStyle(
                              color: Colors.white70, height: 1.5),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(
                              child: _btn(
                                  widget.lang == 'සිංහල'
                                      ? "ප්‍රතික්ෂේප කරන්න"
                                      : "Reject",
                                  Colors.white10,
                                  Colors.white60,
                                  () {}),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _btn(
                                  widget.lang == 'සිංහල'
                                      ? "පිළිගන්න"
                                      : "Accept",
                                  const Color(0xFF00FF66),
                                  Colors.black,
                                  _openMap),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBadge(IconData i, String t) {
    return Row(
      children: [
        Icon(i, size: 16, color: Colors.white38),
        const SizedBox(width: 5),
        Text(t, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }

  Widget _btn(String label, Color bg, Color txt, VoidCallback onTap) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Text(label,
            style: TextStyle(color: txt, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

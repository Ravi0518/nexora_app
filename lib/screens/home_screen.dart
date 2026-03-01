import 'package:flutter/material.dart';
import '../services/language_service.dart';

class HomeScreen extends StatelessWidget {
  final List<dynamic> allSnakes;
  final String lang;
  const HomeScreen({super.key, required this.allSnakes, required this.lang});

  @override
  Widget build(BuildContext context) {
    var t = LanguageService.translations[lang]!;
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            Text(t['welcome']!, style: TextStyle(color: Colors.white54)),
            const Text("Explorer", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            // Quick Identify Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF00FF66),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  const Icon(Icons.camera_alt, size: 50, color: Colors.black),
                  const SizedBox(height: 10),
                  Text(t['quick_id']!, style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(t['point_cam']!, style: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(height: 35),
            Text(t['recent']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // ... (ListView.builder for snakes)
          ],
        ),
      ),
    );
  }
}
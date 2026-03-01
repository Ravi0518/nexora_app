import 'package:flutter/material.dart';

class SnakeDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> snake;
  final String lang;

  const SnakeDetailsScreen({super.key, required this.snake, required this.lang});

  @override
  Widget build(BuildContext context) {
    final d = snake['details'][lang];

    return Scaffold(
      backgroundColor: const Color(0xFF0A120A),
      appBar: AppBar(title: Text(snake['names'][lang]), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(snake['main_image'], width: double.infinity, height: 250, fit: BoxFit.cover),
            const SizedBox(height: 20),
            _infoTile("Habitat", d['habitat'] ?? "Forests and gardens"),
            _infoTile("Behavior", d['behavior'] ?? "Diurnal and aggressive when cornered"),
            _infoTile("Diet", d['diet'] ?? "Rats, frogs, and smaller snakes"),
            _infoTile("Identification", d['description'] ?? "Distinct hood and scale patterns"),
            const SizedBox(height: 40),
            // First Aid Guideline Box
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  const Text("First Aid & Safety", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF00FF66))),
                  const SizedBox(height: 10),
                  Text(d['first_aid'].join("\n"), style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String t, String c) => ExpansionTile(
    title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
    children: [Padding(padding: const EdgeInsets.all(15), child: Text(c, style: const TextStyle(color: Colors.white54)))],
  );
}
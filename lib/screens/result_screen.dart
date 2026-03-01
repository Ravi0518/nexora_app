import 'dart:io'; // FIX: Adds the 'File' definition
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final String imagePath;

  const ResultScreen({super.key, required this.data, required this.imagePath});

  void _callHospital() async {
    final Uri url = Uri.parse('tel:1990');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    bool isDanger = data['is_venomous'] ?? false;
    Color themeColor = isDanger ? Colors.redAccent : const Color(0xFF00FF66);

    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF07120B),
            flexibleSpace: FlexibleSpaceBar(
              background: imagePath.startsWith('assets')
                  ? Image.asset(imagePath, fit: BoxFit.cover)
                  : Image.file(File(imagePath), fit: BoxFit.cover), // FIX: File now defined
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // FIX: Corrected spelling
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['name'] ?? "Unknown",
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                            Text(data['scientific'] ?? "",
                                style: TextStyle(color: themeColor.withOpacity(0.7), fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  _buildInfoTile("General Description", data['description'] ?? "", Icons.info_outline, Colors.white),
                  const SizedBox(height: 15),
                  _buildInfoTile("Danger & Symptoms", data['symptoms'] ?? "", Icons.warning_amber_rounded, Colors.orangeAccent),
                  const SizedBox(height: 40),
                  if (isDanger)
                    ElevatedButton.icon(
                      onPressed: _callHospital,
                      icon: const Icon(Icons.phone_in_talk, color: Colors.white),
                      label: const Text("CALL EMERGENCY (1990)"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(double.infinity, 60)),
                    ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String body, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4)), // FIX: Changed lineHeight to height
      ],
    );
  }
}
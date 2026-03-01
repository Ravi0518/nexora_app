import 'package:flutter/material.dart';

class IdentifyDescriptionScreen extends StatefulWidget {
  const IdentifyDescriptionScreen({super.key});

  @override
  State<IdentifyDescriptionScreen> createState() => _IdentifyDescriptionScreenState();
}

class _IdentifyDescriptionScreenState extends State<IdentifyDescriptionScreen> {
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A120A),
      appBar: AppBar(
        title: const Text("Identify Snake", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Describe Your Sighting",
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Provide the location and a detailed description of the snake.",
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
            const SizedBox(height: 40),

            // --- 1. LOCATION FIELD ---
            _inputLabel("Location"),
            TextField(
              controller: _locationController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "e.g., Central Park, NYC",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF1A1F1A),
                suffixIcon: const Icon(Icons.my_location, color: Color(0xFF00FF66), size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 25),

            // --- 2. DESCRIPTION FIELD ---
            _inputLabel("Description"),
            TextField(
              controller: _descriptionController,
              maxLines: 6,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Describe color, size, markings, etc.",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF1A1F1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 100), // Space for button

            // --- 3. SUBMIT BUTTON ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF66),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                // Logic to submit description to Laravel API or Experts
              },
              child: const Text(
                "Submit for Identification",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }
}
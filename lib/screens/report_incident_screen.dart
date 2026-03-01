import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';

class ReportIncidentScreen extends StatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  String _selectedType = 'Sighting'; // Sighting or Bite
  File? _image;
  final _descriptionController = TextEditingController();

  // Default Map Position (Mihintale)
  static const LatLng _incidentLocation = LatLng(8.3444, 80.5024);

  // කැමරාවෙන් පින්තූරයක් ගැනීම
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A120A),
      appBar: AppBar(
        title: const Text("Report Incident", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. INCIDENT TYPE SELECTOR
            const Text("Type of Incident", style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                _typeButton("Sighting", Icons.visibility, Colors.greenAccent),
                const SizedBox(width: 15),
                _typeButton("Bite", Icons.emergency, Colors.redAccent),
              ],
            ),
            const SizedBox(height: 30),

            // 2. PHOTO UPLOAD SECTION
            const Text("Photo", style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10, style: BorderStyle.solid),
                ),
                child: _image == null
                    ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, color: Color(0xFF00FF66), size: 40),
                    SizedBox(height: 10),
                    Text("Tap to Add Photo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text("Upload an image of the snake", style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                )
                    : ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_image!, fit: BoxFit.cover)),
              ),
            ),
            const SizedBox(height: 30),

            // 3. DESCRIPTION FIELD
            const Text("Description", style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "e.g., color, size, pattern, behavior...",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF1A1F1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),

            // 4. INCIDENT LOCATION (MAP PREVIEW)
            const Text("Incident Location", style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: const GoogleMap(
                  initialCameraPosition: CameraPosition(target: _incidentLocation, zoom: 15),
                  liteModeEnabled: true, // Static feel as in UI
                  myLocationEnabled: false,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text("📍 123 Main St, Mihintale (Automatically Captured)", style: TextStyle(color: Colors.white38, fontSize: 12)),

            const SizedBox(height: 40),

            // 5. SUBMIT BUTTON
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF66),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                // Logic to send data to Laravel API
              },
              child: const Text("Submit Report", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _typeButton(String label, IconData icon, Color color) {
    bool isSelected = _selectedType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : const Color(0xFF1A1F1A),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : Colors.white38, size: 20),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
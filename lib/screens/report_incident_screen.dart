import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import '../services/location_service.dart';
import '../services/nexora_api_service.dart';
import 'map_screen.dart';

class ReportIncidentScreen extends StatefulWidget {
  final String? scannedImagePath;
  final String? snakeName;
  final String? snakeDescription;
  final double? confidenceScore;

  const ReportIncidentScreen({
    super.key,
    this.scannedImagePath,
    this.snakeName,
    this.snakeDescription,
    this.confidenceScore,
  });

  @override
  State<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends State<ReportIncidentScreen> {
  String _selectedType = 'Sighting'; // Sighting or Bite
  File? _image;
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoadingLocation = true;
  bool _isSubmitting = false;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _prefillData();
  }

  Future<void> _prefillData() async {
    // 1. Pre-fill image
    if (widget.scannedImagePath != null &&
        widget.scannedImagePath!.isNotEmpty) {
      if (mounted) {
        setState(() => _image = File(widget.scannedImagePath!));
      }
    }

    // 2. Pre-fill description
    final parts = <String>[];
    if (widget.snakeName != null && widget.snakeName!.isNotEmpty) {
      parts.add('Snake: ${widget.snakeName}');
    }
    if (widget.snakeDescription != null &&
        widget.snakeDescription!.isNotEmpty) {
      parts.add('Details: ${widget.snakeDescription}');
    }
    if (parts.isNotEmpty) {
      _descriptionController.text = parts.join('\n');
    }

    // 3. Auto-fill phone number from profile
    final profile = await NexoraApiService.getUserProfile();
    if (mounted && profile != null && profile['phone'] != null) {
      _phoneController.text = profile['phone'].toString();
    }
  }

  Future<void> _fetchLocation() async {
    final pos = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        if (pos != null) {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
        }
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _submitReport() async {
    if (_descriptionController.text.trim().isEmpty ||
        _currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please provide a description and wait for location to load.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Get a reversed geocoded address or just send coordinates as string if we don't have a package for it
    final locName =
        "Lat: ${_currentLocation!.latitude.toStringAsFixed(4)}, Lng: ${_currentLocation!.longitude.toStringAsFixed(4)}";

    final res = await NexoraApiService.submitIncident(
      type: _selectedType,
      description: _descriptionController.text.trim(),
      locationName: locName,
      lat: _currentLocation!.latitude,
      lng: _currentLocation!.longitude,
      imagePath: _image?.path,
      reporterPhone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
      snakeName: widget.snakeName,
      confidenceLevel: widget.confidenceScore,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      final rawId = res['incident_id'];
      final incidentId = rawId is int ? rawId : int.tryParse(rawId.toString());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Report submitted! Now select an enthusiast.'),
            backgroundColor: Color(0xFF00FF66)),
      );

      // Navigate to MapScreen to pick an enthusiast
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MapScreen(
            activeIncidentId: incidentId,
            incidentLat: _currentLocation!.latitude,
            incidentLng: _currentLocation!.longitude,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(res['message']?.toString() ?? 'Failed to submit report.'),
            backgroundColor: Colors.redAccent),
      );
    }
  }

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
        title: const Text("Report Incident",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. INCIDENT TYPE SELECTOR
            const Text("Type of Incident",
                style: TextStyle(color: Colors.white70, fontSize: 14)),
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
            const Text("Photo",
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white10, style: BorderStyle.solid),
                ),
                child: _image == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo,
                              color: Color(0xFF00FF66), size: 40),
                          SizedBox(height: 10),
                          Text("Tap to Add Photo",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text("Upload an image of the snake",
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(_image!, fit: BoxFit.cover)),
              ),
            ),
            const SizedBox(height: 30),

            const Text("Description",
                style: TextStyle(color: Colors.white70, fontSize: 14)),
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
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),

            // 4. CONTACT NUMBER FIELD
            const Text("Contact Number",
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter your contact number",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF1A1F1A),
                prefixIcon: const Icon(Icons.phone, color: Colors.white54),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),

            // 5. INCIDENT LOCATION (MAP PREVIEW)
            const Text("Incident Location",
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _isLoadingLocation
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF00FF66)))
                    : _currentLocation == null
                        ? const Center(
                            child: Text('Could not fetch location',
                                style: TextStyle(color: Colors.white38)))
                        : FlutterMap(
                            options: MapOptions(
                              initialCenter: _currentLocation!,
                              initialZoom: 15,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.nexora_app',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _currentLocation!,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Color(0xFF00FF66),
                                      size: 36,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 10),
            if (_currentLocation != null)
              Text(
                  "📍 ${_currentLocation!.latitude.toStringAsFixed(4)}, ${_currentLocation!.longitude.toStringAsFixed(4)} (GPS)",
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),

            const SizedBox(height: 40),

            // 6. SUBMIT BUTTON
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF66),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: _isSubmitting ? null : _submitReport,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("Submit Report",
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
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
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : const Color(0xFF1A1F1A),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
                color: isSelected ? color : Colors.transparent, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : Colors.white38, size: 20),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

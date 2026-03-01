import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'id_result_screen.dart';

/// PROFESSIONAL ENGLISH DOCUMENTATION
/// * FILE: scan_screen.dart
/// PURPOSE: A high-fidelity AI-driven camera interface for real-time snake identification.
/// * TECHNICAL IMPLEMENTATION:
/// 1. Image Sourcing: Supports instant camera capture and gallery uploads.
/// 2. API Integration: Transmits binary data to the Azure-hosted CNN endpoint using the 'image' field name.
/// 3. UI/UX Design: Implements a scanning frame overlay with animated 'Detecting' states as per project DNA.
/// 4. Localization: Adaptive labels for English, Sinhala, and Tamil users.

class ScanScreen extends StatefulWidget {
  final String lang;
  const ScanScreen({super.key, required this.lang});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  // --- LOCALIZED LABELS ---
  String _getTxt(String en, String si, String ta) {
    if (widget.lang == 'සිංහල') return si;
    if (widget.lang == 'தமிழ்') return ta;
    return en;
  }

  // --- CORE LOGIC: API COMMUNICATION ---
  Future<void> _processImage(File imageFile) async {
    setState(() => _isProcessing = true);

    try {
      String fileName = imageFile.path.split('/').last;

      // Creating Multi-part Form Data for Azure API
      FormData formData = FormData.fromMap({
        "image":
            await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });

      // Transmitting to Azure CNN Endpoint
      var response = await Dio().post(
        "https://snake-api-eshan123.azurewebsites.net/predict",
        data: formData,
      );

      setState(() => _isProcessing = false);

      if (response.statusCode == 200 && mounted) {
        // Successful inference: Navigate to ID Result Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IDResultScreen(
              snakeData: response.data,
              currentLang: widget.lang,
              confidenceScore:
                  (response.data['top_prediction']['confidence'] ?? 0.0)
                      .toDouble(),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError();
    }
  }

  Future<void> _capture(ImageSource source) async {
    final XFile? image =
        await _picker.pickImage(source: source, imageQuality: 85);
    if (image != null) {
      _processImage(File(image.path));
    }
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getTxt(
            "API connection error. Try again.",
            "සම්බන්ධතාවය අසාර්ථකයි. නැවත උත්සාහ කරන්න.",
            "இணைப்பு தோல்வியடைந்தது")),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. DUMMY CAMERA VIEW (Replace with CameraPreview if using camera package)
          const Center(
              child:
                  Icon(Icons.camera_rounded, color: Colors.white12, size: 100)),

          // 2. SCANNING OVERLAY UI (Matches Screenshot)
          _buildScanningOverlay(),

          // 3. TOP ACTION BAR
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.bolt, color: Colors.white),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text("CNN AI ACTIVE",
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
                ),
                const Icon(Icons.grid_view_rounded, color: Colors.white),
              ],
            ),
          ),

          // 4. DETECTION INDICATOR
          if (_isProcessing) _buildDetectionStatus(),

          // 5. BOTTOM CONTROLS
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text("PHOTO",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2)),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery Button
                    IconButton(
                      icon: const Icon(Icons.photo_library_outlined,
                          color: Colors.white, size: 30),
                      onPressed: () => _capture(ImageSource.gallery),
                    ),
                    // Main Capture Button
                    GestureDetector(
                      onTap: () => _capture(ImageSource.camera),
                      child: Container(
                        height: 80,
                        width: 80,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4)),
                        child: Container(
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle)),
                      ),
                    ),
                    // Switch Camera Button
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios_outlined,
                          color: Colors.white, size: 30),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Center(
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white30, width: 1),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Stack(
          children: [
            // Corners of the Scanner
            _corner(top: 0, left: 0, angle: 0),
            _corner(top: 0, right: 0, angle: 1.57),
            _corner(bottom: 0, left: 0, angle: -1.57),
            _corner(bottom: 0, right: 0, angle: 3.14),
          ],
        ),
      ),
    );
  }

  Widget _corner(
      {double? top,
      double? bottom,
      double? left,
      double? right,
      required double angle}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          height: 40,
          width: 40,
          decoration: const BoxDecoration(
            border: Border(
                top: BorderSide(color: Colors.white, width: 4),
                left: BorderSide(color: Colors.white, width: 4)),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(15)),
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionStatus() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 380),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00FF66))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFF00FF66))),
            const SizedBox(width: 12),
            Text(
              _getTxt("Detecting Species...", "විශේෂය හඳුනාගනිමින්...",
                  "இனங்களைக் கண்டறிதல்..."),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

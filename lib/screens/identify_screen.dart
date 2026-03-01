import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class IdentifyScreen extends StatelessWidget {
  const IdentifyScreen({super.key});

  Future<void> _pick(BuildContext context, ImageSource s) async {
    final img = await ImagePicker().pickImage(source: s);
    if (img != null) {
      // Navigate to Scan Animation Screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Identify Snake"), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Start Identification", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            _btn(context, "Capture Image", Icons.camera_alt, const Color(0xFF00FF66), Colors.black, () => _pick(context, ImageSource.camera)),
            _btn(context, "Upload Gallery", Icons.image, const Color(0xFF1A1F1A), Colors.white, () => _pick(context, ImageSource.gallery)),
            _btn(context, "Describe Details", Icons.description, const Color(0xFF1A1F1A), Colors.white70, () {}),
          ],
        ),
      ),
    );
  }

  Widget _btn(BuildContext context, String t, IconData i, Color bg, Color txt, VoidCallback tap) {
    return Container(
      width: double.infinity, height: 65, margin: const EdgeInsets.only(bottom: 15),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        onPressed: tap, icon: Icon(i, color: txt), label: Text(t, style: TextStyle(color: txt, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
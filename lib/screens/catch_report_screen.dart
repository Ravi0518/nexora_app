import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/nexora_api_service.dart';

class CatchReportScreen extends StatefulWidget {
  final String requestId;
  final String lang;

  const CatchReportScreen(
      {super.key, required this.requestId, this.lang = 'English'});

  @override
  State<CatchReportScreen> createState() => _CatchReportScreenState();
}

class _CatchReportScreenState extends State<CatchReportScreen> {
  String _selectedCondition = 'Alive & Healthy';
  File? _image;
  final _speciesController = TextEditingController();
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _conditions = [
    'Alive & Healthy',
    'Injured',
    'Deceased',
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _submitReport() async {
    if (_image == null || _speciesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please provide a photo and identify the species.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Using submitCatchReport which we'll add to NexoraApiService
    final res = await NexoraApiService.submitCatchReport(
      requestId: widget.requestId,
      species: _speciesController.text.trim(),
      condition: _selectedCondition,
      comments: _commentController.text.trim(),
      imagePath: _image!.path,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Catch report submitted!'),
            backgroundColor: Color(0xFF00FF66)),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(res['message'] ?? 'Failed to submit report.'),
            backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      appBar: AppBar(
        title: const Text("Capture Report",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF132A1C),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF00FF66)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                        'Submitting capture details for Incident #${widget.requestId}',
                        style: const TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // PHOTO UPLOAD
            const Text("Verified Capture Photo",
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F1B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: _image == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt,
                              color: Color(0xFF00FF66), size: 40),
                          SizedBox(height: 10),
                          Text("Take Photo",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(_image!, fit: BoxFit.cover)),
              ),
            ),
            const SizedBox(height: 30),

            // SPECIES
            const Text("Identified Species",
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: _speciesController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "e.g., Indian Cobra, Rat Snake",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF1A1F1B),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),

            // CONDITION
            const Text("Condition of Snake",
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: _conditions.map((c) {
                final isSelected = _selectedCondition == c;
                return ChoiceChip(
                  label: Text(c,
                      style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal)),
                  selected: isSelected,
                  selectedColor: const Color(0xFF00FF66),
                  backgroundColor: const Color(0xFF1A1F1B),
                  onSelected: (val) => setState(() => _selectedCondition = c),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),

            // COMMENTS
            const Text("Additional Comments",
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Location released, specific behaviors, etc...",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF1A1F1B),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 40),

            // SUBMIT BUTTON
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
                  : const Text("Submit Catch Report",
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

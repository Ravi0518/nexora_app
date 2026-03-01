import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/nexora_api_service.dart';

/// Content Contribution Screen — matches Screen 8 design.
/// Allows verified snake enthusiasts to submit educational articles or safety tips.
class ContentContributionScreen extends StatefulWidget {
  final String lang;
  const ContentContributionScreen({super.key, this.lang = 'English'});

  @override
  State<ContentContributionScreen> createState() =>
      _ContentContributionScreenState();
}

class _ContentContributionScreenState extends State<ContentContributionScreen> {
  String _type = 'article'; // 'article' or 'safety_tip'
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  File? _attachedMedia;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _attachedMedia = File(picked.path));
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _snack('Please enter a title.', Colors.orangeAccent);
      return;
    }
    if (_contentCtrl.text.trim().isEmpty) {
      _snack('Please enter content.', Colors.orangeAccent);
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await NexoraApiService.submitContent(
      type: _type,
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      mediaPath: _attachedMedia?.path,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      _snack('Submitted for admin review!', const Color(0xFF00FF66));
      _titleCtrl.clear();
      _contentCtrl.clear();
      setState(() => _attachedMedia = null);
    } else {
      _snack(result['message'] ?? 'Submission failed.', Colors.redAccent);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Content Contribution',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TYPE TOGGLE ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF131A14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _typeTab('Educational Article', 'article'),
                  _typeTab('Safety Tip', 'safety_tip'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── TITLE ────────────────────────────────────────────────
            _label('Title'),
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., The Diet of the Eastern Diamondback',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF131A14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            // ── CONTENT ──────────────────────────────────────────────
            _label('Article Content'),
            TextField(
              controller: _contentCtrl,
              maxLines: 8,
              style: const TextStyle(color: Colors.white, height: 1.5),
              decoration: InputDecoration(
                hintText: 'Write your article here...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF131A14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            // ── ATTACH MEDIA ─────────────────────────────────────────
            GestureDetector(
              onTap: _pickMedia,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      style: BorderStyle.solid),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        color: Colors.amber, size: 22),
                    const SizedBox(width: 10),
                    const Text('Attach Media (Photos, Videos)',
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),

            // Attached media preview
            if (_attachedMedia != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(_attachedMedia!,
                          width: 100, height: 100, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _attachedMedia = null),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: Colors.redAccent, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // ── NOTE ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Note: All submissions are reviewed by an administrator before publication.',
                style:
                    TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 28),

            // ── SUBMIT ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2E1F),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CircularProgressIndicator(
                        color: Color(0xFF00FF66), strokeWidth: 2)
                    : const Text('Submit for Review',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _typeTab(String label, String value) {
    final isActive = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1A4025) : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isActive ? const Color(0xFF00FF66) : Colors.white38,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13)),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }
}

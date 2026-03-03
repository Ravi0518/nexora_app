import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'id_result_screen.dart';

/// Scan Screen — Live camera viewfinder with AI identification.
class ScanScreen extends StatefulWidget {
  final String lang;
  const ScanScreen({super.key, required this.lang});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraReady = false;
  bool _isProcessing = false;
  int _selectedCameraIdx = 0;

  // ── HELPERS ──────────────────────────────────────────────────────────────────
  String _t(String en, String si, String ta) {
    if (widget.lang == 'සිංහල') return si;
    if (widget.lang == 'தமிழ்') return ta;
    return en;
  }

  // ── LIFECYCLE ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera(0);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      // Reset flag first so the preview stops trying to render the dying controller
      setState(() => _isCameraReady = false);
      _cameraController?.dispose();
      _cameraController = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(_selectedCameraIdx);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  // ── CAMERA INIT ───────────────────────────────────────────────────────────────
  Future<void> _initCamera(int cameraIdx) async {
    // Dispose any existing controller before creating a new one
    final oldController = _cameraController;
    if (oldController != null) {
      setState(() {
        _isCameraReady = false;
        _cameraController = null;
      });
      await oldController.dispose();
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      final controller = CameraController(
        _cameras[cameraIdx],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
        _selectedCameraIdx = cameraIdx;
      });
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  void _switchCamera() {
    if (_cameras.length < 2) return;
    final next = (_selectedCameraIdx + 1) % _cameras.length;
    _cameraController?.dispose();
    setState(() {
      _isCameraReady = false;
      _cameraController = null;
    });
    _initCamera(next);
  }

  // ── CAPTURE FROM CAMERA LIVE ─────────────────────────────────────────────────
  Future<void> _captureAndProcess() async {
    if (_isProcessing || _cameraController == null || !_isCameraReady) return;
    try {
      final XFile photo = await _cameraController!.takePicture();
      await _processImage(File(photo.path));
    } catch (e) {
      _showError(e.toString());
    }
  }

  // ── PICK FROM GALLERY ─────────────────────────────────────────────────────────
  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1080,
      maxHeight: 1080,
    );
    try {
      if (image != null) await _processImage(File(image.path));
    } catch (e) {
      _showError(e.toString());
    }
  }

  // ── API CALL ─────────────────────────────────────────────────────────────────
  Future<void> _processImage(File imageFile) async {
    setState(() => _isProcessing = true);
    try {
      final formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ));

      final response = await dio.post(
        "https://snake-api-eshan123.azurewebsites.net/predict",
        data: formData,
      );

      setState(() => _isProcessing = false);

      if (response.statusCode == 200 && mounted) {
        final data = response.data;
        if (data == null || data['top_prediction'] == null) {
          throw Exception("Invalid data format from AI API");
        }

        // The CNN API returns class_id inside predictions[0], not in top_prediction.
        // We use it to fetch the correct snake from the Laravel /api/snakes/{id}.
        int? snakeId;
        final predictions = data['predictions'];
        if (predictions is List && predictions.isNotEmpty) {
          final first = predictions[0];
          final rawId = first['class_id'];
          if (rawId != null) {
            snakeId = rawId is int ? rawId : int.tryParse(rawId.toString());
          }
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IDResultScreen(
              snakeData: data,
              currentLang: widget.lang,
              confidenceScore:
                  (data['top_prediction']['confidence'] ?? 0.0).toDouble(),
              snakeId: snakeId,
              imagePath: imageFile
                  .path, // Passed to ID result screen so it can be passed to Report Incident
            ),
          ),
        );
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("SCAN ERROR: $e");
      setState(() => _isProcessing = false);
      _showError(e.toString());
    }
  }

  void _showError(String er) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_t("API connection error. Try again.\n($er)",
          "සම්බන්ධතාවය අසාර්ථකයි.", "இணைப்பு தோல்வியடைந்தது")),
      backgroundColor: Colors.redAccent,
    ));
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. LIVE CAMERA PREVIEW (full screen) ────────────────────────────
          _buildCameraPreview(),

          // ── 2. DARK GRADIENT — top & bottom only; middle is clear ───────────
          _buildGradientOverlay(),

          // ── 3. TOP BAR ───────────────────────────────────────────────────────
          _buildTopBar(),

          // ── 4. SCAN FRAME ────────────────────────────────────────────────────
          _buildScanFrame(),

          // ── 5. PROCESSING INDICATOR ──────────────────────────────────────────
          if (_isProcessing) _buildProcessingOverlay(),

          // ── 6. BOTTOM CONTROLS ───────────────────────────────────────────────
          _buildBottomControls(),
        ],
      ),
    );
  }

  // ── 1. CAMERA PREVIEW ────────────────────────────────────────────────────────
  Widget _buildCameraPreview() {
    final controller = _cameraController;
    if (!_isCameraReady ||
        controller == null ||
        !controller.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                  color: Color(0xFF00FF66), strokeWidth: 2),
              SizedBox(height: 16),
              Text("Starting camera...",
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Guard: controller may have been disposed between the check above
        // and this builder callback executing.
        if (!controller.value.isInitialized) {
          return Container(color: Colors.black);
        }
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.previewSize!.height,
              height: controller.value.previewSize!.width,
              child: CameraPreview(controller),
            ),
          ),
        );
      },
    );
  }

  // ── 2. GRADIENT ──────────────────────────────────────────────────────────────
  Widget _buildGradientOverlay() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xCC000000), // dark top
            Color(0x00000000), // transparent middle — camera visible
            Color(0x00000000),
            Color(0xEE000000), // dark bottom for controls
          ],
          stops: [0.0, 0.25, 0.65, 1.0],
        ),
      ),
    );
  }

  // ── 3. TOP BAR ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back
          _iconBtn(
              Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),

          // CNN badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF00FF66).withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: Color(0xFF00FF66), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text("CNN AI ACTIVE",
                    style: TextStyle(
                        color: Color(0xFF00FF66),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2)),
              ],
            ),
          ),

          // Grid
          _iconBtn(Icons.grid_view_rounded, () {}),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );

  // ── 4. SCAN FRAME ────────────────────────────────────────────────────────────
  Widget _buildScanFrame() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 260,
            height: 260,
            child: Stack(
              children: [
                // Top-left corner
                Positioned(top: 0, left: 0, child: _corner(topLeft: true)),
                // Top-right corner
                Positioned(top: 0, right: 0, child: _corner(topRight: true)),
                // Bottom-left corner
                Positioned(
                    bottom: 0, left: 0, child: _corner(bottomLeft: true)),
                // Bottom-right corner
                Positioned(
                    bottom: 0, right: 0, child: _corner(bottomRight: true)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _t('Position the snake inside the frame', 'නාය රාමුව ඇතුළේ තබන්න',
                'பாம்பை சட்டத்தினுள் வைக்கவும்'),
            style: const TextStyle(color: Colors.white60, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _corner(
      {bool topLeft = false,
      bool topRight = false,
      bool bottomLeft = false,
      bool bottomRight = false}) {
    const color = Color(0xFF00FF66);
    const size = 30.0;
    const thick = 3.0;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          thickness: thick,
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }

  // ── 5. PROCESSING OVERLAY ────────────────────────────────────────────────────
  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF00FF66).withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF00FF66))),
              const SizedBox(width: 14),
              Text(
                _t("Analysing...", "විශ්ලේෂණය කරමින්...",
                    "பகுப்பாய்வு செய்கிறது..."),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 6. BOTTOM CONTROLS ───────────────────────────────────────────────────────
  Widget _buildBottomControls() {
    return Positioned(
      bottom: 36,
      left: 0,
      right: 0,
      child: Column(
        children: [
          // Mode pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _t("PHOTO", "ඡායාරූප", "புகைப்படம்"),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery
              _sideBtn(Icons.photo_library_outlined,
                  _t('Gallery', 'ගැලරිය', 'கேலரி'), _pickFromGallery),

              // Capture
              GestureDetector(
                onTap: _captureAndProcess,
                child: Container(
                  height: 80,
                  width: 80,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FF66).withValues(alpha: 0.35),
                        blurRadius: 22,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Color(0xFF07120B), size: 30),
                  ),
                ),
              ),

              // Switch camera
              _sideBtn(Icons.flip_camera_ios_outlined,
                  _t('Switch', 'මාරු', 'மாற்று'), _switchCamera),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sideBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white12,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 5),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      );
}

// ── CORNER PAINTER ───────────────────────────────────────────────────────────
class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool topLeft, topRight, bottomLeft, bottomRight;

  const _CornerPainter({
    required this.color,
    required this.thickness,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;

    if (topLeft) {
      canvas.drawLine(Offset.zero, Offset(w, 0), p);
      canvas.drawLine(Offset.zero, Offset(0, h), p);
    }
    if (topRight) {
      canvas.drawLine(Offset.zero, Offset(w, 0), p);
      canvas.drawLine(Offset(w, 0), Offset(w, h), p);
    }
    if (bottomLeft) {
      canvas.drawLine(Offset(0, h), Offset(w, h), p);
      canvas.drawLine(Offset(0, 0), Offset(0, h), p);
    }
    if (bottomRight) {
      canvas.drawLine(Offset(0, h), Offset(w, h), p);
      canvas.drawLine(Offset(w, 0), Offset(w, h), p);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

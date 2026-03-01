import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class IDResultScreen extends StatefulWidget {
  final Map<String, dynamic> snakeData;
  final String currentLang;
  final double confidenceScore;

  const IDResultScreen({
    super.key,
    required this.snakeData,
    required this.currentLang,
    required this.confidenceScore,
  });

  @override
  State<IDResultScreen> createState() => _IDResultScreenState();
}

class _IDResultScreenState extends State<IDResultScreen> {
  Map<String, dynamic>? _localDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSnakeDetails();
  }

  // --- LOGIC: Call Emergency 119 ---
  Future<void> _callEmergency() async {
    final Uri url = Uri.parse('tel:119');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint("Could not launch 119");
    }
  }

  Future<void> _loadSnakeDetails() async {
    try {
      String topSpecies = widget.snakeData['top_prediction']?['species'] ?? "";
      final String response = await DefaultAssetBundle.of(context).loadString('assets/data/snakes.json');
      final List<dynamic> data = json.decode(response);

      final match = data.firstWhere(
            (e) => e['id'].toString().toLowerCase() == topSpecies.toLowerCase().replaceAll(' ', '_'),
        orElse: () => null,
      );

      setState(() {
        _localDetails = match;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(backgroundColor: Color(0xFF07120B), body: Center(child: CircularProgressIndicator(color: Color(0xFF00FF66))));

    final bool isVenomous = _localDetails?['is_venomous'] ?? true;
    final String commonName = _localDetails?['names']?[widget.currentLang] ?? widget.snakeData['top_prediction']?['species'];
    final String scientificName = _localDetails?['scientific_name'] ?? "Species scientific name " ;

    // --- DYNAMIC IMAGE PATH ---
    // Uses the ID from JSON to find the image in your specific folder
    final String snakeId =_localDetails?['names']?[widget.currentLang] ?? widget.snakeData['top_prediction']?['species'];
    final String heroImagePath = 'assets/images/$snakeId.jpg';

    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      body: Stack(
        children: [
          _buildHeroImage(heroImagePath),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 180),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _badge(isVenomous ? "Venomous" : "Non-Venomous", isVenomous ? Colors.redAccent : Colors.blueAccent, Icons.warning_amber_rounded),
                            const SizedBox(width: 10),
                            _badge("${widget.confidenceScore.toStringAsFixed(0)}% Confidence", const Color(0xFF00FF66), Icons.check_circle),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Text(commonName, style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
                        Text(scientificName, style: const TextStyle(color: Colors.white38, fontSize: 16, fontStyle: FontStyle.italic)),

                        const SizedBox(height: 30),

                        _buildAccordion("About this Snake", _localDetails?['details']?[widget.currentLang]?['habitat'] ?? "Details not available."),
                        _buildAccordion("First Aid", _localDetails?['details']?[widget.currentLang]?['first_aid']?.join("\n• ") ?? "Call emergency immediately."),
                        _buildAccordion("Distribution Map", "Found mainly in dry and intermediate zones of Sri Lanka."),

                        const SizedBox(height: 30),

                        const Text("Compare with Stock Photos", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        _buildPhotoCarousel(snakeId),

                        const SizedBox(height: 40),

                        Row(
                          children: [
                            // --- TRY AGAIN: Returns to Scanner ---
                            Expanded(child: _actionBtn("Try Again", Colors.white10, Colors.white, () => Navigator.pop(context))),
                            const SizedBox(width: 15),
                            Expanded(child: _actionBtn("Report Sighting", Colors.white10, Colors.white, () { /* Report Logic */ })),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // --- REQUEST EXPERT: Navigate to your Expert List ---
                        _bigBtn("Request Expert Assistance", const Color(0xFF00FF66), Colors.black, Icons.headset_mic_outlined, () {
                          // Navigator.push(context, MaterialPageRoute(builder: (context) => const ExpertListScreen()));
                        }),

                        const SizedBox(height: 10),

                        // --- EMERGENCY CALL 119 ---
                        _bigBtn("EMERGENCY: Call 119", Colors.redAccent, Colors.white, Icons.phone, _callEmergency),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(top: 50, left: 20, child: CircleAvatar(backgroundColor: Colors.black45, child: IconButton(icon: const Icon(Icons.chevron_left, color: Colors.white), onPressed: () => Navigator.pop(context)))),
        ],
      ),
    );
  }

  // --- UI BUILDER METHODS ---

  Widget _buildHeroImage(String path) {
    return Container(
      height: 450,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(path),
          fit: BoxFit.cover,
          // If image doesn't exist, show logo as fallback
          onError: (exception, stackTrace) => const AssetImage('assets/images/logo.png'),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.2), const Color(0xFF07120B)],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.5))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAccordion(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF131A14), borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Text(content, style: const TextStyle(color: Colors.white70, height: 1.5)),
          )
        ],
      ),
    );
  }

  Widget _buildPhotoCarousel(String id) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, i) => Container(
          width: 120,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            image: DecorationImage(
              // You can name your gallery images as indian_cobra_1.jpg etc.
              image: AssetImage('assets/images/snakes/${id}_${i+1}.jpg'),
              fit: BoxFit.cover,
              onError: (e, s) => const AssetImage('assets/images/logo.png'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(String label, Color bg, Color txt, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15)),
        child: Center(child: Text(label, style: TextStyle(color: txt, fontWeight: FontWeight.bold))),
      ),
    );
  }

  Widget _bigBtn(String label, Color bg, Color txt, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 65,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: txt),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: txt, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
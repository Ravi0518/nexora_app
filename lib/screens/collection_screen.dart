import 'package:flutter/material.dart';
import 'dart:convert';
import 'id_result_screen.dart';

/// PROFESSIONAL ENGLISH DOCUMENTATION
/// * FILE: collection_screen.dart
/// PURPOSE: Provides an educational catalog of snake species found in Sri Lanka.
/// * TECHNICAL STEPS:
/// 1. Data Retrieval: Fetches localized species metadata from 'assets/data/snakes.json'.
/// 2. Navigation: Transitions to IDResultScreen by providing the required snake data,
/// language, and a default confidence score to satisfy the constructor.
/// 3. UI/UX: Implements a dark-themed list with venomous/non-venomous badges.
/// 4. Localization: Fully supports English, Sinhala, and Tamil labels.

class CollectionScreen extends StatefulWidget {
  final String lang;
  const CollectionScreen({super.key, required this.lang});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  List<dynamic> _allSnakes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSnakeData();
  }

  // --- PROFESSIONAL METHOD: Local Data Fetching ---
  Future<void> _fetchSnakeData() async {
    const String jsonPath = 'assets/data/snakes.json';
    try {
      final String response =
          await DefaultAssetBundle.of(context).loadString(jsonPath);
      final List<dynamic> data = json.decode(response);

      setState(() {
        _allSnakes = data;
        _isLoading = false;
      });
      debugPrint("Nexora: Successfully loaded ${_allSnakes.length} species.");
    } catch (e) {
      debugPrint("Nexora Error: Failed to load $jsonPath. $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // English: Setting labels based on current language for the UI header
    final String title = widget.lang == 'සිංහල'
        ? "සර්ප විශේෂ එකතුව"
        : (widget.lang == 'தமிழ்' ? "பாம்பு இனங்கள்" : "Snake Collection");

    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF66)))
          : _allSnakes.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: _allSnakes.length,
                  itemBuilder: (context, index) {
                    final snake = _allSnakes[index];
                    return _buildSnakeTile(snake);
                  },
                ),
    );
  }

  // --- UI COMPONENT: SNAKE LIST TILE ---
  Widget _buildSnakeTile(Map<String, dynamic> snake) {
    // English: Getting localized names
    final String name =
        snake['names']?[widget.lang] ?? snake['names']?['English'] ?? "Unknown";
    final bool isVenomous = snake['is_venomous'] ?? false;

    return GestureDetector(
      onTap: () {
        // FIX: Providing 'confidenceScore' as 100.0 since this is from the official collection
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IDResultScreen(
              snakeData: snake,
              currentLang: widget.lang,
              confidenceScore: 100.0, // Satisfies the required parameter
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF131A14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            // English: Species Image Placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                width: 80,
                height: 80,
                child: const Icon(Icons.image_not_supported_rounded,
                    color: Colors.white10),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  _buildVenomBadge(isVenomous),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildVenomBadge(bool isVenomous) {
    final Color color = isVenomous ? Colors.redAccent : const Color(0xFF00FF66);
    final String label = isVenomous
        ? (widget.lang == 'සිංහල' ? "විෂ සහිතයි" : "Venomous")
        : (widget.lang == 'සිංහල' ? "විෂ රහිතයි" : "Non-venomous");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(
        widget.lang == 'සිංහල' ? "දත්ත හමු නොවීය" : "No species found",
        style: const TextStyle(color: Colors.white38),
      ),
    );
  }
}

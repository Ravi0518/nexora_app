import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../services/nexora_api_service.dart';

class IDResultScreen extends StatefulWidget {
  final Map<String, dynamic> snakeData;
  final String currentLang;
  final double confidenceScore;

  /// Optional: pass the snake's numeric ID directly (e.g. from collection screen)
  /// to trigger GET /api/snakes/{id} immediately.
  final int? snakeId;

  const IDResultScreen({
    super.key,
    required this.snakeData,
    required this.currentLang,
    required this.confidenceScore,
    this.snakeId,
  });

  @override
  State<IDResultScreen> createState() => _IDResultScreenState();
}

class _IDResultScreenState extends State<IDResultScreen> {
  Map<String, dynamic>? _snake;
  bool _isLoading = true;
  int _currentImageIdx = 0;
  final PageController _pageController = PageController();

  // Maps app lang label → JSON lang key
  String get _langKey {
    if (widget.currentLang == 'සිංහල') return 'si';
    if (widget.currentLang == 'தமிழ்') return 'ta';
    return 'en';
  }

  // Safe getter for the current-language detail block
  Map<String, dynamic> get _detail {
    final details = _snake?['details'];
    if (details is Map) {
      return (details[_langKey] ?? details['en'] ?? {}) as Map<String, dynamic>;
    }
    return {};
  }

  // Helper: get translated string from a map field (e.g. names, danger_level)
  String _fromMap(dynamic field, {String fallback = ''}) {
    if (field is Map) {
      return (field[_langKey] ?? field['en'] ?? fallback).toString();
    }
    return field?.toString() ?? fallback;
  }

  @override
  void initState() {
    super.initState();
    _loadSnakeDetails();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _callEmergency() async {
    final uri = Uri.parse('tel:119');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── DATA LOADING ────────────────────────────────────────────────────────────
  Future<void> _loadSnakeDetails() async {
    // ── CASE A: Direct snake ID passed (e.g. from collection screen) ────────────
    if (widget.snakeId != null) {
      try {
        final result = await NexoraApiService.getSnakeById(widget.snakeId!);
        if (result != null && result.isNotEmpty) {
          setState(() {
            _snake = result;
            _isLoading = false;
          });
          return;
        }
      } catch (_) {}
    }

    // ── CASE B: snakeData is already a full snake object (has scientific_name at
    //          root level, not wrapped in top_prediction). Use it directly.
    if (widget.snakeData.containsKey('scientific_name') &&
        !widget.snakeData.containsKey('top_prediction')) {
      setState(() {
        _snake = widget.snakeData;
        _isLoading = false;
      });
      return;
    }

    // ── CASE C: CNN top_prediction flow ────────────────────────────────────
    final topPrediction = widget.snakeData['top_prediction'];
    final String topSpecies = topPrediction?['species']?.toString() ?? '';

    // 1. Use ID from CNN response if present
    final rawId = topPrediction?['id'];
    if (rawId != null) {
      final int? snakeId =
          rawId is int ? rawId : int.tryParse(rawId.toString());
      if (snakeId != null) {
        try {
          final result = await NexoraApiService.getSnakeById(snakeId);
          if (result != null && result.isNotEmpty) {
            setState(() {
              _snake = result;
              _isLoading = false;
            });
            return;
          }
        } catch (_) {}
      }
    }

    // 2. Fall back to name-based search via Web Admin API
    if (topSpecies.isNotEmpty) {
      try {
        final results = await NexoraApiService.getSnakes(search: topSpecies);
        if (results.isNotEmpty) {
          setState(() {
            _snake = results.first;
            _isLoading = false;
          });
          return;
        }
      } catch (_) {}
    }

    // 3. Fall back to local JSON (exact slug, then partial name match)
    try {
      final raw = await DefaultAssetBundle.of(context)
          .loadString('assets/data/snakes.json');
      final List<dynamic> list = json.decode(raw);

      dynamic match = list.firstWhere(
        (e) =>
            e['id'].toString().toLowerCase() ==
            topSpecies.toLowerCase().replaceAll(' ', '_'),
        orElse: () => null,
      );

      match ??= list.firstWhere(
        (e) {
          final names = e['names'] as Map? ?? {};
          return names.values.any((n) =>
              n.toString().toLowerCase().contains(topSpecies.toLowerCase()) ||
              topSpecies.toLowerCase().contains(n.toString().toLowerCase()));
        },
        orElse: () => null,
      );

      setState(() {
        _snake = match;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // ── URL FIX (Android emulator) ───────────────────────────────────────────────
  /// On the Android emulator, 127.0.0.1 resolves to the emulator's own loopback.
  /// Replace it with 10.0.2.2 which routes to the host machine (where Laravel runs).
  String _fixUrl(String url) =>
      url.replaceFirst('http://127.0.0.1', 'http://10.0.2.2');

  // ── IMAGE SOURCES ────────────────────────────────────────────────────────────
  /// Returns up to 3 image sources in order:
  /// 1. main_image (or API image_url)
  /// 2-3. stock_photos (up to 2)
  List<String> get _imageSources {
    final List<String> imgs = [];

    // Main image — rewrite host for emulator
    final main =
        _snake?['image_url']?.toString() ?? _snake?['main_image']?.toString();
    if (main != null && main.isNotEmpty) imgs.add(_fixUrl(main));

    // Stock photos (from API: image_urls[], or local JSON: stock_photos[])
    final stocks = _snake?['image_urls'] ?? _snake?['stock_photos'];
    if (stocks is List) {
      for (final s in stocks) {
        final src = s?.toString() ?? '';
        if (src.isNotEmpty) imgs.add(_fixUrl(src));
        if (imgs.length >= 3) break;
      }
    }

    // If nothing found, use local asset fallback
    if (imgs.isEmpty) {
      final speciesSlug = (_snake?['id'] ??
              widget.snakeData['top_prediction']?['species'] ??
              '')
          .toString()
          .replaceAll(' ', '_')
          .toLowerCase();
      if (speciesSlug.isNotEmpty) imgs.add('assets/images/$speciesSlug.jpg');
    }

    return imgs.take(3).toList();
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF07120B),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00FF66)),
        ),
      );
    }

    final bool isVenomous = () {
      final v = _snake?['is_venomous'];
      return v == true || v == 1 || v == 'true' || v == '1';
    }();

    final String commonName = _fromMap(_snake?['names'],
        fallback: widget.snakeData['top_prediction']?['species'] ?? 'Unknown');

    final String scientificName = (_snake?['scientific_name'] ?? '').toString();

    final String dangerLevel = _fromMap(_snake?['danger_level'], fallback: '');

    final String about = _detail['about']?.toString() ??
        _detail['habitat']?.toString() ??
        _snake?['description']?.toString() ??
        'Details not available.';

    final String habitat = _detail['habitat']?.toString() ??
        _snake?['habitat']?.toString() ??
        'Details not available.';

    final rawFirstAid = _detail['first_aid'] ?? _snake?['first_aid'];
    final String firstAid = rawFirstAid is List
        ? rawFirstAid.map((e) => '• $e').join('\n')
        : rawFirstAid?.toString() ?? 'Call emergency immediately.';

    final rawDonts = _detail['donts'];
    final String donts = rawDonts is List
        ? rawDonts.map((e) => '✗ $e').join('\n')
        : rawDonts?.toString() ?? '';

    final region = _snake?['region']?.toString();

    final images = _imageSources;

    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      body: Stack(children: [
        // ── IMAGE GALLERY (top hero) ──────────────────────────────────────────
        _buildImageGallery(images),

        // ── SCROLLABLE CONTENT ────────────────────────────────────────────────
        SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Space for image
                SizedBox(height: images.isEmpty ? 200 : 340),

                // ── DETAILS CARD ──────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF07120B),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges row
                        Row(children: [
                          _badge(
                            isVenomous
                                ? _localise(
                                    'Venomous', 'විෂ සහිතයි', 'நச்சுத்தன்மை')
                                : _localise(
                                    'Non-Venomous', 'විෂ රහිතයි', 'நச்சற்றது'),
                            isVenomous ? Colors.redAccent : Colors.blueAccent,
                            Icons.warning_amber_rounded,
                          ),
                          const SizedBox(width: 10),
                          _badge(
                            '${widget.confidenceScore.toStringAsFixed(0)}% '
                            '${_localise("Confidence", "විශ්වාසය", "நம்பகத்தன்மை")}',
                            const Color(0xFF00FF66),
                            Icons.check_circle,
                          ),
                        ]),

                        const SizedBox(height: 14),

                        // Common name
                        Text(commonName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                height: 1.2)),

                        // Scientific name
                        if (scientificName.isNotEmpty)
                          Text(scientificName,
                              style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic)),

                        // Danger level pill
                        if (dangerLevel.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isVenomous
                                  ? Colors.redAccent.withValues(alpha: 0.15)
                                  : Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isVenomous
                                    ? Colors.redAccent.withValues(alpha: 0.4)
                                    : Colors.green.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(dangerLevel,
                                style: TextStyle(
                                    color: isVenomous
                                        ? Colors.redAccent
                                        : Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],

                        // Image dots
                        if (images.length > 1) ...[
                          const SizedBox(height: 12),
                          _buildDotIndicator(images.length),
                        ],

                        const SizedBox(height: 22),

                        // ── ACCORDION SECTIONS ────────────────────────────────
                        _buildAccordion(
                          _localise(
                              'About this Snake', 'සර්පයා ගැන', 'பாம்பு பற்றி'),
                          about,
                          Icons.info_outline_rounded,
                        ),
                        _buildAccordion(
                          _localise('Habitat', 'වාසස්ථානය', 'வாழிடம்'),
                          habitat,
                          Icons.terrain_rounded,
                        ),
                        _buildAccordion(
                          _localise('First Aid', 'ප්‍රථමාධාර', 'முதலுதவி'),
                          firstAid,
                          Icons.health_and_safety_outlined,
                          accentColor: Colors.orangeAccent,
                        ),
                        if (donts.isNotEmpty)
                          _buildAccordion(
                            _localise(
                                "Do NOT", 'නොකළ යුතු දේ', 'செய்யக்கூடாதவை'),
                            donts,
                            Icons.cancel_outlined,
                            accentColor: Colors.redAccent,
                          ),
                        _buildAccordion(
                          _localise('Distribution', 'ව්‍යාප්තිය', 'பரம்பல்'),
                          region != null
                              ? _localise(
                                  'Found mainly in the $region zone of Sri Lanka.',
                                  '$region කලාපයේ ශ්‍රී ලංකාවේ ප්‍රධාන වශයෙන් දක්නට ලැබේ.',
                                  'இலங்கையின் $region மண்டலத்தில் காணப்படும்.')
                              : _localise(
                                  'Widespread in Sri Lanka.',
                                  'ශ්‍රී ලංකාව පුරා දක්නට ලැබේ.',
                                  'இலங்கை முழுவதும் காணப்படும்.'),
                          Icons.map_outlined,
                        ),

                        const SizedBox(height: 28),

                        // ── ACTION BUTTONS ────────────────────────────────────
                        Row(children: [
                          Expanded(
                            child: _actionBtn(
                              _localise('Go Back', 'ආපසු', 'திரும்பு'),
                              Colors.white12,
                              Colors.white,
                              () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _actionBtn(
                              _localise(
                                  'Report Sighting', 'වාර්තා කරන්න', 'அறிக்கை'),
                              Colors.white12,
                              Colors.white,
                              () {},
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),

                        _bigBtn(
                          _localise('Request Expert Assistance',
                              'විශේෂඥ සහාය ඉල්ලන්න', 'நிபுணர் உதவி கோர'),
                          const Color(0xFF00FF66),
                          Colors.black,
                          Icons.headset_mic_outlined,
                          () {},
                        ),
                        const SizedBox(height: 10),
                        _bigBtn(
                          _localise('EMERGENCY: Call 119', 'හදිසි: 119 අමතන්න',
                              'அவசரம்: 119 அழைக்கவும்'),
                          Colors.redAccent,
                          Colors.white,
                          Icons.phone,
                          _callEmergency,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── BACK BUTTON ───────────────────────────────────────────────────────
        Positioned(
          top: 50,
          left: 16,
          child: SafeArea(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── LANGUAGE HELPER ──────────────────────────────────────────────────────────
  String _localise(String en, String si, String ta) {
    if (widget.currentLang == 'සිංහල') return si;
    if (widget.currentLang == 'தமிழ்') return ta;
    return en;
  }

  // ── IMAGE GALLERY ────────────────────────────────────────────────────────────
  Widget _buildImageGallery(List<String> images) {
    if (images.isEmpty) {
      return Container(
        height: 380,
        color: const Color(0xFF0D2018),
        child: Center(
          child: Image.asset('assets/images/nexor.png',
              width: 120, opacity: const AlwaysStoppedAnimation(0.2)),
        ),
      );
    }

    return SizedBox(
      height: 380,
      child: Stack(children: [
        // PageView of images
        PageView.builder(
          controller: _pageController,
          onPageChanged: (i) => setState(() => _currentImageIdx = i),
          itemCount: images.length,
          itemBuilder: (_, i) => _buildSingleImage(images[i]),
        ),

        // Gradient over
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0xFF07120B)],
              stops: [0.55, 1.0],
            ),
          ),
        ),

        // Image counter badge
        if (images.length > 1)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentImageIdx + 1} / ${images.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _buildSingleImage(String src) {
    // Network URL
    if (src.startsWith('http')) {
      return Image.network(
        src,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                color: const Color(0xFF0D2018),
                child: const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF00FF66), strokeWidth: 2))),
      );
    }
    // Local asset
    return Image.asset(
      src,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => _imagePlaceholder(),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: const Color(0xFF0D2018),
        child: Center(
          child: Image.asset('assets/images/nexor.png',
              width: 90, opacity: const AlwaysStoppedAnimation(0.2)),
        ),
      );

  // ── DOT INDICATOR ────────────────────────────────────────────────────────────
  Widget _buildDotIndicator(int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(right: 6),
          width: i == _currentImageIdx ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: i == _currentImageIdx
                ? const Color(0xFF00FF66)
                : Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  // ── ACCORDION ────────────────────────────────────────────────────────────────
  Widget _buildAccordion(
    String title,
    String content,
    IconData icon, {
    Color accentColor = const Color(0xFF00FF66),
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: accentColor, size: 20),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 28, right: 4, bottom: 14),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        iconColor: Colors.white38,
        collapsedIconColor: Colors.white38,
        initiallyExpanded: title.contains('About') ||
            title.contains('ගැන') ||
            title.contains('பற்'),
        children: [
          Text(content,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  // ── BADGE ────────────────────────────────────────────────────────────────────
  Widget _badge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ]),
    );
  }

  // ── ACTION BUTTONS ────────────────────────────────────────────────────────────
  Widget _actionBtn(String label, Color bg, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: fg, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _bigBtn(
      String label, Color bg, Color fg, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  color: fg, fontWeight: FontWeight.bold, fontSize: 15)),
        ]),
      ),
    );
  }
}

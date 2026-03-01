import 'package:flutter/material.dart';
import '../services/language_service.dart';
import '../services/nexora_api_service.dart';
import 'id_result_screen.dart';

/// Collection Screen — matches Screen 10 design:
/// Filter chips (Venomous / Non-Venomous / By Region) + search bar + list from API.
class CollectionScreen extends StatefulWidget {
  final String lang;
  const CollectionScreen({super.key, required this.lang});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  List<Map<String, dynamic>> _allSnakes = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _activeFilter = 'All';
  final _searchController = TextEditingController();

  final List<String> _filters = [
    'All',
    'Venomous',
    'Non-Venomous',
    'By Region'
  ];
  final List<String> _regions = [
    'All',
    'Wet Zone',
    'Dry Zone',
    'North',
    'Central',
    'Hill Country'
  ];
  String _selectedRegion = 'All';

  String _t(String key) => LanguageService.t(widget.lang, key);

  @override
  void initState() {
    super.initState();
    _fetchSnakes();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSnakes() async {
    setState(() => _isLoading = true);
    bool? venomous;
    if (_activeFilter == 'Venomous') venomous = true;
    if (_activeFilter == 'Non-Venomous') venomous = false;

    final data = await NexoraApiService.getSnakes(
      venomous: venomous,
      region: _activeFilter == 'By Region' ? _selectedRegion : null,
      search: _searchController.text,
    );

    if (!mounted) return;
    setState(() {
      _allSnakes = data;
      _filtered = data;
      _isLoading = false;
    });
  }

  void _applyFilters() {
    final q = _searchController.text.toLowerCase();
    // Map the UI language label to the API language key (en/si/ta)
    String langKey;
    if (widget.lang == 'සිංහල') {
      langKey = 'si';
    } else if (widget.lang == 'தமிழ்') {
      langKey = 'ta';
    } else {
      langKey = 'en';
    }
    setState(() {
      _filtered = _allSnakes.where((s) {
        final namesMap = s['names'];
        final name =
            (namesMap is Map ? (namesMap[langKey] ?? namesMap['en'] ?? '') : '')
                .toString()
                .toLowerCase();
        final sci = (s['scientific_name'] ?? '').toLowerCase();
        return name.contains(q) || sci.contains(q);
      }).toList();
    });
  }

  void _setFilter(String filter) {
    setState(() {
      _activeFilter = filter;
      _searchController.clear();
    });
    _fetchSnakes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_t('my_collection'),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () => FocusScope.of(context).requestFocus(FocusNode()),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── SEARCH BAR ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search species...',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF131A14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── FILTER CHIPS ────────────────────────────────────────────
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: _filters.map((f) => _filterChip(f)).toList(),
            ),
          ),

          // ── REGION DROPDOWN (only when "By Region" selected) ────────
          if (_activeFilter == 'By Region')
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: DropdownButtonFormField<String>(
                value: _selectedRegion,
                dropdownColor: const Color(0xFF131A14),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF131A14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                items: _regions
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedRegion = v);
                  _fetchSnakes();
                },
              ),
            ),
          const SizedBox(height: 10),

          // ── RESULTS COUNT ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Text('${_filtered.length} species found',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),

          // ── SNAKE LIST ──────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00FF66)))
                : _filtered.isEmpty
                    ? Center(
                        child: Text(_t('no_collection'),
                            style: const TextStyle(color: Colors.white38),
                            textAlign: TextAlign.center))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 4),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) => _buildSnakeTile(_filtered[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final isActive = _activeFilter == label;
    return GestureDetector(
      onTap: () => _setFilter(label),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00FF66) : const Color(0xFF131A14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white60,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSnakeTile(Map<String, dynamic> snake) {
    // Resolve name using API lang key (en / si / ta)
    String name = 'Unknown';
    final namesRaw = snake['names'];
    if (namesRaw is Map) {
      String langKey;
      if (widget.lang == 'සිංහල') {
        langKey = 'si';
      } else if (widget.lang == 'தமிழ்') {
        langKey = 'ta';
      } else {
        langKey = 'en';
      }
      name = (namesRaw[langKey] ?? namesRaw['en'] ?? 'Unknown').toString();
    }
    final sci = snake['scientific_name']?.toString() ?? '';
    // is_venomous can come from API as bool or from JSON as String "true"/"false"
    final venomousRaw = snake['is_venomous'];
    final isVenomous =
        venomousRaw == true || venomousRaw == 'true' || venomousRaw == 1;
    final rawImageUrl = snake['image_url']?.toString();
    // Rewrite 127.0.0.1 → 10.0.2.2 for Android emulator compatibility
    final imageUrl = rawImageUrl != null
        ? rawImageUrl.replaceFirst('http://127.0.0.1', 'http://10.0.2.2')
        : null;

    return GestureDetector(
      onTap: () {
        final rawId = snake['id'];
        final int? snakeId =
            rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IDResultScreen(
              snakeData: snake,
              currentLang: widget.lang,
              confidenceScore: 100.0,
              snakeId: snakeId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF131A14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Row(
          children: [
            // Snake image
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(20)),
              child: SizedBox(
                width: 90,
                height: 90,
                child: imageUrl != null
                    ? Image.network(imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _snakePlaceholder())
                    : _snakePlaceholder(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text(sci,
                        style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 6),
                    _venomBadge(isVenomous),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Icon(Icons.chevron_right_rounded, color: Colors.white24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _snakePlaceholder() {
    return Container(
      color: const Color(0xFF0A140A),
      child: const Icon(Icons.pest_control_rounded,
          color: Colors.white10, size: 36),
    );
  }

  Widget _venomBadge(bool isVenomous) {
    final color = isVenomous ? Colors.redAccent : const Color(0xFF00FF66);
    final label = isVenomous
        ? LanguageService.t(widget.lang, 'venomous')
        : LanguageService.t(widget.lang, 'non_venomous');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label.toUpperCase(),
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5)),
    );
  }
}

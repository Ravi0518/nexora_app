import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/language_service.dart';
import '../services/nexora_api_service.dart';
import 'scan_screen.dart';
import 'collection_screen.dart';
import 'report_incident_screen.dart';
import 'emergency_screen.dart';
import 'nearby_rescuers_screen.dart';
import 'map_screen.dart';

/// User Home Screen — matches Screen 16 design:
/// Snake-eye hero card, My Collection & Report tiles, Did You Know fact card.
class UserHomeScreen extends StatefulWidget {
  final String lang;
  const UserHomeScreen({super.key, this.lang = 'English'});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  String _firstName = 'Explorer';
  String _userRole = 'General Public';
  Map<String, dynamic> _fact = {
    'fact':
        'The Inland Taipan has the most toxic venom of any snake in the world.',
    'image_url': null,
  };
  bool _factDismissed = false;
  List<Map<String, dynamic>> _recentIncidents = [];
  bool _isLoadingIncidents = true;

  String _t(String key) => LanguageService.t(widget.lang, key);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(UserHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rebuild when the parent passes a new language
    if (oldWidget.lang != widget.lang) {
      setState(() {});
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    // Try fetching fresh profile from API
    final profile = await NexoraApiService.getUserProfile();
    final fact = await NexoraApiService.getRandomFact();
    final incidents = await NexoraApiService.getMyIncidents();

    if (!mounted) return;
    setState(() {
      _firstName = profile?['fname'] ?? prefs.getString('fname') ?? 'Explorer';
      _userRole =
          profile?['role'] ?? prefs.getString('role') ?? 'General Public';
      _fact = fact;
      _recentIncidents = incidents;
      _isLoadingIncidents = false;
    });
  }

  Future<void> _callEmergency() async {
    final url = Uri(scheme: 'tel', path: '1990');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not open Maps: $e');
    }
  }

  Future<void> _callNumber(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch dialer: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // ── HEADER ─────────────────────────────────────────────────
              _buildHeader(),
              const SizedBox(height: 24),

              // ── IDENTIFY HERO CARD (Screen 16 style) ───────────────────
              _buildIdentifyCard(),
              const SizedBox(height: 16),

              // ── MY COLLECTION + REPORT INCIDENT (side by side) ─────────
              Row(
                children: [
                  Expanded(
                      child: _buildTileCard(
                    title: _t('my_collection'),
                    subtitle: _t('view_past_identifications'),
                    imagePath: null,
                    accent: const Color(0xFF1A2E1F),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                CollectionScreen(lang: widget.lang))),
                  )),
                  const SizedBox(width: 14),
                  Expanded(
                      child: _buildTileCard(
                    title: _t('report_incident'),
                    subtitle: _t('report_snake_subtitle'),
                    imagePath: null,
                    accent: const Color(0xFF1F1A0E),
                    isMap: true,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ReportIncidentScreen())),
                  )),
                ],
              ),
              const SizedBox(height: 16),

              // ── DID YOU KNOW CARD ───────────────────────────────────────
              if (!_factDismissed) _buildDidYouKnowCard(),
              if (!_factDismissed) const SizedBox(height: 16),

              // ── QUICK ACTIONS ───────────────────────────────────────────
              Text(_t('quick_services'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildQuickActions(),
              const SizedBox(height: 24),

              // ── RECENT REPORTS / IDENTIFICATIONS ──────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_t('Recent Reports'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {}, // Future expansion
                    child: const Text('See All',
                        style:
                            TextStyle(color: Color(0xFF00FF66), fontSize: 13)),
                  )
                ],
              ),
              const SizedBox(height: 12),
              _buildRecentIncidentsList(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ── WIDGETS ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF131A14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/nexor.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, $_firstName!',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(_userRole,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white54),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildIdentifyCard() {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ScanScreen(lang: widget.lang))),
      child: Container(
        width: double.infinity,
        height: 210,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: const Color(0xFF0D2018),
          image: const DecorationImage(
            image: AssetImage(
              'assets/images/Sri Lankan green vine snake.jpg',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Color(0xAA07120B), BlendMode.darken),
            onError: null,
          ),
        ),
        child: Stack(
          children: [
            // gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xDD07120B)],
                  stops: [0.3, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_t('identify_a_snake'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_t('scan_subtitle'),
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF66),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt,
                            color: Colors.black, size: 16),
                        const SizedBox(width: 5),
                        Text(_t('scan'),
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTileCard({
    required String title,
    required String subtitle,
    required String? imagePath,
    required Color accent,
    required VoidCallback onTap,
    bool isMap = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Stack(
          children: [
            // Icon background
            Positioned(
              right: -10,
              top: -10,
              child: Icon(
                isMap ? Icons.map_outlined : Icons.grid_view_rounded,
                size: 90,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isMap
                          ? Icons.add_location_alt_rounded
                          : Icons.collections_bookmark_rounded,
                      color:
                          isMap ? Colors.orangeAccent : const Color(0xFF00FF66),
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 10),
                      maxLines: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDidYouKnowCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131A14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_t('did_you_know'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 6),
                Text(_fact['fact'] ?? '',
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 13, height: 1.4)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setState(() => _factDismissed = true),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_t('dismiss'),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 80,
              height: 80,
              color: const Color(0xFF0A140A),
              child: const Icon(Icons.pest_control_rounded,
                  color: Color(0xFF00FF66), size: 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _Action(
          _t('emergency'),
          Icons.local_hospital_rounded,
          Colors.redAccent,
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => EmergencyScreen(lang: widget.lang)))),
      _Action(
          _t('experts'),
          Icons.people_alt_rounded,
          Colors.purpleAccent,
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NearbyRescuersScreen()))),
      _Action(
          _t('live_map'),
          Icons.map_rounded,
          Colors.tealAccent,
          () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const MapScreen()))),
      _Action(_t('call_1990'), Icons.phone_in_talk_rounded, Colors.greenAccent,
          _callEmergency),
    ];
    return Row(
      children: actions
          .map((a) => Expanded(
                child: GestureDetector(
                  onTap: a.onTap,
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131A14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Icon(a.icon, color: a.color, size: 22),
                        const SizedBox(height: 6),
                        Text(a.label,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 10),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildRecentIncidentsList() {
    if (_isLoadingIncidents) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Color(0xFF00FF66)),
        ),
      );
    }

    if (_recentIncidents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF131A14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: const Text(
          'No recent reports yet.',
          style: TextStyle(color: Colors.white54),
          textAlign: TextAlign.center,
        ),
      );
    }

    final displayList = _recentIncidents.take(5).toList();

    return Column(
      children: displayList.map((inc) {
        final title = inc['type']?.toString().toUpperCase() ?? 'REPORT';
        final subtitle = inc['location_name'] ?? 'Unknown location';
        final status = inc['status'] ?? 'pending';
        final hasEnthusiast = inc['assigned_enthusiast'] != null;

        Color statusColor;
        IconData statusIcon;
        switch (status.toString().toLowerCase()) {
          case 'resolved':
          case 'completed':
            statusColor = const Color(0xFF00FF66);
            statusIcon = Icons.check_circle_outline_rounded;
            break;
          case 'assigned':
            statusColor = Colors.orangeAccent;
            statusIcon = Icons.person_pin_circle_outlined;
            break;
          default:
            statusColor = Colors.white54;
            statusIcon = Icons.hourglass_empty_rounded;
        }

        return GestureDetector(
          onTap: () => _showIncidentDetails(inc),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF131A14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: hasEnthusiast
                      ? Colors.orangeAccent.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.05)),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              title: Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subtitle,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12)),
                  if (hasEnthusiast) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded,
                            color: Colors.orangeAccent, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          inc['assigned_enthusiast']['name'] ?? 'Enthusiast',
                          style: const TextStyle(
                              color: Colors.orangeAccent, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status.toString().toUpperCase(),
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded,
                      color: Colors.white24, size: 18),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showIncidentDetails(Map<String, dynamic> inc) {
    final String status = inc['status']?.toString() ?? 'open';
    final String rawLocationName = inc['location_name']?.toString() ?? '';
    final String type = inc['type']?.toString().toUpperCase() ?? 'REPORT';
    final String? snakeName = inc['snake_name']?.toString();
    final String? imgPath = inc['image_path']?.toString();
    final String? rawDescription = inc['description']?.toString();
    final String? reporterPhone = inc['reporter_phone']?.toString();
    final double? lat = double.tryParse(inc['lat']?.toString() ?? '');
    final double? lng = double.tryParse(inc['lng']?.toString() ?? '');
    final String reportedAt = inc['reported_at']?.toString().length != null &&
            inc['reported_at'].toString().length >= 10
        ? inc['reported_at'].toString().substring(0, 10)
        : '';

    // Detect if location_name is just raw coordinates (e.g. "Lat: 7.xxx, Lng: 80.xxx")
    final bool locationNameIsCoords = rawLocationName.isEmpty ||
        rawLocationName.toLowerCase().startsWith('lat:') ||
        RegExp(r'^-?\d+\.\d+\s*,\s*-?\d+\.\d+$')
            .hasMatch(rawLocationName.trim());
    final String locationLabel =
        locationNameIsCoords ? 'Incident Location' : rawLocationName;

    final String description =
        (rawDescription == null || rawDescription.trim().isEmpty)
            ? ''
            : rawDescription.trim();

    final Map<String, dynamic>? enthusiast = inc['assigned_enthusiast'] != null
        ? Map<String, dynamic>.from(inc['assigned_enthusiast'])
        : null;

    final String imageUrl = (imgPath != null && imgPath.isNotEmpty)
        ? '${NexoraApiService.baseUrl}/../storage/$imgPath'
        : '';

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'completed':
        statusColor = const Color(0xFF00FF66);
        break;
      case 'assigned':
        statusColor = Colors.orangeAccent;
        break;
      default:
        statusColor = Colors.white54;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0E1512),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 6),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                      children: [
                        // ── Header ─────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'My Report',
                                    style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12,
                                        letterSpacing: 1),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    snakeName ?? type,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (reportedAt.isNotEmpty)
                                    Text(
                                      'Reported on $reportedAt',
                                      style: const TextStyle(
                                          color: Colors.white38, fontSize: 11),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: statusColor.withValues(alpha: 0.5),
                                    width: 0.8),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // ── Image ───────────────────────
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  height: 190,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (_, child, progress) =>
                                      progress == null
                                          ? child
                                          : Container(
                                              height: 190,
                                              color: Colors.white10,
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Color(0xFF00FF66),
                                                ),
                                              ),
                                            ),
                                  errorBuilder: (_, __, ___) => _noImageBox(),
                                )
                              : _noImageBox(),
                        ),

                        const SizedBox(height: 18),

                        // ── Description ─────────────────
                        _label('Description'),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131A14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: description.isNotEmpty
                              ? Text(
                                  description,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      height: 1.6),
                                )
                              : Row(
                                  children: const [
                                    Icon(Icons.info_outline_rounded,
                                        color: Colors.white24, size: 16),
                                    SizedBox(width: 8),
                                    Text(
                                      'No description added for this report.',
                                      style: TextStyle(
                                          color: Colors.white38, fontSize: 13),
                                    ),
                                  ],
                                ),
                        ),

                        const SizedBox(height: 18),

                        // ── Location ────────────────────
                        _label('Location'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            if (lat != null && lng != null) {
                              _openGoogleMaps(lat, lng);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131A14),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.orangeAccent
                                      .withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    color: Colors.orangeAccent, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        locationLabel,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (lat != null && lng != null)
                                        Text(
                                          'Lat: ${lat.toStringAsFixed(5)}, Lng: ${lng.toStringAsFixed(5)}',
                                          style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 11),
                                        ),
                                    ],
                                  ),
                                ),
                                if (lat != null && lng != null)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.orangeAccent
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.open_in_new_rounded,
                                        color: Colors.orangeAccent, size: 16),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // ── Reporter Phone (if no enthusiast yet) ────────
                        if (reporterPhone != null &&
                            reporterPhone.isNotEmpty &&
                            enthusiast == null) ...[
                          const SizedBox(height: 18),
                          _label('Your Contact'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF131A14),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.phone_outlined,
                                    color: Colors.white54, size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  reporterPhone,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 22),

                        // ── Assigned Enthusiast ──────────
                        _label('Assigned Enthusiast'),
                        const SizedBox(height: 8),
                        enthusiast != null
                            ? _enthusiastCard(enthusiast)
                            : Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF131A14),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.person_off_outlined,
                                        color: Colors.white38, size: 22),
                                    SizedBox(width: 12),
                                    Text(
                                      'No enthusiast assigned yet',
                                      style: TextStyle(
                                          color: Colors.white38, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),

                        const SizedBox(height: 28),

                        // ── Close ───────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(sheetCtx),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                    color: Colors.white24, width: 1),
                              ),
                            ),
                            child: const Text('Close',
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _enthusiastCard(Map<String, dynamic> ent) {
    final String name = ent['name']?.toString() ?? 'Unknown';
    final String? phone = ent['phone']?.toString();
    final bool isAccepted = ent['is_accepted'] == true;
    final double? eLat = double.tryParse(ent['lat']?.toString() ?? '');
    final double? eLng = double.tryParse(ent['lng']?.toString() ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isAccepted
                ? const Color(0xFF00FF66).withValues(alpha: 0.4)
                : Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    color: Colors.white70, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          isAccepted
                              ? Icons.check_circle_rounded
                              : Icons.schedule_rounded,
                          color: isAccepted
                              ? const Color(0xFF00FF66)
                              : Colors.orangeAccent,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAccepted ? 'Accepted' : 'Pending Acceptance',
                          style: TextStyle(
                              color: isAccepted
                                  ? const Color(0xFF00FF66)
                                  : Colors.orangeAccent,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 14),

          // Contact row
          if (phone != null && phone.isNotEmpty)
            GestureDetector(
              onTap: () => _callNumber(phone),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF66).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone_in_talk_rounded,
                        color: Color(0xFF00FF66), size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Contact',
                            style:
                                TextStyle(color: Colors.white38, fontSize: 10)),
                        Text(
                          phone,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF66).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color:
                              const Color(0xFF00FF66).withValues(alpha: 0.4)),
                    ),
                    child: const Text('Call',
                        style: TextStyle(
                            color: Color(0xFF00FF66),
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ],
              ),
            )
          else
            const Text('No contact number available',
                style: TextStyle(color: Colors.white38, fontSize: 13)),

          // Location row
          if (eLat != null && eLng != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _openGoogleMaps(eLat, eLng),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.my_location_rounded,
                        color: Colors.orangeAccent, size: 16),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'View Enthusiast Location',
                      style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(Icons.open_in_new_rounded,
                      color: Colors.orangeAccent, size: 16),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _noImageBox() {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_rounded,
              color: Colors.white38, size: 44),
          SizedBox(height: 8),
          Text('No image available',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
} // end _UserHomeScreenState

class _Action {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Action(this.label, this.icon, this.color, this.onTap);
}

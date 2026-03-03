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
    final url = Uri.parse('tel:1990');
    if (await canLaunchUrl(url)) await launchUrl(url);
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

    // Show up to 3 recent incidents
    final displayList = _recentIncidents.take(3).toList();

    return Column(
      children: displayList.map((inc) {
        final title = inc['type'] ?? 'Report';
        final subtitle = inc['location_name'] ?? 'Unknown location';
        final status = inc['status'] ?? 'pending';
        Color statusColor;
        switch (status.toString().toLowerCase()) {
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

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF131A14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.history_rounded,
                  color: Colors.white54, size: 20),
            ),
            title: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            subtitle: Text(subtitle,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.toString().toUpperCase(),
                style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Action {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Action(this.label, this.icon, this.color, this.onTap);
}

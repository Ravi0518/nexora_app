import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/nexora_api_service.dart';

/// The active requests tab for Enthusiasts.
class EnthusiastRequestsTab extends StatefulWidget {
  final String lang;

  const EnthusiastRequestsTab({super.key, required this.lang});

  @override
  State<EnthusiastRequestsTab> createState() => _EnthusiastRequestsTabState();
}

class _EnthusiastRequestsTabState extends State<EnthusiastRequestsTab> {
  List<Map<String, dynamic>> _requests = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isResponding = false;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final data = await NexoraApiService.getExpertRequests();
    if (!mounted) return;
    setState(() {
      _requests = data;
      _isLoading = false;
    });
  }

  Future<void> _openMap(double lat, double lng) async {
    final url =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _respond(bool accept) async {
    if (_requests.isEmpty) return;
    final req = _requests[_currentIndex];
    setState(() => _isResponding = true);

    final ok =
        await NexoraApiService.respondToRequest(req['id'].toString(), accept);

    if (!mounted) return;
    setState(() => _isResponding = false);

    if (accept && ok) {
      final lat = req['lat'] as double?;
      final lng = req['lng'] as double?;
      if (lat != null && lng != null) _openMap(lat, lng);
      // Here we could also push to CatchReportScreen when it's built
    }

    // Remove handled request
    setState(() {
      _requests.removeAt(_currentIndex);
      if (_currentIndex >= _requests.length && _currentIndex > 0) {
        _currentIndex = _requests.length - 1;
      }
    });
  }

  String _tl(String en, String si, String ta) {
    if (widget.lang == 'සිංහල') return si;
    if (widget.lang == 'தமிழ்') return ta;
    return en;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF00FF66)));
    }

    if (_requests.isEmpty) {
      return _buildEmptyState();
    }

    return _buildRequestCard(_requests[_currentIndex]);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: Color(0xFF00FF66), size: 64),
          const SizedBox(height: 20),
          const Text('No Pending Requests',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('You\'re all caught up!',
              style: TextStyle(color: Colors.white38)),
          const SizedBox(height: 30),
          TextButton(
            onPressed: _loadRequests,
            child: const Text('Refresh',
                style: TextStyle(color: Color(0xFF00FF66))),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final requests = _requests;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Request count indicator
          if (requests.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Text('${_currentIndex + 1} of ${requests.length} requests',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 13)),
                  const Spacer(),
                  Row(
                    children: List.generate(
                      requests.length,
                      (i) => Container(
                        width: i == _currentIndex ? 20 : 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: i == _currentIndex
                              ? const Color(0xFF00FF66)
                              : Colors.white12,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Text(
              _tl('New Assistance Request', 'නව සහාය ඉල්ලීම',
                  'புதிய உதவி கோரிக்கை'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF131A14),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Map Preview
                if (req['lat'] != null && req['lng'] != null)
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(28)),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(
                            double.tryParse(req['lat'].toString()) ?? 0.0,
                            double.tryParse(req['lng'].toString()) ?? 0.0,
                          ),
                          initialZoom: 15,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.nexora_app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(
                                  double.tryParse(req['lat'].toString()) ?? 0.0,
                                  double.tryParse(req['lng'].toString()) ?? 0.0,
                                ),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.redAccent,
                                  size: 36,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Snake / incident image
                if (req['image_url'] != null)
                  Image.network(
                    req['image_url'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                else
                  _imagePlaceholder(),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location + time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _infoBadge(Icons.location_on_outlined,
                              '${req['distance_km'] ?? '?'} km away'),
                          _infoBadge(Icons.access_time_rounded,
                              req['reported_at'] ?? 'Unknown time'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(req['location_name'] ?? '',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 16),

                      Text(
                          _tl("User's Description", "යූසර්ගේ විස්තරය",
                              "பயனர் விளக்கம்"),
                          style: const TextStyle(
                              color: Color(0xFF00FF66),
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(req['description'] ?? '',
                          style: const TextStyle(
                              color: Colors.white70, height: 1.5)),
                      const SizedBox(height: 24),

                      // Accept / Reject buttons
                      Row(
                        children: [
                          Expanded(
                            child: _btn(
                              _tl('Reject', 'ප්‍රතික්ෂේප කරන්න', 'நிராகரி'),
                              Colors.white10,
                              Colors.white60,
                              _isResponding ? null : () => _respond(false),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _btn(
                              _tl('Accept', 'පිළිගන්න', 'ஏற்று'),
                              const Color(0xFF00FF66),
                              Colors.black,
                              _isResponding ? null : () => _respond(true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigate between requests
          if (requests.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _currentIndex > 0
                        ? () => setState(() => _currentIndex--)
                        : null,
                    child: const Text('← Prev',
                        style: TextStyle(color: Colors.white38)),
                  ),
                  const SizedBox(width: 20),
                  TextButton(
                    onPressed: _currentIndex < requests.length - 1
                        ? () => setState(() => _currentIndex++)
                        : null,
                    child: const Text('Next →',
                        style: TextStyle(color: Colors.white38)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 240,
      color: const Color(0xFF0A140A),
      child: const Center(
        child:
            Icon(Icons.pest_control_rounded, color: Colors.white10, size: 60),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white38),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }

  Widget _btn(String label, Color bg, Color txtColor, VoidCallback? onTap) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: onTap,
        child: Text(label,
            style: TextStyle(color: txtColor, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

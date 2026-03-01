import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/nexora_api_service.dart';

/// Nearby Rescuers Screen — matches Screen 11 design.
/// Loads expert data from API with fallback.
class NearbyRescuersScreen extends StatefulWidget {
  const NearbyRescuersScreen({super.key});

  @override
  State<NearbyRescuersScreen> createState() => _NearbyRescuersScreenState();
}

class _NearbyRescuersScreenState extends State<NearbyRescuersScreen> {
  List<Map<String, dynamic>> _experts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExperts();
  }

  Future<void> _loadExperts() async {
    final data = await NexoraApiService.getExperts();
    if (!mounted) return;
    setState(() {
      _experts = data;
      _isLoading = false;
    });
  }

  Future<void> _callNumber(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Request Assistance',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // ── SAFETY NOTICE ───────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orangeAccent, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Important: Do not approach the snake. Maintain a safe distance.',
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // ── HEADER COUNT ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Experts Near You',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('${_experts.length} Found',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── EXPERTS LIST ────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00FF66)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _experts.length,
                    itemBuilder: (ctx, i) => _buildExpertCard(_experts[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertCard(Map<String, dynamic> expert) {
    final isAvailable = expert['status'] == 'available';
    final statusText = isAvailable ? 'Available Now' : 'Responds in 15 mins';
    final statusColor =
        isAvailable ? const Color(0xFF00FF66) : Colors.orangeAccent;
    final distKm = expert['distance_km']?.toString() ?? '?';
    final phone = expert['phone'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131A14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF0A140A),
            backgroundImage: expert['profile_image_url'] != null
                ? NetworkImage(expert['profile_image_url']) as ImageProvider
                : null,
            child: expert['profile_image_url'] == null
                ? const Icon(Icons.person, color: Color(0xFF00FF66))
                : null,
          ),
          const SizedBox(width: 14),

          // Name + role + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expert['name'] ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                Text(expert['role'] ?? '',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(statusText,
                        style: TextStyle(color: statusColor, fontSize: 11)),
                    const Text(' • ', style: TextStyle(color: Colors.white24)),
                    Text('$distKm km away',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          _circleBtn(Icons.chat_bubble_outline_rounded, const Color(0xFF1A331A),
              const Color(0xFF00FF66), isAvailable, () {}),
          const SizedBox(width: 8),
          _circleBtn(
              Icons.phone_rounded,
              isAvailable ? const Color(0xFF00FF66) : const Color(0xFF1A1F1A),
              isAvailable ? Colors.black : Colors.white38,
              true,
              phone.isNotEmpty ? () => _callNumber(phone) : null),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, Color bg, Color iconCol, bool enabled,
      VoidCallback? onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: iconCol, size: 18),
      ),
    );
  }
}

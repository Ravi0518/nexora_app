import 'package:flutter/material.dart';
import '../services/nexora_api_service.dart';

/// Nearby Rescuers Screen — shown after submitting an incident.
/// Loads nearby enthusiasts from GET /api/experts/nearby and lets the user
/// assign the incident to one via POST /api/incidents/{id}/assign.
class NearbyRescuersScreen extends StatefulWidget {
  /// The ID of the incident that was just submitted (null = browse-only mode).
  final int? incidentId;

  /// Coordinates used to query nearby enthusiasts.
  final double? lat;
  final double? lng;

  const NearbyRescuersScreen({
    super.key,
    this.incidentId,
    this.lat,
    this.lng,
  });

  @override
  State<NearbyRescuersScreen> createState() => _NearbyRescuersScreenState();
}

class _NearbyRescuersScreenState extends State<NearbyRescuersScreen> {
  List<Map<String, dynamic>> _experts = [];
  bool _isLoading = true;
  int? _assigningId; // user_id of enthusiast being assigned to

  @override
  void initState() {
    super.initState();
    _loadExperts();
  }

  Future<void> _loadExperts() async {
    setState(() => _isLoading = true);
    final data = await NexoraApiService.getExperts(
      lat: widget.lat,
      lng: widget.lng,
    );
    if (!mounted) return;
    setState(() {
      _experts = data;
      _isLoading = false;
    });
  }

  Future<void> _assign(Map<String, dynamic> expert) async {
    final incidentId = widget.incidentId;
    if (incidentId == null) return;

    final userId = expert['user_id'] as int?;
    if (userId == null) return;

    setState(() => _assigningId = userId);

    final res = await NexoraApiService.assignIncident(
      incidentId: incidentId,
      enthusiastId: userId,
    );

    if (!mounted) return;
    setState(() => _assigningId = null);

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Enthusiast assigned!'),
          backgroundColor: const Color(0xFF00FF66),
        ),
      );
      // Pop back to home after successful assignment
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Failed to assign.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.incidentId != null
              ? 'Request Enthusiast Help'
              : 'Nearby Enthusiasts',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            onPressed: _loadExperts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── SAFETY NOTICE ─────────────────────────────────────────────
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
                    'Do not approach the snake. Select a nearby enthusiast to request help.',
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // ── HEADER COUNT ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Enthusiasts Near You',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_experts.length} Found',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── EXPERTS LIST ──────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00FF66)))
                : _experts.isEmpty
                    ? _buildEmptyState()
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, color: Colors.white24, size: 54),
          const SizedBox(height: 16),
          const Text('No enthusiasts nearby',
              style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Try again later or contact emergency services.',
              style: TextStyle(color: Colors.white24, fontSize: 12)),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _loadExperts,
            child:
                const Text('Retry', style: TextStyle(color: Color(0xFF00FF66))),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertCard(Map<String, dynamic> expert) {
    // API shape: { user_id, fname, lname, distance }
    final userId = expert['user_id'];
    final name = '${expert['fname'] ?? ''} ${expert['lname'] ?? ''}'.trim();
    final distKm = expert['distance'] ?? expert['distance_km'];
    final distKmVal =
        distKm != null ? double.tryParse(distKm.toString()) : null;
    final distStr = distKmVal != null
        ? '${distKmVal.toStringAsFixed(2)} km away'
        : '? km away';

    final isAssigning = _assigningId == userId;
    final canAssign = widget.incidentId != null && userId != null;

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
            radius: 26,
            backgroundColor: const Color(0xFF0A140A),
            backgroundImage: expert['profile_image_url'] != null
                ? NetworkImage(expert['profile_image_url']) as ImageProvider
                : null,
            child: expert['profile_image_url'] == null
                ? const Icon(Icons.person, color: Color(0xFF00FF66))
                : null,
          ),
          const SizedBox(width: 14),

          // Name + distance
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Enthusiast',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: Color(0xFF00FF66)),
                    const SizedBox(width: 4),
                    Text(distStr,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          // Request Help button (only when incidentId is set)
          if (canAssign)
            isAssigning
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Color(0xFF00FF66), strokeWidth: 2))
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF66),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () => _assign(expert),
                    child: const Text('Request',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
        ],
      ),
    );
  }
}

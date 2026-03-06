import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'map_screen.dart';
import '../services/nexora_api_service.dart';
import '../services/location_service.dart';

class EnthusiastDashboardTab extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EnthusiastDashboardTab({super.key, required this.userData});

  @override
  State<EnthusiastDashboardTab> createState() => _EnthusiastDashboardTabState();
}

class _EnthusiastDashboardTabState extends State<EnthusiastDashboardTab> {
  bool _isLoading = true;
  bool _isAvailable = false;
  List<Map<String, dynamic>> _activeRequests = [];
  List<Map<String, dynamic>> _catchReports = [];
  BuildContext? _ctx; // stable context for dialogs

  @override
  void initState() {
    super.initState();
    // Assuming userData might contain initial 'is_available' flag
    _isAvailable = widget.userData['is_available'] == 1 ||
        widget.userData['is_available'] == true;
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final requests = await NexoraApiService.getExpertRequests();
      final reports = await NexoraApiService.getExpertCatchReports();

      if (mounted) {
        setState(() {
          _activeRequests = requests;
          _catchReports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    // Push GPS + availability in  Future<void> _toggleAvailability(bool value) async {
    bool success = false;
    bool hasLocation = false;
    String errorMsg = 'Failed to update status';

    try {
      final pos = await LocationService.getCurrentLocation();
      if (pos != null) {
        hasLocation = true;
        final result = await NexoraApiService.updateExpertLocationWithStatus(
          pos.latitude,
          pos.longitude,
          isAvailable: value,
        );
        success = result['success'] == true;
        if (!success) {
          errorMsg = '[${result['statusCode']}] ${result['message']}';
        }
      } else {
        // No GPS — status only
        success = await NexoraApiService.updateExpertStatus(value);
      }
    } catch (e) {
      errorMsg = e.toString();
      success = await NexoraApiService.updateExpertStatus(value);
    }

    if (!mounted) return;

    if (success) {
      setState(() => _isAvailable = value);
      if (value && !hasLocation) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠️ You are online but your location could not be shared. '
              'Please enable GPS and toggle again.',
            ),
            backgroundColor: Colors.orangeAccent,
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(value ? 'You are now online 📍' : 'You are now offline'),
            backgroundColor:
                value ? const Color(0xFF00FF66) : Colors.orangeAccent,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Show actual server error so we can debug
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _ctx = context; // store for safe dialog usage
    final String name =
        widget.userData['full_name'] ?? widget.userData['fname'] ?? 'Expert';

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: const Color(0xFF00FF66),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            // Header & Availability Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back,',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    CupertinoSwitch(
                      value: _isAvailable,
                      activeColor: const Color(0xFF00FF66),
                      onChanged: _toggleAvailability,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isAvailable ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: _isAvailable
                            ? const Color(0xFF00FF66)
                            : Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Quick Stats
            Row(
              children: [
                _statCard('Total Rescues', _catchReports.length.toString(),
                    Icons.verified_user_outlined, const Color(0xFF00FF66)),
                const SizedBox(width: 15),
                _statCard('Active Jobs', _activeRequests.length.toString(),
                    Icons.notifications_active_outlined, Colors.orangeAccent),
              ],
            ),

            const SizedBox(height: 30),

            // Assigned Jobs Section
            _buildSectionHeader('Assigned Jobs', Icons.assignment_late_outlined,
                Colors.orangeAccent),
            const SizedBox(height: 15),
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00FF66)))
                : _activeRequests.isEmpty
                    ? _buildEmptyState('No active jobs at the moment.')
                    : _buildAssignedJobsList(),

            const SizedBox(height: 30),

            // Recent Snake Catches
            _buildSectionHeader('Recent Catches', Icons.history_rounded,
                const Color(0xFF00FF66)),
            const SizedBox(height: 15),
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00FF66)))
                : _catchReports.isEmpty
                    ? _buildEmptyState('No recent catches recorded.')
                    : _buildCatchReportsList(),

            const SizedBox(height: 30),

            // Action Hint / Live Map Access
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF132A1C),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF66).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.map_outlined,
                          color: Color(0xFF00FF66)),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Live Map & Dispatch',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          SizedBox(height: 4),
                          Text(
                              'View all incidents and fellow enthusiasts on the map. You will be notified of nearby emergencies.',
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131A14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
      ),
    );
  }

  Future<void> _openGoogleMaps(double lat, double lng, String label) async {
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not open Google Maps: $e');
    }
  }

  Future<void> _callReporter(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch dialer: $e');
    }
  }

  void _showJobDetails(BuildContext context, Map<String, dynamic> incident) {
    final imgPath = incident['image_path'];
    final reporterPhone = incident['reporter_phone']?.toString() ?? '';
    final locationName = incident['location_name'] ?? 'Unknown Location';
    final description = incident['description'] ?? 'No details provided.';
    final lat = double.tryParse(incident['lat']?.toString() ?? '');
    final lng = double.tryParse(incident['lng']?.toString() ?? '');
    final incidentType = incident['incident_type']?.toString() ?? '';

    final String imageUrl = imgPath != null
        ? '${NexoraApiService.baseUrl}/../storage/$imgPath'
        : '';

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
                  // --- drag handle ---
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
                        // ── Header ──────────────────────────────────────
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    Colors.orangeAccent.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.assignment_late_outlined,
                                  color: Colors.orangeAccent, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Assigned Job Request',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (incidentType.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: incidentType.toLowerCase() == 'bite'
                                      ? Colors.red.withValues(alpha: 0.2)
                                      : Colors.orangeAccent
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: incidentType.toLowerCase() == 'bite'
                                        ? Colors.redAccent
                                        : Colors.orangeAccent,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  incidentType.toUpperCase(),
                                  style: TextStyle(
                                    color: incidentType.toLowerCase() == 'bite'
                                        ? Colors.redAccent
                                        : Colors.orangeAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // ── Image ────────────────────────────────────────
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (_, child, progress) =>
                                      progress == null
                                          ? child
                                          : Container(
                                              height: 200,
                                              color: Colors.white10,
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Color(0xFF00FF66),
                                                ),
                                              ),
                                            ),
                                  errorBuilder: (_, __, ___) =>
                                      _noImagePlaceholder(),
                                )
                              : _noImagePlaceholder(),
                        ),

                        const SizedBox(height: 20),

                        // ── Location ─────────────────────────────────────
                        _sectionLabel('Location'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            if (lat != null && lng != null) {
                              _openGoogleMaps(lat, lng, locationName);
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
                                        locationName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (lat != null && lng != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                                          style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 11),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.open_in_new_rounded,
                                    color: Colors.orangeAccent,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ── Description ───────────────────────────────────
                        _sectionLabel('Description'),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131A14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Text(
                            description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ── Contact Details ───────────────────────────────
                        if (reporterPhone.isNotEmpty) ...[
                          _sectionLabel('Contact Details'),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _callReporter(reporterPhone),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF131A14),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: const Color(0xFF00FF66)
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00FF66)
                                          .withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        Icons.phone_in_talk_rounded,
                                        color: Color(0xFF00FF66),
                                        size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Reporter Phone',
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 11),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          reporterPhone,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00FF66)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: const Color(0xFF00FF66)
                                              .withValues(alpha: 0.4)),
                                    ),
                                    child: const Text(
                                      'Call',
                                      style: TextStyle(
                                          color: Color(0xFF00FF66),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                        ] else ...[
                          const SizedBox(height: 28),
                        ],

                        // ── Accept Button ─────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(sheetCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Job accepted! On your way.'),
                                  backgroundColor: Color(0xFF00FF66),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.check_circle_outline_rounded,
                                size: 20),
                            label: const Text(
                              'Accept Job',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00FF66),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // ── Decline / Close ───────────────────────────────
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
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500),
                            ),
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

  Widget _noImagePlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_rounded,
              color: Colors.white38, size: 48),
          SizedBox(height: 8),
          Text('No image available',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildAssignedJobsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _activeRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final job = _activeRequests[index];
        final incident = job['incident'] ?? job; // Fallback for diff shapes

        return GestureDetector(
          onTap: () => _showJobDetails(_ctx ?? context, incident),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF131A14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orangeAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: Colors.orangeAccent, size: 20),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incident['location_name'] ?? 'Unknown Location',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        incident['description'] ?? 'No details provided.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCatchReportsList() {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _catchReports.length,
        separatorBuilder: (_, __) => const SizedBox(width: 15),
        itemBuilder: (context, index) {
          final report = _catchReports[index];
          final imgPath = report['snake_image_path'];

          return Container(
            width: 220,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF131A14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imgPath != null
                          ? Image.network(
                              '${NexoraApiService.baseUrl}/../storage/$imgPath',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _defaultSnakeIcon(),
                            )
                          : _defaultSnakeIcon(),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report['species_identified'] ?? 'Unknown Species',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                          Text(
                            report['snake_condition'] ?? 'Unknown',
                            style: const TextStyle(
                                color: Color(0xFF00FF66), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Divider(color: Colors.white10),
                Text(
                  report['created_at'] != null
                      ? report['created_at'].toString().substring(0, 10)
                      : 'Date Unknown',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _defaultSnakeIcon() {
    return Container(
      width: 40,
      height: 40,
      color: Colors.black26,
      child: const Icon(Icons.pest_control_rounded,
          color: Colors.white38, size: 20),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F1B),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 15),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

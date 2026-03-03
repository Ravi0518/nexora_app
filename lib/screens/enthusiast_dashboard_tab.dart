import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'map_screen.dart';
import '../services/nexora_api_service.dart';

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
    final success = await NexoraApiService.updateExpertStatus(value);
    if (success && mounted) {
      setState(() => _isAvailable = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'You are now online' : 'You are now offline'),
          backgroundColor:
              value ? const Color(0xFF00FF66) : Colors.orangeAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update status'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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

  Widget _buildAssignedJobsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _activeRequests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final job = _activeRequests[index];
        final incident = job['incident'] ?? job; // Fallback for diff shapes

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131A14),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
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
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
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

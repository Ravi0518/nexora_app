import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';
import '../services/nexora_api_service.dart';

class MapScreen extends StatefulWidget {
  final int? activeIncidentId;
  final double? incidentLat;
  final double? incidentLng;

  const MapScreen({
    super.key,
    this.activeIncidentId,
    this.incidentLat,
    this.incidentLng,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  List<Map<String, dynamic>> _enthusiasts = [];
  List<Map<String, dynamic>> _incidents = [];
  bool _isLoading = true;
  bool _isListVisible = true;
  Timer? _refreshTimer;

  // Central Sri Lanka fallback position
  static const LatLng _initialPosition = LatLng(7.8731, 80.7718);

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadData();
    // Auto-refresh map data every 30 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _silentRefresh(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    if (widget.incidentLat != null && widget.incidentLng != null) {
      _currentLocation = LatLng(widget.incidentLat!, widget.incidentLng!);
      _mapController.move(_currentLocation!, 12);
      setState(() {});
      return;
    }

    final pos = await LocationService.getCurrentLocation();
    if (!mounted) return;
    if (pos != null) {
      _currentLocation = LatLng(pos.latitude, pos.longitude);
      _mapController.move(_currentLocation!, 10);
    }
    setState(() {});
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final enthusiastsData = await NexoraApiService.getEnthusiasts();
    final incidentsData = await NexoraApiService.getRecentIncidents();

    if (!mounted) return;

    // Sort enthusiasts by distance from current location if available
    if (_currentLocation != null) {
      enthusiastsData.sort((a, b) {
        final aLat =
            double.tryParse((a['last_lat'] ?? a['lat'])?.toString() ?? '');
        final aLng =
            double.tryParse((a['last_lng'] ?? a['lng'])?.toString() ?? '');
        final bLat =
            double.tryParse((b['last_lat'] ?? b['lat'])?.toString() ?? '');
        final bLng =
            double.tryParse((b['last_lng'] ?? b['lng'])?.toString() ?? '');

        if (aLat == null || aLng == null) return 1; // no GPS → to end
        if (bLat == null || bLng == null) return -1;

        final aDist = _haversineKm(_currentLocation!.latitude,
            _currentLocation!.longitude, aLat, aLng);
        final bDist = _haversineKm(_currentLocation!.latitude,
            _currentLocation!.longitude, bLat, bLng);
        return aDist.compareTo(bDist);
      });
    }

    setState(() {
      _enthusiasts = enthusiastsData;
      _incidents = incidentsData;
      _isLoading = false;
    });
  }

  /// Refresh enthusiast positions silently (no loading spinner).
  Future<void> _silentRefresh() async {
    final enthusiastsData = await NexoraApiService.getEnthusiasts();
    final incidentsData = await NexoraApiService.getRecentIncidents();
    if (!mounted) return;

    if (_currentLocation != null) {
      enthusiastsData.sort((a, b) {
        final aLat =
            double.tryParse((a['last_lat'] ?? a['lat'])?.toString() ?? '');
        final aLng =
            double.tryParse((a['last_lng'] ?? a['lng'])?.toString() ?? '');
        final bLat =
            double.tryParse((b['last_lat'] ?? b['lat'])?.toString() ?? '');
        final bLng =
            double.tryParse((b['last_lng'] ?? b['lng'])?.toString() ?? '');
        if (aLat == null || aLng == null) return 1;
        if (bLat == null || bLng == null) return -1;
        final aDist = _haversineKm(_currentLocation!.latitude,
            _currentLocation!.longitude, aLat, aLng);
        final bDist = _haversineKm(_currentLocation!.latitude,
            _currentLocation!.longitude, bLat, bLng);
        return aDist.compareTo(bDist);
      });
    }

    setState(() {
      _enthusiasts = enthusiastsData;
      _incidents = incidentsData;
    });
  }

  /// Haversine great-circle distance in km.
  double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = (dLat / 2).abs() < 1
        ? (dLat / 2) * (dLat / 2) +
            (dLng / 2) * (dLng / 2) * _cos(_toRad(lat1)) * _cos(_toRad(lat2))
        : 1.0;
    // simplified — good enough for nearby distances
    return r * 2 * (a < 1 ? (a > 0 ? a : 0) : 1);
  }

  double _toRad(double deg) => deg * 3.14159265358979 / 180;
  double _cos(double rad) => (rad * rad < 1) ? 1 - rad * rad / 2 : 0;

  // ── ENTHUSIAST DIALOG ────────────────────────────────────────────────────
  void _showEnthusiastDialog(
    BuildContext context,
    Map<String, dynamic> e,
    bool isAvailable,
    Color statusColor,
    String phone,
  ) {
    final name = '${e['fname'] ?? ''} ${e['lname'] ?? ''}'.trim();
    final affiliation = e['affiliation']?.toString() ?? 'Independent';
    // API returns either 'user_id' or 'id' depending on endpoint
    final userId = e['user_id'] ?? e['id'];
    final hasActiveIncident = widget.activeIncidentId != null && userId != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
        decoration: const BoxDecoration(
          color: Color(0xFF0E1A10),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── "Select this enthusiast" banner when coming from incident ──
            if (hasActiveIncident) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF66).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF00FF66).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.back_hand_rounded,
                        color: Color(0xFF00FF66), size: 16),
                    SizedBox(width: 8),
                    Text('Tap "Request Help" to notify this enthusiast',
                        style:
                            TextStyle(color: Color(0xFF00FF66), fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Avatar + name row
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  child:
                      Icon(Icons.person_rounded, color: statusColor, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : 'Enthusiast',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        affiliation,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    isAvailable ? 'Available' : 'Offline',
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Phone row
            if (phone.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_rounded,
                        color: Color(0xFF00FF66), size: 20),
                    const SizedBox(width: 12),
                    Text(phone,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 15)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Call button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await launchUrl(Uri.parse('tel:$phone'),
                          mode: LaunchMode.externalApplication);
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.call_rounded, size: 18),
                  label: const Text('Call Enthusiast',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF66),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No contact number available.',
                    style: TextStyle(color: Colors.white38, fontSize: 13)),
              ),
            ],
            // ── REQUEST HELP button — always prominent when incident is active ──
            if (hasActiveIncident) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final res = await NexoraApiService.assignIncident(
                      incidentId: widget.activeIncidentId!,
                      enthusiastId: userId,
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res['message']?.toString() ??
                          (res['success'] == true
                              ? 'Help request sent!'
                              : 'Failed.')),
                      backgroundColor: res['success'] == true
                          ? const Color(0xFF00FF66)
                          : Colors.redAccent,
                    ));
                  },
                  icon: const Icon(Icons.back_hand_rounded, size: 20),
                  label: const Text('Request Help',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A120A),
      appBar: AppBar(
        title: const Text(
          'Live Map',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── OPENSTREETMAP ───────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 8,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.nexora_app',
              ),
              MarkerLayer(
                markers: [
                  // 1. Current user location
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 30,
                      ),
                    ),
                  // 2. Enthusiast markers (green bubble with initial)
                  ..._enthusiasts
                      .where((e) =>
                          (e['last_lat'] != null && e['last_lng'] != null) ||
                          (e['lat'] != null && e['lng'] != null))
                      .map((e) {
                    final lat = double.tryParse(
                            (e['last_lat'] ?? e['lat'])?.toString() ?? '') ??
                        0.0;
                    final lng = double.tryParse(
                            (e['last_lng'] ?? e['lng'])?.toString() ?? '') ??
                        0.0;
                    final isAvailable =
                        (e['is_available'] == 1 || e['is_available'] == true);
                    final bubbleColor = isAvailable
                        ? const Color(0xFF00FF66)
                        : Colors.orangeAccent;
                    final initial =
                        (e['fname']?.toString() ?? '?')[0].toUpperCase();
                    final phone = e['phone']?.toString() ?? '';
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 52,
                      height: 62,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _showEnthusiastDialog(
                              context, e, isAvailable, bubbleColor, phone);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Bubble ──
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: bubbleColor.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            // ── Triangle pointer ──
                            CustomPaint(
                              size: const Size(14, 8),
                              painter: _BubbleTriangle(bubbleColor),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  // 3. Incident markers
                  ..._incidents
                      .where((i) => i['lat'] != null && i['lng'] != null)
                      .map((i) {
                    final lat = double.tryParse(i['lat'].toString()) ?? 0.0;
                    final lng = double.tryParse(i['lng'].toString()) ?? 0.0;
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFF1A1313),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.redAccent,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Active Incident',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Type: ${i['type'] ?? 'Unknown'}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Location: ${i['location_name'] ?? 'Unknown'}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                  ),
                                  if (i['description'] != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Details: ${i['description']}',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                  if (i['reporter_phone'] != null &&
                                      i['reporter_phone']
                                          .toString()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final url = Uri.parse(
                                            'tel:${i['reporter_phone']}',
                                          );
                                          try {
                                            await launchUrl(url,
                                                mode: LaunchMode
                                                    .externalApplication);
                                          } catch (e) {
                                            debugPrint(
                                                'Could not launch \$url');
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.phone_in_talk_rounded,
                                        ),
                                        label: const Text('Call Reporter'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text(
                                    'Close',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.redAccent.withValues(alpha: 0.2),
                            border: Border.all(
                              color: Colors.redAccent,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.redAccent,
                            size: 26,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // ── LOADING ─────────────────────────────────────────────────────
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF66)),
            ),

          // ── DRAGGABLE BOTTOM SHEET ─────────────────────────────────────────
          if (!_isLoading)
            Positioned.fill(
              child: IgnorePointer(
                // Only absorb pointer in the sheet region, pass through on the map
                ignoring: false,
                child: DraggableScrollableSheet(
                  initialChildSize: 0.3,
                  minChildSize: 0.08,
                  maxChildSize: 0.6,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1A10),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isListVisible = !_isListVisible;
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              color: Colors.transparent, // expand tap area
                              child: Column(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  if (!_isListVisible)
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 16),
                                      child: Text(
                                        'Show Map Lists',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (_isListVisible)
                            Expanded(
                              child: SingleChildScrollView(
                                controller: scrollController,
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // ── ENTHUSIASTS HEADER ──
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        0,
                                        20,
                                        8,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            '${_enthusiasts.length} Enthusiasts',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF00FF66,
                                              ).withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '${_enthusiasts.where((e) => e['is_available'] == 1 || e['is_available'] == true).length} Available',
                                              style: const TextStyle(
                                                color: Color(0xFF00FF66),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // ── ENTHUSIASTS LIST ──
                                    ListView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      shrinkWrap: true,
                                      itemCount: _enthusiasts.length,
                                      itemBuilder: (context, i) {
                                        final e = _enthusiasts[i];
                                        final isAvailable =
                                            (e['is_available'] == 1 ||
                                                e['is_available'] == true);
                                        final statusColor = isAvailable
                                            ? const Color(0xFF00FF66)
                                            : Colors.orangeAccent;
                                        final eLat = double.tryParse(
                                            (e['last_lat'] ?? e['lat'])
                                                    ?.toString() ??
                                                '');
                                        final eLng = double.tryParse(
                                            (e['last_lng'] ?? e['lng'])
                                                    ?.toString() ??
                                                '');
                                        final hasLocation =
                                            eLat != null && eLng != null;

                                        // Distance label
                                        String distLabel = 'No location';
                                        if (hasLocation &&
                                            _currentLocation != null) {
                                          final km = _haversineKm(
                                            _currentLocation!.latitude,
                                            _currentLocation!.longitude,
                                            eLat!,
                                            eLng!,
                                          );
                                          distLabel = km < 1
                                              ? '${(km * 1000).toStringAsFixed(0)} m away'
                                              : '${km.toStringAsFixed(1)} km away';
                                        }

                                        return GestureDetector(
                                          onTap: () {
                                            if (hasLocation) {
                                              _mapController.move(
                                                LatLng(eLat!, eLng!),
                                                15,
                                              );
                                            }
                                            _showEnthusiastDialog(
                                              context,
                                              e,
                                              isAvailable,
                                              statusColor,
                                              e['phone']?.toString() ?? '',
                                            );
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 10),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF131A14),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: isAvailable
                                                    ? const Color(0xFF00FF66)
                                                        .withValues(alpha: 0.3)
                                                    : Colors.white10,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                // Avatar bubble
                                                Container(
                                                  width: 42,
                                                  height: 42,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        statusColor.withValues(
                                                            alpha: 0.15),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      (e['fname']?.toString() ??
                                                              '?')[0]
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                        color: statusColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                // Name + distance
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        '${e['fname'] ?? ''} ${e['lname'] ?? ''}'
                                                            .trim(),
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .location_on_outlined,
                                                            size: 12,
                                                            color: statusColor,
                                                          ),
                                                          const SizedBox(
                                                              width: 3),
                                                          Text(
                                                            distLabel,
                                                            style:
                                                                const TextStyle(
                                                              color: Colors
                                                                  .white38,
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Status badge
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        statusColor.withValues(
                                                            alpha: 0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    border: Border.all(
                                                        color: statusColor
                                                            .withValues(
                                                                alpha: 0.4)),
                                                  ),
                                                  child: Text(
                                                    isAvailable
                                                        ? '🟢 Available'
                                                        : '🟡 Offline',
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                    // ── INCIDENTS SECTION ──
                                    if (_incidents.isNotEmpty) ...[
                                      const Divider(
                                        color: Colors.white10,
                                        height: 30,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          0,
                                          20,
                                          8,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              '${_incidents.length} Active Incidents',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // ── INCIDENTS LIST ──
                                      ListView.builder(
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        shrinkWrap: true,
                                        itemCount: _incidents.length,
                                        itemBuilder: (context, i) {
                                          final incident = _incidents[i];
                                          return ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.redAccent
                                                  .withValues(alpha: 0.2),
                                              child: const Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.redAccent,
                                                size: 20,
                                              ),
                                            ),
                                            title: Text(
                                              incident['type'] ??
                                                  'Unknown Sighting',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            subtitle: Text(
                                              incident['location_name'] ??
                                                  'Unknown Location',
                                              style: const TextStyle(
                                                color: Colors.white54,
                                                fontSize: 12,
                                              ),
                                            ),
                                            onTap: () {
                                              final lat = double.tryParse(
                                                  incident['lat'].toString());
                                              final lng = double.tryParse(
                                                  incident['lng'].toString());
                                              if (lat != null && lng != null) {
                                                _mapController.move(
                                                  LatLng(lat, lng),
                                                  15,
                                                );
                                              }
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Green bubble triangle pointer painter ──────────────────────────────────
class _BubbleTriangle extends CustomPainter {
  final Color color;
  const _BubbleTriangle(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = ui.Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubbleTriangle old) => old.color != color;
}

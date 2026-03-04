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
  int?
      _assigningSucceedId; // Expert ID who received the assignment successfully
  bool _isAssigning = false;

  // Central Sri Lanka fallback position
  static const LatLng _initialPosition = LatLng(7.8731, 80.7718);

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadData();
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
    // Replacing getRescueRequests with the new 24h incidents endpoint
    final incidentsData = await NexoraApiService.getRecentIncidents();

    if (!mounted) return;
    setState(() {
      _enthusiasts = enthusiastsData;
      _incidents = incidentsData;
      _isLoading = false;
    });
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
                  // 2. Enthusiast markers
                  ..._enthusiasts
                      .where((e) => e['lat'] != null && e['lng'] != null)
                      .map((e) {
                    final lat = double.tryParse(e['lat'].toString()) ?? 0.0;
                    final lng = double.tryParse(e['lng'].toString()) ?? 0.0;
                    final isAvailable =
                        (e['is_available'] == 1 || e['is_available'] == true);
                    final color = isAvailable
                        ? const Color(0xFF00FF66)
                        : Colors.orangeAccent;
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFF131A14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Text(
                                '${e['fname'] ?? ''} ${e['lname'] ?? ''}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${e['affiliation'] ?? 'Independent'}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    isAvailable
                                        ? 'Status: Available'
                                        : 'Status: Busy',
                                    style: TextStyle(color: color),
                                  ),
                                  if (e['phone'] != null &&
                                      e['phone'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 20),
                                    StatefulBuilder(
                                        builder: (ctx, setDialogState) {
                                      final bool isAssigned =
                                          _assigningSucceedId == e['user_id'];
                                      final bool canRequestHelp =
                                          widget.activeIncidentId != null &&
                                              e['user_id'] != null &&
                                              !isAssigned;

                                      return SizedBox(
                                        width: double.infinity,
                                        child: _isAssigning && canRequestHelp
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                        color:
                                                            Color(0xFF00FF66)))
                                            : canRequestHelp
                                                ? ElevatedButton.icon(
                                                    onPressed: () async {
                                                      setDialogState(() =>
                                                          _isAssigning = true);
                                                      final res =
                                                          await NexoraApiService
                                                              .assignIncident(
                                                        incidentId: widget
                                                            .activeIncidentId!,
                                                        enthusiastId:
                                                            e['user_id'],
                                                      );
                                                      if (!context.mounted)
                                                        return;
                                                      setDialogState(() {
                                                        _isAssigning = false;
                                                        if (res['success'] ==
                                                            true) {
                                                          _assigningSucceedId =
                                                              e['user_id'];
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(res[
                                                                          'message']
                                                                      ?.toString() ??
                                                                  'Help request sent!'),
                                                              backgroundColor:
                                                                  const Color(
                                                                      0xFF00FF66),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(res[
                                                                          'message']
                                                                      ?.toString() ??
                                                                  'Failed to send request.'),
                                                              backgroundColor:
                                                                  Colors
                                                                      .redAccent,
                                                            ),
                                                          );
                                                        }
                                                      });
                                                    },
                                                    icon: const Icon(Icons
                                                        .back_hand_rounded),
                                                    label: const Text(
                                                        'Help Request'),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                        0xFF00FF66,
                                                      ),
                                                      foregroundColor:
                                                          Colors.black,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        vertical: 12,
                                                      ),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                    ),
                                                  )
                                                : ElevatedButton.icon(
                                                    onPressed: () async {
                                                      final url = Uri.parse(
                                                        'tel:${e['phone']}',
                                                      );
                                                      if (await canLaunchUrl(
                                                          url)) {
                                                        await launchUrl(url,
                                                            mode: LaunchMode
                                                                .externalApplication);
                                                      }
                                                    },
                                                    icon: const Icon(
                                                      Icons
                                                          .phone_in_talk_rounded,
                                                    ),
                                                    label: const Text(
                                                        'Call / Contact'),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                        0xFF00FF66,
                                                      ),
                                                      foregroundColor:
                                                          Colors.black,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        vertical: 12,
                                                      ),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                    ),
                                                  ),
                                      );
                                    }),
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
                            color: color.withValues(alpha: 0.2),
                            border: Border.all(color: color, width: 2),
                          ),
                          child: Icon(
                            Icons.person_pin_circle_rounded,
                            color: color,
                            size: 26,
                          ),
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
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url,
                               mode: LaunchMode.externalApplication);
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

          // ── BOTTOM SHEET ─────────────────────────────────────────────────
          if (!_isLoading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
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
                              margin: const EdgeInsets.symmetric(vertical: 10),
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
                                        borderRadius: BorderRadius.circular(20),
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
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                shrinkWrap: true,
                                itemCount: _enthusiasts.length,
                                itemBuilder: (context, i) {
                                  final e = _enthusiasts[i];
                                  final isAvailable = (e['is_available'] == 1 ||
                                      e['is_available'] == true);
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: isAvailable
                                          ? const Color(
                                              0xFF00FF66,
                                            ).withValues(alpha: 0.2)
                                          : Colors.orangeAccent.withValues(
                                              alpha: 0.2,
                                            ),
                                      child: Text(
                                        (e['fname'] ?? '?')[0].toUpperCase(),
                                        style: TextStyle(
                                          color: isAvailable
                                              ? const Color(0xFF00FF66)
                                              : Colors.orangeAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      '${e['fname'] ?? ''} ${e['lname'] ?? ''}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${e['affiliation'] ?? 'Independent'} • ${e['experience_years'] ?? '?'} yrs',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                    onTap: () {
                                      final lat =
                                          double.tryParse(e['lat'].toString());
                                      final lng =
                                          double.tryParse(e['lng'].toString());
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
                                  physics: const NeverScrollableScrollPhysics(),
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
                                        incident['type'] ?? 'Unknown Sighting',
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
              ),
            ),
        ],
      ),
    );
  }
}

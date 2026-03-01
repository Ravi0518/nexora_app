import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLocation;

  // මූලික සිතියම් ස්ථානය (Mihintale)
  static const LatLng _initialPosition = LatLng(8.3444, 80.5024);

  // සිතියම මත පෙන්වන සලකුණු (Sample Incident Data)
  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('incident_1'),
      position: LatLng(8.3550, 80.5133),
      infoWindow: InfoWindow(
          title: "Russell's Viper", snippet: "High Priority • 15 min ago"),
    ),
    const Marker(
      markerId: MarkerId('incident_2'),
      position: LatLng(8.3300, 80.4900),
      infoWindow:
          InfoWindow(title: "Rat Snake", snippet: "Reported 2 hours ago"),
    ),
  };

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  // යූසර්ගේ වත්මන් ස්ථානය ලබා ගැනීම
  void _getUserLocation() async {
    final pos = await LocationService.getCurrentLocation();
    if (mounted) {
      if (pos != null) {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_currentLocation!, 14),
          );
        }
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A120A),
      appBar: AppBar(
        title: const Text("Nearby Incidents",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: Stack(
        children: [
          // Google Map Widget
          GoogleMap(
            initialCameraPosition:
                const CameraPosition(target: _initialPosition, zoom: 14),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),

          // Bottom Info Overlay (Matches Screen 16 UI)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F1A),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.5), blurRadius: 15)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _incidentTile("Russell's Viper", "2.3 km • Central Park",
                      Colors.redAccent),
                  const Divider(color: Colors.white10),
                  _incidentTile(
                      "Rat Snake", "4.1 km • Riverside", Colors.greenAccent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _incidentTile(String name, String detail, Color color) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(Icons.warning, color: color, size: 18)),
      title: Text(name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(detail,
          style: const TextStyle(color: Colors.white54, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
    );
  }
}

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'nexora_api_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;

  /// Starts tracking the enthusiast's location if they are available.
  Future<void> startTracking() async {
    if (_isTracking) return;

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    // Start listening to location updates
    _isTracking = true;
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update every 50 meters
      ),
    ).listen((Position position) {
      _handleLocationUpdate(position);
    });
  }

  /// Stops tracking location
  void stopTracking() {
    _positionStream?.cancel();
    _isTracking = false;
  }

  /// Handles a new location reading
  Future<void> _handleLocationUpdate(Position position) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if user is an enthusiast
    final role = prefs.getString('role');
    if (role != 'enthusiast') {
      stopTracking();
      return;
    }

    // Cache latest location locally
    await prefs.setDouble('last_lat', position.latitude);
    await prefs.setDouble('last_lng', position.longitude);

    // Send to API to update system map
    await NexoraApiService.updateExpertLocation(
      position.latitude,
      position.longitude,
    );
  }

  /// One-off location fetch for incidents
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          return null;
        }
      }

      return await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ));
    } catch (_) {
      return null;
    }
  }
}

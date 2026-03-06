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

    _isTracking = true;

    // ── Push location IMMEDIATELY on startup (don't wait for movement) ──
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await _handleLocationUpdate(pos);
    } catch (_) {
      // ignore permission/hardware errors — stream will retry
    }

    // Continue streaming updates every 50 metres
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

  /// One-off location fetch with timeout + fallback chain:
  ///   1. getCurrentPosition (8s timeout)
  ///   2. getLastKnownPosition
  ///   3. Locally cached coords from SharedPreferences
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _cachedPosition();

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return _cachedPosition();
      }

      // ── Try high-accuracy with an 8-second timeout ──────────────────────
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).timeout(const Duration(seconds: 8));
        // Cache it for future fallback
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('last_lat', pos.latitude);
        await prefs.setDouble('last_lng', pos.longitude);
        return pos;
      } catch (_) {
        // Timeout or error — fall through to last-known
      }

      // ── Fallback 1: Geolocator.getLastKnownPosition ─────────────────────
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) return lastKnown;

      // ── Fallback 2: locally cached coords ───────────────────────────────
      return _cachedPosition();
    } catch (_) {
      return _cachedPosition();
    }
  }

  /// Reconstructs a Position from SharedPreferences-cached lat/lng (best effort).
  static Future<Position?> _cachedPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('last_lat');
      final lng = prefs.getDouble('last_lng');
      if (lat == null || lng == null) return null;
      return Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 999,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    } catch (_) {
      return null;
    }
  }
}

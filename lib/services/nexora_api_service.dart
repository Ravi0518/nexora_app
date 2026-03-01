import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized API service for Nexora app.
/// Handles all data fetching: snakes, experts, incidents, rescue requests, facts.
class NexoraApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // ── AUTH HELPERS ────────────────────────────────────────────────────────────

  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, String>> _publicHeaders() async {
    return {'Accept': 'application/json', 'Content-Type': 'application/json'};
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 1. SNAKE SPECIES
  // ════════════════════════════════════════════════════════════════════════════

  /// GET /api/snakes — Full species list for collection screen.
  static Future<List<Map<String, dynamic>>> getSnakes({
    bool? venomous,
    String? region,
    String? search,
  }) async {
    try {
      String url = '$baseUrl/snakes';
      final params = <String, String>{};
      if (venomous != null) params['venomous'] = venomous.toString();
      if (region != null && region != 'All') params['region'] = region;
      if (search != null && search.isNotEmpty) params['q'] = search;
      if (params.isNotEmpty) {
        url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }

      final res =
          await http.get(Uri.parse(url), headers: await _publicHeaders());
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        // Handle Laravel paginated response: { data: [...], total: N, ... }
        if (decoded is Map && decoded.containsKey('data')) {
          return List<Map<String, dynamic>>.from(decoded['data']);
        }
        // Handle direct array response
        if (decoded is List) {
          return List<Map<String, dynamic>>.from(decoded);
        }
        // Handle wrapped: { snakes: [...] }
        for (final key in ['snakes', 'items', 'results']) {
          if (decoded is Map &&
              decoded.containsKey(key) &&
              decoded[key] is List) {
            return List<Map<String, dynamic>>.from(decoded[key]);
          }
        }
      }
      // Non-200 or unrecognised shape → fall back to local data
      return _localSnakeFallback();
    } catch (_) {
      return _localSnakeFallback();
    }
  }

  /// GET /api/snakes/{id} — Single snake detail.
  static Future<Map<String, dynamic>?> getSnakeById(int id) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/snakes/$id'),
        headers: await _publicHeaders(),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 2. USER PROFILE
  // ════════════════════════════════════════════════════════════════════════════

  /// GET /api/user/profile — Authenticated user's full profile.
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: await _authHeaders(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // Cache locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fname', data['fname'] ?? '');
        await prefs.setString('email', data['email'] ?? '');
        return data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 3. EXPERTS / NEARBY RESCUERS
  // ════════════════════════════════════════════════════════════════════════════

  /// GET /api/experts/nearby?lat=X&lng=Y — All available snake experts.
  static Future<List<Map<String, dynamic>>> getExperts(
      {double? lat, double? lng}) async {
    try {
      String url = '$baseUrl/experts/nearby';
      if (lat != null && lng != null) {
        url += '?lat=$lat&lng=$lng';
      } else {
        url += '?lat=8.3444&lng=80.5024';
      }
      final res = await http.get(
        Uri.parse(url),
        headers: await _authHeaders(),
      );
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// POST /api/experts/status — Update enthusiast availability status.
  static Future<bool> updateExpertStatus(bool isAvailable) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/experts/status'),
        headers: await _authHeaders(),
        body: jsonEncode({'is_available': isAvailable}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// POST /api/experts/location — Update enthusiast location
  static Future<bool> updateExpertLocation(double lat, double lng) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/experts/location'),
        headers: await _authHeaders(),
        body: jsonEncode({'lat': lat, 'lng': lng}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 4. INCIDENTS
  // ════════════════════════════════════════════════════════════════════════════

  /// GET /api/incidents — For map view.
  static Future<List<Map<String, dynamic>>> getIncidents() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/incidents'),
        headers: await _authHeaders(),
      );
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// POST /api/incidents — Submit a sighting/bite report.
  static Future<Map<String, dynamic>> submitIncident({
    required String type,
    required String description,
    required String locationName,
    double? lat,
    double? lng,
    String? imagePath,
  }) async {
    try {
      // Use multipart for image upload
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/incidents'),
      );
      final headers = await _authHeaders();
      request.headers.addAll(headers..remove('Content-Type'));
      request.fields['type'] = type;
      request.fields['description'] = description;
      request.fields['location_name'] = locationName;
      if (lat != null) request.fields['lat'] = lat.toString();
      if (lng != null) request.fields['lng'] = lng.toString();
      if (imagePath != null) {
        request.files
            .add(await http.MultipartFile.fromPath('image', imagePath));
      }

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        return {'success': true, ...jsonDecode(body)};
      }
      return {'success': false, 'message': 'Submission failed.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 5. RESCUE REQUESTS (ENTHUSIAST)
  // ════════════════════════════════════════════════════════════════════════════

  /// GET /api/rescue-requests — Pending requests for the logged-in enthusiast.
  static Future<List<Map<String, dynamic>>> getRescueRequests() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/rescue-requests'),
        headers: await _authHeaders(),
      );
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
      return _localRescueFallback();
    } catch (_) {
      return _localRescueFallback();
    }
  }

  /// POST accept/reject rescue request.
  static Future<bool> respondToRequest(String requestId, bool accept) async {
    try {
      final action = accept ? 'accept' : 'reject';
      final res = await http.post(
        Uri.parse('$baseUrl/rescue-requests/$requestId/$action'),
        headers: await _authHeaders(),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// POST /api/experts/catch-report — Submit an expert catch report
  static Future<Map<String, dynamic>> submitCatchReport({
    required String requestId,
    required String species,
    required String condition,
    required String comments,
    required String imagePath,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/experts/catch-report'),
      );
      final headers = await _authHeaders();
      request.headers.addAll(headers..remove('Content-Type'));

      request.fields['request_id'] = requestId;
      request.fields['species'] = species;
      request.fields['condition'] = condition;
      request.fields['comments'] = comments;
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        return {'success': true, ...jsonDecode(body)};
      }
      return {'success': false, 'message': 'Failed to submit.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 6. CONTENT CONTRIBUTION
  // ════════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> submitContent({
    required String type,
    required String title,
    required String content,
    String? mediaPath,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/content'),
      );
      final headers = await _authHeaders();
      request.headers.addAll(headers..remove('Content-Type'));
      request.fields['type'] = type;
      request.fields['title'] = title;
      request.fields['content'] = content;
      if (mediaPath != null) {
        request.files
            .add(await http.MultipartFile.fromPath('media', mediaPath));
      }
      final streamed = await request.send();
      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        return {'success': true, 'message': 'Submitted for review.'};
      }
      return {'success': false, 'message': 'Submission failed.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 7. DID YOU KNOW FACT
  // ════════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getRandomFact() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/facts/random'),
        headers: await _publicHeaders(),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      return _localFactFallback();
    } catch (_) {
      return _localFactFallback();
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // LOCAL FALLBACK DATA (used when API is unavailable / during development)
  // ════════════════════════════════════════════════════════════════════════════

  static List<Map<String, dynamic>> _localSnakeFallback() => [
        {
          'id': 1,
          'names': {
            'English': 'King Cobra',
            'සිංහල': 'රජ නයා',
            'தமிழ்': 'ராஜ நாகம்'
          },
          'scientific_name': 'Ophiophagus hannah',
          'is_venomous': true,
          'region': 'North',
          'image_url': null,
          'description':
              'The world\'s longest venomous snake, capable of reaching 18 feet.',
          'first_aid': 'Call 1990 immediately. Do not apply a tourniquet.',
          'habitat': 'Dense forests, grasslands near water bodies.',
        },
        {
          'id': 2,
          'names': {
            'English': 'Rat Snake',
            'සිංහල': 'හාල් දඬුවා',
            'தமிழ்': 'எலி பாம்பு'
          },
          'scientific_name': 'Ptyas mucosa',
          'is_venomous': false,
          'region': 'Central',
          'image_url': null,
          'description':
              'A large, harmless snake commonly found in agricultural areas.',
          'first_aid': 'Clean wound, apply antiseptic. Non-venomous.',
          'habitat': 'Paddy fields, urban gardens, forests.',
        },
        {
          'id': 3,
          'names': {
            'English': "Russell's Viper",
            'සිංහල': 'තිත් පොළඟා',
            'தமிழ்': 'விரியன்'
          },
          'scientific_name': 'Daboia russelii',
          'is_venomous': true,
          'region': 'Dry Zone',
          'image_url': null,
          'description':
              'One of the most dangerous snakes in Sri Lanka, responsible for most bite deaths.',
          'first_aid':
              'EMERGENCY: Call 1990. Immobilize patient. Reach hospital within 1 hour.',
          'habitat': 'Dry grasslands, scrub jungles, agricultural areas.',
        },
        {
          'id': 4,
          'names': {
            'English': 'Indian Cobra',
            'සිංහල': 'නයා',
            'தமிழ்': 'நாகம்'
          },
          'scientific_name': 'Naja naja',
          'is_venomous': true,
          'region': 'Wet Zone',
          'image_url': null,
          'description':
              'The iconic hooded snake of Sri Lanka, sacred in culture.',
          'first_aid':
              'Call 1990. Anti-venom required. Keep patient calm and still.',
          'habitat': 'Forests, plantations, paddy fields, human settlements.',
        },
        {
          'id': 5,
          'names': {
            'English': 'Green Pit Viper',
            'සිංහල': 'කොළ මැරිච්චා',
            'தமிழ்': 'பச்சை விரியன்'
          },
          'scientific_name': 'Trimeresurus trigonocephalus',
          'is_venomous': true,
          'region': 'Hill Country',
          'image_url': null,
          'description':
              'Sri Lanka\'s only endemic viper, bright green with a prehensile tail.',
          'first_aid':
              'Seek urgent medical attention. Anti-venom available at major hospitals.',
          'habitat': 'Rainforests, tea estates, montane forests.',
        },
        {
          'id': 6,
          'names': {
            'English': 'Sri Lanka Krait',
            'සිංහල': 'මාපිල',
            'தமிழ்': 'கட்டு விரியன்'
          },
          'scientific_name': 'Bungarus ceylonicus',
          'is_venomous': true,
          'region': 'Wet Zone',
          'image_url': null,
          'description': 'Endemic to Sri Lanka, extremely venomous, nocturnal.',
          'first_aid':
              'CRITICAL: Call 1990 immediately. Neurotoxic venom acts fast.',
          'habitat': 'Wet zone forests, rubber and coconut plantations.',
        },
      ];

  static List<Map<String, dynamic>> _localRescueFallback() => [
        {
          'id': 'REQ-9902',
          'location_name': 'Mihintale, Anuradhapura',
          'lat': 8.3444,
          'lng': 80.5024,
          'distance_km': 1.2,
          'reported_at': '5 mins ago',
          'description':
              'Large snake found near the garden gate. Seems inactive but needs removal.',
          'image_url':
              'https://images.unsplash.com/photo-1531386151447-ad762e755da6?w=600',
          'status': 'pending',
        },
      ];

  static Map<String, dynamic> _localFactFallback() => {
        'id': 1,
        'fact':
            'The Inland Taipan has the most toxic venom of any snake in the world.',
        'image_url': null,
      };
}

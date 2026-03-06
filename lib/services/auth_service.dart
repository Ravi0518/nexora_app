import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Use your Mac's Local IP (Run 'ifconfig' in terminal to find it)
  // 🔧 Use your Mac's WiFi IP (run: ipconfig getifaddr en0 in terminal)
  // ❌ 10.0.2.2 only works for Android Emulator, NOT real devices!
  static const String baseUrl = 'https://nexora.wisegen.lk/api';

  /// STEP 1: Send OTP to check email availability
  Future<Map<String, dynamic>> sendOTP(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Failed to send OTP',
      };
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  /// STEP 2: Verify OTP and create the account
  Future<Map<String, dynamic>> verifyAndRegister(
      Map<String, String> userData, String otp) async {
    try {
      final Map<String, dynamic> payload = {
        'fname': userData['fname'],
        'lname': 'NexoraUser',
        'email': userData['email'],
        'password': userData['password'],
        'role': userData['role'],
        'otp': otp,
      };

      if (userData['role'] == 'enthusiast') {
        payload['phone'] = userData['phone'];
        payload['affiliation'] = userData['org'];

        // Convert exp to int
        int expYears = 0;
        if (userData['exp'] != null && userData['exp']!.isNotEmpty) {
          expYears = int.tryParse(userData['exp']!) ?? 0;
        }
        payload['experience_years'] = expYears;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/verify-register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode(payload),
      );

      try {
        final data = jsonDecode(response.body);

        if (response.statusCode == 201 && data['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          if (data['token'] != null) {
            await prefs.setString('token', data['token']);
          }
          await prefs.setString('email', userData['email'] ?? '');
          await prefs.setString('role', userData['role'] ?? 'user');
          return {
            'success': true,
            'message': data['message'] ?? 'Account created.'
          };
        }

        return {
          'success': false,
          'message':
              data['message'] ?? 'Registration failed (${response.statusCode})'
        };
      } catch (e) {
        final preview = response.body.length > 50
            ? '${response.body.substring(0, 50)}...'
            : response.body;
        return {
          'success': false,
          'message': 'Server Error (${response.statusCode}): $preview'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// STEP 3: Resend Verification (for previously registered but unverified)
  Future<Map<String, dynamic>> resendEmailVerification(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/email/resend'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'] ?? 'Failed to resend'
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Authenticates user and persists session.
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final user = data['user'] as Map<String, dynamic>? ?? {};

        // Null-safe writes — setString() requires non-null String
        await prefs.setString(
            'token', (data['access_token'] ?? data['token'] ?? '').toString());
        await prefs.setString(
            'user_id', (user['user_id'] ?? user['id'] ?? '').toString());
        await prefs.setString(
            'fname', (user['fname'] ?? user['name'] ?? '').toString());
        await prefs.setString('email', (user['email'] ?? '').toString());
        await prefs.setString('role', (user['role'] ?? 'user').toString());

        return {'success': true, 'role': (user['role'] ?? 'user').toString()};
      }
      // Handle Account Not Active (SRS Requirement)
      else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Account inactive. Please verify email.'
        };
      } else {
        return {'success': false, 'message': 'Invalid email or password.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection Error.'};
    }
  }

  // ---------------------------------------------------------------------------
  // 2. PASSWORD & SESSION MANAGEMENT (The "Missing" Functions)
  // ---------------------------------------------------------------------------

  /// Sends password reset link.
  Future<Map<String, dynamic>> sendPasswordResetLink(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Your password reset link has been sent to your email.'
        };
      }
      return {'success': false, 'message': 'Email address not found.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error.'};
    }
  }

  /// Check if user is already logged in (for Auto-Login).
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }

  /// Clear all local session data.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Get headers for subsequent API calls (Sighting/Profile).
  Future<Map<String, String>> getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ---------------------------------------------------------------------------
  // 3. PROFILE MANAGEMENT (Own account modification - SRS Requirement)
  // ---------------------------------------------------------------------------

  /// Update user profile (name, phone).
  Future<Map<String, dynamic>> updateProfile(String name, String phone) async {
    try {
      final headers = await getAuthHeaders();
      final prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString('user_id');

      final response = await http.put(
        Uri.parse('$baseUrl/user/update/$userId'),
        headers: headers,
        body: jsonEncode({'fname': name, 'phone': phone}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Update cached name locally
        await prefs.setString('fname', name);
        return {'success': true, 'message': 'Profile updated successfully.'};
      }
      return {'success': false, 'message': data['message'] ?? 'Update failed.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Delete the authenticated user's account permanently.
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final headers = await getAuthHeaders();
      final prefs = await SharedPreferences.getInstance();

      final response = await http.delete(
        Uri.parse('$baseUrl/delete-account'),
        headers: headers,
      );

      // Accept 200 or 204 as success
      if (response.statusCode == 200 || response.statusCode == 204) {
        await prefs.clear();
        return {'success': true};
      }
      final data = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : <String, dynamic>{};
      return {'success': false, 'message': data['message'] ?? 'Delete failed.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}

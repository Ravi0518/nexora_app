import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Use your Mac's Local IP (Run 'ifconfig' in terminal to find it)
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  /// STEP 1: Send OTP to check email availability
  Future<Map<String, dynamic>> sendOTP(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/send-otp'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Connection failed: $e'};
    }
  }

  /// STEP 2: Verify OTP and create the account
  Future<Map<String, dynamic>> verifyAndRegister(Map<String, String> userData, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-register'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'fname': userData['fname'],
          'email': userData['email'],
          'password': userData['password'],
          'role': userData['role'],
          'otp': otp,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        // Optional: Save token immediately if you want auto-login
        // final prefs = await SharedPreferences.getInstance();
        // await prefs.setString('token', data['token']);
        return {'success': true, 'message': data['message']};
      }

      return {'success': false, 'message': data['message'] ?? 'Registration failed'};
    } catch (e) {
      return {'success': false, 'message': 'Server error: $e'};
    }
  }
  // ---------------------------------------------------------------------------
  // 1. AUTHENTICATION (Registration & Login)
  // ---------------------------------------------------------------------------

  /// Registers a new user with full error handling for SRS Requirement 03.
  Future<Map<String, dynamic>> register(
      String fname, String email, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'fname': fname,
          'lname': 'NexoraUser', // Required by DB Schema
          'email': email,
          'password': password,
          'password_confirmation': password, // Required by Laravel Validation
          'role': role,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'message': 'Account created successfully!'};
      }
      // Handle Duplicate Email (Requirement 03)
      else if (response.statusCode == 409 || (response.statusCode == 422 && data['errors']?['email'] != null)) {
        return {'success': false, 'message': 'This email is already registered.'};
      }
      else {
        return {'success': false, 'message': data['message'] ?? 'Registration failed.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network Error: Cannot reach server.'};
    }
  }

  /// Authenticates user and persists session.
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();

        // FIX: Mapping 'access_token' from Laravel response
        await prefs.setString('token', data['access_token']);
        await prefs.setString('user_id', data['user']['user_id'].toString());
        await prefs.setString('fname', data['user']['fname']);
        await prefs.setString('email', data['user']['email']);
        await prefs.setString('role', data['user']['role']);

        return {'success': true, 'role': data['user']['role']};
      }
      // Handle Account Not Active (SRS Requirement)
      else if (response.statusCode == 403) {
        return {'success': false, 'message': 'Account inactive. Please verify email.'};
      }
      else {
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
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Reset link sent to your email.'};
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
      'Authorization': 'Bearer $token',
    };
  }
}
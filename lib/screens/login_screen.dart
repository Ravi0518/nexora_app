import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  void _login() async {
    if (_email.text.isEmpty || _pass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await _auth.login(_email.text.trim(), _pass.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success']) {
      // FIX: Ensure these match the 'role' strings in your Laravel Database
      if (res['role'] == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        // This covers 'general_public' or any other non-admin role
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "Login Failed"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const SizedBox(height: 100),

            // UPDATED: Logo from Assets
            Image.asset(
              'assets/images/logo.png',
              height: 120,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if image path is wrong
                return const Icon(Icons.bug_report, color: Color(0xFF00FF66), size: 80);
              },
            ),

            const SizedBox(height: 30),
            const Text("Welcome Back", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Log in to continue your adventure.", style: TextStyle(color: Colors.white38, fontSize: 16)),
            const SizedBox(height: 50),

            _label("Email"),
            _field(_email, "Enter your email", Icons.email_outlined),

            const SizedBox(height: 25),

            _label("Password"),
            _field(_pass, "Enter your password", Icons.lock_outline, isPass: true),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                child: const Text("Forgot Password?", style: TextStyle(color: Color(0xFF00FF66))),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF66),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("Login", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? ", style: TextStyle(color: Colors.white38)),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SignupScreen())),
                  child: const Text("Sign Up", style: TextStyle(color: Color(0xFF00FF66), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))));

  Widget _field(TextEditingController c, String h, IconData i, {bool isPass = false}) => TextField(
    controller: c,
    obscureText: isPass ? _obscure : false,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: h,
      hintStyle: const TextStyle(color: Colors.white12),
      prefixIcon: Icon(i, color: Colors.white38),
      suffixIcon: isPass ? IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
          onPressed: () => setState(() => _obscure = !_obscure)
      ) : null,
      filled: true,
      fillColor: const Color(0xFF1A1F1B),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00FF66), width: 1)),
    ),
  );
}
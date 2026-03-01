import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart'; // Make sure to create this file

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  String _selectedRole = 'user';
  bool _isLoading = false;
  bool _obscure = true;

  // --- REGISTRATION LOGIC ---
  void _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // PHASE 1: Send OTP & Check Email Availability on Server
      final res = await _auth.sendOTP(_emailController.text.trim());

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res['success']) {
        // PHASE 2: Navigate to OTP Verification Screen
        // We pass the data here, but it ONLY saves to the DB after OTP is verified
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(
              userData: {
                'fname': _nameController.text.trim(),
                'email': _emailController.text.trim(),
                'password': _passController.text.trim(),
                'role': _selectedRole,
              },
            ),
          ),
        );
      } else {
        // Show Error (e.g., Email already registered)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connection error. Is Laravel running?"), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white)
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Branded Logo
              Image.asset('assets/images/logo.png', height: 100,
                  errorBuilder: (c, e, s) => const Icon(Icons.bug_report, color: Color(0xFF00FF66), size: 50)),

              const SizedBox(height: 25),
              const Text("Create Account", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Verify your email to join Nexora.", style: TextStyle(color: Colors.white38, fontSize: 16)),
              const SizedBox(height: 40),

              // ROLE SELECTION
              const Align(alignment: Alignment.centerLeft, child: Text("I am a...", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500))),
              const SizedBox(height: 12),
              Row(
                children: [
                  _roleBtn("General Public", _selectedRole == 'user', () => setState(() => _selectedRole = 'user')),
                  const SizedBox(width: 10),
                  _roleBtn("Snake Enthusiast", _selectedRole == 'enthusiast', () => setState(() => _selectedRole = 'enthusiast')),
                ],
              ),

              const SizedBox(height: 35),

              _label("Full Name"),
              _field(_nameController, "Enter your name", Icons.person_outline,
                  validator: (v) => (v == null || v.isEmpty) ? "Name is required" : null),

              const SizedBox(height: 20),

              _label("Email Address"),
              _field(_emailController, "example@mail.com", Icons.email_outlined,
                  validator: (v) => (v != null && !v.contains('@')) ? "Invalid email" : null),

              const SizedBox(height: 20),

              _label("Password"),
              _field(_passController, "Min. 8 characters", Icons.lock_outline, isPass: true,
                  validator: (v) => (v != null && v.length < 8) ? "Password too short" : null),

              const SizedBox(height: 50),

              // MAIN CTA BUTTON
              SizedBox(
                width: double.infinity, height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF66),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _handleSignup,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text("Get Verification Code", style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? ", style: TextStyle(color: Colors.white38)),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text("Log In", style: TextStyle(color: Color(0xFF00FF66), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI HELPER WIDGETS ---
  Widget _roleBtn(String t, bool s, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: s ? const Color(0xFF132A1C) : const Color(0xFF1A1F1B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: s ? const Color(0xFF00FF66) : Colors.transparent),
        ),
        child: Center(child: Text(t, style: TextStyle(color: s ? Colors.white : Colors.white38, fontWeight: FontWeight.bold))),
      ),
    ),
  );

  Widget _label(String text) => Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))));

  Widget _field(TextEditingController c, String h, IconData i, {bool isPass = false, String? Function(String?)? validator}) => TextFormField(
    controller: c,
    obscureText: isPass ? _obscure : false,
    validator: validator,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: h, hintStyle: const TextStyle(color: Colors.white10),
      prefixIcon: Icon(i, color: Colors.white38, size: 20),
      suffixIcon: isPass ? IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white38), onPressed: () => setState(() => _obscure = !_obscure)) : null,
      filled: true, fillColor: const Color(0xFF1A1F1B),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00FF66))),
      errorStyle: const TextStyle(color: Colors.redAccent),
    ),
  );
}
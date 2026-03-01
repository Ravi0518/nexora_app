import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String lang;
  const ForgotPasswordScreen({super.key, this.lang = 'English'});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _auth = AuthService();
  bool _isLoading = false;

  // Localization helper
  String _t(String key) => LanguageService.t(widget.lang, key);

  // ── FUNCTIONAL REQUIREMENT: Password forgot form data submits + validation ──
  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();

    // Validation
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('email_invalid')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Wire to real API
    final res = await _auth.sendPasswordResetLink(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(res['success'] ? _t('reset_sent') : _t('reset_not_found')),
        backgroundColor:
            res['success'] ? const Color(0xFF00FF66) : Colors.redAccent,
      ),
    );

    if (res['success']) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('reset_password'),
                style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 15),
            Text(
              _t('reset_subtitle'),
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 40),
            Text(_t('email_address'),
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: _t('email_hint'),
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF141D16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF00FF66))),
                prefixIcon:
                    const Icon(Icons.email_outlined, color: Colors.white38),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF66),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _isLoading ? null : _sendResetLink,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(_t('send_instructions'),
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

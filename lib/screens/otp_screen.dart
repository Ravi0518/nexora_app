import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';

class OTPScreen extends StatefulWidget {
  final Map<String, String> userData;
  final String lang;
  const OTPScreen({super.key, required this.userData, this.lang = 'English'});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _otpController = TextEditingController();
  final _auth = AuthService();
  bool _isVerifying = false;

  String _t(String key) => LanguageService.t(widget.lang, key);

  void _verify() async {
    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_t('enter_otp')), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isVerifying = true);
    final res = await _auth.verifyAndRegister(
        widget.userData, _otpController.text.trim());
    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (res['success']) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_t('reset_sent')),
            backgroundColor: const Color(0xFF00FF66)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(res['message']?.toString() ?? 'Verification failed.'),
            backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_t('verify_email'),
            style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.mark_email_read_outlined,
                color: Color(0xFF00FF66), size: 70),
            const SizedBox(height: 25),
            Text(
              _t('otp_subtitle'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(
                  fontSize: 32, letterSpacing: 10, color: Color(0xFF00FF66)),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: const TextStyle(color: Colors.white12),
                filled: true,
                fillColor: const Color(0xFF1A1F1B),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Color(0xFF00FF66)),
                ),
                counterStyle: const TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF66),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _isVerifying ? null : _verify,
                child: _isVerifying
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        _t('verify_btn'),
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

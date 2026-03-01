import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class OTPScreen extends StatefulWidget {
  final Map<String, String> userData;
  const OTPScreen({super.key, required this.userData});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _otpController = TextEditingController();
  final _auth = AuthService();
  bool _isVerifying = false;

  void _verify() async {
    setState(() => _isVerifying = true);
    final res = await _auth.verifyAndRegister(widget.userData, _otpController.text.trim());
    setState(() => _isVerifying = false);

    if (res['success']) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success! Please Login.")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message']), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text("OTP Verification")),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Text("Enter the 6-digit code sent to your email", textAlign: TextAlign.center),
            const SizedBox(height: 30),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 32, letterSpacing: 10, color: Color(0xFF00FF66)),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: "000000", filled: true, fillColor: Color(0xFF1A1F1B)),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF66)),
                onPressed: _isVerifying ? null : _verify,
                child: _isVerifying ? const CircularProgressIndicator() : const Text("Confirm & Register", style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class VerifyEmailPanel extends StatelessWidget {
  const VerifyEmailPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/nexor.png', height: 120),
            const SizedBox(height: 50),
            const Text("Check Your Email",
                style: TextStyle(
                    color: Color(0xFF00FF66),
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            const Text(
              "We've sent a verification link to your inbox. Please verify your account to start your adventure.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF66)),
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: const Text("Proceed to Login",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

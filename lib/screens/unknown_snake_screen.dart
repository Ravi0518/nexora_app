import 'package:flutter/material.dart';

class UnknownSnakeScreen extends StatelessWidget {
  final String lang;

  const UnknownSnakeScreen({
    super.key,
    required this.lang,
  });

  String _t(String en, String si, String ta) {
    if (lang == 'සිංහල') return si;
    if (lang == 'தமிழ்') return ta;
    return en;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07120B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: Colors.blueAccent,
                size: 80,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _t('Snake Not in Database', 'සර්පයා දත්ත ගබඩාවේ නොමැත',
                  'பாம்பு தரவுத்தளத்தில் இல்லை'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _t(
                'A snake was detected in this image, but our AI cannot confidently identify its species. It may be a rare or undocumented snake.',
                'මෙම ඡායාරූපයේ සර්පයෙකු හඳුනාගෙන ඇත, නමුත් අපගේ AI හට එහි වර්ගය විශ්වාසයෙන් හඳුනාගත නොහැක. එය දුර්ලභ හෝ ලේඛනගත කර නොමැති සර්පයෙකු විය හැකිය.',
                'இந்தப் படத்தில் ஒரு பாம்பு கண்டறியப்பட்டுள்ளது, ஆனால் எங்கள் AI ஆல் அதன் இனத்தை நம்பிக்கையுடன் அடையாளம் காண முடியவில்லை. இது ஒரு அரிய அல்லது ஆவணப்படுத்தப்படாத பாம்பாக இருக்கலாம்.',
              ),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white12,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _t('Go Back', 'ආපසු යන්න', 'திரும்பிச் செல்'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60), // Push slightly above true center
          ],
        ),
      ),
    );
  }
}

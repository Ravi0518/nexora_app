import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _key = 'user_lang';

  static Map<String, Map<String, String>> translations = {
    'English': {
      'welcome': 'Welcome back,',
      'quick_id': 'Quick Identify',
      'point_cam': 'Point camera at snake',
      'recent': 'Recent Activity',
      'emergency': 'EMERGENCY: Call Helpline',
      'request_help': 'Request Assistance',
    },
    'සිංහල': {
      'welcome': 'ආයුබෝවන්,',
      'quick_id': 'සර්පයා හඳුනාගන්න',
      'point_cam': 'කැමරාව සර්පයා දෙසට යොමු කරන්න',
      'recent': 'මෑතකදී බැලූ සර්පයන්',
      'emergency': 'හදිසි ඇමතුම: 1990',
      'request_help': 'සහාය ලබාගන්න',
    },
    'தமிழ்': {
      'welcome': 'வரவேற்கிறோம்,',
      'quick_id': 'அடையாளம் காணுங்கள்',
      'point_cam': 'பாம்பின் மீது கேமராவைக் காட்டவும்',
      'recent': 'சமீபத்திய செயல்பாடு',
      'emergency': 'அவசரகாலம்: 1990',
      'request_help': 'உதவி கோருங்கள்',
    }
  };

  static Future<void> setLang(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, lang);
  }

  static Future<String?> getLang() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }
}